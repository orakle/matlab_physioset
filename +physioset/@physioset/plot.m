function h = plot(data, varargin)

import misc.process_arguments;

opt.PlotEvents  = true;
opt.Interactive = true;
[~, opt] = process_arguments(opt, varargin);

if ~exist('eegplot', 'file'),
    error('EEGLAB is required for plotting physiosets');
end

if opt.PlotEvents,
    ev = get_event(data);
else
    ev = [];
end
sens = sensors(data);

if ~isempty(sens),
    sens = eeglab(sens);
end

warning('off', 'event:OutOfRange');
EEG = eeglab(data);
warning('on', 'event:OutOfRange');

if opt.Interactive,
    if nargin == 2
        EEG2 = eeglab(varargin{1});
        eegplot(EEG.data, 'events', EEG.event, 'eloc_file', sens, ...
            'srate', data.SamplingRate, 'data2', EEG2.data);
    else
        eegplot(EEG.data, 'events', EEG.event, 'eloc_file', sens, ...
            'srate', data.SamplingRate);
    end
    h = gcf;
else
    h  = plot(plotter.eegplot.eegplot.eegplot(varargin{:}), ...
        EEG.data, 'events', EEG.event, 'eloc_file', sens, ...
        'srate', data.SamplingRate);
end


% Remove annoying callbacks
set(gcf, ...
    'WindowButtonDownFcn',      [], ...
    'WindowButtonMotionFcn',    [], ...
    'WindowButtonUpFcn',        []);



end