function value = get_method_config(obj, varargin)

if isempty(varargin),
    value = obj;
    return;
end

if numel(varargin) == 1,
    value = obj.(varargin{1});
    return;
end

value = cell(1, numel(varargin)/2);

i = 1;
while i < numel(varargin)
    value{i} = obj.(varargin{i})(varargin{i+1});
    i = i + 2;
end

if numel(value) == 1,
    value = value{1};
end

end
