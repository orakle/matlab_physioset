function [EEG,com] = eeglabel(EEG, regions, type)
% eeglabel() - labels portions of continuous data in an EEGLAB dataset
%
% Usage:
%   >> EEGOUT = eeglabel(EEGIN, regions, type)
%
% Inputs:
%   INEEG      - input dataset
%   regions    - array of regions to consider. number x [beg end]  of
%                regions. 'beg' and 'end' are expressed in term of points
%                in the input dataset. Size of the array is
%                number x 2 of regions.
%   type       - type of editing. Use type='add' to add events that cover
%                the marked regions. Use type='remove' to remove the events
%                with an onset within the marked region.
%
% Outputs:
%   INEEG      - output dataset with updated data, events latencies and
%                additional events.
%
% Author: German Gomez-Herrero <german.gomezherrero@tut.fi>
%         Institute of Signal Processing
%         Tampere University of Technology, 2008
%
% See also:
%   POP_EEGLABEL, EEGLAB
%

% Copyright (C) <2008>  <German Gomez-Herrero>
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

if nargin < 2,
    help eeglabel;
end
if isempty(regions),
    return;
end
if nargin < 3 || isempty(type),
    type = 'add';
end




% handle regions from eegplot and insert labels
% -------------------------------------
if size(regions,2) > 2,
    regions = regions(:,3:4);
end

switch lower(type),
    
    case 'add',
        % open a window to get the label value
        % --------------------------------------
        uigeom = {[1.5 1];[1.5 1];[1.5 1]};
        uilist = {{'style' 'text' 'string' 'Label for this EEG epoch(s):'} ...
            {'style' 'edit' 'string' ''} ...            
            {'style' 'text' 'string' 'Additional info:'} ...
            {'style' 'edit' 'string' ''} ...
            {'style' 'text' 'string' 'Ignore event durations (set=yes):'} ...
            {'style' 'checkbox' 'string' '' 'value' 0} ...
            };
        guititle = 'Choose a label - eeglabel()';
        result = inputgui( uigeom, uilist, 'pophelp(''eeglabel'')', guititle, [], 'normal');
        
        if isempty(result),
            com = '';
            return;
        end
        
        label = eval(['''' result{1} '''']);
        info = eval(['''' result{2} '''']);
        ignore_durations = result{3};
        new_event_template = struct('type', [], ...
            'latency', [], ...
            'duration', 1, ...
            'urevent', NaN, ...
            'position', NaN, ...
            'epoch', 1, ...
            'info',[]);        
     
        new_event = repmat(new_event_template, size(regions,1), 1);
        
        for i = 1:size(regions,1),
            new_event(i).type = label;
            new_event(i).latency = round(regions(i,1)-.5);
            if ~ignore_durations,
                new_event(i).duration = regions(i,2)-regions(i,1);               
            end
            new_event(i).info = info;
            new_event(i).epoch = ceil(new_event(i).latency/size(EEG.data,2));
        end
        
        EEG.event = new_event;
        
        % They must be consistent and this displays distracting status msgs
        % EEG = eeg_checkset(EEG,'eventconsistency');
        
    case 'remove',
        if isempty(EEG.event), return; end
        
        for i = 1:size(regions,1),
            first = round(regions(i,1)-.5);
            last = first+round(regions(i,2)-regions(i,1));
            remove_flag = false(1,length(EEG.event));
            for j = 1:length(EEG.event),
                if EEG.event(j).latency > first && EEG.event(j).latency < last,
                    remove_flag(j) = true;
                end
            end
            EEG.event(remove_flag) = [];
        end        
        
        
    otherwise
        error('eeglabel:unknownType', ...
            'Unknown operation type ''%s''', type);
        
        
end

com = sprintf('%s = eeglabel( %s, %s);', inputname(1), inputname(1), vararg2str({ regions }));
return;
