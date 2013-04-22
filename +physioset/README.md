physioset API documentation
================

The MATLAB package [physioset][physioset-pkg] contains various data 
structures and supporting functions to handle high-dimensional 
physiological datasets. The main component of the `physioset` package API 
is the [physioset class][physioset-class]. Below you can find a list of 
all API components. The `@` symbol is used to denote classes, the `+` 
symbol is used to identify MATLAB packages. 

API component                  | What is it for? 
--------------                 | -------------------- 
[@physioset][physioset-class]  | Main data structure for high-dimensional physiological datasets
[+event][event-pkg]            | Handling events within physiosets
[+import][import-pkg]          | Importing data from disk files
[+plotter][plotter-pkg]        | Plotting physiological datasets

[physioset-pkg]: ./
[physioset-class]: ./%40physioset
[event-pkg]: ./%2Bevent
[import-pkg]: ./%2Bimport
[plotter-pkg]: ./%2Bplotter

Below you can find some usage examples of the API provided by the 
`physioset` package.

### Create physioset from MATLAB matrix

Physiosets are almost always created using a suitable _importer_, 
implemented by one of the classes contained in the [+import][import-pkg] 
package. To import data from a MATLAB matrix we need to use the 
[matrix][matrix-class] importer:

````matrix
% Create a random data matrix (10 data channels, 1000 samples)
X = randn(10, 1000);

% Create matrix importer object
myImporter = physioset.import.matrix;

% Use myImporter to import data matrix X
myData = import(myImporter, X);

% Display some information on the generated physioset
% This is equivalent to omitting the semicolon in the line above
disp(myData);

````

The last command above will generate an output similar to this:

````matlab

handle
Package: pset


                Name : 20130422T104001_ee223
               Event : []
             Sensors : 10 sensors.dummy; 
         SampingRate : 250 Hz
             Samples : 1000 (  4.0 seconds), 0 bad samples (0.0%)
            Channels : 10, 0 bad channels (0.0%)
           StartTime : 22-Apr-2013 10:40:01
        Equalization : no

Meta properties:

````

Note that method `import()` of the `matrix` importer made quite a few 
assumptions such as the sampling rate of your data (250 Hz) and the type
of sensors that were used to acquire the data (some `dummy` sensors, 
meaning that the sensor class is unknown, or not applicable). 







[matrix]: ./%2Bimport/%40matrix


