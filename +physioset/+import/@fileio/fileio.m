classdef fileio < pset.import.abstract_physioset_import
    
    % Documentation: pkg_pset_import.txt
    % Description: Fieldtrip's fileio data importer
    
    properties
       Fieldtrip; 
    end
    
    methods
        function obj = fileio(varargin)
           obj = obj@pset.import.abstract_physioset_import(varargin{:}); 
            % Add the fieldtrip toolbox to the path  
            locs = [pset.import.globals.evaluate.Fieldtrip;...
                misc.split(':', path)];
            for i = 1:numel(locs),
                if exist(locs{i}, 'dir')
                    obj.Fieldtrip = locs{i};
                    break;
                end
            end
            if isempty(obj.Fieldtrip),
                ME = MException('pset.import.@fileio:fileio:MissingDependency', ...
                    'Fieldtrip dependency is missing. Get it from: http://fieldtrip.fcdonders.nl');
                throw(ME);
            end

        end
    end
    
    methods
        eegsetObj = import(obj, filename, varargin);        
    end
    
    
end