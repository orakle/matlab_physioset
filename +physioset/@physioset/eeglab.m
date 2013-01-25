function EEG = eeglab(obj, varargin)
% EEGLAB - Conversion to an EEGLAB structure
%
% eeg = eeglab(eegsetObj)
%
% eeg = eeglab(eegsetObj, 'key', value, ...)
%
% where
%
% EEGSETOBJ is an eegset object
%
% EEG is an EEGLAB data structure
%
% ## Accepted (optional) key/value options:
%
%   BadChannels : (string) Default: 'reject'
%       Determines what is to be done with the bad channels when exporting
%       to EEGLAB format. Other alternatives are: 'flatten' (make zero) and
%       'interpolate'. Note that 'interpolate' does not work yet.
%
%   BadSamples : (string) Default: 'reject'
%       Same as BadChannels but used to determine what is to be done with
%       the bad data samples. The 'interpolate' policy is not implemented
%       yet.
%
% ## Notes:
%
% * This function requires the EEGLAB toolbox:
%   http://sccn.ucsd.edu/eeglab/
%
% * Once a physioset has been exported to EEGLAB format, you can easily
%   load it into EEGLAB, by doing the following:
%
%   eeglab; % Start EEGLAB
%   [ALLEEG EEG] = eeg_store(ALLEEG, eeglabStr, CURRENTSET);
%
%   Where eeglabStr is the result of converting a physioset to EEGLAB
%   format.
%
% * For epoched datasets, any trial that contains at least one bad sample
%   will be rejected. This might be too harsh but allows a simplified
%   implementation.
%
%
% ## Examples:
%
% Example 1: Import to EEGLAB only the EEG channels
%
% data = pset.load('myfile.pseth');
% selector =  pset.selector.sensor_class('Class', 'EEG');
% select(selector, data);
% eeglabStr = eeglab(data);
% eeglab; % Start EEGLAB
% [ALLEEG EEG] = eeg_store(ALLEEG, eeglabStr, CURRENTSET);
%
% See also: fieldtrip

% Documentation: pset_eegset_class.txt
% Description: Conversion to an EEGLAB structure

import misc.check_dependency;
import misc.epoch_get;
import physioset.event.event;
import physioset.event.std.trial_begin;
import physioset.event.std.epoch_begin;
import misc.process_arguments;

check_dependency('eeglab');

opt.BadChannels = 'reject';
opt.BadSamples  = 'reject';
opt.EpochRejTh  = 25;
[~, opt] = process_arguments(opt, varargin);

% Do something about the bad channels/samples
didSelection = deal_with_bad_data(obj, opt.BadChannels);

% Convert data selection into events
selectionEv = epoch_begin(NaN, 'Type', '__DataSelection');
selectionEv = get_pnt_selection_events(obj, selectionEv);

% Reconstruct trials, if necessary. This complicates things...
hasEpochs = false;
    
evArray = get_event(obj);
    
if isempty(evArray),
    
    data = obj.PointSet(:,:);    
    
else    
   
    isTrialEv = evArray == trial_begin;
    trialEvs  = evArray(isTrialEv);
    
    if isempty(trialEvs),
        
        data = obj.PointSet(:,:);
        
    else
        
        hasEpochs = true;
        [data, trialEvsNew, ~, origPos] = epoch_get(obj, trialEvs);
     
        % Remove any non-complete trials
        epochEvs = selectionEv;
        
        if ~isempty(epochEvs),
            epochPos = get_sample(epochEvs);

            first = origPos;
            last  = first + size(data,2);
            
            isBad = false(1, numel(trialEvsNew));
            for i = 1:numel(trialEvsNew)

                isBad(i) = any(epochPos > first(i) & epochPos <=last(i));
                
            end
            
            trialEvsNew(isBad) = [];
            data(:,:,isBad) = [];
        end
        
        evArray(evArray == trial_begin) = [];
        evArray = [evArray;trialEvsNew];
        
        
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
end


end


function didSelection = deal_with_bad_data(obj, policy)

if ~any(is_bad_channel(obj)) && ~any(is_bad_sample(obj)),
    didSelection = false;
    return;
end

didSelection = true;

if nargin < 2 || isempty(policy), policy = 'reject'; end

switch lower(policy)
    
    case 'reject',
        
        select(obj, ~is_bad_channel(obj), ~is_bad_sample(obj));
        
    case 'flatten',
        
        obj.PointSet(is_bad_channel(obj), is_bad_sample(obj)) = 0;
        
    otherwise,
        
        error('Invalid policy ''%s''', policy);
        
end

end

