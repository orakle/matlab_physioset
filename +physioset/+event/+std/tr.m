classdef (Sealed) tr < physioset.event.event
    
     methods
        
        function obj = tr(pos, varargin)
            
            if nargin < 1 || isempty(pos), 
                obj.Type = '__TR';
                return; 
            end
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__TR', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
    end
    
end