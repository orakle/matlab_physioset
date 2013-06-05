function ftripStruct = fieldtrip(obj, varargin)
% fieldtrip - Conversion to an Fieldtrip structure
% =======
%
% ## Usage
%
%````matlab
% ftripStr = fieldtrip(pObj)
% ftripStr = fieldtrip(eegsetObj, 'key', value, ...)
%````
%
% where
%
% `pObj` is a `physioset` object
%
% `ftripStr` is the exported EEGLAB data structure
%
%
% ## Accepted (optional) key/value options:
% 
% ### BadDataPolicy
%
% __Default:__ `'reject'`
% __Class:__    `char`
%
% Determines what is to be done with the bad data when exporting to
% Fieldtrip format. See the documentation of 
% [physioset.deal_with_bad_data][deal_with_bad_data] for information
% regarding valid bad data policies.
% 
% [deal_wit_bad_data]: ../deal_with_bad_data.md
%
%
% ## Notes:
%
% * For epoched datasets, any trial that contains one or more bad samples
%   will be rejected. This might be too harsh but allows a simplified
%   implementation.
%
%
% ## Examples:
%
% ### Export only the EEG channels
%
% ````matlab
% data = pset.load('myfile.pseth');
% selector =  pset.selector.sensor_class('Class', 'EEG');
% select(selector, data);
% ftripStr = fieldtrip(data);
% ````
%
% See also: eeglab

import physioset.event.event;
import physioset.deal_with_bad_data;
import misc.process_arguments;

opt.BadData = 'reject';
[~, opt] = process_arguments(opt, varargin);

% Do something about the bad channels/samples
[didSelection, evIdx] = deal_with_bad_data(obj, opt.BadData);

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

%% Take care of trial-based datasets (which contain trial_begin events)
if isempty(obj.Event),
    eventArray = obj.Event;
else
    eventArray = select(obj.Event, 'Type', ...
        get(physioset.event.std.trial_begin, 'Type'));
end
if numel(eventArray) < 2,
    ftripStruct.trial = {obj.PointSet(:,:)};
    ftripStruct.time  = {sampling_time(obj)};
else
    nTrials = numel(eventArray);
    
    if ~isempty(evIdx) && strcmpi(opt.BadData, 'reject'),
       error(['Cannot use bad data policy ''reject'' in the presence ' ...
           'of bad data samples']); 
    end    
    
    ftripStruct.sampleinfo = nan(nTrials,2);
    tInfo = get_meta(eventArray(1), 'trialinfo');
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
        
        % Samples corresponding to this trial
        trialBeg   = get(ev, 'Sample');
        trialDur   = get(ev, 'Duration');
        trialSampl = trialBeg:trialBeg+trialDur-1;
        trialTime  = sampling_time(obj);
        trialTime  = trialTime(trialSampl);
        
        ftripStruct.time{trialItr}  = trialTime;
        
        
        ftripStruct.sampleinfo(trialItr,:) = get_meta(ev, 'sampleinfo');
        if ~isempty(tInfo),
            tInfo = get_meta(ev, 'trialinfo');
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

evArray = get_event(obj);
if ~isempty(evArray),
    evSelector = physioset.event.class_selector('Class', 'trial_begin');
    evArray = select(~evSelector, evArray);
end

if ~isempty(evArray)    
    ftripStruct.cfg.event = fieldtrip(evArray);        
end

% Undo temporary selections
if didSelection,
    restore_selection(obj);
    delete_event(obj, evIdx);
end

end