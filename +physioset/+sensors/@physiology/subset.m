function obj = subset(obj, idx)
% SUBSET - Creates a sensors.physiology object as a subset of another
%
% objSubset = subset(obj, idx)
%
% Where
%
% OBJSUBSET object is a sensors.physiology object that contains the sensors
% with indices IDX in object OBJ
%
% See also: sensors.physiology

% Description: class_sensors_physiology.txt
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