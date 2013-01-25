classdef (Sealed) discontinuity < physioset.event.event
    
    methods
        
        function obj = discontinuity(pos, varargin)
            
            if nargin < 1 || isempty(pos),
                obj.Type = '__Discontinuity';
                return;
            end
            
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__Discontinuity', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
    end
    
    
end