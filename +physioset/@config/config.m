classdef config < pset.physioset.itypes.abstract_config
    % CONFIG - Default configuration options for class physioset
    %
    % ## Usage synopsis:
    %
    % import pset.physioset.*;
    % import eegpipe.*;
    %
    % % Set the configuration for method fprintf
    % cfg = config('fprintf', {'ParseDisp', true, 'SaveBinary', true});
    %
    % % Or, alternatively:
    % options = mjava.hash;
    % options('ParseDisp') = true;
    % options('SaveBinary') = true;
    % cfg = config('fprintf', options);
    %
    % % Or, alternatively:
    % cfg = config;
    % cfg = set_method_config(cfg, 'fprintf', {'ParseDisp', false});
    % parseDisp = get_method_config(cfg, 'fprintf', {'ParseDisp'});
    %
    % % Construct a physioset with the given method configuration
    % myPset = import(pset.import.matrix, pset.pset.randn(10,10000));
    % myPset = set_method_config(myPset, cfg);
    %
    % % Or, alternatively:
    % myPset = set_method_config(myPset, 'fprintf', {'ParseDisp', false});
    %
    % % You can also get all method configs as a hash object:
    % myHash = get_method_config(myPset, 'fprintf');
    %
    % % Or get individual configuration options:
    % value = get_method_config(myPset, 'fprintf', 'ParseDisp');
    %
    % % Options accepted by method fprintf:
    % keys(cfg.fprintf)
    %
    %
    % ## Accepted methods and corresponding configuration options:
    %
    % * fprintf: ParseDisp, SaveBinary
    %
    %
    % ## Notes:
    %
    % * See the help of each method for a description of each argument
    %
    % * Methods set_method_config() and get_method_config are very similar
    %   to methods set() and get(), which are both inherited from class
    %   abstract_config. The only difference between the two set of methods
    %   is that the latter take and return cell arrays, while the former
    %   return hashes.
    %
    % See also: pset.physioset.physioset
    
    % Documentation: class_pset_physioset.txt
    % Description: Default method configuration options
    
    
    %% PUBLIC INTERFACE ...................................................
    
    properties
        
        fprintf = mjava.hash('ParseDisp', true, 'SaveBinary', false);
        
    end
    
    methods
        
        obj = set_method_config(obj, varargin);
        
        value = get_method_config(obj, varargin);
        
    end
    
    
    % Constructor
    methods
        function obj = config(varargin)
            
            obj = set_method_config(obj, varargin{:});
            
        end
        
    end
    
end