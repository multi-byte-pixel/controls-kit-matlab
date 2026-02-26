function [L, obs_poles] = design_observer(A, C, desired_obs_poles)
% DESIGN_OBSERVER  Design observer gain L via pole placement.
%
% INPUTS:
%   A                - system matrix (n x n)
%   C                - output matrix (p x n)
%   desired_obs_poles - desired observer poles (row or column vector)
%
% OUTPUTS:
%   L         - observer gain matrix (n x p)
%   obs_poles - actual observer poles (eigenvalues of A - L*C)
%
% Uses the transpose trick: L = place(A', C', obs_poles)'

desired_obs_poles = desired_obs_poles(:).';  % ensure row vector

% Observer gain via transpose trick
try
    L = place(A', C', desired_obs_poles)';
catch
    L = acker(A', C', desired_obs_poles)';
end

obs_poles = eig(A - L * C);

end
