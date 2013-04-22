function h = plot(data, varargin)

if ~exist('eegplot', 'file'),
    error('EEGLAB is required for plotting physiosets');
end

% Events
ev = get_event(data);
if ~isempty(ev), ev = eeglab(ev); end

% Sensors
sens = sensors(data);
if ~isempty(sens), sens = eeglab(sens); end

if nargin == 2   
    eegplot(data, 'events', ev, 'eloc_file', sens, ...
        'srate', data.SamplingRate, 'data2', varargin{1});
else
    eegplot(data, 'events', ev, 'eloc_file', sens, ...
        'srate', data.SamplingRate);
end
h = gcf;

% Remove annoying callbacks
set(gcf, ...
    'WindowButtonDownFcn',      [], ...
    'WindowButtonMotionFcn',    [], ...
    'WindowButtonUpFcn',        []);

end