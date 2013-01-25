function dist = euclidean_dist(obj)
% EUCLIDEAN_DIST - Euclidean distance between EEG physioset.sensors.
%
% dist = euclidean_dist(obj)
%
%
% Where
%
% OBJ is a physioset.sensors.eeg object containing the especifications of K physioset.sensors.
%
% DIST is a KxK matrix with the Euclidean distances between each pair of
% physioset.sensors.
%
%
% See also: physioset.sensors.eeg

% Documentation: class_physioset.sensors.eeg.txt
% Description: Euclidean distance between EEG physioset.sensors.

import misc.euclidean_dist;

dist = nan(obj.NbSensors);
for i = 1:obj.NbSensors
    dist(:, i) = euclidean_dist(obj.Cartesian(i,:), obj.Cartesian);
end



end