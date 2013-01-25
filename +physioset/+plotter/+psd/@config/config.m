classdef config < goo.abstract_setget_handle
    % CONFIG - Configuration for class psd
    %
    % ## Usage synopsis:
    %
    % import pset.plotter.psd.*;
    % cfg = config;
    % cfg = config('key', value, ...)
    % cfg = set(cfg, 'key', value, ...)
    % value = get(cfg, 'key')
    %
    %
    % ## Accepted key/value pairs:
    %
    %       Estimator: A spectrum.? or spectrum2.? class. Alternatively, it
    %           can also be a function_handle that evaluates to an object
    %           of any of such classes and that takes a sampling rate as
    %           only input argument. Default: @(fs) ...
    %           spectrum2.minmax('Estimator', spectrum.welch('Hamming', fs*2));
    %           This argument specifies the estimator that will be used for
    %           computing the PSDs.
    %
    %       Normalized: Logical scalar. Default: false
    %           Should the input data be normalized to have unit variance
    %           before plotting the PSD?
    %
    %       Channels: Cell array with sets of channel indices. Default:  {}
    %           Overrides MaxChannels and plots the PSD across the
    %           specified sets of channels.
    %
    %       Windows: A Kx2 numeric array. Default: []
    %           Overrides WinLength and MaxWindows below and plots the PSD
    %           across the especified set of data windows. The first column
    %           of Windows contains epoch start points (in samples) and the
    %           second column epoch end points.
    %
    %       MaxChannels: A natural scalar. Default: 50
    %           Maximum number of data channels to consider for plotting.
    %           Beware that setting this argument to a large value can slow
    %           down dramatically the computations.
    %
    %       ChannelClass: Cell array of strings. Default: {}
    %           Will generate plots only for the specified channel classes.
    %           If left empty, all channel classes will be plotted.
    %
    %       ChannelType: Cell array of strings. Default: {}
    %           Will generate plots only for the specified channel types.
    %           If left empty, all channel types will be considered.
    %
    %       MaxWindows: Natural scalar. Default: 50
    %           Maximum number of data epochs to consider.
    %
    %       WinLength: Positive scalar. Default: 5
    %           Duration of the analysis windows, in seconds.
    %
    %       Folder: A valid directory name (a string). Default: ''
    %           The figures will be saved to this directory.
    %
    %       Plotter: A plotter.psd object.
    %           Default: plotter.psd('FrequencyRange', [0 60]);
    %           Determines the actual looks of the PSD plots, which are
    %           generated by calling method plot() of the provided plotter
    %           object.
    %
    %       Args: A cell array. Default: {}
    %           The input arguments to use when calling method psd() on the
    %           provided estimator.
    %
    % See also: psd, demo
    
    % Description: Configuration for class psd
    % Documentation: class_config.txt
    
    
    %% PUBLIC INTERFACE ...................................................
    
    properties
        
        BlackBgPlots = false;
        SVG          = true;
        PrintDrivers = {};%{'pdf'}
        Estimator    = @(fs, L) spectrum2.percentile(...
            'Estimator', ...
            spectrum.welch('Hamming', min(ceil(L/5),fs*3)));
        MaxChannels  = 50;
        MaxWindows   = 50;
        WinLength    = Inf;
        Windows      = [];
        Channels     = [];
        ChannelClass = '';
        ChannelType  = '';
        Folder       = '';
        Plotter      = ...
            plotter.psd.psd(...
            'FrequencyRange',   [0 60], ...
            'Visible',          false ...
            );
        Args         = {};
        
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
        
        
        function obj = set.Estimator(obj, value)
            import exceptions.*
            valueClass = class(value);
            if ~isa(value, 'function_handle') && isempty(regexp(valueClass, ...
                    '^spectrum\d*.', 'once')),
                throw(InvalidPropValue('Estimator', ...
                    'Must be a function handle or of spectrum class'));
            end
            
            if isa(value, 'function_handle'),
                % must evaluate to a spectrum class
                try
                    tmp = value(500, 3000);
                catch ME
                    throw(InvalidPropValue('Estimator', ...
                        sprintf(['Function handle must be a function of ' ...
                        'sampling rate: %s'], ME.message)));
                end
                if isempty(regexp(class(tmp), '^spectrum\d.', 'once'))
                    throw(InvalidPropValue('Estimator', ...
                        ['Function handle must evaluate to a ' ...
                        'valid spectrum object']));
                end
                
            end
            obj.Estimator = value;
            
        end
   
        function obj = set.MaxChannels(obj, value)
            import misc.isnatural;
            import exceptions.*
            if isempty(value),
                obj.MaxChannels = 50;
                return;
            end
            
            if numel(value) ~= 1,
                throw(InvalidPropValue('MaxChannels', ...
                    'Must be a scalar'));
            end
            
            if value > 1000,
                throw(InvalidPropValue('MaxChannels', ...
                    sprintf('I will not do that many (%d) channels??', ...
                    value)));
            end
            
            obj.MaxChannels = value;
            
        end
        
        function obj = set.MaxWindows(obj, value)
            import misc.isnatural;
            import exceptions.*
            if isempty(value),
                obj.MaxWindows = 50;
                return;
            end
            
            if numel(value) ~= 1 || ~isnatural(value),
                throw(InvalidPropValue('MaxWindows', ...
                    'Must be a natural scalar'));
            end
            
            if value > 1000,
                throw(InvalidPropValue('MaxWindows', ...
                    sprintf('I will not do that many (%d) windows', ...
                    value)));
            end
            
            obj.MaxWindows = value;
            
        end
        
        function obj = set.WinLength(obj, value)
            import exceptions.*
            if isempty(value),
                obj.WinLength = Inf;
                return;
            end
            
            if numel(value) ~= 1 || ~isnumeric(value) || value < 0,
                throw(InvalidPropValue('WinLength', ...
                    'Must be a positive scalar (number of seconds)'));
            end
            obj.WinLength = value;
        end
        
        function obj = set.Windows(obj, value)
            import misc.isnatural;
            import exceptions.*
            
            if isempty(value),
                obj.Windows = [];
                return;
            end
            
            if ~isnumeric(value) || ndims(value) > 2 || size(value, 2) ~= 2, %#ok<ISMAT>
                throw(InvalidPropValue('Windows', ...
                    'Must be a numeric matrix with two columns'));
            end
            
            if ~isnatural(value),
                throw(InvalidPropValue('Windows', ...
                    'Must be a matrix of natural numbers'));
            end
            
            % Ensure that the windows are sorted
            [~, idx] = sort(value(:,1), 'ascend');
            value = value(idx, :);
            
            % Windows cannot overlap
            if any(value(1:end-1,2) > value(2:end,1)),
                throw(InvalidPropValue('Windows', ...
                    'Overlapping windows are not allowed'));
            end
            
            obj.Windows = value;
            
        end
        
        function obj = set.Channels(obj, value)
            import misc.isnatural;
            import exceptions.*
            if isempty(value),
                obj.Channels = [];
                return;
            end
            
            if ~iscell(value),
                value = {value};
            end
            
            if ~iscell(value),
                throw(InvalidPropValue('Channels', ...
                    'Must be a cell array or a numeric vector'));
            end
            
            if ~all(cellfun(@(x) misc.isnatural(x), value))
                throw(InvalidPropValue('Channels', ...
                    'Must be a cell array of sets of channel indices'));
            end
            
            obj.Channels = value;
            
        end
        
        function obj = set.ChannelClass(obj, value)
            import exceptions.*
            if isempty(value),
                obj.ChannelClass = '';
                return;
            end
            
            if ischar(value),
                value = {value};
            elseif ~iscell(value),
                throw(InvalidPropValue('ChannelClass', ...
                    'Must be a cell array of strings'));
            end
            
            obj.ChannelClass = value;
        end
        
        function obj = set.ChannelType(obj, value)
            import exceptions.*
            if isempty(value),
                obj.ChannelType = '';
                return;
            end
            if ischar(value),
                value = {value};
            elseif ~iscell(value),
                throw(InvalidPropValue('ChannelType', ...
                    'Must be a cell array of strings'));
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
                        sprintf('Dir %s is not valid', value)));
                end
            end
            
            obj.Folder = value;
            
        end
        
        function obj = set.Plotter(obj, value)
            import exceptions.*
            if isempty(value),
                obj.Plotter = plotter.psd('FrequencyRange', [0 60]);
                return;
            end
            
            if numel(value) ~= 1 || ~isa(value, 'plotter.psd.psd'),
                throw(InvalidPropValue('Plotter', ...
                    'Must be of class plotter.psd.psd'));
            end
            obj.Plotter = value;
        end
        
        function obj = set.Args(obj, value)
            import exceptions.*
            if isempty(value),
                obj.Args = {};
                return;
            end
            
            if ~iscell(value) || mod(numel(value), 2),
                throw(InvalidPropValue('Args', ...
                    ['Must be a cell array with an even number ' ...
                    'of elements']));
            end
            
            for i = 1:2:numel(value),
                if ~ischar(value{i}) || ~isvector(value{i}),
                    throw(InvalidPropValue('Args', ...
                        'Must be a cell array with key/value pairs'));
                end
            end
            obj.Args = value;
        end
        
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
            
        end
        
    end
    
    
    
end