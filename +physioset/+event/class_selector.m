classdef class_selector < physioset.event.selector & goo.abstract_setget
    % CLASS_SELECTOR - Selects events of standard class(es)
    %
    % import physioset.event.*;
    % mySelector = class_selector(evClass1, evClass2, ...);
    %
    % Where
    %
    % EVCLASS1, EVCLASS2, etc are the classes of the events that are to be
    % selected.
    %
    %
    % See also: event, physioset, selector, physioset.event.std
    
    % Description: Selects events of standard class(es)
    % Documentation: class_class_selector.txt
    
    % PUBLIC INTERFACE ....................................................
    properties
        
        EventClass;
        EventType;
        
    end
    
    methods
        
        function obj = set.EventClass(obj, value)
            
            import exceptions.*
            
            if ~iscell(value), value = {value}; end
            
            isEvent = cellfun(@(x) isa(x, 'physioset.event.event'), value);
            
            if any(isEvent),
                regex = '^.*?([^\.])+$';
                value(isEvent) = cellfun(@(x) regexprep(class(x), ...
                    regex, '$1'), value(isEvent), 'UniformOutput', false);
            end
            
            fullClassName = cellfun(@(x) ['physioset.event.std.' x], value, ...
                'UniformOutput', false);            
          
           if ~all(cellfun(@(x) exist(x, 'class'), fullClassName)),
                
                throw(InvalidPropValue('EventClass', ...
                    'Must be a string/cell array of valid event name(s)'));
                
            end
            
            obj.EventClass = value;
            
        end
        
        function obj = set.EventType(obj, value)
           
            import exceptions.*
            
            if ~iscell(value), value = {value}; end
            
            isString = cellfun(@(x) misc.isstring(x), value);
            
            if ~all(isString),
                throw(InvalidPropValue('EventType', ...
                    'Must be a cell array of strings'));
            end
            
            obj.EventType = value;            
            
        end
        
        
    end
    
    % physioset.event.selector.selector interface
    methods
        
        function [evArray, idx] = select(obj, evArray)
           
            selected = true(size(evArray));
            
            if ~isempty(obj.EventClass), 
            fullClassName = cellfun(@(x) ['physioset.event.std.' x], ...
                obj.EventClass, 'UniformOutput', false);    
            
            af = @(x) ismember(class(x), fullClassName);
            
            selected = selected & arrayfun(af, evArray);           
            end
            
            
            if ~isempty(obj.EventType),
                
                af = @(x) ismember(get(x, 'Type'), obj.EventType);
                selected = selected & arrayfun(af, evArray);
                
            end
          
            evArray = evArray(selected);
            
            idx = find(selected);
            
        end
        
    end
    
    % Constructor
    methods
        
        function obj = class_selector(varargin)     
            
            import misc.process_arguments;
            
            opt.Class = {};
            opt.Type  = {};
            
            [~, opt] = process_arguments(opt, varargin);
            
            obj.EventClass = opt.Class;
            obj.EventType  = opt.Type;
            
        end
        
    end
    
end