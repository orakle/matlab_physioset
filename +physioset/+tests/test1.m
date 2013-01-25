function [status, MEh] = test1()
% TEST1 - Tests demo functionality

import test.simple.*;
import mperl.file.spec.*;
import physioset.*;
import pset.session;
import safefid.safefid;
import datahash.DataHash;

MEh     = [];

initialize(7);

%% Default constructor
try
    
    name = 'default constructor';
    physioset;
    ok(true, name);
    
catch ME
    
    ok(ME, name);
    MEh = [MEh ME];
    
end

%% Build a method configuration object
try
    
    name = 'method configuration';
    cfg = config('fprintf', {'ParseDisp', true, 'SaveBinary', true});
    ok(all(cell2mat(cfg.fprintf({'ParseDisp', 'SaveBinary'}))), name);
    
catch ME
    
    ok(ME, name);
    MEh = [MEh ME];
    
end

%% Alternative construction of a configuration object
try
    
    name = 'alternative config object construction';
    options = mjava.hash;
    options{'ParseDisp', 'SaveBinary'} = {false, false};
    cfg = config('fprintf', options);
    ok( ~any(cell2mat(cfg.fprintf({'ParseDisp', 'SaveBinary'}))), name);
    
catch ME
    
    ok(ME, name);
    MEh = [MEh ME];
    
end


%% Yet another config construction alternative
try
    
    name = 'another alternative for config object construction';
    cfg = config;
    cfg = set_method_config(cfg, 'fprintf', {'ParseDisp', false});
    parseDisp = get_method_config(cfg, 'fprintf', {'ParseDisp'});
    ok(~parseDisp, name);
    
catch ME
    
    ok(ME, name);
    MEh = [MEh ME];
    
end

%% Construct a dummy physioset and modify its method config
try
    
    name = 'modify method config of physioset';
    warning('off', 'session:NewSession');
    myPset = import(physioset.import.matrix, randn(10,10000));
    warning('on', 'session:NewSession');
    set_method_config(myPset, cfg);
    set_method_config(myPset, 'fprintf', {'ParseDisp', true});
    parseDisp = get_method_config(cfg, 'fprintf', {'ParseDisp'});
    ok(parseDisp, name);
    
catch ME
    
    ok(ME, name);
    MEh = [MEh ME];
    
end

%% Get all configs as a hash object 
try
    
    name = 'get all config options as hash';
    myHash = get_method_config(myPset, 'fprintf');
    ok(myHash('ParseDisp'), name);
    
catch ME
    
    ok(ME, name);
    MEh = [MEh ME];
    
end

%% Get all configs as a config object 
try
    
    name = 'get all config options as object';
    get_method_config(myPset);
    ok(true, name);
    
catch ME
    
    ok(ME, name);
    MEh = [MEh ME];
    
end


clear myPset;

%% Testing summary
status = finalize();

end