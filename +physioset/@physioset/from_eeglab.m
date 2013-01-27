function obj = from_eeglab(str, varargin)
% FROM_EEGLAB - Construction from EEGLAB structure
%
% import physioset.
% obj = physioset.from_eeglab(str, 'key', value, ...)
%
% Where
%
% STR is an EEGLAB structure
%
% OBJ is a physioset object
%
%
% ## Accepted (optional) key/value pairs:
%
%       Filename : A valid file name (a string). Default: ''
%           The name of the memory-mapped file to which the generated
%           physioset will be linked.
%
%       SensorType : A cell array of strings. 
%           Default: repmat({'eeg', str.nbchan, 1)
%           The types of the data sensors. Valid types are: eeg, meg,
%           physiology
%
%       Precision : A string. Default: pset.globals.evaluate.Precision
%           The numeric precision to use for storing the data values
%
%       Writable : Logical scalar. Default: true
%           Should the generated physioset be writable?
%
%       Temporary : Logical scalar. Default: true
%           Should the generated physioset be temporary, i.e. should its
%           corresponding memory mapped be erased when the physioset
%           objects is destructed?
%
%
% See also: from_pset, from_fieldtrip

import misc.process_arguments;
import misc.is_valid_filename;
import mperl.file.spec.catfile;
import physioset.
import pset.pset;
import physioset.event.eventl

%% Error checking
if ~isstruct(str) || ~isfield(str, 'data') || ...
        ~isfield(str, 'chanlocs'),
    ME = physioset.InvalidArgument('str', 'An EEGLAB struct is expected');
    throw(ME);
end

%% Optional input arguments
opt.filename    = '';
opt.precision   = pset.globals.evaluate.Precision;
opt.writable    = true;
opt.temporary   = true;
opt.sensortype  = repmat({'eeg'}, str.nbchan, 1);

[~, opt] = process_arguments(opt, varargin);

if isempty(opt.filename),
    if ~isempty(str.filepath),
       filePath = str.filepath;
    else
       filePath = session.instance.Folder;
    end
    filename = catfile(filePath, str.setname);
    if is_valid_filename(filename),
        opt.filename = filename;
    end
end

if isempty(opt.filename),
    opt.filename = pset.file_naming_policy('Random');
elseif ~is_valid_filename(opt.filename),
    error('The provided file name is not valid');
end

fileExt = globals.evaluate.DataFileExt;
[path, name] = fileparts(opt.filename);
opt.filename = catfile(path, [name fileExt]);

%% Sensor information
uTypes = unique(opt.sensortype);

% We need to ensure that same-type sensors.are correlative
count = 0;
for i = 1:numel(uTypes)
   idx = find(ismember(opt.sensortype, uTypes{i}));
   ordering(count+1:count+numel(idx)) = idx;
   count = count + numel(idx);
end

sensorGroups = cell(1, numel(uTypes));
if ~isempty(str.chanlocs),    
    for i = 1:numel(uTypes)
        chans = str.chanlocs(ismember(opt.sensortype, uTypes{i}));
        sensorGroups{i} = ...
            eval(sprintf('sensors.%s.from_eeglab(%s);', ...
            lower(uTypes{i}), chans));
    end
else
    for i = 1:numel(uTypes)
        nbSensors = numel(find(ismember(opt.sensortype, uTypes{i})));
        sensorGroups{i} = eval(sprintf('sensors.%s.empty(%d);', ...
            uTypes{i}, nbSensors));
    end
end
if numel(sensorGroups) > 1,
    sensors.bj = sensors.mixed(sensorGroups{:});
else
    sensors.bj = sensorGroups{1};
end


%% Events information
eventsObj = event.from_eeglab(str.event);

% If it is an epoched dataset we need to add some extra events to tell so
if str.trials > 1,
   trialEvents = event.trial_begin(1:str.pnts:str.pnts*str.trials, ...
       'Duration', str.pnts); 
   eventsObj = [eventsObj(:); trialEvents(:)];
end


%% Copy data to disk and create physioset object
data = reshape(str.data, str.nbchan, str.pnts*str.trials);
pset.write_mmap(data(ordering,:), opt.filename, ...
    'Precision', opt.precision);
dateformat = globals.evaluate.DateFormat;
timeformat = globals.evaluate.TimeFormat;
if str.trials < 2,
    samplingTime = str.times;
else
    samplingTime = [];
end
obj = physioset(opt.filename, str.nbchan, ...
    'Precision',        opt.precision, ...
    'Temporary',        opt.temporary, ...
    'Writable',         opt.writable, ...
    'Name',             str.setname, ...
    'SamplingRate',     str.srate, ...
    'StartDate',        datestr(now, dateformat), ...
    'StartTime',        datestr(now, timeformat), ...
    'Sensors',          sensors.bj, ...
    'Event',            eventsObj, ...
    'SamplingTime',     samplingTime);

% This might be handy when converting back to EEGLAB format
str.data    = [];
str.icaact  = [];
set(obj, 'eeglab', str);



end