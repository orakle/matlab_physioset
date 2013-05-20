function didSelection = deal_with_bad_data(obj, policy)

if ~any(is_bad_channel(obj)) && ~any(is_bad_sample(obj)),
    didSelection = false;
    return;
end

didSelection = true;

if nargin < 2 || isempty(policy), policy = 'reject'; end

switch lower(policy)
    
    case 'reject',
        
        select(obj, ~is_bad_channel(obj), ~is_bad_sample(obj));
        
    case 'flatten',
        
        obj(is_bad_channel(obj), :) = 0;
        obj(:, is_bad_sample(obj))  = 0; %#ok<*NASGU>
        
    case 'donothing',
        % do nothing
        
    otherwise,
        
        error('Invalid policy ''%s''', policy);
        
end

end