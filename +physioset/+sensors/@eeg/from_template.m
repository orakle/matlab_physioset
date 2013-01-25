function obj = from_template(name, varargin)
% FROM_TEMPLATE - Predefined EEG sensor arrays
%
% obj = physioset.sensors.eeg.from_template(name)
%
% Where
%
% NAME is the name of the template (a string). 
%
% OBJ is a physioset.sensors.eeg object
%
%
% See also: from_eeglab, from_fieldtrip, from_file

% Documentation: class_physioset.sensors.eeg.txt
% Description: Predefined EEG sensor arrays

import misc.is_string;
import physioset.sensors.abstract_sensors
import physioset.sensors.root_path;
import mperl.file.spec.catfile;

if isempty(name),
    obj = physioset.sensors.eeg;
    return;
end

if ~is_string(name),
    throw(abstract_physioset.sensors.InvalidArgValue('Name', ...
        'Must be a string'));
end

% Remove file extension, if it was provided
name = regexprep(name, '.hpts$', '');

switch lower(name)
    
    case {'hydrocel gsn 256 1.0', 'hydrocelgsn25610x2e0', 'hydrocel256', ...
            'egi256'},
        % EGI's HydroCel GSN 256 1.0        
        file     = catfile(root_path, 'templates/hydrocelgsn25610x2e0.hpts');
        
       
    otherwise
        file = [];
end

if isempty(file),
    obj = [];
else
    
    warning('off', 'physioset.sensors.MissingPhysDim');
    warning('off', 'physioset.sensors.InvalidLabel');
    obj = physioset.sensors.eeg.from_file(file, varargin{:});   
    warning('on', 'physioset.sensors.MissingPhysDim');
    warning('on', 'physioset.sensors.InvalidLabel');
    
end


end