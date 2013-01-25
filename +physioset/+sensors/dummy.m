classdef dummy < physioset.sensors.abstract_sensors
    
    properties (SetAccess = protected)
        Label = [];
    end
    
    properties (Dependent)
        NbSensors;          % Number of physioset.sensors.signals
    end
    
    methods
        function value  = get.NbSensors(obj)
            value = numel(obj.Label);
        end
    end
    
    % Consistency checks
    methods
        function obj = set.Label(obj, value)
            import io.edfplus.valid_label;
            import physioset.sensors.abstract_sensors
            if ischar(value) && isvector(value), value = {value(:)'}; end
            if isempty(value) || ~iscell(value) || ...
                    ~all(cellfun(@(x) ischar(x), value)),
                throw(abstract_physioset.sensors.InvalidPropValue('Label', ...
                    'Must be a cell array of strings'));
            end
            
            if numel(unique(value)) ~= numel(value),
                throw(abstract_physioset.sensors.InvalidPropValue('Label', ...
                    'Must be unique'));
            end
            
            obj.Label = value;
        end
    end
    
    % physioset.sensors.sensorsinterface
    methods
        function labelsArray = labels(obj)
            labelsArray = obj.Label;
        end
        
        function nbSensors = nb_sensors(obj)
            nbSensors = obj.NbSensors;
        end
        
        function type = types(obj)
            type = repmat({'dummy'}, obj.NbSensors,1);
        end
        
        function [sensorArray, idx] = sensor_groups(obj)
            sensorArray = {obj};
            idx = {1:nb_sensors(obj)};
        end
        
        function labelsArray = orig_labels(obj)
            labelsArray = obj.Label;
        end
        
        function weights = get_eqweights(obj)
            weights = eye(nb_sensors(obj));
        end
        
        function physDim = get_physdim(obj)
            physDim = repmat({'na'}, obj.NbSensors, 1);
        end
        
        function obj = set_physdim(obj, ~)
            % do nothing
        end
        
        function obj = subset(obj, idx)
            if isempty(idx),
                obj = [];
                return;
            end            
            sortedIdx = sort(idx);            
            if any(sortedIdx ~= idx),
                error('Indices must be sorted');
            end            
            if ~isempty(obj.Label),
                obj.Label = obj.Label(idx);
            end     
        end
    end
    
    % Constructor
    methods
        function obj = dummy(nbSensors, varargin)
            import physioset.sensors.abstract_sensors
            import misc.process_arguments;
            
            if nargin < 1 || nbSensors < 1, return; end            
           
            opt.Label           = [];            
            [~, opt] = process_arguments(opt, varargin);
            
            if isempty(opt.Label), 
                opt.Label = num2cell(1:nbSensors); 
                opt.Label = cellfun(@(x) num2str(x), opt.Label, ...
                    'UniformOutput', false);
            end
            
            obj.Label = opt.Label;     
        end
    end
    
end