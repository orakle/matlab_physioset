classdef abstract_physioset_import < ...
        physioset.import.physioset_import & ...
        goo.abstract_setget & ...
        goo.verbose
    % abstract_physioset_import - Commonality among physioset_import classes
    %
    % The `abstract_physioset_import` class is an abstract class designed for
    % inheritance. This means that instances of the class cannot be created
    % but instead the purpose of the class is to provide its children
    % classes with common properties and methods. The values of the
    % properties listed below can be set during construction of an object
    % of a child class using key/value pairs. For instance, the command:
    %
    % ````matlab
    % importObj = physioset.import.matrix(...
    %       'Temporary', true, ...
    %       'Writable', false)
    % ````
    %
    % will create an importer object of class `matrix` (a child class of class
    % `abstract_physioset_import`). The property `Temporary` and `Writable`
    % properties (both defined by the `abstract_physioset_import` class) will be
    % set to `true` and `false`, respectively.
    %
    %
    % ## Optional construction arguments
    %
    % The following optional arguments can be provided during construction
    % as key/value pairs.
    %
    %
    % ### `Precision`
    %
    % __Class__: `char`
    %
    % __Default__: `pset.globals.get.Precision`
    %
    % The numeric precision that should be used when importing data.
    %
    %
    % ### `Writable`
    %
    % __Class__: `logical`
    %
    % __Default__: `pset.globals.get.Writable`
    %
    % If set to `true` the generated object will be _writable_, in the
    % sense that the contents of its associated memory map can be modified
    % through its public API. For instance:
    %
    % ````matlab
    % importer = physioset.import.matrix('Writable', false);
    % obj = import(importer, randn(10,1000));
    % obj(1,1) = 0; % Not allowed
    % obj.Writable = true;
    % obj(1,1) = 0; % Now it is allowed
    % ````
    %
    % ### `Temporary`
    %
    % __Class__: `logical`
    %
    % __Default__: `pset.globals.get.Temporary`
    %
    % If set to true, the associated memory map and header file will be
    % deleted once all references to the `pset` object have been cleared
    % from MATLAB's workspace.
    %
    % ### `FileNaming`
    %
    % __Class__: `char`
    %
    % __Default:__ `'inherit'`
    %
    % Either `'Inherit'`, `'Random'`, or `'Session'`. See the documentation
    % of [pset.file_naming_policy][file-naming-policy] for more
    % information.
    %
    %
    % ### `ReadEvents`
    %
    % __Class__: `logical`
    %
    % __Default:__ `true`
    %
    % If set to true, the events information will also be imported. This
    % can slow down the data import considerably in some cases. Not all
    % data importers take into consideration the value of this property,
    % i.e. events may be imported even if `ReadEvents` is set to `false`.
    %
    % See also: physioset.import
 
    %% PROTECTED INTERFACE ................................................
    
    methods (Access = protected)
       
        function args = construction_args_pset(obj)
            
           args = {...
               'Precision', obj.Precision, ...
               'Writable',  obj.Writable, ...
               'Temporary', obj.Temporary ...
               'FileName',  obj.FileName ...
               };               
            
        end
        
        % Might be overloaded by children classes
        function args = construction_args_physioset(~)
         
            args = {};
            
        end
        
        
    end
    
    
    %% PUBLIC INTERFACE ...................................................
    properties 
        
       Precision    = pset.globals.get.Precision;
       Writable     = pset.globals.get.Writable;
       Temporary    = pset.globals.get.Temporary;
       ChunkSize    = pset.globals.get.ChunkSize;
       ReadEvents   = true;  
       FileName     = '';
       FileNaming   = 'inherit';
       Sensors      = [];
       EventMapping = mjava.hash({'TREV', 'tr', 'TR\s.+', 'tr'})
       
    end   
   
   % Set methods / consistency checks
   methods
       
       function obj = set.Precision(obj, value)       
           
           import exceptions.*;
           
           if ~ischar(value),
               throw(InvalidPropValue('Precision', ...
                   'Must be a string'));             
           end
           
           if ~any(strcmpi(value, {'double', 'single'})),
               throw(InvalidPropValue('Precision', ...
                   sprintf('Invalid precision ''%s''', value)));              
           end           
           
           obj.Precision = value;           
           
       end       
  
       function obj = set.Writable(obj, value)   
           
           import exceptions.*;
           if numel(value) > 1 || ~islogical(value),
               throw(InvalidPropValue('Writable', ...
                   'Must be a logical scalar'));        
           end                      
           obj.Writable = value;     
           
       end
       
       function obj = set.Temporary(obj, value)    
           
           import exceptions.*;
           if numel(value) > 1 || ~islogical(value),
               throw(InvalidPropValue('Temporary', ...
                   'Must be a logical scalar'));    
           end                      
           
           obj.Temporary = value;           
           
       end
       
       function obj = set.ChunkSize(obj, value)
           
           import exceptions.*;
           import misc.isinteger;            
           if numel(value) > 1 || ~isinteger(value) || value < 0,
               throw(InvalidPropValue('ChunkSize', ...
                   'The ChunkSize property must be a natural number'));            
           end                      
           obj.ChunkSize = value;           
       end
       
       function obj = set.ReadEvents(obj, value)     
           
           import exceptions.*;
           if isempty(value) || numel(value) > 1 || ~islogical(value),
               throw(InvalidPropValue('ReadEvents', ...
                   'Must be a logical scalar'));            
           end                                 
           
           obj.ReadEvents = value;  
           
       end
       
          
        function obj = set.Sensors(obj, value)
           
            import exceptions.*;
            import goo.pkgisa;
            
            if isempty(value), 
                obj.Sensors = [];
                return;
            end
            
            if ~isa(value, 'sensors.sensors'),
               
                throw(InvalidPropValue('Sensors', ...
                    'Must be a sensors.object'));
                
            end
            
            obj.Sensors = value;
            
        end
        
        function obj = set.FileName(obj, value)
           
            import exceptions.*;
            import pset.globals;
            
            if ~ischar(value),
                throw(InvalidPropValue('FileName', ...
                    'Must be a valid file name (a string)'));
            end
            
            [pathName, fileName, ext] = fileparts(value);
            
            if isempty(pathName), pathName = pwd; end
            
            psetExt = globals.get.DataFileExt;
            
            if ~isempty(ext) && ~strcmp(ext, psetExt),
                warning('abstract_physioset_import:InvalidExtension', ...
                    'Replaced file extension %s -> %s', ext, psetExt);
            end
            
            value = [pathName, filesep, fileName, psetExt];
            
            obj.FileName = value;            
            
        end
        
        function obj = set.EventMapping(obj, value)
           
            import exceptions.*;
            
            if isempty(value),
                obj.EventMapping = [];
                return;
            end
            
            if numel(value) ~= 1 || ~isa(value, 'mjava.hash'),
                throw(InvalidPropValue('EventMapping', ...
                    'Must be a mjava.hash object'));
            end
            obj.EventMapping = value;
            
        end
        
       
   end   
   
   methods (Abstract)
       
       varargout = import(obj, filename, varargin)       
       
   end    
   
   % Constructor   
   methods
       
       function obj = abstract_physioset_import(varargin)    
           
           if nargin < 1, return; end           
        
           % Set public properties
           obj = set(obj, varargin{:});
           
       end
       
   end
   
end