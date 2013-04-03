function physiosetObj = import(obj, varargin)
% IMPORT - Imports MFF files
%
% pObj = import(obj, fileName)
% pObjArray = import(obj, fileName1, fileName2, ...);
%
% ## Notes:
%
%   * Compressed .gz files are supported.
%
% See also: mff


import pset.globals;
import mperl.split;
import io.mff2.*
import physioset.physioset;
import physioset.event.event;
import misc.sizeof;
import misc.eta;
import pset.file_naming_policy;
import exceptions.*
import misc.decompress;

if numel(varargin) == 1 && iscell(varargin{1}),
    varargin = varargin{1};
end

% Deal with the multi-file case
if nargin > 2
    pObj = cell(numel(varargin), 1);
    for i = 1:numel(varargin)
        pObj{i} = import(obj, varargin{i});
    end
    return;
end

fileName = varargin{1};

% Default values of optional input arguments
verbose      = is_verbose(obj);
verboseLabel = get_verbose_label(obj);
origVerboseLabel = goo.globals.get.VerboseLabel;
goo.globals.set('VerboseLabel', verboseLabel);

% The input file might be zipped
[status, fileName] = decompress(fileName, 'Verbose', verbose);
isZipped = ~status;

% Determine the names of the generated (imported) files
if isempty(obj.FileName),
    
    newFileName = file_naming_policy(obj.FileNaming, fileName);
    dataFileExt = globals.get.DataFileExt;
    newFileName = [newFileName dataFileExt];
    
else
    
    newFileName = obj.FileName;
    
end


%% IMPORTANT: The BIOSIG toolbox includes its own version of str2double,
% which can slow down considerably mff data import. Therefore, we must get
% rid of the BIOSIG toolbox from the path. Another reason why BIOSIG should
% be within a package instead of polluting the global namespace
myPath = path;
if isunix
   myPath = split(':', myPath); 
else
   myPath = split(';', myPath); 
end
mustRemove = cellfun(@(x) ~isempty(strfind(x, 't200_FileAccess')), myPath);
if any(mustRemove),
    rmpath(myPath{mustRemove});
end

%% Read first block of file
if verbose,
    fprintf([verboseLabel 'Reading first data block of %s...'], ...
        fileName)
end
if ~exist(fileName, 'file'),
    [pathName, fileName] = fileparts(fileName);
    if exist([pathName filesep fileName], 'file')
        fileName = [pathName filesep fileName];
    else
        throw(InvalidArgValue('fileName', ...
            'Must be a valid (existing) file name'));
    end
end
[data, fs, fidBins] = read_data(fileName, 1, 1, [], true, false); 
if ~iscell(data),
    data = {data};
end
if verbose,
    fprintf('[done]\n\n')
end

%% Read header
if verbose,
    fprintf([verboseLabel 'Reading header...']);
end
hdr = read_header(fileName);
if verbose,
    fprintf('[done]\n\n')
end
hdr.fs = fs;

% Size of a block in bytes
if ~iscell(data), data = {data}; end
blockSize = 0;
for i = 1:numel(data)
    blockSize = blockSize + sizeof(class(data{i}(1)))*numel(data{i});
end

% Number of blocks that are to be read in one time
maxMemoryChunk  = globals.get.LargestMemoryChunk;
nbBlocksPerRead = ceil(maxMemoryChunk/blockSize);

% Approximate number of blocks
lastPos = nan(1, numel(fidBins));
pos     = nan(1, numel(fidBins));
for i = 1:numel(fidBins)
    pos(i) = ftell(fidBins(i));
    fseek(fidBins(i), 0, 'eof');
    lastPos(i) = ftell(fidBins(i));
    fseek(fidBins(i), pos(i), 'bof');
end

%% Read sensor information
if verbose,
    fprintf([verboseLabel 'Reading sensor information...']);
end
[sens, fids, ext] = read_sensors(fileName);

% Fiducials
if ~isempty(fids),
    fidStr      = fids;
    fiducials   = mjava.hash;
    fiducials{fidStr.label{:}} = ...
        mat2cell(fidStr.loc, ones(size(fidStr.loc,1),1), 3);  
else
    fiducials = [];
end

% Extra head surface points
if ~isempty(ext.label),
    extraStr    = ext;
    extra       = mjava.hash;
    extra{extraStr.label{:}} = ...
        mat2cell(extraStr.loc, ones(size(extraStr.loc,1),1), 3);
