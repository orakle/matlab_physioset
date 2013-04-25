physioset class
================

Memory-mapped physiological dataset class


## Construction:

````
obj = physioset.physioset
obj = physioset.physioset('key', value, ...)
````

Where

`obj` is a physioset.physioset object


### Optional construction arguments

Optional construction arguments are provided at `('key', value)` 
tuples. The constructor of the physioset class admits all the 
construction arguments accepted by the constructor of the parent
class pset.pset. Additionally, the following `('key', value)` pairs
are also accepted:

__SamplingRate__ : _numeric_

   The data sampling rate. Must be an integer scalar. Defaults to
   `250`.

__Sensors__ : _sensors.sensors_

   Describes the physiological sensors. Defaults to an array of 
   `dummy` sensors.

__Event__ : _physioset.event.event_

   Event or markers that provide information on specific data
   samples or epochs.

__StartTime__ : _char_
   The start time of the recording in format HH:MM:SS. Defaults 
   to `datestr(now, 'HH:MM:SS')`

__StartDate__ : _char_
   Starting date of the recording in format dd-mmm-yyyy. Default 
   to `datestr(now, 'dd-mmm-yyyy')`


## Usage synopsis

The usage examples below assume the following import directives:

````matlab
import physioset.physioset physioset.import.matrix;
import pset.pset  pset.session;
import spt.pca.pca;
````

Import data from MATLAB matrix, the generated memory-mapped file 
will be stored under directory `D:\tmp`

````matlab
session.instance('D:/tmp');
myPhysioset = import(matrix, randn(4, 10000))
````

Create a new physioset object that will contain only the first 20
channels and the first 1000 samples of `myPhysioset`

````matlab
myPhysiosetSubset = subset(myPhysioset, 1:20, 1:1000);
````

Project data into its principal components:

````matlab
pcaObj = learn(pca, myPhysioset);
pcs = project(pcaObj, myPhysioset);
````

Convert `physioset` object to a plain `pset` object
````matlab
myPset = pset.pset(myPhysioset);
````

Convert `myPhysioset` to a Fieldtrip and EEGLAB structures:

````matlab
myFtripStr  = fieldtrip(myPhysioset);
myEEGLABStr = eeglab(myPhysioset);
````

Construct `physioset` object from Fieldtrip structure:
````matlab
myPhysioset2 = physioset.from_fieldtrip(myFtripStruct);

Low-pass filter a `physioset`:
````matlab
filtObj = filter.lpfilt('fc', 0.5)  A low pass filter
filter(filtObj, myPhysioset2);

Note that the filtering syntax above is completely equivalent to:
myPhysioset2 = filter(filtObj, myPhysioset2);
````

In both cases above, the data values contained in myPhysioset2 
_will be modified_. This is because class physioset is a handle class. 
See `help handle` for more information. If you want to pass a
`physioset` object by value, you need to explicitely create a copy of
the object:
````matlab
myPhysiosetCopy = copy(myPhysioset);
myPhysiosetCopy = filter(filtObj, myPhysioset);
````