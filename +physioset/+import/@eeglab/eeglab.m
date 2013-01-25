classdef eeglab < physioset.import.abstract_physioset_import
    % EEGLAB - Class for importing EEGLAB files
    %
    % obj = physioset.import.eeglab('key', value, ...)
    %
    %
    % ## Accepted key/value pairs:
    %
    % See help physioset.import.abstract_physioset_import
    %
    %
    %
    % See also: physioset.import.abstract_physioset_import
    
    % Documentation: pkg_physioset.import.txt
    % Description: Imports EEGLAB files
    
    methods
        function obj = eeglab(varargin)
           obj = obj@physioset.import.abstract_physioset_import(varargin{:}); 
        end
    end
    
    % EEGC.import.interface
    methods
        eegset_obj = import(obj, ifilename, varargin);        
    end
    
    
    
    
end