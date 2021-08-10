% Returns the maximum value and corresponding index from a list of values and indices.
% This is used in proc_dives_v2 to find the peak of each dive

function out = maxidx(iv)
    [vmax,aidx] = max(iv(:,2)); % find max value and array index
    out = [iv(aidx,1),vmax];    % return max value and corresponding input index
end
