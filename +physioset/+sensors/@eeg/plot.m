function h = plot(obj)
% PLOT - Scatter plot of sensor locations
%
% plot(obj)
%
% Where
%
% OBJ is a physioset.sensors.eeg object
% 
%
% See also: physioset.sensors.eeg

% Documentation: class_physioset.sensors.eeg.txt
% Description: Plots physioset.sensors.locations

h = scatter3(obj.Cartesian(:,1), obj.Cartesian(:,2), obj.Cartesian(:,3), 'r', 'filled');

axis equal;
set(gca, 'visible', 'off');
set(gcf, 'color', 'white');

end