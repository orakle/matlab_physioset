function obj = subset(obj, idx)


obj = subset@physioset.sensors.physiology(obj, idx);

if ~isempty(obj.Cartesian),
    obj.Cartesian = obj.Cartesian(idx,:);
end


end