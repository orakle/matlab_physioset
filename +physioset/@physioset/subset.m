function obj = subset(obj, varargin)
% SUBSET - Creates physioset object as a subset of another physioset object
%
% objNew = subset(obj, rowIdx, colIdx)
%
% Where
%
% OBJ is a physioset.object
%
% ROWIDX is a numeric array of channel indices
%
% COLIDX is a numeric array of sample indices
%
% OBJNEW is the newly created physioset object
%
%
% See also: physioset. pset

% Documentation: class_physioset.txt
% Description: Creates physioset from a subset of another physioset

import physioset.physioset;

if nargin == 2 && isa(varargin{1}, 'pset.selector.selector'),
    
    select(varargin{1}, obj);
    dimSel = obj.DimSelection;
    pntSel = obj.PntSelection;
    restore_selection(varargin{1});
    
elseif nargin > 2,
    
    dimSel = varargin{1};
    pntSel = varargin{2};
    
elseif nargin > 1,
    
    dimSel = varargin{1};
    pntSel = 1:nb_pnt(obj);
    
else
    
    dimSel = 1:nb_dim(obj);
    pntSel = 1:nb_pnt(obj);
    
end

%% Fix the SamplingTime, BadSample and Event properties

samplingTime = sampling_time(obj);
badSample    = is_bad_sample(obj, 1:nb_pnt(obj));
event        = get_event(obj);

if ~isempty(setdiff(1:nb_pnt(obj), pntSel)),
    
    % A subset of points
    samplingTime = samplingTime(pntSel);
    badSample    = badSample(pntSel);
    
    if ~isempty(event),
        evSel = pset.event.sample_selector(pntSel);
        event = select(evSel, event);
    end
    
end

%% Fix the BadChan and Sensors properties

badChan  = is_bad_channel(obj, 1:nb_dim(obj));
sensObj  = sensors(obj);

if ~isempty(setdiff(1:nb_dim(obj), dimSel)),    
    
    sensObj = subset(sensObj, dimSel);    
    badChan = badChan(dimSel);
    
end

%% Fix the equalization properties

% Takes care of selections already
[eqWeights, eqWeightsOrig, physDimPrefixOrig] = get_equalization(obj);

if ~isempty(eqWeights),
    eqWeights           = eqWeights(dimSel,:);
    eqWeightsOrig       = eqWeightsOrig(dimSel,:);
    physDimPrefixOrig   = physDimPrefixOrig(dimSel);
end

%% Create the low-level pointset
psetObj = subset(obj.PointSet, varargin{:});

args = construction_args(obj);

obj = physioset.from_pset(psetObj, args{:}, ...
    'Sensors',              sensObj, ...
    'Event',                event, ...
    'SamplingTime',         samplingTime, ...
    'EqWeights',            eqWeights, ...
    'EqWeightsOrig',        eqWeightsOrig, ...
    'PhysDimPrefixOrig',    physDimPrefixOrig, ...
    'BadChannel',           badChan, ...
    'BadSample',            badSample);


end