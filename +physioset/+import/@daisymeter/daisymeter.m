classdef daisymeter < physioset.import.abstract_physioset_import
    % daisymeter - Imports Geneactiv's 3D accelerometry in .bin format
    %
    % ## Usage synopsis:
    %
    % ````matlab
    % import physioset.import.daisymeter;
    % importer = daisymeter('FileName', 'myOutputFile');
    % data = import(importer, 'myFile.txt');
    % ````
    %
    % ## Accepted (optional) construction arguments (as key/values):
    %
    % * All key/values accepted by abstract_physioset_import constructor
    %
    % See also: abstract_physioset_import
 
    
    % physioset.import.import interface
    methods
        physiosetObj = import(obj, filename, varargin);        
    end
    
    
    % Constructor
    methods
        
        function obj = daisymeter(varargin)
            obj = obj@physioset.import.abstract_physioset_import(varargin{:});             
        end
        
    end
    
    
end