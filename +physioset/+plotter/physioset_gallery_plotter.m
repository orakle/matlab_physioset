classdef physioset_gallery_plotter < ...
        report.abstract_gallery_plotter
    % PHYSIOSET_GALLERY_PLOTTER - Plot figure galleries from physiosets
    
    % Constructor
    methods
        
        function obj = physioset_gallery_plotter(varargin)
            
            obj = obj@report.abstract_gallery_plotter(varargin{:});
            
        end
        
    end
    
    
end