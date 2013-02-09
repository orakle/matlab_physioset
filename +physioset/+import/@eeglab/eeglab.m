classdef eeglab < physioset.import.abstract_physioset_import
    % EEGLAB - Imports EEGLAB's .set files
    %
    % ## Usage synopsis:
    %
    % import physioset.import.eeglab;
    % importer = eeglab('FileName', 'myOutputFile');
    % data = import(importer, 'myMFFfile.mff');
    %
    % ## Accepted (optional) construction arguments (as key/values):
    %
    % * All key/values accepted by abstract_physioset_import constructor
    %
    % See also: abstract_physioset_import
    
    
    % physioset.import.import interface
    methods
        physObj = import(obj, ifilename, varargin);        
    end
    
    % Constructor
    methods
        
        function obj = eeglab(varargin)
            obj = obj@physioset.import.abstract_physioset_import(varargin{:});             
        end
        
    end
    
    
end