function obj = subset(obj, idx)

obj.Cartesian   = obj.Cartesian(idx,:);
obj.Weights     = obj.Weights(idx,:);


end