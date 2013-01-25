function obj = clear_bad_sample(obj, idx)
% SET_BAD_SAMPLE - Marks one or more sample(s) as bad
%
%
% obj = clear_bad_sample(obj, idx)
%
% Where
%
% OBJ is a physioset.object
%
% IDX is the index or indices of the samples that are to be marked as good
%
%
% See also: clear_bad_channel, set_bad_sample, physioset

% Description: Unmarks bad samples
% Documentations: class_physioset.txt

import misc.isnatural;
import physioset.

if nargin < 2 || isempty(idx), idx = []; end

if ischar(idx),
    if strcmpi(idx, 'all'),
        idx = 1:obj.NbPoints;
    elseif strcmpi(idx, 'none'),
        idx = [];
    else
        physioset.InvalidSampleIndex(['Unknown channel index ''' ...
            idx(:)' '''']);
    end
end

if ~isempty(idx) && ~isnatural(idx),
    throw(physioset.InvalidSampleIndex('Sample index must be a natural number'));
end

if any(idx > obj.NbPoints),
    throw(physioset.InvalidSampleIndex(...
        sprintf('Sample index (%d) exceeds number of samples (%d)', ...
        find(idx>obj.NbPoints, 'first'), obj.NbPoints)));
end

if isempty(obj.PntSelection),
    obj.BadSample(idx) = false;
else
    obj.BadSample(obj.PntSelection(idx)) = false; 
end

end