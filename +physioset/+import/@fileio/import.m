function pObj = import(obj, varargin)
% IMPORT - Imports files using Fieldtrip' fileio module
%
% pObj = import(obj, fileName)
% pObjArray = import(obj, fileName1, fileName2, ...);
%
% ## Notes:
%
%   * Compressed .gz files are supported.
%
% See also: fileio


import physioset.physioset;
import pset.globals;
import physioset.event.event;
import pset.file_naming_policy;
import misc.process_arguments;
import misc.sizeof;
import misc.eta;
import misc.decompress;
import safefid.safefid;

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

%% Read the header
if verbose,
    fprintf([verboseLabel 'Reading header...']);
end

hdr = ft_read_header(fileName);

channels = 1:hdr.nChans;

if verbose,
    fprintf([verboseLabel 'Done reading header\n\n']);
end

%% Read events
if obj.ReadEvents
    
    if verbose,
        fprintf([verboseLabel 'Reading events...']);
    end
    eventStr = ft_read_event(fileName, 'header', hdr);
    
    if verbose,
        fprintf('[done]\n\n');
    end
    
    if ~isempty(eventStr), 
        eventArray = event.from_fieldtrip(eventStr); 
    end
else
    eventArray = [];    
end


%% Read the signal values
if verbose,
    fprintf([verboseLabel 'Writing data to binary file...']);
end

ns = length(channels);
chunkSize = globals.get.ChunkSize;
chunkSize = floor(chunkSize/(sizeof(obj.Precision)*ns)); % in samples

if hdr.nTrials > 1,
    % Chunk size must be an integer number of trials
    chunkSize = floor(chunkSize/(hdr.nSamples))*hdr.nSamples;
end
boundary = 1:chunkSize:(hdr.nSamples*hdr.nTrials);
if length(boundary)<2 || boundary(end) < hdr.nSamples*hdr.nTrials,
    boundary = [boundary,  hdr.nSamples*hdr.nTrials+1];
else
    boundary(end) = boundary(end)+1;
end
nbChunks = length(boundary) - 1;

fid = safefid(newFileName, 'w');
tinit = tic;
for chunk_itr = 1:nbChunks   
    
    dat = ft_read_data(fileName, 'begsample', boundary(chunk_itr),...
        'endsample', boundary(chunk_itr+1)-1, 'checkboundary', false, ...
        'chanidx', channels, 'header', hdr);     
    
    if ndims(dat) > 2, %#ok<ISMAT>
        dat = reshape(dat, [size(dat,1), round(numel(dat)/size(dat,1))]);
    end
    
    % Write the chunk into the output binary file
    fwrite(fid, dat(:), obj.Precision);
    if verbose, 
        eta(tinit, nbChunks, chunk_itr); 
    end
end
if verbose, fprintf('\n'); end


%% Generate output physioset

% Generate the output eegset object
physiosetArgs = construction_args_physioset(obj);

dateFormat  = globals.get.DateFormat;
timeFormat  = globals.get.TimeFormat;
startDate   = datestr(now, dateFormat);
startTime   = datestr(now, timeFormat);

pObj = physioset(newFileName, size(dat,1), physiosetArgs{:}, ...
    'StartDate',    startDate, 'StartTime', startTime, ...
    'Event',        eventArray, ...
    'Sensors',      sensorArray, ...
    'SamplingRate', max(hdr.sr), ...
    'Header',       hdr);


%% Undoing stuff
goo.globals.set('VerboseLabel', origVerboseLabel);

if isZipped,
    delete(fileName);
end


end