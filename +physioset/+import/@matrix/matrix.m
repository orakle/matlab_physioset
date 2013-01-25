classdef matrix < physioset.import.abstract_physioset_import
    % MATRIX - Imports numeric MATLAB matrices
    %
    % ## Usage synopsis:
    % 
    % % Create a matrix importer with a sampling rate of 763 Hz
    % myImporter = physioset.import.matrix(763);
    % obj = import(myImporter, randn(10,1000));
    %
    %
    % Where
    %
    % MYIMPORTER is a physioset.import.matrix object
    %
    % OBJ is a physioset.object that contains that data values
    % contained in matrix LFP.
    %
    % ## Optional construction arguments (as key/value pairs):
    %
    %   * All key/value pairs accepted by the constructor of clas
    %     abstract_physioset_import
    %
    %
    %
    % See also: abstract_physioset_import, physioset.import.
    
    % Documentation: import.txt
    % Description: Imports a MATLAB matrix
    
     %% PROTECTED INTERFACE ................................................
    
    methods (Access = protected)       
     
        % Overrides parent method
        function args = construction_args_physioset(obj)
         
            args = {...
                'SamplingRate', obj.SamplingRate, ...
                'Sensors',      obj.Sensors};
            
        end
        
        
    end
    
    
    %% PUBLIC INTERFACE ...................................................
    
    properties
        
        SamplingRate;
        Sensors;
        
    end
    
    % Consistency checks
    methods
       
        function obj = set.SamplingRate(obj, value)
           
            import exceptions.*
            import misc.isnatural;            
            
            if numel(value) ~= 1 || ~isnatural(value),
                throw(InvalidPropValue('SamplingRate', ...
                    'Must be a natural scalar'));
            end
            obj.SamplingRate = value;            
            
        end        
        
        function obj = set.Sensors(obj, value)
           
            import exceptions.*
            import goo.pkgisa;
            
            if isempty(value), 
                obj.Sensors = [];
                return;
            end
            
            if ~pkgisa(value, 'sensors'),
               
                throw(InvalidPropValue('Sensors', ...
                    'Must be a sensors object'));
                
            end
            
            obj.Sensors = value;
            
        end
        
    end
    
    % physioset.import.interface
    methods
        
        physObj = import(obj, filename, varargin);
        
    end
    
    % Constructor
    methods
        
        function obj = matrix(sr, varargin)  
            
            import pset.globals; 
            
            if nargin < 1, sr = globals.get.SamplingRate; end
            
            if ischar(sr), 
                varargin = [sr varargin];
                sr = globals.get.SamplingRate;
            end
            
            obj = obj@physioset.import.abstract_physioset_import(varargin{:});            
           
            obj.SamplingRate = sr;            
            
        end
        
    end
    
    
    
end