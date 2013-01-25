% DEMO - Demonstrates functionality of class snapshots
%
% To run demo use the command:
%
% pset.plotter.snapshots.demo
%
%
% (c) German Gomez-Herrero <german.gomezherrero@kasku.org>
%
%
% See also: snapshots, make_test

import eegpipe.session;
import mperl.file.find.regexpdir;
import external.jan_simon.DataHash;
import mperl.file.spec.catdir;

if ~exist('VISIBLE', 'var') || isempty(VISIBLE), %#ok<*NODEF>
    VISIBLE = true;
end

if ~exist('INTERACTIVE', 'var') || isempty(INTERACTIVE),
    INTERACTIVE = VISIBLE;    
end

if INTERACTIVE,  VISIBLE = true; end

%% Create a temporary dir for the demo files
warning('off', 'session:NewSession');
PATH = catdir(session.instance.Folder, DataHash(randn(1,100)));
mkdir(PATH);
warning('on', 'session:NewSession');

if VISIBLE, echo on; close all; clc; end

%% Define the plotter configuration
% e.g. we want to plot snapshots of 10 and 30 seconds
import pset.plotter.snapshots.*;
myConfig = config('WinLength', [10, 30], 'Folder', PATH);

if INTERACTIVE, pause; clc; end


%% Build the plotter object
myPlotter = snapshots(myConfig); %#ok<*NASGU>

if INTERACTIVE, pause; clc; end

%% Or alternatively you could have done this:
myPlotter = snapshots('WinLength', 10, 'Folder', PATH);

if INTERACTIVE, pause; clc; end


%% Or this
myPlotter = snapshots; % Default constructor
myPlotter = set_config(myPlotter, 'WinLength', [10 30], 'Folder', PATH);

if INTERACTIVE, pause; clc; end

%% Indeed the configuration has been properly stored
if ~all(get_config(myPlotter, 'WinLength') == [10 30]), error('!'); end

if INTERACTIVE, pause; clc; end


%% Import some sample data and plot it
myData = import(physioset.import.matrix, randn(250, 10000));
plot(myPlotter, myData);

% See that the figures have been created in folder session.instance.Folder
% Press CTRL+C here if you want to inspect the figures. Otherwise, all
% files generated by this demo will be automatically deleted after you
% press any key.
if INTERACTIVE, pause; clc; end

%% Cleanup

clear myData myReport;
rmdir(PATH, 's');