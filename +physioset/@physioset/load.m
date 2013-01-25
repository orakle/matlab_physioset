function obj = load(filename)
% LOAD - Loads a physioset from a .mat file
%
%
% obj = load(filename)
%
% Where
%
% FILENAME is the full path to the .mat file. Note that filename may have a
% non-standard extension such as 'physioseth'. 
%
%
% See also: physioset. pset

% Documentation: class_physioset.txt
% Description: Loads physioset from a mat file

import mperl.file.spec.rel2abs;


filename = rel2abs(filename);

tmp = load(filename, '-mat');

obj = tmp.obj;
[path, name] = fileparts(filename);
[~, ~, extOld] = fileparts(obj.DataFile);
newDataFile = [path '/' name extOld];
if exist(newDataFile, 'file'),    
    fid = fopen(newDataFile);
    if fid > 0,
        fclose(fid);
        obj.PointSet = set_datafile(obj.PointSet, newDataFile);    
        obj.PointSet = set_hdrfile(obj.PointSet, filename);
    end
end