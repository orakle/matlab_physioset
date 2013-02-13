function obj = from_fieldtrip(fStruct, varargin)
% FROM_FIELDTRIP - Construction from FIELDTRIP structure
%
% import physioset.
% obj = physioset.from_fieldtrip(fStruct);
% obj = physioset.from_fieldtrip(fStruct, 'key', value, ...)
%
% Where
%
% FSTRUCT is a Fieldtrip struct
%
% OBJ is an eegset object
%
%
% ## Accepted (optional) key/value pairs:
%
%       Filename : A valid file name (a string). Default: ''
%           The name of the memory-mapped file to which the generated
%           physioset will be linked.
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
% See also: physioset. pset.eegset.from_pset, pset.eegset.from_eeglab


import physioset.event.event;
import pset.pset;
import physioset.physioset;
import misc.process_arguments;

%% Error checking
if ~isstruct(fStruct) || ~isfield(fStruct, 'fsample') || ...
    ~isfield(fStruct, 'cfg'),
  ME = physioset.InvalidArgument('str', 'A Fieldtrip struct is expected');
  throw(ME);
end

%% Optional input arguments
opt.filename    = '';
opt.precision   = pset.globals.evaluate.Precision;
opt.writable    = true;
opt.temporary   = true;
[~, opt] = process_arguments(opt, varargin);

if isempty(opt.filename),
  opt.filename = pset.file_naming_policy('Random');
end

%% Sensor information
if isfield(fStruct, 'grad'),
    sensorsObj = sensors.meg.from_fieldtrip(fStruct.grad, fStruct.label); 
elseif isfield(fStruct, 'elec'),
    sensorsObj = sensors.eeg.from_fieldtrip(fStruct.elec, fStruct.label);
else
    warning('physioset:MissingSensorInformation', ...
        ['Fieldtrip structure does not contain sensor information:' ...
        'Assuming vanilla EEG sensors.']);
    sensorsObj = sensors.eeg.empty();
end

% Create an event per trial
nEvents = numel(fStruct.trial);
ev = repmat(event, nEvents, 1);
durAll = 0;
for i = 1:numel(fStruct.trial),
  offset = -find(fStruct.time{i} >= 0, 1)+1;
  if offset>=0,
    offset = round(offset/fStruct.fsample);
  end
  sample = -offset + 1 + durAll;
  dur    = size(fStruct.time{i}, 2);
  durAll = durAll + dur;
  
  thisEvent  = event.trial_begin(sample, ...  
    'Offset',       offset, ...
    'Duration',     dur);
  
  thisEvent = set(thisEvent, ...
    'sampleinfo',   fStruct.sampleinfo(i, :), ...
    'time',         fStruct.time{i});
  
  if isfield(fStruct, 'trialinfo')
    thisEvent = set(thisEvent, ...
      'trialinfo', fStruct.trialinfo(i, :));
  else
    thisEvent = set(thisEvent, ...
      'trialinfo', []);
  end
    
  ev(i) = thisEvent;
end

data = [fStruct.trial{:}];

pset.write_mmap(data, opt.filename, varargin{:});

% Create the physioset object
dateformat = pset.globals.evaluate.DateFormat;
timeformat = pset.globals.evaluate.TimeFormat;
obj = physioset(opt.filename, size(data,1), ...
  'SamplingRate',     fStruct.fsample, ...
  'StartDate',        datestr(now, dateformat), ...
  'StartTime',        datestr(now, timeformat), ...
  'Sensors',          sensorsObj, ...
  'Continuous',       false, ...
  'Event',            ev, ...
  'SamplingTime',     [], ...
  varargin{:});

extraFields = {'cfg', 'hdr', 'time', 'sampleinfo', 'trialinfo'};
for i = 1:numel(extraFields),
  if isfield(fStruct, extraFields{i})
    obj = set(obj, extraFields{i}, fStruct.(extraFields{i}));
  end
end

