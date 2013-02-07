classdef neuromag < physioset.import.abstract_physioset_import
    % NEUROMAG - Imports Neuromag .fif files
    %
    % ## Usage synopsis:
    %
    % import physioset.import.neuromag;
    % importer = neuromag('FileName', 'myOutputFile');
    % data = import(mff, 'myMFFfile.fif');
    %
    % ## Accepted (optional) construction arguments (as key/values):
    %
    % * All key/values accepted by abstract_physioset_import constructor
    %
    %       Equalize': Logical scalar. Default: true
    %           If set to true, the data from different modalities 
    %           (EEG, MEG, Physiology) will be scaled such that they all 
    %           have similar variances. This means for instance that MEG
    %           data in T, which has much smaller scale than EEG data in V,
    %           might result in MEG data to be transformed to a smaller
    %           scale (e.g. pT instead of T). Additionally, the modality
    %           with the highest variance will be scaled so that its
    %           variance is in the range of 100 physical units. This means
    %           that EEG data originally
    %                 expressed in V is very likely to be transformed to mV.
    %                 Default: true
    %
    % See also: abstract_physioset_import
    
    %% Implementation .....................................................
    methods (Static, Access = 'private')
        
        grad = grad_reorder(grad, idx);
        grad = grad_change_unit(grad, newUnit);
        
    end
    
    
    %% Public interface ....................................................
    properties
        Equalize;
        Trigger2Type;
    end
    
    % Set/Get methods
    methods
        
        function obj = set.Trigger2Type(obj, value)
            if ~isempty(value) && ~isa(value, 'mjava.hash'),
                throw(InvalidPropValue('Trigger2Type', ...
                    'Must be an mjava.hash object'));
            end
            obj.Trigger2Type = value;
        end
        
    end
    
    % physioset.import.importer interface
    methods
        physObj = import(obj, filename, varargin);
    end
    
    
    % Constructor
    methods
        function obj = neuromag(varargin)
            
            obj = obj@physioset.import.abstract_physioset_import(varargin{:});
            
        end
    end
    
end