function obj = clear_bad_channel(obj, index)
% CLEAR_BAD_CHANNEL - Removes a bad channel marking
%
% obj = clear_bad_channel(obj, idx)
%
% Where
%
% OBJ is a pset.physioset object
%
% IDX is the index or indices of the channel(s) whose bad channel mark has
% to be removed
%
% 
% See also: set_bad_channel, clear_bad_sample, physioset

% Documentation: class_pset_physioset.txt
% Description: Removes a bad channel marking

import misc.isnatural;
import eegpipe.exceptions.*;
import misc.str2multiline;

if nargin < 2 || isempty(index), index = []; end

if ischar(index),
    if strcmpi(index, 'all'),
        index = 1:obj.NbDims;
    elseif strcmpi(index, 'none'),
        index = [];
    else
        reshape(index, 1, numel(index));
        msg = sprintf('Unknown channel index ''%s''', index);
        throw(InvalidArgValue('index', msg));
    end
end

if ~isempty(index) && ~isnatural(index),
    throw(physioset.InvalidChannelIndex('Must be a natural number'));
end

if any(index > obj.NbDims),
    throw(physioset.InvalidChannelIndex(...
        sprintf('Channel index (%d) exceeds number of channels (%d)', ...
        find(index>obj.NbDims, 'first'), obj.NbDims)));
end

if isempty(obj.DimSelection),
    obj.BadChan(index) = false;
else
    obj.BadChan(obj.DimSelection(index)) = false;
end


end