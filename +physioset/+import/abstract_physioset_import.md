abstract_physioset_import - Commonality among physioset_import classes

The abstract_physioset_import class is an abstract class designed for
inheritance. This means that instances of the class cannot be created
but instead the purpose of the class is to provide its children
classes with common properties and methods. The values of the
properties listed below can be set during construction of an object
of a child class using key/value pairs. For instance, the command:

importObj = physioset.import.eeglab('FileNaming', 'Temporary')

will create an object of class physioset.import.eeglab, which inherits
from class abstract_physioset_import. The property 'FileNaming' (which
is defined by the abstract_physioset_import class) will be set to
'Temporary'. 


## Optional construction arguments

The following optional arguments can be provided during construction
as key/value pairs.


### `Precision`

__Class__: `char`

__Default__: `pset.globals.get.Precision`

The numeric precision that should be used when importing data. 


### `Writable`

__Class__: `logical` 

__Default__: `pset.globals.get.Writable`

If set to `true` the generated object will be _writable_, in the
sense that the contents of its associated memory map can be modified
through its public API. For instance, if `obj` is a (non-empty)
writable `pset` then the following can be used to assign a value 0 to
the first point that it contains:

````matlab
obj(1) = 0;
````

### `Temporary`

__Class__: `logical`

__Default__: `pset.globals.get.Temporary`

If set to true, the associated memory map and header file will be
deleted once all references to the `pset` object have been cleared
from MATLAB's workspace.

### `FileNaming`

__Class__: `char`

__Default:__ `'inherit'`

Either `'Inherit'`, `'Random'`, or `'Session'`. See the documentation
of [pset.file_naming_policy][file-naming-policy] for more
information.


### `ReadEvents`

__Class__: `logical`

__Default:__ `true`

If set to true, the events information will also be imported. This
can slow down the data import considerably in some cases. Not all
data importers take into consideration the value of this property,
i.e. events may be imported even if `ReadEvents` is set to `false`.


See also: physioset.import.eegset_import
