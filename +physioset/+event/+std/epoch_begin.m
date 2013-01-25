classdef (Sealed) epoch_begin < pset.event.event
    
     methods
        
        function obj = epoch_begin(pos, varargin)
            
            if nargin < 1 || isempty(pos), 
                pos = NaN;
            end
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__EpochBegin', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
    end
    
end