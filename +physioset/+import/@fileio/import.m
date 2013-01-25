function physiosetObj = import(obj, filenameIn, varargin)
% IMPORT - Imports FILEIO files
%
% physiosetObj = import(obj, filename)
% physiosetObj = import(obj, 'key', value, ...)
%
% Where
%
% OBJ is an physioset.import.fileio object
%
% FILENAME is the name of the file to be imported. Alternatively, FILENAME
% can be the name of a directory in which case all files within the
% directory will be imported.
%
% 
% ## Most relevant key/value pairs:
%
%       Filename : (string) Default: session.instance.tempname
%           Name of the generated file. This argument is ignored if
%           FILENAME is a cell array of file names.
%
%       StartTime : (numeric scalar) Default: [], i.e. read from beginning
%           Start time of the EEG epoch to read from the file, seconds
%
%       EndTime : (numeric scalar) Default: [], i.e. read until the end
%           End time of the EEG epoch, in seconds
%
%       Channels : (natural) Default: [], i.e. all opt.channels
%           Indices of the channels to read
%
%       Verbose : (logical) Default: OBJ.Verbose
%
%
% ## Secondary key/value pairs:
%
%       StartSample : (natural scalar) Default: 1
%           First sample to read
%
%       EndSample : (natural scalar) Default: [], last recorded sample
%           Last sample to read
% 
% Notes:
%
% * The epoch range has to be specified either in samples or in time but not
%   in both
%
% * You can used external.regexpdir.regexpdir to build the cell array of
%   files that are to be imported. Example:
%
%   import external.regexpdir.regexpdir;
%   % Get names of all .mff files under the root directory dataFolder
%   myFiles = regexpdir('C:/dataFolder', '.mff$', true);
%   myObj = import(physioset.import.fileio, myFiles);
%
%
% See also: physioset.import.


% Description: Import data from disk file
% Documentation: class_physioset.import.fileio.txt

if iscell(filenameIn),
    physiosetObj = cell(numel(filenameIn), 1);
    for i = 1:numel(filenameIn)
        physiosetObj{i} = import(obj, filenameIn{i}, varargin{:});
    end   
    return;   
end

import physioset.
import physioset.import.globals;
import pset.event;
import pset.file_naming_policy;
import misc.process_arguments;
import misc.sizeof;
import misc.eta;
import misc.decompress;

if nargin < 2,
    ME = MException('import:invalidInput', ...
        'At least two input arguments are expected');
    throw(ME);
end

% Add fieltrip to the pathname
pathAdded = false;
if isempty(strfind(path, obj.Fieldtrip))
    addpath(genpath(obj.Fieldtrip));
    pathAdded = true;
end

% Default values of optional input arguments
opt.filename    = [];
opt.dateformat  = globals.evaluate.DateFormat;
opt.timeformat  = globals.evaluate.TimeFormat;
opt.regexp      = '([^.]+)';
opt.verbose     = obj.Verbose;

opt.starttime   = [];
opt.endtime     = [];
opt.startsample = [];
opt.endsample   = [];
opt.channels    = [];

[~, opt] = process_arguments(opt, varargin);

if (~isempty(opt.starttime) || ~isempty(opt.endtime)) && ...
        (~isempty(opt.startsample) || ~isempty(opt.endsample)),
    ME = MException('import:invalidInput', ...
        ['Data range must be specified either in samples or in time ' ...
        '(seconds) but not in both']);
    throw(ME);
end

if ~isempty(filenameIn) && ~isempty(opt.folder),
    ME = MException('import:invalidInput', ...
        ['The ''opt.folder'' optional argument is only accepted if the '...
        'Iopt.filename mandatory input argument is empty']);
    throw(ME);
end

% Use recursion to process a opt.folder file by file
if isempty(filenameIn) && isempty(opt.folder),
    physiosetObj = [];
    return;
elseif isempty(filenameIn)    
    file_list = opt.regexpi_dir(opt.folder, opt.regexp);
    physiosetObj = cell(numel(file_list), 1);
    [~, remove_flag] = process_varargin(...
        {'opt.folder', 'opt.verbose', 'compact'}, varargin);
    for i = 1:numel(file_list)
        if opt.verbose,
            [~, this_name, this_ext] = fileparts(file_list{i});
            fprintf('\n(import) Importing ''%s''...', [this_name this_ext]);            
        end
        physiosetObj{i} = import(obj, file_list{i}, 'opt.verbose', false, ...
             varargin{~remove_flag});  
        if opt.verbose,
            fprintf('[done]\n');            
        end       
    end
    return;
