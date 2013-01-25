function obj = from_eeglab(eStr)
% FROM_EEGLAB - Converts a EEGLAB struct into a physioset.sensors.eeg object
%
% obj = physioset.sensors.eeg.from_eeglab(eeglabStr)
%
% Where
%
% EEGLABSTR is a EEGLAB struct with EEG electrodes/channels information
%
% OBJ is the generated physioset.sensors.eeg object
% 
%
% See also: from_fieldtrip, from_file

% Documentation: class_physioset.sensors.eeg.txt
% Description:  Construction from EEGLAB struct


xyz = nan(numel(eStr),3);
for i = 1:numel(eStr)
   if isempty(eStr(i).X), continue; end
    xyz(i,:) = [eStr(i).X eStr(i).Y eStr(i).Z];
end

label = cell(numel(eStr), 1);
for i = 1:numel(label)
    label{i} = eStr(i).labels;
end

obj = physioset.sensors.eeg('Cartesian', xyz, 'OrigLabel', label);

end