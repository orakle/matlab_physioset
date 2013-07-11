classdef generator
    % GENERATOR - Interface for event generators
    %
    % See also: event
    
    methods (Abstract)
        
       evArray = generate(obj, data, varargin); 
      
    end
    
    
end