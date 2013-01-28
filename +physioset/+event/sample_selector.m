classdef sample_selector < physioset.event.selector & goo.abstract_setget
    
    
   
    properties
       
        Sample;
        
    end
    
    methods
        
        function [evArray, idx] = select(obj, evArray)
            
           if isempty(obj.Sample) || isempty(evArray),
               idx = 1:numel(evArray);
               return; 
           end
            
           sample = get_sample(evArray);
           off    = get_offset(evArray);
           dur    = get_duration(evArray);
           
           inRange = false(size(evArray));
           
           for i = 1:numel(evArray)
              
               idx = (sample(i) + off(i)):(sample(i) + off(i) + dur(i) - 1);
               inRange(i) = all(ismember(idx, obj.Sample));
               
           end
           
           evArray = evArray(inRange);    
           
           idx = find(inRange);
            
        end
        
        
    end
    
    
    methods
        
        function obj = sample_selector(varargin)
           
            if nargin < 1, return; end
            
            if nargin > 1,
                sampleRange = cell2mat(varargin);
            else
                sampleRange = varargin{1};
            end
            
            obj.Sample = unique(sampleRange);
            
        end
        
        
    end
    
    
end