classdef (Sealed) file_begin < physioset.event.event
    
    methods
        
        function obj = file_begin(pos, varargin)
            
            if nargin < 1 || isempty(pos),
                obj.Type = '__FileBegin';
                return;
            end
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__FileBegin', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
        
    end
    
end