function pop_eeglabel(EEG, type, evGen)

import eeglab.eegplot;

if strcmpi(type, 'add'),
    button_label = 'ADD LABEL';
    command = ...
        [ 'str = get(gcbf, ''UserData'');' ...
        'EEG = physioset.event.utils.eeglabel(str.EEG,eegplot2event(TMPREJ,-1),''add'');' ...
        'evArray = physioset.event.event.from_eeglab(EEG.event);' ...
        'notify(str.event_generator, ''AddEventGui'', physioset.event.utils.event_info_AddEventGui(evArray));'];
    
elseif strcmpi(type, 'remove'),
    button_label = 'REMOVE EVENTS';
    command = ...
        [ 'str = get(gcbf, ''UserData'');' ...
        '[EEG delFlag] = physioset.event.utils.eeglabel(str.EEG,eegplot2event(TMPREJ,-1),''remove'');' ... 
        'notify(str.event_generator, ''DelEventGui'', physioset.event.utils.event_info_DelEventGui(delFlag));'];   
    
else
    error('pop_eeglabel:unknownType',...
        'Unknown operation type ''%s''', type);
end

% call eegplot with the appropriate options
eegplot( EEG.data, 'srate', EEG.srate, 'title', 'Scroll channel activities -- eegplot()', ...
			 'limits', [EEG.xmin EEG.xmax]*1000 , 'command', command, ...
             'butlabel', button_label,...
             'events', EEG.event); 
         
str = get(gcf, 'UserData');
str.EEG = EEG;
str.event_generator = evGen;
set(gcf, 'UserData', str);

end
