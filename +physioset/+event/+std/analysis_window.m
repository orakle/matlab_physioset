classdef (Sealed) analysis_window < pset.event.event
    
    methods
        
        function obj = analysis_window(pos, varargin)
            
            if nargin < 1 || isempty(pos),
                obj.Type = '__AnalysisWindow';
                return;
            end
            
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__AnalysisWindow', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
    end
    
    
end