physioset data importers
================

The MATLAB package [physioset.import][physioset-import-pkg] contains data
importer classes. These classes can be used to generate 
[physioset][physioset] objects based on the values contained in disk files
of various formats. 

[physioset-import-pkg]: ./
[physioset]: ../@physioset/README.md

Data importer classes are organized in the following class hierarchy:


CLASS DIAGRAM HERE


## Available data importers

A list of currently available data importers can be found below. However, 
this list might be outdated. In general, any class contained within the 
[physioset.import][physioset-import-pkg] package is a data importer class.
Thus, you can get the most up-to-date list of available importers by 
inspecting the [package contents][physioset-import-pkg].

Data Importer (class name)       | Data format 
--------------                   | -------------------- 
[@daisymeter][daisymeter-class]  | Dimesimeter light measurements (`.txt`)
[@edfplus][edfplus-class]        | Time-series in [EDF+ format][edfplus] (`.edf`)
[@eeglab][eeglab-class]          | [EEGLAB][eeglab]'s `.set` files
[@fieldtrip][fieldtrip-class]    | [Fieldtrip][fieldtrip]'s data structure in `.mat` format
[@fileio][fileio-class]          | A wrapper to Fieldtrip's [fileio][fileio] module
[@geneactiv_bin][geneactiv-class]| [Geneactiv][geneactiv]'s `.bin` accelerometry data format
[@matrix][matrix-class]          | MATLAB matrix in MATLAB's workspace
[@mff][mff-class]                | [EGI][egi]'s `.mff` data format for high-density EEG
[@neuromag][neuromag-class]      | [Neuromag][neuromag]'s `.fif` format for MEG
[@physioset][physioset-class]    | [meegpipe][meegpipe]'s physiological dataset format `.pset`/`.pseth`

[daisymeter-class]: ./@dimesimeter
[edfplus-class]: ./@edfplus
[edfplus]: http://www.edfplus.info/
[eeglab-class]: ./@eeglab
[eeglab]: http://sccn.ucsd.edu/eeglab/
[fieldtrip-class]: ./@fieldtrip
[fieldtrip]: http://fieldtrip.fcdonders.nl/ 
[fileio]: http://fieldtrip.fcdonders.nl/development/fileio
[geneactiv-class]: ./@geneactiv_bin
[geneactiv]: http://www.geneactive.co.uk/
[matrix-class]: ./@matrix
[class-mff]: ./@mff
[egi]: http://www.egi.com/
[neuromag-class]: http://www.elekta.com/healthcare-professionals/products/elekta-neuroscience/functional-mapping.html
[physioset-class]: ./@physioset
[meegpipe]: http://www.germangh.com/meegpipe/




