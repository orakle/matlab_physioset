function obj = empty(nb)

labels = cellfun(@(x) ['EEG ' num2str(x)], num2cell(1:nb), 'UniformOutput', false); 
obj = physioset.sensors.eeg('Cartesian', nan(nb,3), 'Label', labels, 'PhysDim', 'uV');


end