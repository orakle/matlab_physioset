function obj = synchronize(varargin)
% synchronize - Synchronize and resample physioset objects
%
% ## Usage
%
% ````matlab
% obj = synchronize(obj1, obj2, ...)
% obj = synchronize(obj1, obj2, obj3, ..., 'policy')
% ````
%
% where `obj1`, `obj2`, ... are a set of `physioset` objects containing
% measurements that were simultaneously acquired but possibly at different
% sampling rates or in general at non-overlapping sampling instants.
%
% `policy` is a string identifying the synchronization policy. This
% argument is equivalent to the `synchronizemethod` argument taken by
% method [synchronize][matlab-sync] of MATLAB's built-in 
% [timeseries][timeseries] objects.
%
% [matlab-sync]: http://www.mathworks.nl/help/matlab/ref/timeseries.synchronize.html
% [timeseries]: http://www.mathworks.nl/help/matlab/ref/timeseriesclass.html
%
% `obj` is the result of synchronizing (possibly resampling) the set of
% input physiosets.
%
%
% ## Optional arguments
% 
% The following arguments can be optionally provided as key/value pairs:
% 
% ### `FileNaming`
% 
% __Class__: `char`
% 
% __Default__: `inherit`
% 
% The policy for determining the name of the disk file that will hold the 
% synchronized `physioset` values. 
% 
% ### `FileName`
% 
% __Class__: `char`
% 
% __Default__: `[]`
% 
% If provided and not empty, this file name will be used as the destination
% of the synchronized `physioset`. Note that this argument overrides argument
% `FileNaming`.
% 
% ### `InterpMethod`
% 
% __Class__: `char`
% 
% __Default__: `linear`
% 
% The interpolation method to use. See the documentation of MATLAB's 
% built-in [interp1][interp1] function for a list of supported interpolation 
% methods.
% 
% [interp1]: http://www.mathworks.nl/help/matlab/ref/interp1.html
% 
% ### `Verbose`
% 
% __Class__: `logical`
% 
% __Default__ : `true`
% 
% If set to false, the operation of `synchronize` will not produce any 
% status messages.

%
% 
% ## Examples
%
% ### Just resampling
%
% Synchronize two physiosets with common start times but different sampling
% rates:
%
% ````matlab
% import physioset.import.matrix;
% timeOrig = now;
% % Sampled at 10 Hz
% pObj1 = import(matrix(10, 'StartTime', timeOrig), randn(2,10));
% % Sampled at 100 Hz
% pObj2 = import(matrix(100, 'StartTime', timeOrig), randn(2,100));
% % Sampled at 1000 Hz
% pObj3 = import(matrix(1000, 'StartTime', timeOrig), randn(1,1000));
% % Synchronize them (i.e. upsample pObj1)
% pObj = synchronize(pObj3, pObj2, pObj1, 'union');
% ````
%
% ### Resampling and synchronizing
%
% Synchronize three physiosets with overlapping sampling times and
% different sampling rates:
%
% ````matlab
% import physioset.import.matrix;
% timeOrig1 = now;
% secsPerDay = 24*60*60;
% timeOrig2 = timeOrig1 - 10/secsPerDay;
% timeOrig3 = timeOrig1 + 10/secsPerDay; 
%
% % Sampled at 10 Hz
% pObj1 = import(matrix(10, 'StartTime', timeOrig1), randn(2,20*10));
% % Sampled at 100 Hz
% pObj2 = import(matrix(100, 'StartTime', timeOrig2), randn(2,25*100));
% % Sampled at 1000 Hz
% pObj3 = import(matrix(1000, 'StartTime', timeOrig3), randn(1,25*1000));
% % Add some dummy events for test purposes
% import physioset.event.event;
% ev = event(100, 'Type', 'firstEv'); 
% add_event(pObj1, ev);
% ev = event(110, 'Type', 'secondEv');
% add_event(pObj1, ev);
% ev = event(1000, 'Type', 'thirdEv');
% add_event(pObj3, ev);
% 
% % Synchronize them (i.e. upsample pObj1)
% pObj = synchronize(pObj3, pObj2, pObj1);
% ````
%
% See also: timeseries, synchronize

import misc.sizeof;
import pset.file_naming_policy;
import safefid.safefid;
import misc.split_arguments;
import misc.process_arguments;
import misc.eta;
import misc.unique_filename;
import physioset.physioset;

verboseLabel = '(physioset.synchronize) ';

pObjCount = 1;
while pObjCount < nargin && isa(varargin{pObjCount+1}, 'physioset.physioset'),
    pObjCount = pObjCount + 1;
end
pObjArray = varargin(1:pObjCount);

if nargin > pObjCount,
    syncMethod = varargin{pObjCount+1};
    varargin = varargin(pObjCount+2:end);
else
    syncMethod = 'Uniform';    
    varargin = {};
end

% Find out the max sampling rate
sr = max(cellfun(@(x) x.SamplingRate, pObjArray));
if strcmpi(syncMethod, 'uniform') && isempty(varargin),
    varargin = {'Interval', 1/sr};
end

[thisArgs, varargin] = split_arguments(...
    {'InterpMethod', 'FileNaming', 'FileName', 'Verbose'}, varargin);

