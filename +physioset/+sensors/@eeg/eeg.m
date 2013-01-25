classdef eeg < physioset.sensors.physiology
    % SENSORS.EEG - EEG physioset.sensors.class
    %
    % ## Construction:
    %
    % obj = physioset.sensors.eeg;
    % obj = physioset.sensors.eeg('Cartesian', coord);
    % obj = physioset.sensors.eeg('key', value, ...);
    %
    % Where
    %
    % OBJ is a physioset.sensors.eeg object
    %
    %
    % ## Accepted key/value pairs:
    %
    %       Cartesian: Kx3 double array. Default: []
    %           Cartesian coordinates of the physioset.sensors.
    %
    %       Spherical: A Kx3 double array. Default: []
    %           Spherical coordinates of the physioset.sensors.
    %
    %       Polar: Kx3 double array. Default: []
    %           Polar coordinates.
    %
    %       * All key/value pairs accepted by the constructor of class
    %         physioset.sensors.physiology
    %
    %
    % ## Notes:
    %
    % * Sensor coordinates might be provided in Cartesian, Polar or
    %   Spherical coordinate systems. However, if more than one type of
    %   coordinates are provided, the Cartesian coordinates will be
    %   preferred over spherical and the spherical over polar.
    %
    %
    % ## Public Interface Synopsis:
    %
    % % Construct from Fieldtrip struct
    % obj = physioset.sensors.meg.from_fieldtrip(str);
    %
    % % Construct from EEGLAB struct
    % obj = physioset.sensors.meg.from_eeglab(str);
    %
    % str = eeglab(obj)                 % Convert to EEGLAB format
    %
    % str = fieldtrip(obj)              % Convert to Fieldtrip format
    %
    % obj = read(obj, 'physioset.sensors.sfp');   % Read locations from file
    %
    % obj = map2surf(obj, surface);     % Map physioset.sensors.onto a surface
    %
    %
    % See also: physioset.sensors.meg, physioset.sensors.
    
    % Documentation: class_physioset.sensors.eeg.txt
    % Description: Class definition
    
    
    methods (Access=private)
        
        function obj = check(obj)
            import physioset.sensors.eeg;
            import physioset.sensors.abstract_sensors
            
            if ~isempty(obj.TransducerType) || ~isempty(obj.PhysDim) || ...
                    ~isempty(obj.Fiducials),
                if isempty(obj.Label)
                    throw(abstract_physioset.sensors.InvalidPropValue('Label', ...
                        'Must be unique non-empty labels (strings)'));
                end
            elseif isempty(obj.Label) && ~isempty(obj.Cartesian),
                if isempty(obj.Label)
                    throw(abstract_physioset.sensors.InvalidPropValue('Label', ...
                        'Must be unique non-empty labels (strings)'));
                end
            end
            if ~isempty(obj.Label) && length(obj.Label) ~= nb_sensors(obj),
                if isempty(obj.Label)
                    throw(abstract_physioset.sensors.InvalidPropValue('Label', ...
                        'Does not match number of physioset.sensors.));
                end
            end
        end
        
    end
    
    %% Public interface ....................................................
    properties (SetAccess = 'private')
        Cartesian;          % Cartesian coordinates of the EEG physioset.sensors.
        Fiducials;          % Hash with the cartesian coordinates of the fiducials
        Extra;              % Hash with additional head surface points
    end
    
    properties (Dependent = true)
        Spherical;
        Polar;
    end
    
    % Get methods
    methods
        function value = get.Spherical(obj)
            if isempty(obj),
                value = [];
            else
                [a, b, c] = cart2sph(obj.Cartesian(:,1), ...
                    obj.Cartesian(:,2), obj.Cartesian(:,3));
                value = [a b c];
            end
        end
        
        function value = get.Polar(obj)
            if isempty(obj),
                value = [];
            else
                [a, b, c] = cart2pol(obj.Cartesian(:,1), ...
                    obj.Cartesian(:,2), obj.Cartesian(:,3));
                value = [a b c];
            end
        end
    end
    
    % Consistency checks (Set methods)
    methods
        
        function obj = set.Cartesian(obj, value)
            
            import exceptions.*
            if ~isnumeric(value) || any(value(:)>=Inf) || ...
                    any(value(:)<=-Inf) ...
                    || size(value,2)~=3,
                throw(InvalidPropValue('Cartesian', ...
                    'Must be a Kx3 matrix'));
            end
            obj.Cartesian = value;
        end
        
        function obj = set.Fiducials(obj, value)
            
            import exceptions.*
            if isempty(value),
                obj.Fiducials = [];
                return;
            end
            if ~isa(value, 'mjava.hash'),
                throw(InvalidPropValue('Fiducials', ...
                    'Must be a mjava.hash object'));
            end
            
            isValid = cellfun(@(x) isnumeric(x) && isvector(x) && ...
                size(x,2) == 3, values(value));
            
            if ~all(isValid),
                throw(InvalidPropValue('Fiducials', ...
                    sprintf('Invalid coordinates for physioset.sensors.%s', ...
                    regexprep(num2str(find(~isValid)), '\s+', ', '))));
            end
            
            obj.Fiducials = value;
        end
        
        function obj = set.Extra(obj, value)
            
            import exceptions.*
            if isempty(value),
                obj.Extra = [];
                return;
            end
            if ~isa(value, 'mjava.hash'),
                throw(InvalidPropValue('Extra', ...
                    'Must be a mjava.hash object'));
            end
            
            isValid = cellfun(@(x) isnumeric(x) && isvector(x) && ...
                size(x,2) == 3, values(value));
            
            if ~all(isValid),
                throw(InvalidPropValue('Extra', ...
                    sprintf('Invalid coordinates for extra points %s', ...
                    regexprep(num2str(find(~isValid)), '\s+', ', '))));
            end
            
            obj.Extra = value;
        end
        
    end
    
    % Implemented by this class
    methods
        
        struct  = eeglab(obj, what);
        struct  = fieldtrip(obj, varargin);
        dist    = euclidean_dist(obj);
        h       = plot(obj);
        radius  = head_radius(obj, varargin);
        dist    = get_distance(obj, idx);
        
    end
    
    % From physioset.sensors.sensorsinterface (redefinitions)
    methods
        
        physioset.sensors.= subset(physioset.sensors. idx);
        
    end
    
    % Static contructors
    methods (Static)
        
        obj = from_eeglab(eStr);
        obj = from_fieldtrip(fStr, label);
        obj = from_file(file, varargin);
        obj = from_hash(hashObj);
        obj = from_template(name, varargin);
        obj = guess_from_labels(labels);
        obj = empty(nb);
        
    end
    
    % Constructor
    methods
        
        function obj = eeg(varargin)
            import misc.process_arguments;
            import misc.cartesian;
            import physioset.sensors.abstract_sensors
            
            %% Call parent constructor
            obj = obj@physioset.sensors.physiology(varargin{:});
            
            if nargin < 1, return; end
            
            %% Ensure that the labels are valid EEG labels
            isValid = cellfun(...
                @(x) io.edfplus.is_valid_label(x, 'EEG'), ...
                obj.Label);
            if ~all(isValid),
                warning('physioset.sensors.InvalidLabel', ...
                    ['Sensor labels are not EDF+ compatible. \n' ...
                    'Automatically creating compatible EEG labels: ' ...
                    'EEG 1, EEG 2, ...']),
                
                newLabels = cell(size(obj.Label));
                for i = 1:numel(obj.Label),
                    newLabels{i} = ['EEG ' num2str(i)];
                end
                obj.Label = newLabels;
                
            end
            
            %% Ensure valid PhysDims
            if isempty(obj.PhysDim),
                warning('physioset.sensors.MissingPhysDim', ...
                    'Physical dimensions not provided: assuming uV');
                obj.PhysDim = repmat({'uV'}, size(obj.Label, 1), 1);
            end
            
            %% Properties specific to EEG physioset.sensors.
            opt.Fiducials           = [];
            opt.Extra               = [];
            [~, opt] = process_arguments(opt, varargin);
            
            obj.Cartesian = cartesian(varargin{:});
            obj.Fiducials = opt.Fiducials;
            obj.Extra     = opt.Extra;
            
            % Global consistency check
            obj = check(obj);
            
        end
        
    end
    
end