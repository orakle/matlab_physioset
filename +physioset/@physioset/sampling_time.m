function [value, absTime] = sampling_time(obj)

if isempty(obj.PntSelection),
    value = obj.SamplingTime;
else
    value = obj.SamplingTime(obj.PntSelection);
end

if nargout > 1,
    absTime = arrayfun(@(x) ...
        addtodate(get_time_origin(obj), x, 'millisecond'), round(value*1000));
end


end