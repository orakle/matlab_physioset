dimesimeter light measurements importer
================

Imports [Geneactiv][geneactiv]'s 3D accelerometry in .bin format.

[geneactiv]: http://www.geneactive.co.uk/
    
## Usage synopsis:
  
````matlab
import physioset.import.dimesimeter;

% Get a sample data file (a pair of txt files)
urlBase = 'http://kasku.org/data/meegpipe/';
urlwrite([urlBase 'pupw_0001_ambient-light_coat_ambulatory_header.txt'], ...
    'sample_header.txt');
urlwrite([urlBase 'pupw_0001_ambient-light_coat_ambulatory.txt'], ...
    'sample.txt');

% Create a data importer object
importer = dimesimeter('FileName', 'myOutputFile');

% Import the sample file
data = import(importer, 'sample_header.txt');
````
 
## Accepted (optional) construction arguments (as key/values):
  
All key/values accepted by [abstract_physioset_import][abs-phys-imp]
constructor.

[abs-phys-imp]: ../abstract_physioset_import.md


  
