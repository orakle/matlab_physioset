classdef (Sealed) trial_begin < physioset.event.event
    
    methods
        
        function obj = trial_begin(pos, varargin)
            
            if nargin < 1 || isempty(pos), 
                obj.Type = '__TrialBegin';
                return; 
            end
            
            obj = repmat(obj, size(pos));
            
            varargin = ['Type', '__TrialBegin', varargin];
            
            for i = 1:numel(obj)
                
                obj(i).Sample = pos(i);
                
                obj(i) = set(obj(i), varargin{:});
                
            end
            
        end
        
    end
    
    
end