classdef fieldtrip < pset.import.abstract_physioset_import
    % FIELTRIP - Class for importing FIELTRIP files
    %
    % obj = pset.import.fieldtrip('key', value, ...)
    %
    %
    % ## Accepted key/value pairs:
    %
    %   * See: help pset.import.abstract_physioset_import
    %
    % See also: pset.import, pset.physioset.from_fieldtrip
    
    % Documentation: pkg_pset_import.txt
    % Description: Imports FIELDTRIP files
    
    
    
    methods
        function obj = fieldtrip(varargin)
           obj = obj@pset.import.abstract_physioset_import(varargin{:}); 
        end
    end
    
    % EEGC.import.interface
    methods
        eegset_obj = import(obj, ifilename, varargin);        
    end
    
    
    
    
end