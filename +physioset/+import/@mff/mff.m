classdef mff < pset.import.abstract_physioset_import
    % MFF - Imports Netstation MFF files
    %
    % ## Usage synopsis:
    %
    % import pset.import.mff;
    % importer = mff('FileName', 'myOutputFile');
    % data = import(mff, 'myMFFfile.mff');
    %
    % ## Accepted (optional) construction arguments (as key/values):
    %
    % * All key/values accepted by abstract_physioset_import constructor
    %
    % See also: abstract_physioset_import
    
    % Documentation: pkg_import.txt
    % Description: Imports EGI .mff files
    
    properties
       
        Channels;
        
    end
    
    % Consistency checks
    methods
        
        function obj = set.Channels(obj, value)
            
           import exceptions.*
           import misc.isnatural;
           
           if ~isnumeric(value) || ~isvector(value) || ~isnatural(value),
               throw(InvalidPropValue('Channels', ...
                   'Must be an array of channel indices'));
           end
           
           obj.Channels = value;
            
        end
        
        
    end
    
    
    % pset.import.import interface
    methods
        [eegsetObj, physiosetObj] = import(obj, filename, varargin);        
    end
    
    
    % Constructor
    methods
        
        function obj = mff(varargin)
            obj = obj@pset.import.abstract_physioset_import(varargin{:});             
        end
        
    end
    
    
end