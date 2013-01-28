function h = plot(data, varargin)

import misc.process_arguments;
import misc.epoch_get;

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

if ~isempty(ev),
    
    [ev, epochDur, trialBeginEv] = eeglab(ev);
    
    if isnan(epochDur),
        X = data.PointSet(:,:);
    else
        X = epoch_get(data, trialBeginEv);
    end
  
    if opt.Interactive,
        eegplot(X, 'events', ev, 'eloc_file', sens, ...
            'srate', data.SamplingRate);
        h = gcf;
    else
        h  = plot(plotter.eegplot.eegplot.eegplot(varargin{:}), ...
            data.PointSet(:,:), 'events', ev, 'eloc_file', sens, ...
            'srate', data.SamplingRate);
    end
    
else
    
    if opt.Interactive,
        eegplot(data.PointSet(:,:), 'eloc_file', sens, ...
            'srate', data.SamplingRate);
        h = gcf;
    else
        h  = plot(plotter.eegplot.eegplot(varargin{:}), ...
            data.PointSet(:,:), 'eloc_file', sens, ...
            'srate', data.SamplingRate);
    end
    
end

% Remove annoying callbacks
set(gcf, ...
    'WindowButtonDownFcn',      [], ...
    'WindowButtonMotionFcn',    [], ...
    'WindowButtonUpFcn',        []);



end