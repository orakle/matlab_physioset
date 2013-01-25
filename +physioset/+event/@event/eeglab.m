function [ev, epochDur] = eeglab(a)
% EEGLAB - Conversion to EEGLAB events
%
% sArray = eeglab(eArray);
% [sArray, epochDur] = eeglab(eeglab);
%
% Where
%
% EARRAY is an array of event objects
%
% SARRAY is a struct array according to EEGLAB's format. This array should
% be placed in the field 'event' of a given EEGLAB EEG data structure.
%
% EPOCHDUR is the duration of the data epochs, if ERRAY contains
% trial_begin events. If there are no such events, then EPOCHDUR is set to
% NaN.
%
% See also: from_eeglab, struct, fieldtrip

% Documentation: class_vent.txt
% Description: Conversion to EEGLAB events

%% Create trials if necessary
epochDur = NaN;
isTrialBegin = arrayfun(@(x) isa(x, 'trial_begin'), a);
trialBeginEv = a(isTrialBegin);

if ~isempty(trialBeginEv),
    
    trialBegin = get(trialBeginEv, 'Sample');
    
    epochDur = unique(trialBeginEv, 'Duration');
    
    if numel(epochDur) > 1,
        ME = MException('event:DiffDurEpochs', ...
            'EEGLAB format cannot handled different duration epochs');
        throw(ME);
    end
    
    trialEnd = trialBegin + epochDur - 1;
    
    if trialBegin(1) ~= 1,
        ME = MException('event:WrongTrialBegin', ...
            'EEGLAB epochs should start at sample 1');
        throw(ME);
    end
    
    a(isTrialBegin) = [];
    
    if isempty(a),
        pos = [];
    else
        pos = get(a, 'Sample');
    end
    
    if iscell(pos), pos = cell2mat(pos); end
    
    epochVal = nan(size(pos));
    
    for i = 1:numel(pos),
        
        tmp = find(pos(i) >= trialBegin & pos(i) <= trialEnd, 1, 'first');
        
        if (pos(i) + epochDur - 1) > trialEnd
            a(i) = set(a(i), 'Duration', trialEnd-pos(i)+1);
        end
        
        if isempty(tmp),
            warning('event:OutOfRange', ...
                ['Event %d at sample %d seems to be out of range. '...
                'I will remove it.'], i, pos(i));
        else
            epochVal(i) = tmp;
        end
        
    end
    
    epoched = true;
    
else
    
    epoched = false;
    epochVal = [];
    
end

if ~isempty(epochVal),
    outOfRange = isnan(epochVal);
    if epoched,
        % Remove events that do not fall within any epoch
        a(outOfRange)        = [];
        epochVal(outOfRange) = [];
    end
end

args = {'type', '', 'latency', [], 'position', [], 'urevent', [], ...
    'meta', struct};

if epoched,
    args = [args, {'epoch', []}];
end

if isempty(a),
    ev = [];
    return;
end

evStr = struct(args{:});

ev    = repmat(evStr, 1, numel(a));

% These are meta-props that have a meaning in EEGLAB
eeglabFields  = {'Position', 'Epoch', 'Urevent'};

types = get(a, 'Type');
if ischar(types), types = {types}; end

sample = get(a, 'Sample');

for i = 1:numel(a)
    
    ev(i).type     = types{i};
    ev(i).latency  = sample(i);
    ev(i).position = get_meta(a(i), 'Position');
    ev(i).urevent  = get_meta(a(i), 'Urevent');
    
    if epoched
        ev(i).epoch = epochVal(i);
    end
    
    metaData      = get_meta(a(i));
    
    duplicateFields = intersect(fieldnames(metaData), eeglabFields);
    ev(i).meta      = rmfield(metaData, duplicateFields);
    
end


end