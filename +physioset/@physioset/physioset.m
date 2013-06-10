classdef physioset < ...
        pset.mmappset & ...
        goo.printable_handle & ...
        goo.verbose_handle
    % PHYSIOSET - Memory-mapped physiological dataset class
    %
    % A data structure to handle physiological datasets (possibly of
    % different modalities) and related meta-information (e.g. events,
    % sensors information, sampling instants, etc).
    %
    %
    % ## Construction:
    %
    % ````
    % obj = physioset.physioset
    % obj = physioset.physioset('key', value, ...)
    % ````
    %
    % Where
    %
    % `obj` is a `physioset.physioset` object
    %
    %
    % ## Optional construction arguments
    %
    % Optional construction arguments are provided at `('key', value)`
    % tuples. The constructor of the physioset class admits all the
    % construction arguments accepted by the constructor of the parent
    % class pset.pset. Additionally, the following `('key', value)` pairs
    % are also accepted:
    %
    % ### `SamplingRate`
    %
    % __Default:__ `250`
    %
    % __Class__: `numeric`
    %
    % The data sampling rate, in samples per second.
    %
    %
    % ### `Sensors`
    %
    % __Default:__ An array of `dummy` sensors
    %
    % __Class:__ `sensors.sensors`
    %
    % Describes the physiological sensors.
    %
    %
    % ### `Event`
    %
    % __Default:__ `[]`
    %
    % __Class:__ `physioset.event.event`
    %
    % Event or markers that provide information on specific data samples or
    % epochs.
    %
    %
    % ### `StartTime`
    %
    % __Default:__ `datestr(now, 'HH:MM:SS')`
    %
    % __Class:__ `char` array
    %
    % The start time of the recording in format `HH:MM:SS`.
    %
    %
    % ### `StartDate`
    %
    % __Default:__ `datestr(now, 'dd-mmm-yyyy')`
    %
    % __Class:__ `char` array
    %
    % Starting date of the recording in format `dd-mmm-yyyy`.
    %
    %
    %
    % ## Usage synopsis
    %
    % The usage examples below assume the following import directives:
    %
    % ````matlab
    % import physioset.physioset physioset.import.matrix;
    % import pset.pset  pset.session;
    % import spt.pca.pca;
    % ````
    %
    % Import data from MATLAB matrix, the generated memory-mapped file
    % will be stored under directory `D:\tmp`
    %
    % ````matlab
    % session.instance('D:/tmp');
    % myPhysioset = import(matrix, randn(4, 10000))
    % ````
    %
    % Create a new physioset object that will contain only the first 20
    % channels and the first 1000 samples of `myPhysioset`
    %
    % ````matlab
    % myPhysiosetSubset = subset(myPhysioset, 1:20, 1:1000);
    % ````
    %
    % Project data into its principal components:
    %
    % ````matlab
    % pcaObj = learn(pca, myPhysioset);
    % pcs = project(pcaObj, myPhysioset);
    % ````
    %
    % Convert `physioset` object to a plain `pset` object
    % ````matlab
    % myPset = pset.pset(myPhysioset);
    % ````
    %
    % Convert `myPhysioset` to a Fieldtrip and EEGLAB structures:
    %
    % ````matlab
    % myFtripStr  = fieldtrip(myPhysioset);
    % myEEGLABStr = eeglab(myPhysioset);
    % ````
    %
    % Construct `physioset` object from Fieldtrip structure:
    % ````matlab
    % myPhysioset2 = physioset.from_fieldtrip(myFtripStruct);
    %
    % Low-pass filter a `physioset`:
    % ````matlab
    % filtObj = filter.lpfilt('fc', 0.5)  A low pass filter
    % filter(filtObj, myPhysioset2);
    %
    % Note that the filtering syntax above is completely equivalent to:
    % myPhysioset2 = filter(filtObj, myPhysioset2);
    % ````
    %
    % In both cases above, the data values contained in myPhysioset2
    % _will be modified_. This is because class physioset is a handle class.
    % See `help handle` for more information. If you want to pass a
    % `physioset` object by value, you need to explicitely create a copy of
    % the object:
    % ````matlab
    % myPhysiosetCopy = copy(myPhysioset);
    % myPhysiosetCopy = filter(filtObj, myPhysioset);
    % ````
    %
    % ## Class methods
    %
    % ### pset.mmapset interface
    %
    % Class `physioset` implements the [mmappset] interface.
    %
    % [mmappset]: https://github.com/germangh/matlab_pset/blob/master/%2Bpset/mmappset.md
    %
    %
    % ### Data conversion methods
    %
    % Method name             | Description
    % ---------------         | ------------
    % [eeglab][eeglab]        | Conversion to EEGLAB structure
    % [fieldtrip][fieldtrip]  | Conversion to Fieldtrip structure
    %
    %
    % [eeglab]: ./eeglab.md
    % [fieldtrip]: ./fieldtrip.md
    %
    %
    % ### Other methods
    %
    % Documentation to be done
    %
    % See also: pset.pset, physioset.event.event, sensors.sensors

    
    
    %% IMPLEMENTATION .....................................................
    
    
    properties (GetAccess = private, SetAccess = private)
        
        History;            % Processing history
        PointSet;           % A pset.pset object
        Offset;             % For methods remove_offset, restore_offset
        EqWeights;          % Equalization weights
        EqWeightsOrig;      % The inverse of this transforms the data to its original scales
        PhysDimPrefixOrig;  % The original (before equalization) physical dimensions prefix
        BadChan;            % Indicates whether a channel is bad
        BadSample;          % Indicates whether a sample is bad
        Event;              % One or more pset.event objects
        Sensors;            % A sensors.physiology object
        SamplingTime;       % Sampling instants relative to StartTime
        Config = physioset.config;     % Method configuration options
        ProcHistory = {};   
        TimeOrig;
        
    end
    
    properties (Access = private, Dependent)
        
        NbDims;
        NbPoints;
        DimSelection;
        PntSelection;
        DimMap;
        DimInvMap;
        StartTime;
        StartDate;
        
    end
    
    % Get methods for the dependent properties
    methods
        
        function val    = get.NbDims(obj)
            val = obj.PointSet.NbDims;
        end
        
        function val    = get.NbPoints(obj)
            val = obj.PointSet.NbPoints;
        end
        
        function val    = get.DimSelection(obj)
            val = obj.PointSet.DimSelection;
        end
        
        function val    = get.PntSelection(obj)
            val = obj.PointSet.PntSelection;
        end
        
        function val    = get.DimMap(obj)
            val = obj.PointSet.DimMap;
        end
        
        function val    = get.DimInvMap(obj)
            val = obj.PointSet.DimInvMap;
        end
        
        function val    = get.StartTime(obj)            
            val = datestr(obj.TimeOrig, pset.globals.get.TimeFormat);            
        end
        
        function val    = get.StartDate(obj)
            val = datestr(obj.TimeOrig, pset.globals.get.DateFormat);
        end            
            
        
    end
    
    methods (Access = private)
        
        check(obj);
        
        % Memory mapping (pset.pset forwarded methods)
        varargout = get_chunk(obj, varargin);
        
        varargout = get_map_index(obj, varargin);
        
        destroy_mmemmapfile(obj, varargin);
        
        % For reporting
        myTable = parse_disp(obj);
        
        name = default_name(obj);
        
        % Gets equalization props. taking into account selections
        [weights, origWeights, physdim] = get_equalization(obj);
        
    end
    
    
    %% PUBLIC INTERFACE ...................................................
    
    properties (SetAccess = private)
        
        SamplingRate;       % Sampling rate in Hz
    
    end
    
    % Consistency checks (Set methods)
    methods
        
        function set.Event(obj, v)
            import exceptions.*;
            
            if ~all(isempty(v)) && ~isa(v, 'physioset.event.event'),
                throw(InvalidPropValue('Event', ...
                    'Must be (an array of) physioset.event.event object(s)'));
            end
            
            if ~isempty(v),
                obj.Event = sort(v);
            else
                obj.Event = v;
            end
        end
        
        function set.Sensors(obj, v)
            import exceptions.*;
            
            if isempty(v),
                obj.Sensors = [];
                return;
            end
            
            if ~isa(v, 'sensors.sensors'),
                throw(InvalidPropValue('Sensors', ...
                    'Must be of class sensors.sensors'));
            end
            obj.Sensors = v;
        end
        
        function set.SamplingRate(obj, v)
            
            import misc.isnatural;
            import exceptions.*;
            
            if numel(v) ~= 1,
                throw(InvalidPropValue('SamplingRate', ...
                    'Must be a scalar'));
            end
            obj.SamplingRate = v;
            
        end
        
        function set.StartDate(obj, v)
            import exceptions.*;
            
            if ~isempty(v) && ~ischar(v),
                throw(InvalidPropValue('Date', ...
                    'Must be a string'));
            end
            
            obj.StartDate = v;
        end
        
        function set.StartTime(obj, v)
            import exceptions.*;
            
            if ~isempty(v) && ~ischar(v),
                throw(InvalidPropValue('Time', ...
                    'Must be a string'));
            end
            
            obj.StartTime = v;
        end
        
        function set.SamplingTime(obj, v)
            import misc.isnatural;
            import exceptions.*;
            import goo.from_constructor;
            
            if ~isempty(v) && ~all(v > -eps),
                throw(InvalidPropValue('SamplingTime', ...
                    'Must be an array of positive scalars'));
            end
            obj.SamplingTime = v;
            
            if ~from_constructor(obj),
                check(obj);
            end
            
        end
        
    end
    
    % goo.printable_handle interface
    methods
        
        count = fprintf(fid, obj);
        
    end
    
    % pset.mmappset interface
    methods
        
        y   = subsref(obj, s);
        
        obj = subsasgn(obj, s, b);
        
        function nDims    = nb_dim(obj)
            nDims = nb_dim(obj.PointSet);
        end
        
        function nPnts    = nb_pnt(obj)
            nPnts = nb_pnt(obj.PointSet);
        end        
      
        function filename = get_datafile(obj)
            filename = get_datafile(obj.PointSet);
        end
        
        function filename = get_hdrfile(obj)
            filename = get_hdrfile(obj.PointSet);
        end
        
        newObj = copy(obj, varargin);
        
        newObj = subset(obj, varargin);
        
        obj    = concatenate(varargin);
        
        save(obj, filename);
        
        function obj = delay_embed(obj, varargin)
            obj.PointSet = delay_embed(obj.PointSet, varargin{:});
            obj.Sensors  = sensors.dummy(obj.PointSet.NbDims);
        end
        
        function obj = loadobj(obj)
            obj.PointSet = loadobj(obj.PointSet);
        end
        
        function obj = saveobj(obj)
            obj.PointSet = saveobj(obj.PointSet);
        end
        
        function obj = move(obj, varargin)
            obj.PointSet = move(obj.PointSet, varargin{:});
        end
        
        function obj = sphere(obj, varargin)
            obj = sphere(obj.PointSet, varargin{:});
        end
        
        function obj = reref(obj, W)
            newPset = W*copy(obj.PointSet);
            for i = 1:size(obj, 1),
                obj.PointSet(i,:) = newPset(i,:);
            end
        end
        
        function obj = smooth_transitions(obj, evArray, varargin)
            obj.PointSet = ...
                smooth_transitions(obj.PointSet, evArray, varargin{:});
        end
        
        % Selection related methods
        function obj = select(obj, varargin)
            
            if nargin < 2, return; end
            
            select(obj.PointSet, varargin{:});            
           
        end
        
        function obj = invert_selection(obj, varargin)
            invert_selection(obj.PointSet, varargin{:});            
        end
        
        function obj = clear_selection(obj)
            clear_selection(obj.PointSet);
        end
        
        function obj = restore_selection(obj)
            restore_selection(obj.PointSet);
        end
        
        function obj = backup_selection(obj)
            backup_selection(obj.PointSet);
        end
        
        function bool = has_selection(obj)
            bool = has_selection(obj.PointSet);
        end
        
        function dimSel = dim_selection(obj)
            dimSel = dim_selection(obj.PointSet);
        end
        
        function pntSel = pnt_selection(obj)
            pntSel = pnt_selection(obj.PointSet);
        end
        
        function obj = set_dim_selection(obj, sel)
            set_dim_selection(obj.PointSet, sel);
        end
        
        function obj = set_pnt_selection(obj, sel)
            set_pnt_selection(obj.PointSet, sel);
        end
        
        ev = get_pnt_selection_events(obj, evTemplate);
        
        % Projection related methods
        function obj = project(obj, varargin)
            obj = project(obj.PointSet, varargin{:});
        end
        
        function obj = clear_projection(obj)
            clear_projection(obj);
        end
        
        function obj = restore_projection(obj)
            restore_projection(obj.PointSet);
        end
        
        function obj = backup_projection(obj)
            backup_projection(obj.PointSet);
        end
        
        
    end
    
    % Const public methods
    methods
        
        time               = get_time_origin(obj);
        
        args               = construction_args(obj, type);
        
        bool               = is_bad_channel(obj, idx);
        
        bool               = is_bad_sample(obj, idx);
        
        sensObj            = sensors(obj);
        
        % These two methods are identical, sampling_time is kept for
        % backward compatibility
        [sTime, absTime]   = sampling_time(obj);        
        [sTime, absTime]   = get_sampling_time(obj, idx);
        
        value              = get_method_config(obj, varargin);
        
        nbEvents           = nb_event(obj);
        
        [evArray, rawIdx]  = get_event(obj, idx);
        
        history            = get_processing_history(obj, idx);
        
        h = plot(obj, varargin);
        
        % For reporting/plotting purposes
        
        [c, cClass, cType] = default_channel_groups(data, varargin);
        
        windows = default_window_selection(data, varargin);
        
        [y, evNew, samplIdx, evOrig, trialEv] = epoch_get(x, trialEv, base);
        
    end
    
    % Mutable public methods
    methods
        
        obj             = set_bad_channel(obj, index);
        
        obj             = set_bad_sample(obj, index);
        
        obj             = clear_bad_channel(obj, index);
        
        obj             = clear_bad_sample(obj, index);
        
        obj             = select_good_data(data);
        
        [obj, idx]      = add_event(obj, ev);
        
        obj             = delete_event(obj, idx);
        
        obj             = set_method_config(obj, varargin);
        
        % node is a pset.node.node object or 
        obj             = add_processing_history(obj, node);
        
        obj             = equalize(obj, varargin);
        
    end
    
    % MATLAB built-in numeric methods (pset.pset forwarded)
    methods
        
        function obj        = circshift(obj, ~, varargin) %#ok<MANU>            
            error('Not implemented yet!');            
        end
        
        function obj        = conj(obj, varargin)
            obj.PointSet = conj(obj.PointSet, varargin{:});
        end
        
        function C          = cov(obj, varargin)
            C = cov(obj.PointSet, varargin{:});
        end
        
        function obj        = ctranspose(obj, varargin)
            obj.PointSet = ctranspose(obj.PointSet, varargin{:});
        end
        
        function y          = double(obj, varargin)
            y = double(obj.PointSet, varargin{:});
        end
        
        function y          = end(obj, k, ~)
            y = size(obj.PointSet, k);
        end
        
        function obj        = flipud(obj, varargin)
            obj.PointSet = flipud(obj.PointSet, varargin{:});
        end
        
        function bool       = isfloat(obj)
            bool = isfloat(obj.PointSet);
        end
        
        function bool       = isnumeric(obj)
            bool = isnumeric(obj.PointSet);
        end
        
        function bool       = issparse(obj)
            bool = issparse(obj.PointSet);
        end
        
        function val        = length(obj)
            val = length(obj.PointSet);
        end
        
        function bool       = logical(obj)
            bool = logical(obj.PointSet);
        end
        
        function val        = mean(obj, varargin)
            val = mean(obj.PointSet, varargin{:});
        end
        
        function val        = center(obj, varargin)
            val = center(obj.PointSet, varargin{:});
        end
        
        function obj        = minus(varargin)
            
            for i = 1:nargin
                if isa(varargin{i}, 'physioset.physioset'),
                    obj = varargin{i};
                    varargin{i} = obj.PointSet;
                end
            end
            obj.PointSet = minus(varargin{:});
        end
        
        function obj        = mrdivide(varargin)
            for i = 1:nargin
                if isa(varargin{i}, 'physioset.physioset'),
                    varargin{i} = varargin{i}.PointSet;
                end
            end
            obj = mrdivide(varargin{:});
        end
        
        function obj        = mtimes(varargin)
            for i = 1:nargin
                if isa(varargin{i}, 'physioset.physioset'),
                    varargin{i} = varargin{i}.PointSet;
                end
            end
            obj = mtimes(varargin{:});
        end
        
        function val        = ndims(obj, varargin)
            val = ndims(obj.PointSet, varargin{:});
        end
        
        function obj        = plus(varargin)
            for i = 1:nargin
                if isa(varargin{i}, 'physioset.physioset'),
                    obj = varargin{i};
                    varargin{i} = obj.PointSet;
                end
            end
            obj.PointSet = plus(varargin{:});
        end
        
        function obj        = power(obj, varargin)
            obj.PointSet = power(obj.PointSet, varargin{:});
        end
        
        function obj        = rdivide(varargin)
            for i = 1:nargin
                if isa(varargin{i}, 'physioset.physioset'),
                    obj = varargin{i};
                    varargin{i} = obj.PointSet;
                end
            end
            obj.PointSet = rdivide(varargin{:});
        end
        
        function obj        = repmat(obj, varargin)
            obj.PointSet = repmat(obj.PointSet, varargin{:});
        end
        
        function obj        = reshape(obj, varargin)
            obj = reshape(obj.PointSet, varargin{:});
        end
        
        function obj        = sign(obj, varargin)
            obj.PointSet = sign(obj.PointSet, varargin{:});
        end
        
        function val        = single(obj, varargin)
            val = single(obj.PointSet, varargin{:});
        end
        
        function varargout  = size(obj, varargin)
            if nargout == 0,
                varargout{1} = size(obj.PointSet, varargin{:});
                return;
            elseif nargout == 1,
                varargout{1} = size(obj.PointSet, varargin{:});
            else
                varargout = cell(1, nargout);
                for i = 1:nargout,
                    varargout{i} = size(obj.PointSet, i);
                end
            end
        end
        
        function obj        = sum(obj, varargin)
            obj = sum(obj.PointSet, varargin);
        end
        
        function obj        = times(varargin)
            for i = 1:nargin
                if isa(varargin{i}, 'physioset.physioset'),
                    obj = varargin{i};
                    varargin{i} = obj.PointSet;
                end
            end
            obj.PointSet = times(varargin{:});
        end
        
        function obj        = transpose(obj, varargin)
            obj.PointSet = transpose(obj.PointSet, varargin{:});
        end
        
        function val        = var(obj, varargin)
            val = var(obj.PointSet, varargin{:});
        end
        
    end
    
    % Conversion to other types (and related helper methods)
    methods
        
        obj      = pset(obj);
        
        winrej   = eeglab_winrej(obj);
        
        str      = eeglab(obj, varargin);
        
        str      = fieldtrip(obj, varargin);
        
        
    end
    
    % Static constructors
    methods (Static)
        
        obj = from_fieldtrip(str, varargin);
        
        obj = from_eeglab(str, varargin);
        
        obj = from_pset(obj, varargin);
        
        obj = load(obj);
        
    end
    
    % Constructor
    methods
        
        function obj = physioset(varargin)
            
            import pset.pset;
            import misc.process_arguments;
            import pset.globals;
            
            if nargin > 0 && isa(varargin{1}, 'pset.pset'),
                obj.PointSet = varargin{1};
            else
                obj.PointSet = pset(varargin{:});
            end
            
            varargin = varargin(3:end);
            
            opt.samplingrate    = globals.get.SamplingRate;
            opt.sensors         = [];
            opt.event           = [];
            opt.name            = '';            
          
            opt.samplingtime  = [];
            dateFormat        = globals.get.DateFormat;
            timeFormat        = globals.get.TimeFormat;
            opt.startdate     = datestr(now, dateFormat);
            opt.starttime     = now;
            opt.eqweights     = [];
            opt.eqweightsorig = [];
            opt.physdimprefixorig = [];
            opt.badchannel    = [];
            opt.badsample     = [];
            opt.info          = struct;
            
            [~, opt] = process_arguments(opt, varargin);
            
            if isempty(opt.sensors),
                opt.sensors = sensors.dummy(size(obj.PointSet,1));
            end
            
            if isempty(opt.samplingtime),
                
                opt.samplingtime = ...
                    0:1/opt.samplingrate:obj.PointSet.NbPoints/...
                    opt.samplingrate - 1/opt.samplingrate;                
           
            end
            
            
            % physioset name
            if isempty(opt.name),
                opt.name = default_name(obj);
            end
            
            if ischar(opt.starttime),
                opt.starttime = ...
                    datenum([opt.startdate ' ' opt.starttime], ...
                    [dateFormat ' ' timeFormat]);
            end
            
            obj.SamplingRate    = opt.samplingrate;
            obj.Sensors         = opt.sensors;
            obj.SamplingTime    = opt.samplingtime;            
            obj.TimeOrig        = opt.starttime;
            obj.Event           = opt.event;
            obj.EqWeights       = opt.eqweights;
            obj.EqWeightsOrig   = opt.eqweightsorig;
            obj.PhysDimPrefixOrig = opt.physdimprefixorig;
            
            obj                 = set_name(obj, opt.name);
            
            % Set meta properties
            obj = set(obj, opt.info);
            
            if obj.NbDims > 0,
                if isempty(opt.badchannel),
                    obj.BadChan = false(1, obj.NbDims);
                else
                    obj.BadChan = opt.badchannel;
                end
            end
            
            if obj.NbPoints > 0,
                if isempty(opt.badsample),
                    obj.BadSample = false(1, obj.NbPoints);
                else
                    obj.BadSample = opt.badsample;
                end
            end
            
            check(obj);
        end
        
    end
    
end