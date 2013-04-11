function ftripStruct = fieldtrip(obj, varargin)
% FIELDTRIP - Conversion to a Fieldtrip data structure
%
% ftripStruct = fieldtrip(obj)
% ftripStruct = fieldtrip(obj, 'key', value, ...)
%
% Where
%
% OBJ is a physioset.object
%
% FTRIPSTRUCT is a Fieldtrip-compatible data structure
%
% ## Accepted (optional) key/value options:
%
%   BadChannels : (string) Default: 'reject'
%       Determines what is to be done with the bad channels when exporting
%       to EEGLAB format. Other alternatives are: 'flatten' (make zero) and
%       'interpolate'. Note that 'interpolate' does not work yet.
%
%   BadSamples : (string) Default: 'reject'
%       Same as BadChannels but used to determine what is to be done with
%       the bad data samples. The 'interpolate' policy is not implemented
%       yet.
%
% ## Notes:
%
% * This conversion method will assume that events of the same type as
%   physioset.event.trial_begin should be used for defining trial
%   boundaries.
%
% * As Fieldtrip expects single modality data, if you attempt to
%   convert a physioset object that contains multiple modalities (e.g. EEG
%   and MEG), multiple fieltrip structures will be generated, each of which
%   will contain data from a single modality.
%
% * Note that the format in which Fieldtrip structures store MEG sensors.
%   information changed in September 23, 2011. This conversion script will
%   use the new format. For more information visit the URL below:
%
%   <a
%   href="http://fieldtrip.fcdonders.nl/faq/how_are_electrodes_magnetometers_or_gradiometers_described">http://fieldtrip.fcdonders.nl/faq/how_are_electrodes_magnetometers_or_gradiometers_described</a>
%
%
% ## Examples:
%
% # In the examples below we will use the following sample data:
% mySensors = sensors.eeg.from_template('egi256');
% mySensors = subset(mySensors, 1:10:256);
% myImporter = physioset.import.matrix('Sensors', mySensors);
% data = import(myImporter, randn(26, 2000));
% set_meta(data, 'RandomProp', rand(1,100));
%
% ### Example 1: Data selections
% 
% select(data, 1:2:20);
% ftripStr = fieldtrip(data);
% assert(numel(ftripStr.elec.label) == 10);
% 
%
% ### Example 2: export and reject bad channels/bad samples
% 
% clear_selection(data);
% set_bad_channel(data, 1:2:10);
% set_bad_sample(data, 1:1000);
% ftripStr = fieldtrip(data, 'BadSamples', 'reject', ...
%   'BadChannels', 'reject'); 
%
%
% ### Example 3: export and flatten bad data
%
% clear_selection(data);
% set_bad_channel(data, 1:2:10);
% set_bad_sample(data, 1:1000);
% ftripStr = fieldtrip(data, 'BadSamples', 'flatten', ...
%   'BadChannels', 'flatten'); 
%
% See also: eeglab, physioset, physioset.event.event

import physioset.event.event;
import physioset.deal_with_bad_data;
import misc.process_arguments;

opt.BadChannels = 'reject';
opt.BadSamples  = 'reject';
[~, opt] = process_arguments(opt, varargin);

% Do something about the bad channels/samples
didSelection = deal_with_bad_data(obj, opt.BadChannels);

% Important to use method sensors here, instead of obj.Sensors. The
% latter does not have into account "data selections" and would break the
% code below.
sensorArray = sensors(obj);
if ~isempty(sensorArray),
    [group, groupIdx] = sensor_groups(sensorArray);
    if numel(group) > 1,
        ftripStruct = cell(numel(group),1);
        for i = 1:numel(group)
            select(obj, groupIdx{i});
            try
                ftripStruct{i} =  fieldtrip(obj);
            catch ME
                clear_selection(obj);
                rethrow(ME);
            end
        end
        return;
    end   
    if isa(sensorArray, 'sensors.eeg'),        
        ftripStruct.elec  = fieldtrip(sensorArray);
        ftripStruct.label = orig_labels(sensorArray);
    elseif isa(sensorArray, 'sensors.meg'),
        ftripStruct.grad  = fieldtrip(sensorArray);
        ftripStruct.label = orig_labels(sensorArray);
    else
        warning(['Cannot convert %s data to Fieldtrip format. ' ...
            'Only MEG or EEG sensors.are supported.'], class(obj.Sensors));
        ftripStruct = [];
        return;
    end
else
    % Assume EEG data by default
    ftripStruct.label = [];
    ftripStruct.elec  = [];
end

% Take care of trial-based datasets
if isempty(obj.Event),
    eventArray = obj.Event;
else
    eventArray = select(obj.Event, 'Type', ...
        get(physioset.event.std.trial_begin, 'Type'));
end
if numel(eventArray) < 2,
    ftripStruct.trial = {obj.PointSet(:,:)};
    ftripStruct.time  = {obj.SamplingTime};
else
    nTrials = numel(eventArray);
    ftripStruct.sampleinfo = nan(nTrials,2);
    tInfo = get(eventArray(1), 'trialinfo');
    if ~isempty(tInfo),
        ftripStruct.trialinfo  = nan(nTrials, size(tInfo,2));
    end
    ftripStruct.time       = cell(1, nTrials);
    ftripStruct.trial      = cell(1, nTrials);
    for trialItr = 1:nTrials
        ev = eventArray(trialItr);
        begSample = ev.Sample + ev.Offset;
        endSample = begSample + ev.Duration - 1;
        ftripStruct.trial{trialItr} = obj.PointSet(:, begSample:endSample);
        ftripStruct.time{trialItr}  = get(ev, 'time');
        ftripStruct.sampleinfo(trialItr,:) = get(ev, 'sampleinfo');
        if ~isempty(tInfo),
            tInfo = get(ev, 'trialinfo');
            ftripStruct.trialinfo(trialItr,:) = tInfo;
        end
    end
    if isfield(ftripStruct, 'trialinfo') && ...
            all(isnan(ftripStruct.trialinfo(:))),
        ftripStruct = rmfield(ftripStruct, 'trialinfo');
    end
end


ftripStruct.fsample = obj.SamplingRate;

% Other stuff that may be stored as physioset meta-properties
ftripStruct.cfg = get_meta(obj, 'cfg');
ftripStruct.hdr = get_meta(obj, 'hdr');

trialinfo   = get_meta(obj, 'trialinfo');
sampleinfo  = get_meta(obj, 'sampleinfo');
if ~isempty(trialinfo),     ftripStruct.trialinfo   = trialinfo; end
if ~isempty(sampleinfo),    ftripStruct.sampleinfo  = sampleinfo; end

% Undo temporary selections
if didSelection,
    restore_selection(obj);
end

end