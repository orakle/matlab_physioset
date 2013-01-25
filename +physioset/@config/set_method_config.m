function obj = set_method_config(obj, varargin)

import exceptions.*
import mperl.join;

if numel(varargin) == 1 && isa(varargin{1}, 'physioset.config'),
    obj = varargin{1};
    return;
elseif numel(varargin) == 1,
    throw(InvalidArgValue('varargin{1}', ...
        'Must be a config object'));
end

if numel(varargin) > 2 && ~iscell(varargin{2}),
    varargin{2} = varargin(2:end);
    varargin(3:end) = [];
end


i = 1;
while i < numel(varargin)
    
    method = varargin{i};
    cfg    = varargin{i+1};
    i      = i + 2;
    
    if isa(cfg, 'mjava.hash'),
        cfg = cell(cfg);
    end
    
    % Use a private function to check validity of method arguments
    obj.(method) = feval(method, obj.(method), cfg{:});
    
end

end