function obj = delete_event(obj, idx)
% DELETE_EVENT - Deletes events from a physioset
%
% delete_event(obj, idx);
%
% Where
%
% IDX is an array with the indices of the events to be deleted.
% Alternatively, IDX can be a logical array of the same dimensions as OBJ.
%
% See also: add_event

% Description: Delete events
% Documentation: class_physioset.txt

[ev, rawIdx] = get_event(obj);

if islogical(idx) && numel(idx)~=numel(ev),
    error(['Dimensions of logical array IDX do not match the ' ....
        'dimensions of the event array OBJ']);    
end

obj.Event(rawIdx(idx)) = [];



end