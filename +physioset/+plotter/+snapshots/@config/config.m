classdef config < goo.abstract_setget_handle
    % CONFIG - Configuration for class snapshots
    %
    % ## Usage synopsis:
    %
    % import pset.plotter.snapshots.*;
    % cfgObj = config;
    % cfgObj = config('key', value, ...)
    % cfgObj = set(cfgObj, 'key', value, ...)
    % value  = get(cfgObj, 'key')
    %
    % % Create a properly configured snapshots object
    % myPlotter = snapshots(cfgObj);
    %
    %
    % ## Accepted key/value pairs:
    %
    %       BlackBgPlots: Logical scalar. Default: true
    %           If set to true, for each provided printing driver (except
    %           for the minimal .png printing driver), an equivalent figure
    %           with a black background will be generated.
    %
    %       PrintDrivers: Cell array of strings. Default: {'pdf'}
    %           Defines the output format(s) of the generated figures. Note
    %           that .png figures are generated even if PrintDrivers is
    %           empty.
    %
    %       MaxChannels: A natural scalar. Default: 50
    %           Maximum number of data channels to consider for plotting.
    %           Beware that setting this argument to a large value can slow
    %           down dramatically the computations.
    %
    %       Channels: Cell array with sets of channel indices. Default:  {}
    %           Overrides MaxChannels and generates figures for the
    %           specified sub-sets of channels.
    %
    %       ChannelClass: Cell array of strings. Default: {}
    %           Will generate plots only for the specified channel classes.
    %           If left empty, all channel classes will be plotted.
    %
    %       ChannelType: Cell array of strings. Default: {}
    %           Will generate plots only for the specified channel types.
    %           If left empty, all channel types will be considered.
    %
    %       Folder: A valid directory name (a string). Default: ''
    %           The figures will be saved to this directory.
    %
    %       Plotter: A plotter.eegplot object. Default: plotter.eegplot
    %           Determines the actual looks of the snapshots, which are
    %           generated by calling method plot() of the provided plotter
    %           object.
    %
    %       Args: A cell array. Default: {}
    %           The input arguments to use when calling MATLAB's built-in
    %           psd() function
    %
    %       Verbose: Logical scalar. Default: true
    %           If set to true, status messages will be displayed.
    %
    %       VerboseLabel: A string. Default: '(psd.plot.space.psd) '
    %           A string that will precede every status messages.
    %
    % See also: snapshots
    
    % Description: Configuration for class snapshots
    % Documentation: class_config.txt
    
    
    %% IMPLEMENTATION .....................................................
    methods  (Access = private)
        
        % Global consistency check
        function check(obj)
            
            bool = true;
            if isempty(obj.WinLength),
                bool = false;
            end
            if isempty(obj.Epochs) && (isempty(obj.NbGoodEpochs) || ...
                    isempty(obj.NbBadEpochs))
                bool = false;
            end
            if isempty(obj.Channels) && (isempty(obj.MaxChannels) && ...
                    isempty(obj.ChannelClass) && isempty(obj.ChannelType)),
                bool = false;
            end
            
            if ~bool,
                throw(Inconsistent);
            end
        end
        
    end
        
    
    %% PUBLIC INTERFACE ...................................................
    properties
        
        BlackBgPlots    = false;
        SVG             = true;
        PrintDrivers    = {};     % {'pdf'}
        WinLength       = 20;
        NbGoodEpochs    = 4;
        NbBadEpochs     = 4;
        Epochs          = [];
        Channels        = [];
        MaxChannels     = 30;
        ChannelClass    = '';
        ChannelType     = '';
        % Default eegplot scales will be multiplied by this factor
        ScaleFactor     = 2.5;       
        % The image files will be stored here:
        Folder          = '';        
        Plotter         = ...
            plotter.eegplot.eegplot(...
            'Visible', eegpipe.globals.get.VisibleFigures ...
            );
        Resolution      = eegpipe.globals.get.ImageResolution;
        
    end
    
    % Consistency checks
    methods
        
        function obj = set.BlackBgPlots(obj, value)
            
            import exceptions.*
            
            if isempty(value), value = true; end
            
            if ~islogical(value) || numel(value) ~= 1,
                throw(InvalidPropValue('BlackBgPlots', ...
                    'Must be a logical scalar'));
            end
            obj.BlackBgPlots = value;
        end
        
        function obj = set.SVG(obj, value)
            import exceptions.*
            if isempty(value), value = true; end
            
            if ~islogical(value) || numel(value) ~= 1,
                throw(InvalidPropValue('SVG', ...
                    'Must be a logical scalar'));
            end
            obj.SVG = value;
        end
        
        function obj = set.PrintDrivers(obj, value)
            import exceptions.*
            if ischar(value),
                value = {value};
            end
            
            if ~all(cellfun(@(x) ischar(x) && ~isempty(x), value)),
                throw(InvalidPropValue('PrintDrivers', ...
                    'Must be a cell array of strings'));
            end
            
            obj.PrintDrivers = value;
            
        end
        
        function obj = set.ChannelClass(obj, value)
            
            if isempty(value),
                obj.ChannelClass = '';
                return;
            end
            obj.ChannelClass = value;
        end
        
        function obj = set.ChannelType(obj, value)
            
            if isempty(value),
                obj.ChannelType = '';
                return;
            end
            obj.ChannelType = value;
        end
        
        function obj = set.Folder(obj, value)
            import exceptions.*
            if isempty(value),
                obj.Folder = '';
                return;
            end
            
            if ~ischar(value) || ~isvector(value),
                throw(InvalidPropValue('Folder', ...
                    'Must be a string'));
            end
            
            % see whether this is a valid folder name
            if ~exist(value, 'dir'),
                success = mkdir(value);
                if success,
                    rmdir(value);
                else
                    throw(InvalidPropValue('Folder', ...
                        sprintf('Dir %s does not seem to be valid', value)));
                end
            end
            
            obj.Folder = value;
            
        end
        
        function obj = set.Plotter(obj, value)
            import exceptions.*
            if isempty(value),
                obj.Plotter = plotter.eegplot.eegplot;
                return;
            end
            
            if numel(value) ~= 1 || ~isa(value, 'plotter.eegplot.eegplot'),
                throw(InvalidPropValue('Plotter', ...
                    'Must be of class plotter.eegplot'));
            end
            obj.Plotter = value;
        end
        
        function obj = set.Resolution(obj, value)
            import exceptions.*
            import misc.isnatural;
            if isempty(value),
                value = globals.get.ImageResolution;
            end
            
            if numel(value) ~= 1 || ~isnatural(value) || value > 900 || ...
                    value < 100,
                throw(InvalidPropValue('Resolution', ...
                    'Must be a natural scalar in the range [100 900]'));
            end
            
            obj.Resolution = value;
            
        end
        
        
    end
    
    % report.reportable interface
    methods
        [pName, pValue, pDescr] = report_info(obj);
    end
    
    % Constructor
    methods
        
        function obj = config(varargin)
            
            import pset.session;
            
            obj = obj@goo.abstract_setget_handle(varargin{:});
            
            if nargin < 2,
                % Copy constructor
                return;
            end
           
            obj = set(obj, varargin{:});
  
            check(obj);
            
        end
        
    end
    
end