end

% The input file might be zipped
[status, filenameIn] = decompress(filenameIn, 'opt.verbose', opt.verbose);
isZipped = ~status;

% Determine the names of the generated (imported) files
if isempty(opt.filename),
    opt.filename = file_naming_policy(obj.FileNaming, filenameIn);
end

opt.filename = strrep(opt.filename, obj.DataFileExt, '');
opt.filename = [opt.filename obj.DataFileExt];

% Read the header
% =========================================================================
if opt.verbose,
    fprintf('\n(import) Reading header...');
end
hdr = ft_read_header(filenameIn);

if isempty(opt.channels),
    opt.channels = 1:hdr.nChans;
end

sr = hdr.Fs;
sampling_time   = linspace(0, hdr.nSamples/sr, hdr.nSamples);
sensor_label    = hdr.label;
rec_start_date  = datestr(now, opt.dateformat);
rec_start_time  = datestr(now, opt.timeformat);

if opt.verbose,
    fprintf('[done]\n');
    pause(0.001); % To ensure that fprintf flushes the buffer
end

% Read events
% =========================================================================
if obj.ReadEvents
    if opt.verbose,
        fprintf('\n(import) Reading events...');
    end
    eventStr = ft_read_event(filenameIn, 'header', hdr);
    if opt.verbose,
        fprintf('[done]\n');
        pause(0.001);
    end
    if ~isempty(eventStr), 
        eventObj = pset.event.from_fieldtrip(eventStr); 
    end
else
    eventObj = [];    
end


% Read the signal values
% =========================================================================
if opt.verbose,
    fprintf('\n(import) Writing data to binary file...');
end
tinit = tic;
chunksize = floor(obj.ChunkSize/(sizeof(obj.Precision)*length(opt.channels))); % in samples
if hdr.nTrials > 1,
    % Chunk size must be an integer number of trials
    chunksize = floor(chunksize/(hdr.nSamples))*hdr.nSamples;
end
boundary = 1:chunksize:(hdr.nSamples*hdr.nTrials);
if length(boundary)<2 || boundary(end) < hdr.nSamples*hdr.nTrials,
    boundary = [boundary,  hdr.nSamples*hdr.nTrials+1];
else
    boundary(end) = boundary(end)+1;
end
n_chunks = length(boundary) - 1;
fid = fopen(opt.filename, 'w');
if fid < 1,
    ME = MException('physioset.import.fileio:import', ...
        'I could not open file %s for writing', opt.filename);
    throw(ME);
end
for chunk_itr = 1:n_chunks    
    dat = ft_read_data(filenameIn, 'begsample', boundary(chunk_itr),...
        'endsample', boundary(chunk_itr+1)-1, 'checkboundary', false, ...
        'chanidx', opt.channels, 'header', hdr);     
    if ndims(dat) > 2,
        dat = reshape(dat, [size(dat,1), round(numel(dat)/size(dat,1))]);
    end
    % Write the chunk into the output binary file
    fwrite(fid, dat(:), obj.Precision);
    if opt.verbose, 
        eta(tinit, n_chunks, chunk_itr); 
    end
end
n_dims = size(dat,1);
if opt.verbose,
    fprintf('\n');
    pause(0.001);
end

% Close the output file
fclose(fid);


if opt.verbose,
    fprintf('\n(import) Generating @eegset object...');
end

% Generate the output eegset object
[~, name] = fileparts(opt.filename);

physiosetObj = physioset(opt.filename, n_dims, ...
    'Name',             name, ...
    'Precision',        obj.Precision, ...
    'Writable',         obj.Writable, ...
    'Temporary',        obj.Temporary, ...
    'SamplingRate',     sr, ...
    'StartDate',        rec_start_date, ...
    'opt.starttime',        rec_start_time, ...
    'Sensors',          sensors.physiology.from_fieldtrip(hdr), ...
    'Event',            eventObj, ...
    'SamplingTime',     sampling_time, ...
    'Header',           hdr, ...
    'Compact',          obj.Compact);

if isZipped,
    delete(filenameIn);
end

if pathAdded,
    rmpath(genpath(obj.Fieldtrip));
end
if opt.verbose,
    fprintf('[done]\n\n');
end


end