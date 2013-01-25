function physiosetObj = import(obj, fileNameIn, varargin)
% IMPORT - Imports Neuromag MEG files using Fieldtrip fileio module
%
% physiosetObj = import(obj, fileNameIn)
% physiosetObj = import(obj, 'key', value, ...)
%
% Where
%
% OBJ is an physioset.import.fileio object
%
% PHYSIOSETOBJ is a physioset.object
%
% IFILENAME is the name of the EDF+ file to be imported
%
%
% ## Most commonly used key/value pairs:
%
% 'FileName'    : (string) Default: session.instance.tempname
%                 Name of the generated file
%
% 'StartTime'   : (numeric scalar) Start time of the EEG epoch to read from
%                 the file, in seconds
%                 Default: [], i.e. read from the beginning
%
% 'EndTime'     : (numeric scalar) End time of the EEG epoch, in seconds
%                 Default: [], i.e. read until the end
%
% 'Channels'    : (natural) Indices of the channels to read
%                 Default: [], i.e. all channels
%
% 'Verbose'     : (logical) If set to false, no status messages will be
%                 displayed.
%                 Default: obj.Verbose
%
%
% ## Secondary key/value pairs:
%
% 'Value2Type'  : (mjava.hash) A hash defining a mapping from event
%                 values (i.e. trigger values) to event types. See notes
%                 below for an example.
%                 Default: [], i.e. identity mapping
%
% 'StartSample' : (natural scalar) First sample to read.
%                 Default: 1
%
% 'EndSample'   : (natural scalar) Last sample to read.
%                  Default: [], last recorded sample
%
% 'Folder'      : (string) If provided, all files in the specified folder
%                 will be imported, i.e. a cell array of physioset.
%                 objects will be returned.
%                 Default: []
%
% 'RegExp'      : (string) Regular expression that matches the files in the
%                 specified folder that the user wants to import. This key
%                 is relevant only if the Folder key is also provided.
%                 Default: '([^.]+)'
%
% 'Equalize'    : (logical) If set to true, the data from different
%                 modalities (EEG, MEG, Physiology) will be scaled in such
%                 a way that they have similar variances. This means for
%                 instance that MEG data in T, which has much smaller scale
%                 than EEG data in V, might result in MEG data to be
%                 transformed to a smaller scale (e.g. pT instead of T).
%                 Additionally, the modality with the highest variance will
%                 be scaled so that its variance is in the range of 100
%                 physical units. This means that EEG data originally
%                 expressed in V is very likely to be transformed to mV.
%                 Default: true
%
%
% Notes:
%
% * The epoch range has to be specified either in samples or in time but not
%   in both
%
% * If the optional argument folder is provided, then the FILENAMEIN
%   mandatory argument must be empty
%
% * The following Value2Type mapping:
%
%   val2typeMap = mjava.hash;
%   val2typeMap{1:3} = 'Cue';
%   val2typeMap{4:6} = 'Target';
%
%   will map trigger values 1, 2, 3 to an event of type Cue (and value
%   corresponding to the trigger value) and will map trigger values 4:6 to
%   an event of type 'Target' and value matching the corresponding trigger
%   value.
%
% See also: physioset.import.

% Deal with the multi-filename case
if iscell(fileNameIn),
    eegset_obj = cell(numel(fileNameIn), 1);
    for i = 1:numel(fileNameIn)
        eegset_obj{i} = import(obj, fileNameIn{i}, varargin{:});
    end
    return;
end

import physioset.import.neuromag;
import physioset.
import physioset.import.globals;
import pset.event;
import pset.file_naming_policy;
import misc.process_arguments;
import misc.sizeof;
import misc.regexpi_dir;
import misc.eta;
import misc.decompress;
import misc.trigger2code;

if nargin < 2,
    ME = MException('import:invalidInput', ...
        'At least two input arguments are expected');
    throw(ME);
end

% Add fieltrip to the pathname
pathAdded = false;
if isempty(strfind(path, obj.Fieldtrip))
    addpath(genpath(obj.Fieldtrip));
    pathAdded = true;
end

% Default values of optional input arguments
opt.filename     = [];
opt.starttime    = [];
opt.endtime      = [];
opt.startsample  = [];
opt.endsample    = [];
opt.channels     = [];
opt.dateformat   = globals.evaluate.DateFormat;
opt.timeformat   = globals.evaluate.TimeFormat;
opt.folder       = '';
opt.regexp       = '([^.]+)';
opt.verbose      = obj.Verbose;
opt.triggerchan  = 'STI101';
opt.megchan      = '(MEG)(\d+)';
opt.megchantrans = '$1 $2';
opt.eegchan      = '(EEG|EOG)(\d+)';
opt.eegchantrans = '$1 $2';
opt.gradunit     = '.+/m$';
opt.equalize     = obj.Equalize;
% Note that only ECG physiology channels are considered at this point
opt.physchan      = '(ECG)(\d+)';
opt.physchantrans = '$1 $2';

