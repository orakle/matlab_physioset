function physObj = import(obj, ifilename, varargin)
% import - Imports .pset files
%
% physObj = import(obj, ifilename)
% physobj = import(obj, 'key', value, ...)
%
% Where
%
% OBJ is an physioset.import.eeglab object
%
% IFILENAME is the name of the .pset file to be imported. Alternatively,
% IFILENAME can be a cell array containing multiple file names. In the
% latter case, the output PHYSOBJ will be a cell array of physioset
% objects.
%
% PHYSOBJ is a physioset.object (or a cell array, see above). 
%
%
% ## Most relevant key/value pairs:
%
%
% 'Folder'      : (string) If provided, all files in the specified folder
%                 will be imported.
%                 Default: [], i.e. not applicable
%
% 'RegExp'      : (string) Regular expression that matches the files in the
%                 provided folder that the user wants to import.
%                 Default: '([^.]+)', i.e. any file except . and ..
%
% 'Verbose'     : (logical) Default: obj.Verbose
%
%
%
% ## Notes:
%
% * If the optional argument folder is provided, then the IFILENAME
%   mandatory argument must be empty
%
%
%
% See also: physioset.import.

import pset.file_naming_policy;
import physioset.import.globals;
import pset.event;
import misc.process_arguments;
import misc.sizeof;
import misc.regexpi_dir;
import mperl.file.spec.*;
import physioset.import.physioset;
import pset.pset;

% Deal with the multi-filename case using recursion
if iscell(ifilename),
    physObj = cell(numel(ifilename), 1);
    for i = 1:numel(ifilename)
        physObj{i} = import(obj, ifilename{i}, varargin{:});
    end   
    return;
end

opt.folder          = '';
opt.regexp          = '([^.]+\.pseth$)';
opt.verbose         = obj.Verbose;

[~, opt] = process_arguments(opt, varargin);

if ~isempty(ifilename) && ~isempty(opt.folder),
    throw(physioset.InvalidInput(...
        ['The ''Folder'' optional argument is only accepted if the '...
        'IFILENAME mandatory input argument is empty']));
end

% Use recursion to process a folder file by file
if isempty(ifilename) && isempty(opt.folder),
    physObj = [];
    return;
elseif isempty(ifilename)    
    fileList = regexpi_dir(opt.folder, opt.regexp);
    physObj = cell(numel(fileList), 1);   
    for i = 1:numel(fileList)
        if opt.verbose,
            [~, thisName] = fileparts(fileList{i});
            fprintf('\n(import) Importing ''%s''...', thisName);            
        end
        physObj{i} = import(obj, fileList{i}, ...
            'Verbose', false, ...
            'Folder', []);  
        if opt.verbose,
            fprintf('[done]\n');            
        end       
    end
    return;
end

% Read the dataset
physObj = pset.load(ifilename);



end