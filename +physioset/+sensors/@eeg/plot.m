function h = plot(obj)
% PLOT - Scatter plot of sensor locations
%
% plot(obj)
%
% Where
%
% OBJ is a sensors.eeg object
% 
%
% See also: sensors.eeg

% Documentation: class_sensors_eeg.txt
% Description: Plots sensors locations

h = scatter3(obj.Cartesian(:,1), obj.Cartesian(:,2), obj.Cartesian(:,3), 'r', 'filled');

axis equal;
set(gca, 'visible', 'off');
set(gcf, 'color', 'white');

end