function [K, cl_poles] = design_state_feedback(A, B, desired_poles)
% DESIGN_STATE_FEEDBACK  Design state feedback gain K via pole placement.
%
% INPUTS:
%   A             - system matrix (n x n)
%   B             - input matrix (n x 1)
%   desired_poles - row or column vector of desired closed-loop poles
%
% OUTPUTS:
%   K        - state feedback gain vector (1 x n)
%   cl_poles - actual closed-loop poles (eigenvalues of A - B*K)
%
% Uses MATLAB place() for pole placement and validates result.

desired_poles = desired_poles(:).';  % ensure row vector

% Use place() for pole placement (or acker() for SISO with possible repeated poles)
try
    K = place(A, B, desired_poles);
catch
    % Fall back to Ackermann's formula if place() fails (e.g., repeated poles)
    K = acker(A, B, desired_poles);
end

cl_poles = eig(A - B * K);

end
