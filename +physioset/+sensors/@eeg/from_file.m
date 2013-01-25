function obj = from_file(filename, varargin)
% FROM_FILE - Reads EEG physioset.sensors.information from a file
%
% obj = physioset.sensors.eeg.from_file(filename)
%
% obj = physioset.sensors.eeg.from_file(filename, 'key', value, ...)
%
% where
%
% OBJ is a eeg.physioset.sensors.object
%
% FILENAME is the full path to a .sfp or .hpts file with sensor locations
%
%
% ## Accepted (optional) key/value pairs:
%
% 'Fiducials', <FID>
%       The coordinates of the physioset.sensors.with indices FID will be considered
%       to correspond to Fiducials and not to real physioset.sensors. Note that this
%       option is ignored for .hpts files. Default: []
%
% See also: from_eeglab, from_fieldtrip, from_template
% Documentation: class_physioset.sensors.eeg.txt
% Description: Reads physioset.sensors.information from a file


import misc.process_arguments;

opt.fiducials = [];

[~, opt] = process_arguments(opt, varargin);

[~, ~, ext] = fileparts(filename);

InvalidFormat = MException('physioset.sensors.eeg:read:InvalidFormat', ...
    'Format %s is not supported', ext);

switch lower(ext)
    case '.sfp',
        [xyz, id] = io.sfp.read(filename);    
        fidXyz = xyz(opt.fiducials,:);
        xyz = xyz(setdiff(1:size(xyz,1), opt.fiducials), :);
        fidId = id(opt.fiducials);

    case '.hpts', 
        [xyz, cat, id] = io.hpts.read(filename);
        fidXyz      = xyz(ismember(cat, 'cardinal'),:);
        fidId       = id(ismember(cat, 'cardinal'));
        extraXyz    = xyz(ismember(cat, 'extra'),:);
        extraId     = id(ismember(cat, 'extra'));
        xyz         = xyz(ismember(lower(cat), 'eeg'), :);
        id          = id(ismember(cat, 'eeg'));
        
    otherwise
        throw(InvalidFormat);    
end

if ~isempty(fidId),
    fiducials = mjava.hash;
    fiducials{fidId{:}} = mat2cell(fidXyz, ones(size(fidXyz,1),1), 3);
else
    fiducials = [];
end

if ~isempty(extraId),
    extra = mjava.hash;
    extra{extraId{:}} = mat2cell(extraXyz, ones(size(extraXyz,1),1), 3);
else
    extra = [];
end

obj = physioset.sensors.eeg(...
    'Cartesian', xyz, ...
    'OrigLabel', id, ...
    'Fiducials', fiducials, ...
    'Extra',     extra, ...
    varargin{:});


end