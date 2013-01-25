classdef abstract_config < eegpipe.abstract_config
   
    methods
       
        function obj = abstract_config(varargin)
           
            obj = obj@eegpipe.abstract_config(varargin{:});
            
        end
    end
    
end