function [K, ke, L, cl_poles, obs_poles] = full_system_design(A, B, C, ...
    desired_cl_poles, desired_obs_poles, include_integral)
% FULL_SYSTEM_DESIGN  Orchestrator for complete state-space control system design.
%
% Performs state feedback design, optional integral control, observer design,
% and verification in a single call.
%
% INPUTS:
%   A                  - system matrix (n x n)
%   B                  - input matrix (n x 1)
%   C                  - output matrix (1 x n)
%   desired_cl_poles   - desired closed-loop poles (n values, or n+1 for integral)
%   desired_obs_poles  - desired observer poles (n values)
%   include_integral   - (optional) true to add integral control (default: false)
%
% OUTPUTS:
%   K         - state feedback gain (1 x n)
%   ke        - integral gain (scalar, 0 if no integral control)
%   L         - observer gain (n x 1)
%   cl_poles  - actual closed-loop poles
%   obs_poles - actual observer poles

if nargin < 6
    include_integral = false;
end

n = size(A, 1);

% ----- Controllability check -----
[is_ctrl, ~, ~] = check_controllability(A, B);
if ~is_ctrl
    error('full_system_design: System is not controllable. Cannot design state feedback.');
end

% ----- Observability check -----
[is_obs, ~, ~] = check_observability(A, C);
if ~is_obs
    error('full_system_design: System is not observable. Cannot design observer.');
end

% ----- State feedback / integral control -----
ke = 0;
if include_integral
    [K, ke, cl_poles] = design_integral_ctrl(A, B, C, desired_cl_poles);
else
    [K, cl_poles] = design_state_feedback(A, B, desired_cl_poles);
end

% ----- Observer design -----
[L, obs_poles] = design_observer(A, C, desired_obs_poles);

% ----- Verification -----
if include_integral
    verify_solution(A, B, C, K, ke, L, desired_cl_poles, desired_obs_poles);
else
    verify_solution(A, B, C, K, [], L, desired_cl_poles, desired_obs_poles);
end

end