[~, opt] = process_arguments(opt, varargin);

if (~isempty(opt.starttime) || ~isempty(opt.endtime)) && ...
        (~isempty(opt.startsample) || ~isempty(opt.endsample)),
    ME = MException('import:invalidInput', ...
        ['Data range must be specified either in samples or in time ' ...
        '(seconds) but not in both']);
    throw(ME);
end

if ~isempty(fileNameIn) && ~isempty(opt.folder),
    ME = MException('import:invalidInput', ...
        ['The ''Folder'' optional argument is only accepted if the '...
        'IFILENAME mandatory input argument is empty']);
    throw(ME);
end

% Use recursion to process a opt.folder file by file
% =========================================================================
if isempty(fileNameIn) && isempty(opt.folder),
    physiosetObj = [];
    return;
elseif isempty(fileNameIn)
    file_list = opt.regexpi_dir(opt.folder, opt.regexp);
    physiosetObj = cell(numel(file_list), 1);
    for i = 1:numel(file_list)
        if opt.verbose,
            [~, this_name, this_ext] = fileparts(file_list{i});
            fprintf('\n(import) Importing ''%s''...', [this_name this_ext]);
        end
        % This feature has not been tested
        physiosetObj{i} = import(obj, file_list{i}, varargin{:}, ...
            'Verbose', false, ...
            'Folder', []);
        if opt.verbose,
            fprintf('[done]\n');
        end
    end
    return;
end

% The input file might be zipped
[status, fileNameIn] = decompress(fileNameIn, 'Verbose', opt.verbose);
isZipped = ~status;

% Determine the names of the generated (imported) files
if isempty(opt.filename),
    opt.filename = file_naming_policy(obj.FileNaming, fileNameIn);
end

opt.filename = strrep(opt.filename, obj.DataFileExt, '');
opt.filename = [opt.filename obj.DataFileExt];

% Read the header
% =========================================================================
if opt.verbose,
    fprintf('\n(import) Reading header...');
