classdef abstract_sensors < physioset.sensors.sensors & goo.abstract_setget
    % ABSTRACT_SENSORS - Common methods accross physioset.sensors.sensorsclasses
    %
    %
    %
    % See also: physioset.sensors.
    
    % Documentation: class_abstract_physioset.sensors.txt
    % Description: Class definition
    
    
    %% PUBLIC INTERFACE ...................................................
    
    % Default implementations
    methods
        
        obj             = set_physdim_prefix(obj, prefix);
        
        [prefix, power] = get_physdim_prefix(obj);
        
        unit            = get_physdim_unit(obj);
        
        % Default layout is just NaNs
        function layout = layout2d(obj)
            layout = nan(nb_sensors(obj), 3);
        end
        
        function layout = layout3d(obj)
            layout = nan(nb_sensors(obj, 3));
        end
        
        % Default distance is 1
        function dist = get_distance(~, ~)
            dist = 1;
        end
        
        % Conversion to other formats
        struct = fieldtrip(obj);
        struct = eeglab(obj);
        
        
    end
    
end