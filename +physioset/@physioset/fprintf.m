function count = fprintf(fid, obj, varargin)
% FPRINTF - Print physioset information to Remark report
%
% count = fprintf(fid, obj);
% count = fprintf(fid, obj, 'key', value, ...)
%
% Where
%
% FID is a file handle or a io.safefid object
%
% OBJ is a physioset object
%
%
% ## Accepted key/value pairs:
%
%       ParseDisp : (boolean).
%           Default: get_method_config(obj, 'fprintf', 'ParseDisp')
%           If set to true, a summary of the physioset properties will be
%           printed. This will be done by simply parsing the output
%           produced by method disp() of the physioset class.
%
%       SaveBinary: (boolean).
%           Default: get_method_config(obj, 'fprintf', 'SaveBinary')
%           If set to true, a binary copy of the physioset will be saved
%           and a link to it will be printed to the Remark report
%
% See also: physioset

% Description: Print physioset information to report
% Documentation: class_physioset.txt

import misc.process_arguments;
import misc.fid2fname;
import mperl.file.spec.*;
import misc.code2multiline;
import pset.globals;

origVerbose = eegpipe.globals.get.Verbose;
eegpipe.globals.set('Verbose', false);

opt.ParseDisp   = get_method_config(obj, 'fprintf', 'ParseDisp');
opt.SaveBinary  = get_method_config(obj, 'fprintf', 'SaveBinary');

[~, opt] = process_arguments(opt, varargin);

count = 0;
if opt.ParseDisp,
    
    myTable = parse_disp(obj);
    
    count = count + fprintf(fid, myTable);
    
end

if opt.SaveBinary,
    
    fName = rel2abs(fid2fname(fid));
    [rPath fName] = fileparts(fName);
    
    % Save binary data
    dataName    = get_name(obj);
    
    newDataFile = catfile(rPath, fName);
    
    dataFileExt = globals.get.DataFileExt;
    hdrFileExt  = globals.get.HdrFileExt;
    
    if ~exist([newDataFile dataFileExt], 'file'),
        dataCopy = copy(obj, 'DataFile', newDataFile);
        save(dataCopy);
        clear dataCopy;
    end
    
    count = count + ...
        fprintf(fid, '\n%-20s: [%s][%s]\n\n', ...
        'Binary data file', ...
        [dataName dataFileExt], [dataName '-data']);
    
    count = count + ...
        fprintf(fid, '\n%-20s: [%s][%s]\n\n', ...
        'Binary header file', ...
        [dataName hdrFileExt], [dataName '-hdr']);
    
    count = count + ...
        fprintf(fid, '[%s]: %s\n', [dataName '-data'], ...
        [fName dataFileExt]);
    
    count = count + ...
        fprintf(fid, '[%s]: %s\n', [dataName '-hdr'], ...
        [fName hdrFileExt]);
    
    count = count + ...
        fprintf(fid, '\n\nTo load to MATLAB''s workspace:\n\n');
    
    count = count + fprintf(fid, '[[Code]]:\n');
    
    [path, name] = fileparts(newDataFile);
    newDataFile  = catfile(path, [name hdrFileExt]);
    
    code = sprintf('data = pset.load(''%s'')', newDataFile);
    code = code2multiline(code, [], char(9));
    count = count + fprintf(fid, '%s\n\n', code);
    
end

eegpipe.globals.set('Verbose', origVerbose);

end