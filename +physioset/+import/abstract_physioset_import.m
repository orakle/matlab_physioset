classdef abstract_physioset_import < ...
        physioset.import.physioset_import & ...
        goo.abstract_setget & ...
        goo.verbose
    % ABSTRACT_PHYSIOSET_IMPORT - Commonality among physioset_import classes
    %
    % The abstract_physioset_import class is an abstract class designed for
    % inheritance. This means that instances of the class cannot be created
    % but instead the purpose of the class is to provide its children
    % classes with common properties and methods. The values of the
    % properties listed below can be set during construction of an object
    % of a child class using key/value pairs. For instance, the command:
    %
    %   importObj = physioset.import.eeglab('FileNaming', 'Temporary')
    %
    % will create an object of class physioset.import.eeglab, which inherits
    % from class abstract_physioset_import. The property 'FileNaming' (which
    % is defined by the abstract_physioset_import class) will be set to
    % 'Temporary'. 
    %
    %
    % ## Most relevant properties:
    %
    % 'Precision'   : (char) Either 'single' or 'double'. Determines the
    %                 numeric precision that should be used when importing
    %                 data. 
    %                 Default: globals.evaluate.Precision
    %
    % 'Writable'    : (logical) If set to true the generated object will be
    %                 writable in the sense that the contents of its
    %                 associated memory map can be modified through its
    %                 public interface. 
    %                 Default: globals.evaluate.Writable
    %
    % 'Temporary'   : (logical) If set to true, the associated memory map
    %                 and header file will be deleted upon destruction of
    %                 the imported eegset object. 
    %                 Default: globals.evaluate.Temporary
    %
    % 'FileNaming'  : (char) Either 'Inherit', 'Random' or 'Session'. See
    %                  below for information on these three file naming
    %                  policies. 
    %                  Default: globals.evaluate.FileNaming
    %
    % 'ReadEvents'  : (logical) If set to true, the events information will
    %                 also be imported. 
    %                 Default: true
    %  
    % See also: physioset.import.eegset_import
    
    % Documentation: class_physioset.import.abstract_physioset_import.txt
    % Description: Commonality among eegset_import classes
 
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
       
    end   
   
   % Set methods / consistency checks
   methods
       
       function obj = set.Precision(obj, value)       
           
           import exceptions.*
           
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
           
           import exceptions.*
           if numel(value) > 1 || ~islogical(value),
               throw(InvalidPropValue('Writable', ...
                   'Must be a logical scalar'));        
           end                      
           obj.Writable = value;     
           
       end
       
       function obj = set.Temporary(obj, value)    
           
           import exceptions.*
           if numel(value) > 1 || ~islogical(value),
               throw(InvalidPropValue('Temporary', ...
                   'Must be a logical scalar'));    
           end                      
           
           obj.Temporary = value;           
           
       end
       
       function obj = set.ChunkSize(obj, value)
           
           import exceptions.*
           import misc.isinteger;            
           if numel(value) > 1 || ~isinteger(value) || value < 0,
               throw(InvalidPropValue('ChunkSize', ...
                   'The ChunkSize property must be a natural number'));            
           end                      
           obj.ChunkSize = value;           
       end
       
       function obj = set.ReadEvents(obj, value)     
           
           import exceptions.*
           if isempty(value) || numel(value) > 1 || ~islogical(value),
               throw(InvalidPropValue('ReadEvents', ...
                   'Must be a logical scalar'));            
           end                                 
           
           obj.ReadEvents = value;  
           
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