else
    extra = [];
end

eegSensors = sensors.eeg(...
    'Name',         hdr.signal{1}.sensorLayout, ...
    'Cartesian',    sens.loc, ...
    'OrigLabel',    sens.label, ...
    'Fiducials',    fiducials, ...
    'Extra',        extra); 

% Read calibrations for eeg sensors
[gcal, ical] = read_cal(fileName);
eegSensors = set_meta(eegSensors, 'gcal', gcal);
eegSensors = set_meta(eegSensors, 'ical', ical);

% Take care of additional physiological sensors
if numel(hdr.signal) > 1,    
    % Read PNS sensor information
    sens = read_pns_sensors(fileName);
    pnsSensors = sensors.physiology(...
        'Name',         hdr.signal{2}.pnsSetName, ...
        'Label',        sens.name, ...
        'OrigLabel',    sens.name, ...        
        'PhysDim',      sens.unit);    
else
    pnsSensors = [];
end

if verbose,
    fprintf('[done]\n\n');
end

%% Read events
if verbose,
    fprintf([verboseLabel 'Reading events...']);
end
evArray = read_events(fileName, hdr.fs, hdr.beginTime);
if verbose,
    fprintf('[done]\n\n');
end

%% Read data values
fid = fopen(newFileName, 'w');
if fid < 1,
    error('Could not open %s for writing', newFileName);
end

try
    if verbose,
        fprintf('%sWriting data to %s...', verboseLabel, newFileName);
    end
    
    begBlock = 2;
    endBlock = begBlock + nbBlocksPerRead-1;
    
    if ~isempty(pnsSensors),
        sensorsMixed = sensors.mixed(eegSensors, pnsSensors);
    else
        sensorsMixed = eegSensors;
    end
    
    tinit = tic;
    
    while any(cellfun(@(x) ~isempty(x), data)),
        % Discard last (flat) channels
        for i = 1:numel(data)
            data{i}(end,:) = [];
        end
        % Write data to disk
        data = cell2mat(data);
        fwrite(fid, data(:), obj.Precision);
        [data, ~, fidBins] = read_data(fileName, ...
            begBlock, endBlock, [], true, true);
        begBlock = begBlock + nbBlocksPerRead;
        endBlock = endBlock + nbBlocksPerRead;
        if ~iscell(data),
            data = {data};
        end
        if verbose,
           eta(tinit, lastPos(1), ftell(fidBins(1))); 
        end        
    end    
    clear +io/+mff2/read_data; % Clear persistent block counter
   
catch ME
    fclose(fid);
    if ~isempty(fidBins),
        for i = 1:numel(fidBins),
            fclose(fidBins(i));
        end
    end
    clear +io/+mff2/read_data; % Clear persistent block counter
    clear fid fidBins;
    rethrow(ME);
end
fclose(fid);
if ~isempty(fidBins),
    for i = 1:numel(fidBins),
        fclose(fidBins(i));
    end
end
clear fid fidBins;
if verbose,
    fprintf('\n\n');
end

%% Generate output object
if verbose,
    fprintf('%sGenerating a physioset object...', verboseLabel);
end
sampleRate = hdr.fs;

recordTime = hdr.beginTime;

mat = regexpi(recordTime, ...
    ['(?<year>\d{4}+)-(?<month>\d\d)-(?<day>\d\d)T', ...
    '(?<hours>\d\d):(?<mins>\d\d):(?<secs>\d\d).', ...
    '(?<dec>[^+]+)'], ...
    'names');
startTime = [mat.hours ':' mat.mins ':' mat.secs];
startDate = [mat.day '-' mat.month '-' mat.year];

physiosetArgs = construction_args_physioset(obj);
physiosetObj = physioset(newFileName, nb_sensors(sensorsMixed), ...
    physiosetArgs{:}, ...
    'SamplingRate',     sampleRate, ...
    'Sensors',          sensorsMixed, ...
    'StartDate',        startDate, ...
    'StartTime',        startTime, ...
    'Event',            evArray, ...
    'Header',           hdr);

if verbose,
    fprintf('[done]\n\n');
end

%% Undoing stuff 

% Add BIOSIG back to the path
if any(mustRemove),
    addpath(myPath{mustRemove});
end

% Unset the global verbose
goo.globals.set('VerboseLabel', origVerboseLabel);

% Delete unzipped data file
if isZipped,
    delete(fileNameIn);
end

end



