classdef meg < physioset.sensors.physiology
    % SENSORS.MEG - MEG physioset.sensors.class
    %
    % ## Construction:
    %
    % obj = physioset.sensors.meg
    % obj = physioset.sensors.meg('Cartesian', matrix, 'Labels', cellArray);
    % obj = physioset.sensors.meg('key', value, ...)
    %
    % Where
    %
    % OBJ is a physioset.sensors.meg object
    %
    %
    % ## Accepted key/value pairs:
    %
    %       Coils: A physioset.sensors.coil object. Default: []
    %           A description of the geometry of the M coils at each of
    %           the N physioset.sensors.
    %
    %       Cartesian: A numeric Nx3 matrix. Default: []
    %           The Cartesian coordinates of the N MEG physioset.sensors. Sensor
    %           coordinates can also be provided in spherical or polar
    %           coordinates. See below for more information.
    %
    %       Spherical: An Nx3 numeric matrix. Default: []
    %           Spherical coordinates of the N MEG physioset.sensors.
    %
    %       Polar: An Nx3 numeric matrix. Default: []
    %           Polar coordinates of the N MEG physioset.sensors.
    %
    %       Label: A cell array of strings. Default: MEG 1, MEG 2, ...
    %           Labels of the MEG physioset.sensors. These labels must follow the
    %           EDF+ guidelines [1].
    %
    %       PhysDim: A cell array of strings or a string. Default: 'T/m'
    %           The physical dimensions recorded by each sensor. These
    %           texts must also be according to EDF+ guidelines [1]. If
    %           PhysDim is a string rather than a cell array of strings,
    %           the same physical dimension will be assumed for all physioset.sensors.
    %
    %       Orientation: An Nx3 numeric matrix. Default: []
    %           Sensor orientation vectors.
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
    % obj = physioset.sensors.eeg.from_fieldtrip(str);
    %
    % % Construct from EEGLAB struct
    % obj = physioset.sensors.eeg.from_eeglab(str);
    %
    % str = eeglab(obj)                 % Convert to EEGLAB format
    %
    % str = fieldtrip(obj)              % Convert to Fieldtrip format
    %
    %
    % ## References:
    %
    %   [1] Standard EDF+ texts:
    %       http://www.edfplus.info/specs/edftexts.html
    %
    %
    % See also: physioset.sensors.
    
    % Documentation: class_physioset.sensors.meg.txt
    % Description:Class definition
    
    
    %% IMPLEMENTATION .....................................................
    
    properties (SetAccess = 'private')
        Cartesian;     % Cartesian coordinates of the MEG physioset.sensors.
        Orientation;   % Orientation of the MEG physioset.sensors.
        Coils;
        Extra;         % Hash with additional head surface points
    end
    
    % Global consistency check
    methods (Access = private)
        
        function obj = check(obj)
            import exceptions.*
            
            if ~isempty(obj.TransducerType) || ~isempty(obj.PhysDim),
                
                if isempty(obj.Label)
                    throw(abstract_physioset.sensors.InvalidPropValue('Label', ...
                        'Must be unique non-empty labels (strings)'));
                end
               
            
            elseif isempty(obj.Label) && ~isempty(obj.Cartesian),
                
                throw(Inconsistent('Missing sensor labels'));
            end
            
            if ~isempty(obj.Label) && length(obj.Label) ~= obj.NbSensors,
                
                throw(InvalidPropValue('Label', ...
                    'Not consistent with number of physioset.sensors.));
                
            end
            
            if ~isempty(obj.Coils) && obj.Coils.NbSensors ~= obj.NbSensors,
                
                throw(InvalidPropValue('Coils', ...
                    'Not consistent with number of physioset.sensors.));
                
            end
            
        end
        
    end
    
    %% PUBLIC INTERFACE ...................................................
    properties (Dependent = true)
        Spherical;
        Polar;
    end
    
    % Dependent properties getters
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
    
    % Consistency checks (setters)
    methods
        
        % Set/Get methods
        function obj = set.Cartesian(obj, value)
            
            import exceptions.*
            if ~isnumeric(value) || any(value(:)>=Inf) || ...
                    any(value(:)<=-Inf) ...
                    || size(value,2)~=3,
                ME = InvalidPropValue('Coordinates', ...
                    'Must be a Kx3 matrix of Cartesian coordinates');
                throw(ME);
            end
            obj.Cartesian = value;
            
        end
        
        function obj = set.Orientation(obj, value)
            
            import exceptions.*
            if (~isnumeric(value) || any(value(:)>=Inf) || ...
                    any(value(:)<=-Inf)) ...
                    || (~isempty(value) && size(value,2)~=3),
                ME = InvalidPropValue('Orientation', ...
                    'Must be a Kx3 matrix with Cartesian coordinates');
                throw(ME);
            end
            obj.Orientation = value;
            
        end
        
        function obj = set.Coils(obj, value)
            
            import exceptions.*
            
            if ~isempty(value) && ~isa(value, 'physioset.sensors.coils'),
                ME = InvalidPropValue('Coils', ...
                    'Must be of class physioset.sensors.coils');
                throw(ME);
            end
            obj.Coils = value;
            
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
    
    % Conversion to other formats
    methods
        
        struct = fieldtrip(obj);
        struct = eeglab(obj);
        
    end
    
    % physioset.sensors.sensorsinterface (redefinitions)
    methods
        
        physioset.sensors.= subset(physioset.sensors. idx);
        
    end
    
    % Other public methods
    methods
        
        h = plot(obj);
        
    end
    
    % Static constructors
    methods (Static)
        
        obj = from_fieldtrip(fStr, label);
        obj = from_eeglab(eStr);
        obj = empty(nb);
        
    end
    
    % Constructor
    methods
        
        function obj = meg(varargin)
            
            import misc.process_arguments;
            import exceptions.*
            import misc.cartesian;
            
            %% Call parent constructor
            obj = obj@physioset.sensors.physiology(varargin{:});
            
            if nargin < 1, return; end
            
            %% Ensure that the labels are valid MEG labels
            isValid = cellfun(...
                @(x) io.edfplus.is_valid_label(x, 'MEG'), ...
                obj.Label);
            if ~all(isValid),
                warning('physioset.sensors.InvalidLabel', ...
                    ['Sensor labels are not EDF+ compatible. \n' ...
                    'Automatically creating compatible MEG labels: ' ...
                    'MEG 1, MEG 2, ...']),
                tmp = num2str((1:numel(obj.Label))');
                newLabels = ...
                    mat2cell(tmp, ones(size(tmp,1),1), size(tmp,2));
                for i = 1:numel(obj.Label),
                    newLabels{i} = ['MEG ' newLabels{i}];
                end
                obj.Label = newLabels;
            end
            
            %% Ensure valid PhysDims
            if isempty(obj.PhysDim),
                warning('physioset.sensors.meg:meg:MissingPhysDim', ...
                    ['Physical dimensions not provided: assuming ' ...
                    'gradiometric physioset.sensors.(T/m)']);
                obj.PhysDim = repmat({'T/m'}, size(obj.Label, 1), 1);
            end
            
            %% Properties specific to MEG physioset.sensors.
            opt.Coils       = [];
            opt.Orientation = [];
            opt.Extra       = [];
            [~, opt] = process_arguments(opt, varargin);
            
            obj.Coils       = opt.Coils;
            obj.Orientation = opt.Orientation;
            obj.Cartesian   = cartesian(varargin{:});
            obj.Extra       = opt.Extra;
            
            % Global consistency check
            obj = check(obj);
            
        end
    end
end