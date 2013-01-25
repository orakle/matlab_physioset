classdef neuromag < pset.import.abstract_physioset_import
    
    % Documentation: pkg_pset_import.txt
    % Description: Neuromag MEG data importer
    
    methods (Static, Access = 'private')
        grad = grad_reorder(grad, idx);
        grad = grad_change_unit(grad, newUnit);
        
        % Exceptions that may be thrown by this class' methods
        function obj = InvalidFieldtrip
           obj = MException('pset:import:neuromag:InvalidFieldtrip', ...
               ['The Fieldtrip property must be a char array ' ...               
               'specifying the root location of the Fieldtrip toolbox']);           
        end
        function obj = InvalidTrigger2Type
           obj = MException('pset:import:neuromag:InvalidTrigger2Type', ...
               'The Trigger2Type property must be of class mjava.hash');
        end
        
        function obj = InvalidFieldtripStruct
            obj = MException(...
                'pset:import:neuromag:InvalidFieldtripStruct', ...
                ['Invalid Fieldtrip structure. Try updating your ' ...
                'Fieldtrip version']);
        end
    end
    
    
    
    
    % BEGIN PUBLIC INTERFACE ##############################################
    
    properties 
        Equalize; 
    end
    
    properties (SetAccess = 'private');
        Trigger2Type;
        Fieldtrip;
    end
    
    % Set/Get methods
    methods
        function obj = set.Fieldtrip(obj, value)
            if ~isempty(value) && ~ischar(value),
                throw(obj.InvalidFieldtrip);
            end
            obj.Fieldtrip = value;
        end
        
        function obj = set.Trigger2Type(obj, value)
            if ~isempty(value) && ~isa(value, 'mjava.hash'),
                throw(obj.InvalidTrigger2Type);
            end
            obj.Trigger2Type = value;
        end
    end
    
    
    % Constructor
    methods
        function obj = neuromag(varargin)
            import misc.process_arguments;
            obj = obj@pset.import.abstract_physioset_import(varargin{:});
            
            opt.fieldtrip    = [];
            opt.trigger2type = [];
            opt.equalize     = true;
            
            [~, opt] = process_arguments(opt, varargin);
            
            obj.Fieldtrip    = opt.fieldtrip;
            obj.Trigger2Type = opt.trigger2type;
            obj.Equalize     = opt.equalize;
            
            % If not directly provided, try to guess the location of the
            % Fieldtrip fileio module
            if isempty(obj.Fieldtrip),
                locs = [pset.import.globals.evaluate.Fieldtrip;...
                    misc.split(':', path)];
                for i = 1:numel(locs),
                    if exist(locs{i}, 'dir')
                        obj.Fieldtrip = locs{i};
                        break;
                    end
                end
            end
            
            if isempty(obj.Fieldtrip),
                ME = MException('pset:import:neuromag:MissingDependency', ...
                    ['Fieldtrip dependency is missing. Get it from: ' ...
                    'http://fieldtrip.fcdonders.nl']);
                throw(ME);
            end
            
        end
    end
    
    methods
        eegsetObj = import(obj, filename, varargin);
    end
    
    % END PUBLIC INTERFACE ################################################
end