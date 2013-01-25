function hashObj = fprintf(hashObj, varargin)
% FPRINTF - Check configuration options for method fprintf
%
% See also: pset.physioset

% Documentation: class_physioset_impl.txt
% Description: Check configuration options for method fprintf

import eegpipe.exceptions.*;

i = 1;
while i < numel(varargin)
    key   = varargin{i};
    value = varargin{i+1};
    i = i + 2;
    switch key        
        
        case {'ParseDisp', 'SaveBinary'}
            % boolean values
            if numel(value) == 1 && islogical(value),
                hashObj(key) = value;
            else
                throw(InvalidPropValue(key, ...
                    'Must be a logical scalar'));
            end    
        
        otherwise
            error('Unknown configuration option ''%s''', varargin{i});
            
    end
    
end


end