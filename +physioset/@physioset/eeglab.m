function EEG = eeglab(obj, varargin)
% eeglab - Conversion to an EEGLAB structure
% =======
%
% ## Usage
%
%````matlab
% EEG = eeglab(pObj)
% EEG = eeglab(eegsetObj, 'key', value, ...)
%````
%
% where
%
% `pObj` is a `physioset` object
%
% `EEG` is the exported EEGLAB data structure
%
%
% ## Accepted (optional) key/value options:
% 
% ### BadDataPolicy
%
% __Default:__ `'reject'`
% __Class:__    `char`
%
% Determines what is to be done with the bad data when exporting to EEGLAB
% format. See the documentation of 
% [physioset.deal_with_bad_data][deal_with_bad_data] for information
% regarding valid bad data policies.
% 
% [deal_wit_bad_data]: ../deal_with_bad_data.md
%
%
% ## Notes:
%
% * This method requires the EEGLAB toolbox:
%   http://sccn.ucsd.edu/eeglab/
%
% * Once a physioset has been exported to EEGLAB format, you can easily
%   load it into EEGLAB, by doing the following:
%
% ````matlab
%   eeglab; % Start EEGLAB
%   [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
% ````
%
%   Where `EEG` is the result of converting a physioset to EEGLAB
%   format.
%
% * For epoched datasets, any trial that contains one or more bad samples
%   will be rejected. This might be too harsh but allows a simplified
%   implementation.
%
%
% ## Examples:
%
% ### Export only the EEG channels
%
% ````matlab
% data = pset.load('myfile.pseth');
% selector =  pset.selector.sensor_class('Class', 'EEG');
% select(selector, data);
% eeglabStr = eeglab(data);
% eeglab; % Start EEGLAB
% [ALLEEG EEG] = eeg_store(ALLEEG, eeglabStr, CURRENTSET);
% eeglab redraw;
% ````
%
% See also: fieldtrip

import misc.check_dependency;
import physioset.event.event;
import physioset.event.std.trial_begin;
import physioset.event.std.epoch_begin;
import physioset.deal_with_bad_data;
import misc.process_arguments;

check_dependency('eeglab');

opt.BadDataPolicy = 'reject';
opt.EpochRejTh    = 25;
[~, opt] = process_arguments(opt, varargin);

% Do something about the bad channels/samples
[didSelection, evIdx] = deal_with_bad_data(obj, opt.BadDataPolicy);

% Convert data selection into events
%selectionEv = epoch_begin(NaN, 'Type', '__DataSelection');
%selectionEv = get_pnt_selection_events(obj, selectionEv);
%add_event(obj, selectionEv);

% Reconstruct trials, if necessary. This complicates things...
evArray = get_event(obj);
    
if isempty(evArray),
    
    data = obj.PointSet(:,:);    
    
else    
   
    isTrialEv = evArray == trial_begin;
    trialEvs  = evArray(isTrialEv);
    
    if isempty(trialEvs),
        
        data = obj.PointSet(:,:);
        
    else
      
        [data, evArray] = epoch_get(obj, trialEvs);
       
    end
    
end

savedStr = get_meta(obj, 'eeglab');
if ~isempty(savedStr),
    tmp = savedStr;
else
    tmp        = eeg_emptyset;
    tmp.datfile= '';
    tmp.nbchan = size(obj,1);
    tmp.srate  = obj.SamplingRate;
    tmp.xmin   = 0;
    
    dataFile        = get_datafile(obj);
    [~, f_name]     = fileparts(dataFile);
    tmp.setname     = sprintf('%s file', f_name);
    tmp.comments    = [ 'Original file: ' dataFile ];
    tmp.pnts        = size(data, 2);
    tmp.trials      = size(data, 3);
    
    % Sensor information
    sArray = sensors(obj);
    if ~isempty(sArray),
        tmp.chanlocs = eeglab(sArray);
    end

    if ~isempty(evArray),
        tmp.event = eeglab(evArray);
    end
    
end

tmp.data   = data;

evalc('tmp = eeg_checkset(tmp, ''eventconsistency'')');
evalc('tmp = eeg_checkset(tmp, ''makeur'')');   % Make EEG.urevent field
evalc('tmp = eeg_checkset(tmp)');

EEG = tmp;  

% Undo temporary selections
if didSelection,
    restore_selection(obj);
    delete_event(obj, evIdx);
end


end






