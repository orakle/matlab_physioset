function [didSelection, evIdx] = deal_with_bad_data(obj, policy)
% deal_with_bad_data - Prepares physioset for conversion to other formats
%
% Note: This is an internal function, not intended to be used directly.
%
% ## Usage:
%
% ```matlab
% [didSelection, evIdx] = deal_with_bad_data(obj, policy)
% ````
%
% Where
%
% `obj` is a `physioset` object.
%
% `policy` is a string with the name of the policy that will be used for
% dealing with the bad data prior to conversion to a third-party data
% format (e.g. EEGLAB or Fieldtrip).
%
%
% ## Implemented policies
%
% ### reject
%
% Bad data will not be exported to the third-party data format. This policy
% might lead to temporal discontinuities in the exported data. A `boundary`
% event will be added at the location of the discontinuity. The `Value`
% property of such events will be set to the duration of the data epoch
% that was rejected (in data samples).
%
% ### flatten
%
% Bad data will be zeroed out. Events of type `boundary` will be added to
% the exported dataset in order to mark the locations of the bad data
% epochs. The `Value` property of such events will be set to the duration
% of the (flattened) bad data epoch that follows the event.
%
% ### donothing
%
% Export all data, but do add `boundary` events marking the onsets and
% durations of the bad data epochs.

import physioset.event.event;

if ~any(is_bad_channel(obj)) && ~any(is_bad_sample(obj)),
    didSelection = false;
    return;
end

didSelection = true;

if nargin < 2 || isempty(policy), policy = 'reject'; end



switch lower(policy)
    
    case 'reject',
        
        % Mark boundaries with a "boundary" event
        winrej = eeglab_winrej(obj);
        
        evIdx = nan(1, size(winrej,1));
        count = 0;
        for i = 1:size(winrej,1)
            pos = winrej(i,1)-1;
            if pos < 1, continue; end
            
            dur = diff(winrej(i,1:2))+1;
            samplTime = get_sampling_time(obj);
            lat = samplTime(pos);
            thisEv = event(pos, 'Type', 'boundary', 'Time', lat, ...
                'Duration', 1, 'Value', dur);
            
            [~, evIdx(i)] = add_event(obj, thisEv);
            count = count + 1;
        end
        evIdx(count+1:end) = [];
        select(obj, ~is_bad_channel(obj), ~is_bad_sample(obj));
        
    case 'flatten',
        
        evIdx = add_bad_data_events(obj);
        obj(is_bad_channel(obj), :) = 0;
        obj(:, is_bad_sample(obj))  = 0; %#ok<*NASGU>
        
    case 'donothing',
        % do nothing
        evIdx = add_bad_data_events(obj);
        
    otherwise,
        
        error('Invalid policy ''%s''', policy);
        
end



end



function evIdx = add_bad_data_events(obj)
import physioset.event.std.epoch_begin;
% Mark boundaries with a "boundary" event
winrej = eeglab_winrej(obj);

evIdx = nan(1, size(winrej,1));
count = 0;
for i = 1:size(winrej,1)
    pos = winrej(i,1)-1;
    if pos < 1, continue; end
    
    dur = diff(winrej(i,1:2))+1;
    samplTime = get_sampling_time(obj);
    lat = samplTime(pos);
    thisEv = epoch_begin(pos, 'Type', '__BadData', 'Time', lat, ...
        'Duration', dur);
    thisEv = set_meta(thisEv, 'Duration', dur);
    [~, evIdx(i)] = add_event(obj, thisEv);
    count = count+1;
end
evIdx(count+1:end) = [];


end