dimesimeter light measurements importer
================

Imports [Geneactiv][geneactiv]'s 3D accelerometry in .bin format.

[geneactiv]: http://www.geneactive.co.uk/
    
## Usage synopsis:
  
````matlab
import physioset.import.dimesimeter;
importer = dimesimeter('FileName', 'myOutputFile');
data = import(importer, 'myFile.txt');
````
 
## Accepted (optional) construction arguments (as key/values):
  
All key/values accepted by [abstract_physioset_import][abs-phys-imp]
constructor.

[abs-phys-imp]: ../abstract_physioset_import.md


  
