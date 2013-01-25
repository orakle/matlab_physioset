function obj = concatenate(varargin)
% CONCATENATE - Concatenates physiosets
%
% obj = concatenate(obj1, obj2, ...)
%
% Where
%
% OBJ1, OBJ2, ... are the physioset objects that have to be concatenated.
%
% OBJ is the physioset object that results from concatenating the input
% physiosets.
%
%
% See also: physioset, pset

% Documentation: class_pset_physioset.txt
% Description: Concatenates physiosets

import pset.physioset;
import pset.globals;
import misc.process_arguments;

% Distinguish optional key/value pairs from the objects that are 
% to be concatenated
optionalArguments = {};
if nargin > 1,
    isData = cellfun(@(x) isa(x, 'pset.physioset'), varargin);
    idx = find(~isData(:), 1, 'first');
    if isempty(idx),
        optionalArguments = [];
    else
        optionalArguments = varargin(idx:end);
        varargin = varargin(1:idx-1);
    end
end

opt.nameregex = [];

[~, opt] = process_arguments(opt, optionalArguments);

if nargin < 1,
    obj = [];
    return;
end

fileBeginEventType   = globals.evaluate.FileBeginEvent;

% We will use the equalization weights from the first dataset
eqWeights       = varargin{1}.EqWeights;
eqWeightsOrig   = varargin{1}.EqWeightsOrig;

psets   = cell(numel(varargin),1);
sr      = varargin{1}.SamplingRate;
count   = 0;
events  = varargin{1}.Event(:);

for i = 1:numel(varargin)
    if varargin{i}.SamplingRate ~= sr,
        throw(physioset.IncompatiblePhysiosets(...
            'Cannot concatenate datasets with different sampling rates'))
    end
    psets{i} = varargin{i}.PointSet;
    
    % Fix the timings of the events    
    sample = cell2mat(get(varargin{i}.Event, 'Sample'));
    newSample = count+sample;
    newEvents = set(varargin{i}.Event, 'Sample', newSample);   
    
    % Add an event that makes clear where this data came from
    fileEvent = pset.event(count+1, ...
        'Type',     fileBeginEventType, ...
        'Duration', varargin{i}.NbPoints);
    newEvents = [newEvents(:);fileEvent];   
    
    % Translate file name into various tags: subject, block, etc...
    if ~isempty(opt.nameregex),
        [~, name] = fileparts(varargin{i}.DataFile);
        res = regexpi(name, opt.nameregex, 'names');
        if ~isempty(res),
            fnames = fieldnames(res);
            for fieldItr = 1:numel(fnames)
                thisField = fnames{fieldItr};
                newEvents = set(newEvents, thisField, res.(thisField));
            end
        end
    end       
    
    events = [events;newEvents(:)];  %#ok<*AGROW>
    
    count = count + varargin{i}.NbPoints;
end

% Fix the equalizations
for i = 2:numel(psets),
   psets{i} = eqWeightsOrig*pinv(varargin{i}.EqWeightsOrig)*psets{i}; 
end

concatenatedPset = concatenate(psets{:});

temporary = concatenatedPset.Temporary;
concatenatedPset.Temporary =  false;

datafile    = concatenatedPset.DataFile;
nbDims      = concatenatedPset.NbDims;
precision   = concatenatedPset.Precision;
writable    = concatenatedPset.Writable;
compact     = concatenatedPset.Compact;

clear concatenatedPset; % to destroy the memory map but not the file

% Generate the output physioset object
obj = physioset(datafile, ...
     nbDims, ...
    'EqWeights',        eqWeights, ...
    'EqWeightsOrig',     eqWeightsOrig, ...
    'Precision',        precision, ...
    'Writable',         writable, ...
    'Temporary',        temporary, ...
    'SamplingRate',     sr, ...   
    'Continuous',       true, ...
    'Event',            events, ...
    'Sensors',          varargin{1}.Sensors, ...
    'Compact',          compact);



end