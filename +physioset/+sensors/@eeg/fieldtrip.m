function elec = fieldtrip(obj)
% FIELDTRIP - Converts a physioset.sensors.eeg object to a Fieldtrip "elec" structure
%
% elec = fieldtrip(obj)
%
% See also: eeglab, physioset.sensors.eeg

% Documentation: class_physioset.sensors.eeg.txt
% Description: Conversion to Fieldtrip structure


elec = get(obj, 'Fieldtrip_elec');
if isempty(elec),
    elec.elecpos = obj.Cartesian;
    elec.label   = orig_labels(obj);
    elec.chanpos = obj.Cartesian;
end

end