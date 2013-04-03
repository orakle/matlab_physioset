classdef fileio < physioset.import.abstract_physioset_import
    

    methods
        function obj = fileio(varargin)
            obj = obj@physioset.import.abstract_physioset_import(varargin{:});       
        end
    end
    
    methods
        physObj = import(obj, filename, varargin);        
    end
    
    
end