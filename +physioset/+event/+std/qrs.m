classdef (Sealed) qrs < pset.event.event
    
     methods
        
        function obj = qrs(pos, varargin)
            
            if nargin < 1 || isempty(pos), 
                obj.Type = '__QRSComplex';
                return; 
            end
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__QRSComplex', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
    end
    
end