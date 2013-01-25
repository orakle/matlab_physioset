function obj = set_bad_sample(obj, idx)
% SET_BAD_SAMPLE - Marks one or more sample(s) as bad
%
%
% obj = set_bad_sample(obj, idx)
%
% Where
%
% OBJ is a pset.physioset object
%
% IDX is the index or indices of the samples that are to be marked as bad
%
%
% See also: clear_bad_sample, set_bad_channel, physioset

% Description: Marks bad samples
% Documentations: class_pset_physioset.txt

import misc.isnatural;
import eegpipe.exceptions.*;

if nargin < 2 || isempty(idx), idx = []; end

if islogical(idx), idx = find(idx); end

if ~isempty(idx) && ~isnatural(idx),
    throw(InvalidArgValue('idx', 'Sample index must be a natural number'));
end

if any(idx > obj.NbPoints),
    throw(InvalidArgValue('idx', ...
        sprintf('Sample index (%d) exceeds number of samples (%d)', ...
        idx(find(idx(:) > nb_pnt(obj), 1, 'first')), nb_pnt(obj))));
end

if isempty(obj.PntSelection), 
     obj.BadSample(idx) = true;
else
    obj.BadSample(obj.PntSelection(idx)) = true;   
end

end