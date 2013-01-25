classdef (Sealed) chop_begin < pset.event.event
    
     methods
        
        function obj = chop_begin(pos, varargin)
            
            if nargin < 1 || isempty(pos), 
                pos = NaN;
            end
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__ChopBegin', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
    end
    
end