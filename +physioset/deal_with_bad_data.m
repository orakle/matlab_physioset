function [didSelection, evIdx] = deal_with_bad_data(obj, policy)

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
                'Duration', 1);
            thisEv = set_meta(thisEv, 'RejEpochDur', dur);
            
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