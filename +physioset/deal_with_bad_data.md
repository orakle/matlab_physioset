deal_with_bad_data - Prepares physioset for conversion to other formats

Note: This is an internal function, not intended to be used directly, but 
through the various data conversion methods implemented by the 
[physioset][physioset-class] class.

[physioset-class]: ./@physioset/README.md


## Usage:

```matlab
[didSelection, evIdx] = deal_with_bad_data(obj, policy)
````

Where

`obj` is a `physioset` object.

`policy` is a string with the name of the policy that will be used for
dealing with the bad data prior to conversion to a third-party data
format (e.g. EEGLAB or Fieldtrip).


## Implemented policies

### `reject`

Bad data will not be exported to the third-party data format. This policy
might lead to temporal discontinuities in the exported data. A `boundary`
event will be added at the location of the discontinuity. The `Value`
property of such events will be set to the duration of the data epoch
that was rejected (in data samples).

### `flatten`

Bad data will be zeroed out. Events of type `boundary` will be added to
the exported dataset in order to mark the locations of the bad data
epochs. The `Value` property of such events will be set to the duration
of the (flattened) bad data epoch that follows the event.

### `donothing`

Export all data, but do add `boundary` events marking the onsets and
durations of the bad data epochs.


See also: physioset.eeglab, physioset.fieldtrip