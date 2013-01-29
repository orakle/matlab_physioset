function obj    = add_event(obj, evArray)
% ADD_EVENT - Adds events to a physioset
%
% obj = add_event(obj, evArray)
%
% Where
%
% EVARRAY is an array of pset.event objects
%
% See also: event, physioset

% Documentation: class_physioset.txt
% Description: Adds events to a physioset

if isempty(evArray), return; end

% When there are selections, we need to remap the events Sample property
pntSel = pnt_selection(obj);
if ~isempty(pntSel),
   
    origSample = get_sample(evArray);
    
    if any(origSample > numel(pntSel)),
        error('Out of range event');
    end
    
    newSample  = pntSel(origSample);
    evArray    = set_sample(evArray, newSample);
    
end

if ~isempty(obj.Event),
    evArray = [obj.Event(:); evArray(:)];
end

% [~, I] = unique(evArray, 'Sample');
% evArray = evArray(I);

obj.Event = evArray;

end