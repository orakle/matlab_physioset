classdef phys_event_info < event.EventData
    
   
    properties
        EventArray;
    end
    
    methods
       
        function obj = phys_event_info(evArray)
           
            obj.EventArray = evArray;
            
        end
        
    end
    
    
end