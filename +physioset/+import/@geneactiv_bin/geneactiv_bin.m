classdef geneactiv_bin < physioset.import.abstract_physioset_import
    % geneactiv_bin - Imports Geneactiv's 3D accelerometry in .bin format
    %
    % ## Usage synopsis:
    %
    % ````matlab
    % import physioset.import.geneactiv_bin;
    % importer = geneactiv_bin('FileName', 'myOutputFile');
    % data = import(importer, 'myFile.bin');
    % ````
    %
    % ## Accepted (optional) construction arguments (as key/values):
    %
    % * All key/values accepted by abstract_physioset_import constructor
    %
    % See also: abstract_physioset_import
    
    methods (Static, Access = private)
        
        hdr = process_bin_header(hdrIn);
        
    end
    
    % physioset.import.import interface
    methods
        physiosetObj = import(obj, filename, varargin);
    end
    
    
    % Constructor
    methods
        
        function obj = geneactiv_bin(varargin)
            obj = obj@physioset.import.abstract_physioset_import(varargin{:});
        end
        
    end
    
    
end