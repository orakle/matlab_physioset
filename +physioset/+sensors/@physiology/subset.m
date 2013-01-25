function obj = subset(obj, idx)
% SUBSET - Creates a physioset.sensors.physiology object as a subset of another
%
% objSubset = subset(obj, idx)
%
% Where
%
% OBJSUBSET object is a physioset.sensors.physiology object that contains the physioset.sensors.
% with indices IDX in object OBJ
%
% See also: physioset.sensors.physiology

% Description: class_physioset.sensors.physiology.txt
% Documentation: Subset of a sensor array

if isempty(idx),
    obj = [];
    return;
end

sortedIdx = sort(idx);

if any(sortedIdx ~= idx),
   error('Indices must be sorted'); 
end

if ~isempty(obj.TransducerType),
    obj.TransducerType = obj.TransducerType(idx);
end

if ~isempty(obj.Label),
    obj.Label = obj.Label(idx);
end

if ~isempty(obj.OrigLabel),
    obj.OrigLabel = obj.OrigLabel(idx);
end

if ~isempty(obj.PhysDim),
    obj.PhysDim = obj.PhysDim(idx);
end

end