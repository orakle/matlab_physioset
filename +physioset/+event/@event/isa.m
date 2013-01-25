function bool = isa(obj, varargin)


bool = builtin('isa', obj, varargin{:});

if ~bool,
    bool = builtin('isa', obj, ['pset.event.std.' varargin{1}]);
end



end