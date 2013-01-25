function ftripStruct = fieldtrip(obj, varargin)
% FIELDTRIP - Conversion to a Fieldtrip data structure
%
% ftripStruct = fieldtrip(obj)
%
%
% Where
%
% OBJ is a physioset.object
%
% FTRIPSTRUCT is a Fieldtrip-compatible data structure
%
%
%
% ## Notes:
%
% * This conversion method will assume that eventArray of the same type as
%   pset.event.trial_begin should be used for defining trial boundaries.
%
% * As Fieldtrip expects single modality data, if you attempt to
%   convert a physioset object that contains multiple modalities (e.g. EEG
%   and MEG), multiple fieltrip structures will be generated, each of which
%   will contain data from a single modality.
%
% * Note that the format in which Fieldtrip structures store MEG physioset.sensors.
%   information changed in September 23, 2011. This conversion script will
%   use the new format. For more information visit the URL below:
%
%   <a
%   href="http://fieldtrip.fcdonders.nl/faq/how_are_electrodes_magnetometers_or_gradiometers_described">http://fieldtrip.fcdonders.nl/faq/how_are_electrodes_magnetometers_or_gradiometers_described</a>
%
%
% See also: eeglab, physioset, event

% Documentation: class_physioset.txt
% Description: Conversion to Fieldtrip structure

import pset.event.event;

% Important to use method physioset.sensors.) here, instead of obj.Sensors. The
% latter does not have into account "data selections" and would break the
% code below.
sensorArray = physioset.sensors.obj);
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
    if isa(sensorArray, 'physioset.sensors.eeg'),        
        ftripStruct.elec  = fieldtrip(sensorArray);
        ftripStruct.label = orig_labels(sensorArray);
    elseif isa(sensorArray, 'physioset.sensors.meg'),
        ftripStruct.grad  = fieldtrip(sensorArray);
        ftripStruct.label = orig_labels(sensorArray);
    else
        warning(['Cannot convert %s data to Fieldtrip format. ' ...
            'Only MEG or EEG physioset.sensors.are supported.'], class(obj.Sensors));
        ftripStruct = [];
        return;
    end
else
    % Assume EEG data by default
    ftripStruct.label = [];
    ftripStruct.elec  = [];
end

% Take care of trial-based datasets
eventArray = select(obj.Event, 'Type', get(event.trial_begin, 'Type'));
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
ftripStruct.cfg = get(obj, 'cfg');
ftripStruct.hdr = get(obj, 'hdr');

trialinfo   = get(obj, 'trialinfo');
sampleinfo  = get(obj, 'sampleinfo');
if ~isempty(trialinfo),     ftripStruct.trialinfo   = trialinfo; end
if ~isempty(sampleinfo),    ftripStruct.sampleinfo  = sampleinfo; end


end