classdef abstract_gallery_plotter < ...
        physioset.plotter.gallery_plotter & ...
        goo.abstract_configurable_handle & ...
        goo.reportable_handle & ...
        goo.verbose_handle
    
  
    % report.reportable interface
    methods
        
        function str = whatfor(~)
            
            str = '';
            
        end
        
        % Children will probably want to redefine method report_info
        function [pName, pValue, pDescr]   = report_info(obj, varargin)
            
            [pName, pValue, pDescr]   = report_info(obj.Config);
            
        end
        
    end
    
   
    % abstract constructor
    methods
        
        function obj = abstract_gallery_plotter(varargin)
            
            obj = obj@goo.abstract_configurable_handle(varargin{:});
           
            
        end
        
    end
    
    
end