function outStr = eeglab(obj)
% EEGLAB - Converts a physioset.sensors.meg object to an EEGLAB-compatible structure
%
% str = eeglab(obj)
%
% where
%
% OBJ is a physioset.sensors.meg object
%
% STR is a struct array with sensor locations and labels, that complies
% with EEGLAB's standards
%
%
% See also: physioset.sensors.meg

% Documentation: class_physioset.sensors.meg.txt
% Description: Conversion to EEGLAB structure

if isempty(obj.Cartesian), outStr = []; return; end

isMissing = any(isnan(obj.Cartesian),2);
str = physioset.sensors.cart2eeglab(obj.Cartesian(~isMissing,:));

oneChan = str(1);
fnames = fieldnames(oneChan);
for i = 1:numel(fnames)
    oneChan.(fnames{i}) = [];
end

outStr = repmat(oneChan, nb_sensors(obj), 1);
outStr(~isMissing) = str;

origLabels = orig_labels(obj);

if ~isempty(origLabels),
    for i = 1:numel(outStr)
        outStr(i).labels = origLabels{i};
    end
end

end