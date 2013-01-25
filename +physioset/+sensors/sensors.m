classdef physioset.sensors.
    % SENSORS - Interface for sensor array description classes
    %
    %
    % See also: physioset.sensors.
    
    % Documentation: ifc_physioset.sensors.txt
    % Description: Interface for physioset.sensors.classes
    
    methods (Abstract)
        
        %% To be implemented by final classes
        [cArray, cArrayIdx] = sensor_groups(obj);
        
        cellArray           = labels(obj, varargin);
        
        nbSensors           = nb_sensors(obj);
        
        cellArray           = types(obj);
        
        labels              = orig_labels(obj);
        
        cellArray           = get_physdim(obj);
        
        cellArray           = set_physdim(obj);
        
        weights             = get_eqweights(obj);
        
        obj                 = subset(obj, idx);
        
        %% Implemented by abstract_physioset.sensors.
        
        obj                 = set_physdim_prefix(obj, prefix);
        
        [prefix, power]     = get_physdim_prefix(obj);
        
        unit                = get_physdim_unit(obj);
        
        dist                = get_distance(obj, idx);
        
        %% Conversion to
        
        % For plotting purposes
        layout = layout2d(obj);
        
        layout = layout3d(obj);
        
        % Conversion to other formats
        struct = fieldtrip(obj);
        struct = eeglab(obj);
        
    end
    
    
end