end
% Read header but capture the produced messages to avoid too much verbosity
[~, hdr] = evalc( ['ft_read_header(''' fileNameIn ''')'] );

if isempty(opt.channels),
    opt.channels = 1:hdr.nChans;
end
sr = hdr.Fs;
samplingTime = linspace(0, hdr.nSamples/sr, hdr.nSamples);
recStartDate = datestr(now, opt.dateformat);
recStartTime = datestr(now, opt.timeformat);
if opt.verbose,
    fprintf('[done]\n');
    pause(0.001); % To ensure that fprintf flushes the buffer
end

% Read the signal values
% =========================================================================
if opt.verbose,
    fprintf('\n(import) Writing data to binary file...');
end
tinit = tic;
chunkSize = floor(obj.ChunkSize/(sizeof(obj.Precision)*length(opt.channels))); % in samples
if hdr.nTrials > 1,
    % Chunk size must be an integer number of trials
    chunkSize = floor(chunkSize/(hdr.nSamples))*hdr.nSamples;
end
boundary = 1:chunkSize:(hdr.nSamples*hdr.nTrials);
if length(boundary)<2 || boundary(end) < hdr.nSamples*hdr.nTrials,
    boundary = [boundary,  hdr.nSamples*hdr.nTrials+1];
else
    boundary(end) = boundary(end)+1;
end
nbChunks = length(boundary) - 1;
fid = fopen(opt.filename, 'w');
if fid < 1,
    ME = MException('physioset.import.fileio:import', ...
        'I could not open file %s for writing', opt.filename);
    throw(ME);
end

% Trigger data/MEG data/EEG data/Physiology data
isEeg     = cellfun(@(x) ~isempty(x), regexpi(hdr.label(:), opt.eegchan));
isPhys    = cellfun(@(x) ~isempty(x), regexpi(hdr.label(:), opt.physchan));
isTrigger = cellfun(@(x) ~isempty(x), regexpi(hdr.label(:), opt.triggerchan));
isMeg     = cellfun(@(x) ~isempty(x), regexpi(hdr.label(:), opt.megchan));
isGrad    = cellfun(@(x) ~isempty(x), regexpi(hdr.unit(:), opt.gradunit));
isGrad    = isMeg & isGrad;
isMag     = isMeg & ~isGrad;

gradIdx = find(isGrad(:));
magIdx  = find(isMag(:));
megIdx  = [gradIdx;magIdx];
eegIdx  = find(isEeg(:));
physIdx = find(isPhys(:));

triggerData = nan(numel(find(isTrigger)), hdr.nSamples);

varEeg  = 0;
varPhys = 0;
varGrad = 0;
varMag  = 0;
for chunkItr = 1:nbChunks
    begSample = boundary(chunkItr);
    endSample = boundary(chunkItr+1)-1;
    [~, dat] = evalc( ...
        ['ft_read_data(fileNameIn, ' ...
        '''begsample'',        begSample, ' ...
        '''endsample'',        endSample, ' ...
        '''checkboundary'',    false, '...
        '''chanidx'',          opt.channels, '...
        '''header'',           hdr)']);
    if ndims(dat) > 2, %#ok<ISMAT>
        dat = reshape(dat, [size(dat,1), round(numel(dat)/size(dat,1))]);
    end
    % Keep track of the variance of each signal type for equalizing later
    if ~isempty(gradIdx),
        varGrad  = varGrad + median(var(dat(gradIdx,:),[],2));
    end
    if ~isempty(magIdx),
        varMag  = varMag + median(var(dat(magIdx,:),[],2));
    end
    if ~isempty(eegIdx),
        varEeg  = varEeg + median(var(dat(eegIdx,:),[],2));
    end
    if ~isempty(physIdx),
        varPhys  = varPhys + median(var(dat(physIdx,:),[],2));
    end
    % MEG, EEG and EOG is to be written but not trigger data
    triggerData(:, begSample:endSample) = dat(isTrigger,:);
    dat         = dat([gradIdx; magIdx; eegIdx; physIdx], :);
    
    % Write the chunk into the output binary file
    fwrite(fid, dat(:), obj.Precision);
    if opt.verbose,
        eta(tinit, nbChunks, chunkItr);
    end
end
n_dims = size(dat,1);

% Fix the order of the channels in the header
hdr.grad    = neuromag.grad_reorder(hdr.grad, megIdx);
hdr.grad    = neuromag.grad_change_unit(hdr.grad, 'cm');
hdr.label   = hdr.label([gradIdx; magIdx; eegIdx; physIdx]);
hdr.unit    = hdr.unit([gradIdx; magIdx; eegIdx; physIdx]);

% Fix the channel order in gradIdx, etc.
gradIdx = 1:numel(gradIdx);
magIdx  = numel(gradIdx)+1:numel(gradIdx)+numel(magIdx);
eegIdx  = numel(gradIdx)+numel(magIdx)+1:numel(gradIdx)+...
    numel(magIdx)+numel(eegIdx);
physIdx = numel(gradIdx)+numel(magIdx)+numel(eegIdx)+1:...
    numel(gradIdx)+numel(magIdx)+numel(eegIdx)+numel(physIdx);
if opt.verbose,
    fprintf('\n');
    pause(0.001);
end

% Close the output file
fclose(fid);

% Convert trigger data to events
% =========================================================================
if opt.verbose,
    fprintf('\n(import) Gathering events from trigger data...');
end
events = [];
for i = 1:size(triggerData,1),
    [sample, code] = trigger2code(triggerData);
    for j = 1:numel(code),
        thisValue = code(j);
        if ~isempty(obj.Trigger2Type),
            thisType  = obj.Trigger2Type(code(j));
        else
            thisType = [];
        end
        if isempty(thisType),
            thisType = code(j);
        end
        thisEvent = pset.event(sample(j), ...
            'Type', thisType, 'Value', thisValue);
        events = [events;thisEvent]; %#ok<AGROW>
    end
end
if opt.verbose,
    pause(0.0001);
    fprintf('[done]\n\n');
end

% Generate a sensors.mixed object with sensor information
% =========================================================================
if opt.verbose,
    fprintf('(import) Generating sensors descriptions...');
end
eegSensors  = [];
magSensors  = [];
gradSensors = [];
physSensors = [];
if any(isEeg),
    eegLabels = cellfun(@(x) regexprep(x, opt.eegchan, opt.eegchantrans), ...
        hdr.label(eegIdx), 'UniformOutput', false);
    eegSensors  = sensors.eeg(...
        'Label',     eegLabels, ...
        'OrigLabel', hdr.label(eegIdx), ...
        'PhysDim',   hdr.unit(eegIdx));
end

if any(isMag),
    magLabels = cellfun(@(x) regexprep(x, opt.megchan, opt.megchantrans), ...
        hdr.label(magIdx), 'UniformOutput', false);
    % Sensors for the magnetometers
    if isfield(hdr.grad, 'coilpos'),
        % Old Fieldtrip version
        magCoils    = sensors.coils(...
            'Cartesian',    hdr.grad.coilpos, ...
            'Orientation',  hdr.grad.coilori, ...
            'Weights',      hdr.grad.tra(magIdx, :));
        magSensors  = sensors.meg(...
            'Coils',        magCoils, ...
            'Cartesian',    hdr.grad.chanpos(magIdx,:), ...
            'Orientation',  hdr.grad.chanori(magIdx,:), ...
            'PhysDim',      hdr.unit(magIdx), ...
            'Label',        magLabels, ...
            'OrigLabel',    hdr.label(magIdx));
    elseif isfield(hdr.grad, 'pnt'),
        % Old Fieldtrip does not specify coils positions/orientations
        magCoils = sensors.coils('Weights', hdr.grad.tra(magIdx,:));
        magSensors  = sensors.meg(...
            'Coils',        magCoils, ...
            'Cartesian',    hdr.grad.pnt(magIdx,:), ...
            'Orientation',  hdr.grad.ori(magIdx,:), ...
            'PhysDim',      'T', ...
            'Label',        magLabels, ...
            'OrigLabel',    hdr.label(magIdx));
    else
        throw(neuromag.InvalidFieldtripStruct);
    end
end

if any(isGrad),
    gradLabels = cellfun(@(x) regexprep(x, opt.megchan, opt.megchantrans), ...
        hdr.label(gradIdx), 'UniformOutput', false);
    % Sensors for the gradiometers
    if isfield(hdr.grad, 'coilpos'),
        gradCoils    = sensors.coils(...
            'Cartesian',    hdr.grad.coilpos, ...
            'Orientation',  hdr.grad.coilori, ...
            'Weights',      hdr.grad.tra(gradIdx, :));
        gradSensors  = sensors.meg(...
            'Coils',        gradCoils, ...
            'Cartesian',    hdr.grad.chanpos(gradIdx,:), ...
            'Orientation',  hdr.grad.chanori(gradIdx,:), ...
            'PhysDim',      hdr.unit(gradIdx), ...
            'Label',        gradLabels, ...
            'OrigLabel',    hdr.label(gradIdx));
    elseif isfield(hdr.grad, 'pnt'),
        gradCoils = sensors.coils('Weights', hdr.grad.tra(gradIdx,:));
        gradSensors  = sensors.meg(...
            'Coils',        gradCoils, ...
            'Cartesian',    hdr.grad.pnt(gradIdx,:), ...
            'Orientation',  hdr.grad.ori(gradIdx,:), ...
            'PhysDim',      'T/m', ...
            'Label',        gradLabels, ...
            'OrigLabel',    hdr.label(gradIdx));
    else
        throw(neuromag.InvalidFieldtripStruct);
    end
    
end

if any(isPhys),
    physLabels = cellfun(@(x) regexprep(x, opt.physchan, opt.physchantrans), ...
        hdr.label(physIdx), 'UniformOutput', false);
    physSensors = sensors.physiology(...
        'Label',    physLabels, ...
        'PhysDim',  hdr.unit(physIdx));
end

sensorsMixed = sensors.mixed(gradSensors, magSensors, eegSensors, physSensors);

if opt.verbose,
    pause(0.0001);
    fprintf('[done]\n\n');
end

% Create a sensors.meg object
% =========================================================================
if opt.verbose,
    fprintf('(import) Generating a physioset object...');
end
% Generate the output physioset object
[~, name] = fileparts(opt.filename);
physiosetObj = physioset(opt.filename, n_dims, ...
    'Name',             name, ...
    'Precision',        obj.Precision, ...
    'Writable',         obj.Writable, ...
    'Temporary',        obj.Temporary, ...
    'SamplingRate',     sr, ...
    'StartDate',        recStartDate, ...
    'StartTime',        recStartTime, ...
    'Continuous',       true, ...
    'Event',            events, ...
    'Sensors',          sensorsMixed, ...
    'SamplingTime',     samplingTime, ...
    'Compact',          obj.Compact);

physiosetObj = set(physiosetObj, 'hdr', hdr);
if opt.verbose,
    fprintf('[done]\n\n');
end

if opt.equalize
    if opt.verbose,
        fprintf('(import) Equalizing...');
    end
    physiosetObj = equalize(physiosetObj, 'Verbose', opt.verbose);
    
end


if isZipped,
    delete(fileNameIn);
end

if pathAdded,
    rmpath(genpath(obj.Fieldtrip));
end

if opt.verbose,
    fprintf('\n\n');
end

end