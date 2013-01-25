function eegset_obj = import(obj, ifilename, varargin)
% import - Imports EEGLAB .set files
%
% eegset_obj = import(obj, ifilename)
% eegset_obj = import(obj, 'key', value, ...)
%
% Where
%
% OBJ is an physioset.import.eeglab object
%
% IFILENAME is the name of the EEGLAB file to be imported
%
%
% ## Most relevant key/value pairs:
%
% 'FileName'    : (string) Name of the generated file
%                 Default: [], i.e. use the automatic file naming policy
%
% 'StartTime'   : (numeric scalar) Start time of the EEG epoch to read from
%                 the file, in seconds.
%                 Default: [], i.e. read from the beginning
%
% 'EndTime'     : (numeric scalar) End time of the EEG epoch, in seconds
%                 Default: [], i.e. read until the end
%
% 'Channels'    : (natural) Indices of the channels to read
%                 Default: [], i.e. all channels
%
% 'Folder'      : (string) If provided, all files in the specified folder
%                 will be imported.
%                 Default: [], i.e. not applicable
%
% 'RegExp'      : (string) Regular expression that matches the files in the
%                 provided folder that the user wants to import.
%                 Default: '([^.]+)', i.e. any file except . and ..
%
% 'Verbose'     : (logical) Default: obj.Verbose
%
%
% ## Secondary key/value pairs:
%
% 'StartSample' : (natural scalar) First sample to read
%                  Default: 1
%
% 'EndSample'   : (natural scalar) Last sample to read
%                 Default: [], last recorded sample
%
%
% ## Notes:
%
% * The epoch range has to be specified either in samples or in time but not
%   in both
%
% * If the optional argument folder is provided, then the IFILENAME
%   mandatory argument must be empty
%
%
%
% See also: physioset.import.


% Deal with the multi-filename case
if iscell(ifilename),
    eegset_obj = cell(numel(ifilename), 1);
    for i = 1:numel(ifilename)
        eegset_obj{i} = import(obj, ifilename{i}, varargin{:});
    end   
    return;
end

import pset.file_naming_policy;
import pset.eegset;
import physioset.import.globals;
import pset.event;
import misc.process_varargin;
import misc.sizeof;
import misc.regexpi_dir;
import mperl.file.spec.*;

if nargin < 2 || isempty(ifilename),
    ME = MException('import:invalidInput', ...
        'At least two input arguments are expected');
    throw(ME);
end

THIS_OPTIONS = {'filename', ...
    'starttime', ...
    'endtime', ...
    'startsample', ...
    'endsample', ...
    'channels', ...
    'timeformat', ...
    'dateformat', ...
    'folder', ...
    'regexp', ...
    'verbose', ...
     };
 
% Default values of optional input arguments
filename    = [];
starttime   = [];
endtime     = [];
startsample = [];
endsample   = [];
channels    = [];
dateformat  = globals.evaluate.DateFormat;
timeformat  = globals.evaluate.TimeFormat;
folder      = '';
regexp      = '([^.]+)';
verbose     = obj.Verbose;

eval(process_varargin(THIS_OPTIONS, varargin));

if (~isempty(starttime) || ~isempty(endtime)) && ...
        (~isempty(startsample) || ~isempty(endsample)),
    ME = MException('import:invalidInput', ...
        ['Data range must be specified either in samples or in time ' ...
        '(seconds) but not in both']);
    throw(ME);
end

if ~isempty(ifilename) && ~isempty(folder),
    ME = MException('import:invalidInput', ...
        ['The ''Folder'' optional argument is only accepted if the '...
        'IFILENAME mandatory input argument is empty']);
    throw(ME);
end

% Use recursion to process a folder file by file
if isempty(ifilename) && isempty(folder),
    eegset_obj = [];
    return;
elseif isempty(ifilename)    
    file_list = regexpi_dir(folder, regexp);
    eegset_obj = cell(numel(file_list), 1);
    [~, remove_flag] = process_varargin(...
        {'folder', 'verbose', 'compact'}, varargin);
    for i = 1:numel(file_list)
        if verbose,
            [~, this_name, this_ext] = fileparts(file_list{i});
            fprintf('\n(import) Importing ''%s''...', [this_name this_ext]);            
        end
        eegset_obj{i} = import(obj, file_list{i}, 'Verbose', false, ...
            varargin{~remove_flag});  
        if verbose,
            fprintf('[done]\n');            
        end       
    end
    return;
