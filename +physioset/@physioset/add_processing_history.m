function obj = add_processing_history(obj, item)
% ADD_PROCESS_HISTORY - Add processing node to processing history
%
% add_processing_history(obj, item)
%
% Where
%
% ITEM is typically a pset.node.node object, a clone of the processing node
% that processed the data. Alternatively, ITEM might be a string (the name
% of an existing file).
%
% See also: physioset

% Documentation: class_physioset.txt
% Description: Add processing node to processing history

if isa(item, 'pset.node.node'),
    item = clone(item);
elseif ~ischar(item) || (ischar(item) && ~exist(item, 'file')),
    throw(InvalidArgValue('item', ...
        'Must be a processing node or the name of an existing file'));
end

obj.ProcHistory = [obj.ProcHistory; {item}];


end