opt.InterpMethod = 'linear';
opt.FileNaming   = 'inherit';
opt.FileName     = [];
opt.Verbose      = true;
[~, opt] = process_arguments(opt, thisArgs);

% Determine the names of the generated (imported) files
if isempty(opt.FileName),
    
    fileName    = get_datafile(pObjArray{1});
    newFileName = file_naming_policy(opt.FileNaming, fileName);
    dataFileExt = pset.globals.get.DataFileExt;
    newFileName = unique_filename([newFileName dataFileExt]);
  
else
    
    newFileName = opt.FileName;
    
end

% Get the sampling instants for the synchronized physioset
ts = cell(size(pObjArray));
for i = 1:numel(pObjArray)
   ts{i} = timeseries(pObjArray{i}(1,:), sampling_time(pObjArray{i}));   
   ts{i}.TimeInfo.Units = 'seconds';
   ts{i}.TimeInfo.StartDate = get_time_origin(pObjArray{i});
end

% The first physioset will be used as reference
tsSync = ts{1};
iterNum = 0;
while (iterNum <= numel(ts))
    tsSyncTime = tsSync.Time;
    for i = 2:numel(pObjArray),
        [tsSync, ts{i}] = synchronize(tsSync, ts{i}, syncMethod, varargin{:});
    end
    if numel(tsSyncTime) == numel(tsSync.Time) && ...
            all(tsSyncTime == tsSync.Time), 
       break;    
    end
    tsSyncTime = tsSync.Time; 
    iterNum = iterNum + 1;
end

% Convert tsSyncTime to absolute times
secsPerDay = 24*60*60;
tsSyncTime = tsSync.TimeInfo.StartDate+tsSyncTime/secsPerDay;

% Find out the dimensionality of the output physioset
dim = sum(cellfun(@(x) size(x,1), pObjArray));

% Chunk size in number of bytes
precision = pset.globals.get.Precision;
chunkSize = pset.globals.get.ChunkSize/(sizeof(precision)*dim);

% Interpolate chunk by chunk
count = 0;
tinit = tic;
fid = safefid(newFileName, 'w');
if opt.Verbose,
   fprintf([verboseLabel 'Writing synced data to %s ...'], newFileName); 
end
while (count < numel(tsSyncTime)),
    % Interpolate this chunk
    first = count+1;
    last  = min(numel(tsSyncTime), count+chunkSize-1);
    if last > numel(tsSyncTime)-1000,
        last = numel(tsSyncTime);
    end
    thisTime = tsSyncTime(first:last);
    thisData = nan(dim, numel(thisTime));
    dimCount = 1;
    for i = 1:numel(pObjArray)
        [~, pTime] = get_sampling_time(pObjArray{i});        
        for j = 1:size(pObjArray{i},1)
           % Interpolate jth dimension from ith physioset
           thisData(dimCount,:) = interp1(pTime, ...
               pObjArray{i}.PointSet(j,:), thisTime', opt.InterpMethod);   
           dimCount = dimCount + 1;
        end
    end
    fid.fwrite(thisData(:), precision);
    if opt.Verbose,
        eta(tinit, last, numel(tsSyncTime));
    end
    count = last;
end
clear fid;

if opt.Verbose,
    fprintf('\n\n');
end

%% Generate the physioset object

sensArray = cell(size(pObjArray));
for i = 1:numel(pObjArray),
   sensArray{i} = sensors(pObjArray{i}); 
end
sensorsMixed = sensors.mixed(sensArray{:});

samplingTime = (tsSyncTime - tsSyncTime(1))*secsPerDay;
obj = physioset(newFileName, nb_sensors(sensorsMixed), ...  
    'SamplingRate',     sr, ...
    'Sensors',          sensorsMixed, ...
    'StartTime',        tsSyncTime(1), ...
    'SamplingTime',     samplingTime);

% Add events
[~, firstTimeSync] = get_sampling_time(obj, 1);
[~, lastTimeSync] = get_sampling_time(obj, size(obj,2));
for i = 1:numel(pObjArray),
    evArray = get_event(pObjArray{i});
    for j = 1:numel(evArray),
       ev = evArray(j);
       % Find out if this event is within the synchronized range
       first = get_sample(ev)+get_offset(ev);
       last  = first+get_duration(ev)-1;
       [~, markerTime] = get_sampling_time(pObjArray{i}, first - ...
           get_offset(ev));
       [~, firstTime] = get_sampling_time(pObjArray{i}, first);
       [~, lastTime] = get_sampling_time(pObjArray{i}, last);
       if firstTime >= firstTimeSync && lastTime <= lastTimeSync,
          % Within range, so add it after modifying its timing properties
          beginSample = find(tsSyncTime >= firstTime, 1, 'first');
          markerSample = find(tsSyncTime >= markerTime, 1, 'first');
          endSample   = find(tsSyncTime <= lastTime, 1, 'last');
          ev.Sample = markerSample;
          ev.Duration = endSample-beginSample+1;
          ev.Offset = markerSample - beginSample;
          add_event(obj, ev);
       end
    end
end


end