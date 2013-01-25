classdef eeglab < pset.import.abstract_physioset_import
    % EEGLAB - Class for importing EEGLAB files
    %
    % obj = pset.import.eeglab('key', value, ...)
    %
    %
    % ## Accepted key/value pairs:
    %
    % See help pset.import.abstract_physioset_import
    %
    %
    %
    % See also: pset.import.abstract_physioset_import
    
    % Documentation: pkg_pset_import.txt
    % Description: Imports EEGLAB files
    
    methods
        function obj = eeglab(varargin)
           obj = obj@pset.import.abstract_physioset_import(varargin{:}); 
        end
    end
    
    % EEGC.import.interface
    methods
        eegset_obj = import(obj, ifilename, varargin);        
    end
    
    
    
    
end