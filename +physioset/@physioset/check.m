function check(obj)
% CHECK - Global consistency checks for class physioset

import exceptions.*

if ~isempty(obj.SamplingTime) && ...
        ~isempty(obj.PointSet.NbPoints) && ...
        numel(obj.SamplingTime) ~= obj.PointSet.NbPoints,
    
    ME = Inconsistent(...
        ['The number of entries in the SamplingTime property ' ...
        'does not match the number of points in the associated' ...
        'PointSet']);
    throw(ME);
    
end

if ~isempty(obj.Sensors) && nb_sensors(obj.Sensors) ~= obj.NbDims,
    
        ME = Inconsistent(...
            ['The number of sensors.does not match the ' ...
            'number of data dimensions']);
        throw(ME);
    
end

if obj.NbDims ~= numel(obj.BadChan)
    
    ME = Inconsistent(...
        sprintf(['The number of data channels (%d) does not match the'  ...
        'number of elements (%d) of the BadChan property'], obj.NbDims, ...
        numel(obj.BadChan)));
    throw(ME);
    
end

end