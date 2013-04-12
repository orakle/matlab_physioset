function y = copy(obj, varargin)
% COPY - Creates a copy of a physioset.object
%
% objNew = copy(obj)
%
% objNew = copy(obj, 'key', value, ...)
%
% Where
%
% OBJ and OBJNEW are two identical but otherwise independent physioset.
% objects.
%
% 
% ## Major (optional) key/value pairs:
%
%       Path : (string) Default: '', i.e. inherit from input object
%           The path to the directory where the copy of the memory-mapped
%           file should be created.
%
%       DataFile : (string) Default: ''
%           The name of the newly created memory-mapped file.
%               
%
%       Prefix : (string) Default: ''
%           The name of the memory-mapped file will be obtained by adding
%           this prefix to the name of the input memory-mapped file. 
%              
%       Postfix : (string) Default: '' 
%           Same as 'Prefix' but specifies as postfix
%               
%
%       Overwrite : (logical) Default: false
%           If set to true, the memory-mapped file will be created even if
%           it already exists. Otherwise, if the file already exists an
%           error will be triggered. 
%               
%
% ## Notes:
%
% * All key/value pairs accepted by the constructor of physioset.
%   objects are also accepted. Those key/value pairs will be passed directly
%   to the constructor.
%
%
% See also: physioset

% Documentation: class_physioset.txt
% Description: Copies physioset objects

%% Preliminaries
import misc.process_arguments;
import physioset.physioset;
import mperl.file.spec.catfile;
import pset.session;
import pset.globals;

dataExt             = globals.get.DataFileExt;

verbose             = is_verbose(obj);
verboseLabel        = get_verbose_label(obj);

%% Optional input arguments
opt.path            = [];
opt.datafile        = [];
opt.prefix          = [];
opt.postfix         = [];
opt.overwrite       = true;
opt.temporary       = [];
opt.writable        = [];
opt.precision       = [];
opt.transposed      = [];

[~, opt] = process_arguments(opt, varargin);

if isempty(opt.datafile) && isempty(opt.prefix) && isempty(opt.postfix),
    opt.datafile = [...
        session.instance.tempname ...
        globals.get.DataFileExt ...
        ];
end

[path, name] = fileparts(obj.PointSet.DataFile);

if ~isempty(opt.datafile),
    [path, name] = fileparts(opt.datafile);
end

if ~isempty(opt.path),
    path = opt.path;
end

opt.datafile = catfile(path, [opt.prefix name opt.postfix dataExt]);

if ~opt.overwrite && exist(opt.datafile, 'file'),
    warning('physioset:copy:FileExists', ...
        'File %s already exists. Nothing done!', opt.datafile);     
end

%% Create a copy of the data file
[pathstr, fname] = fileparts(opt.datafile);
if isempty(pathstr),
    new_name = ['.' filesep fname dataExt];    
else
    new_name = [pathstr filesep fname dataExt];
end
if verbose,
    [~, nameIn] = fileparts(obj.PointSet.DataFile);
    [~, nameOut] = fileparts(opt.datafile);
    fprintf([verboseLabel, 'Copying ''%s'' -> ''%s''...'], ...
        nameIn, ...
        nameOut);
    pause(0.01);
end
if exist(new_name, 'file'),
    [pathName, fileName] = fileparts(new_name);
    delete(new_name);
    % Associated header file
    hdrFile = [pathName, filesep, fileName, pset.globals.get.HdrFileExt];
    if exist(hdrFile, 'file'),
        delete(hdrFile);
    end
end
copyfile(obj.PointSet.DataFile, new_name);

%% Create an physioset object associated to the new memory-mapped file
if isempty(opt.temporary),
    opt.temporary = obj.PointSet.Temporary;
end
if isempty(opt.writable),
    opt.writable = obj.PointSet.Writable;
end
if isempty(opt.precision),
    opt.precision = obj.PointSet.Precision;
end    
if isempty(opt.transposed),
    opt.transposed = obj.PointSet.Transposed;
end

y = physioset(new_name, obj.PointSet.NbDims, ...  
    'SamplingRate',     obj.SamplingRate, ...
    'Sensors',          obj.Sensors, ...
    'Event',            obj.Event, ...
    'StartDate',        obj.StartDate, ...
    'StartTime',        obj.StartTime, ...
    'Precision',        opt.precision, ...
    'Temporary',        opt.temporary, ...
    'Transposed',       opt.transposed, ...
    'Writable',         opt.writable);

%% Manually copy private properties
y.EqWeights         = obj.EqWeights;
y.EqWeightsOrig     = obj.EqWeightsOrig;
y.PhysDimPrefixOrig = obj.PhysDimPrefixOrig;
y.BadChan           = obj.BadChan;
y.BadSample         = obj.BadSample;
y.ProcHistory       = obj.ProcHistory;

set_name(y, get_full_name(obj));

if ~isempty(obj.PntSelection) || ~isempty(obj.DimSelection),
    select(y, obj.DimSelection, obj.PntSelection);
end

%% Copy meta-properties
set_meta(y, get_meta(obj));

if verbose,
    fprintf('[done]\n\n');
    pause(0.01);
end


end
