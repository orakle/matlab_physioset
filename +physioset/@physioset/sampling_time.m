function value = sampling_time(obj)

if isempty(obj.PntSelection),
    value = obj.SamplingTime;
else
    value = obj.SamplingTime(obj.PntSelection);
end


end