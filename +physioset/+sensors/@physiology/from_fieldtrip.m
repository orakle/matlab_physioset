function obj = from_fieldtrip(hdr)

import sensors.*;

if isfield(hdr, 'grad'),
    obj = meg.from_fieldtrip(hdr);
elseif isfield(hdr, 'pnt'),
    obj = eeg.from_fieldtrip(hdr);
else
    obj = [];
end





end