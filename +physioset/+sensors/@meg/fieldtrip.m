function grad = fieldtrip(obj)
% FIELDTRIP - Converts a physioset.sensors.meg object to a Fieldtrip "grad" structure
%
% str = fieldtrip(obj)
%
% See also: eeglab, physioset.sensors.meg

% Documentation: class_physioset.sensors.meg.txt
% Description: Conversion to Fieldtrip structure

grad = get(obj, 'Fieldtrip_grad');
if isempty(grad),
    grad.chanpos = obj.Cartesian;
    grad.unit    = obj.Unit;
    grad.label   = orig_labels(obj);
end

end