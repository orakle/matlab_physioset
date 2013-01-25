function cfg = get_config(varargin)
% GET_CONFIG - Get user configuration options for package physioset

import mperl.config.inifiles.inifile;
import physioset.root_path;
import mperl.file.spec.catfile;

sysIni  = catfile(root_path, 'physioset.ini');
userIni = 'physioset.ini';

if exist(userIni, 'file'),
    cfg = inifile(which('physioset.ini'));
elseif exist(sysIni, 'file')    
    cfg = inifile(sysIni);
else
    error('No configuration file!');
end

if nargin < 1,
    return;
end

cfg = val(cfg, varargin{:});


end