end

% Determine the names of the generated memory map files
if isempty(filename),
    filename = file_naming_policy(obj.FileNaming, ifilename); 
end
[path name] = fileparts(filename);
filename = catfile(path, [name obj.DataFileExt]);

% Read the header and the events
% =========================================================================
if obj.Verbose,
    fprintf('\n(import) Reading header and events...');
end
hdr = load(ifilename, '-mat');
hdr = hdr.EEG;

if isempty(channels),
    channels = 1:hdr.nbchan;
end

sr = hdr.srate;
sampling_time = linspace(0, hdr.pnts/sr, hdr.pnts);

rec_start_date = datestr(now, dateformat);
rec_start_time = datestr(now, timeformat);
event_obj = pset.event.from_struct(hdr.event);
if obj.Verbose,
    fprintf('[done]\n');
end

% Read the signal values
% =========================================================================
if obj.Verbose,
    fprintf('\n(import) Writing data to binary file...');
end
fpath = fileparts(ifilename);
[~, ~, ext_binary] = fileparts(hdr.data);
fid_in = fopen([fpath filesep hdr.data],'r');
chunksize = floor(obj.ChunkSize/(sizeof(obj.Precision)*hdr.nbchan)); % in samples
boundary = 1:chunksize:hdr.pnts;
if length(boundary)<2 || boundary(end) < hdr.pnts,
    boundary = [boundary,  hdr.pnts+1];
else
    boundary(end) = boundary(end)+1;
end
n_chunks = length(boundary) - 1;
fid = fopen(filename, 'w');
if strcmpi(ext_binary, '.dat'),
    % New EEGLAB format, data is stored rowwise
    for chunk_itr = 1:n_chunks
        % Read n_points from the EEGLAB binary data file
        n_points = boundary(chunk_itr+1)-boundary(chunk_itr);
        format_str = [num2str(n_points) '*float32'];
        skip =  hdr.pnts - (boundary(chunk_itr+1)-1);
        dat = fread(fid_in, hdr.nbchan*n_points, format_str, skip);
        fseek(fid_in, boundary(chunk_itr+1), 'bof');
        % Write the chunk into the output binary file
        dat = reshape(dat, n_points, hdr.nbchan)';
        dat = dat(channels, :);
        fwrite(fid, dat(:), obj.Precision);
        if obj.Verbose,
            fprintf('.');
        end
    end
elseif strcmpi(ext_binary, '.fdt'),
    % Old EEGLAB format, data is stored rowwise
    for chunk_itr = 1:n_chunks
        % Read n_points from the EEGLAB binary data file
        n_points = boundary(chunk_itr+1)-boundary(chunk_itr);
        dat = fread(fid_in, [hdr.nbchan n_points], 'float32');
        dat = dat(channels, :);
        % Write the chunk into the output binary file
        fwrite(fid, dat(:), obj.Precision);
        if obj.Verbose,
            fprintf('.');
        end
    end    
else
    error('EEGC:import_file:unsupportedFormat', ...
        'EEGLAB data files with extension %s are not supported.', ext);
end
n_dims = size(dat,1);
if obj.Verbose,
    fprintf('[done]\n');
end

% Close the input and output files
fclose(fid_in);
fclose(fid);

thisSensors = sensors.eeg.from_eeglab(hdr.chanlocs);

% Generate the output eegset object
% =========================================================================
eegset_obj = eegset(filename, n_dims, ...
    'Precision',    obj.Precision, ...
    'Writable',     obj.Writable, ...
    'Temporary',    obj.Temporary, ...
    'SamplingRate', sr, ...
    'Sensors',      thisSensors, ...
    'StartDate',    rec_start_date, ...
    'StartTime',    rec_start_time, ...    
    'Continuous',   true, ...
    'Event',        event_obj, ...
    'SamplingTime', sampling_time, ...
    'Header',       hdr, ...
    'Compact',      obj.Compact);



end