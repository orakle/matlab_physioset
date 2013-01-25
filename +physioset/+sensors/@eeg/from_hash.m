function obj = from_hash(hashObj)


labels = keys(hashObj)';
coords = cell2mat(values(hashObj)');

obj = physioset.sensors.eeg(...
    'Cartesian', coords, ...
    'Label',     labels);




end