function physioSet = import(obj, iFileName, varargin)
% IMPORT - Imports FIELDTRIP structs
%
% physioSet = import(obj, iFileName)
% physioSet = import(obj, 'key', value, ...)
%
% Where
%
% OBJ is an pset.import.fieldtrip object
%
% IFILENAME is the name of the Fieldtrip file to be imported
%
% PHYSIOSETOBJ is a pset.physioset object containing the imported data
%
%
% ## Optional arguments (as key/value pairs):
%
%
%       FileName: (string) Default: session.instance.tempname
%           Name of the generated file
%
%
% ## Notes:
% 
% * You can used external.regexpdir.regexpdir to build the cell array of
%   files that are to be imported. Example:
%
%   import external.regexpdir.regexpdir;
%   % Get names of all .mff files under the root directory dataFolder
%   myFiles = regexpdir('C:/dataFolder', '.mff$', true);
%   myObj = import(pset.import.fileio, myFiles);
%
%
% See also: pset.import, pset.physioset.from_fieldtrip

import pset.physioset;
import pset.event.event;
import pset.file_naming_policy;
import misc.process_arguments;
import misc.sizeof;
import misc.regexpi_dir;
import mperl.file.spec.*;

verboseLabel = get_verbose_label(obj);
verbose      = is_verbose(obj);

% Set the global verbose (for sub-functions called here)
globals.set('VerboseLabel', verboseLabel);


%% Deal with the multi-filename case using recursion
if iscell(iFileName),
    physioSet = cell(numel(iFileName), 1);
    for i = 1:numel(iFileName)
        physioSet{i} = import(obj, iFileName{i}, varargin{:});
    end
    return;
end

%% Error checking
if nargin < 2 || isempty(iFileName),
    ME = MException('import:invalidInput', ...
        'At least two input arguments are expected');
    throw(ME);
end

%% Optional input arguments
opt.filename    = [];

[~, opt] = process_arguments(opt, varargin);


%% Determine the names of the generated (imported) files
filename = opt.filename;
if isempty(filename),
    filename = file_naming_policy(obj.FileNaming, iFileName);
end
dataFileExt = pset.globals.evaluate.DataFileExt;
filename = regexprep(filename, ['(' dataFileExt ')'], '');
filename = [filename dataFileExt];

%% Load the .mat file and try to guess the name of the data struct
if verbose,
    [~, name, ext] = fileparts(iFileName);
    fprintf([verboseLabel 'Loading %s...'], [name ext]);
end
str = load(iFileName);
if verbose,
    fprintf('[done]\n\n');
end
fNames = fieldnames(str);
data = [];
for i = 1:numel(fNames),
    if isstruct(str.(fNames{i})) && isfield(str.(fNames{i}), 'cfg') && ...
            isfield(str.(fNames{i}), 'fsample'),
        data = str.(fNames{i});        
    end
end
if isempty(data),
    ME = MException('pset:import:fieldtrip:MissingData', ...
        'I could not find any M/EEG data structure in %s', iFileName);
    throw(ME);
end


%% Call the static constructor
if verbose,
    [~, name, ext] = fileparts(iFileName);
    fprintf([verboseLabel 'Generating physioset object %s...'], [name ext]);
end
[~, name] = fileparts(iFileName);
physioSet = physioset.from_fieldtrip(data, ...
    'Name',         name, ...
    'FileName',     filename, ...
    'Precision',    obj.Precision, ...
    'Writable',     obj.Writable, ...
    'Temporary',    obj.Temporary);

%save(physioSet);
if verbose,
    fprintf('\n\n');
end

% Unset the global verbose
globals.set('VerboseLabel', '');

end



