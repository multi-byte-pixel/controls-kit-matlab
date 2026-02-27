function result = verify_solution(A, B, C, K, ke, L, expected_cl_poles, expected_obs_poles)
% VERIFY_SOLUTION  Comprehensive verification of a control system design.
%
%   result = verify_solution(A, B, C, K, ke, L, expected_cl_poles, expected_obs_poles)
%
%   Checks that the designed controller gains (K, ke) and observer gain (L)
%   produce the expected closed-loop and observer poles. Returns a struct
%   with pass/fail flags and detailed comparison data.
%
%   This function is the final validation step: after designing K, ke, L
%   with design_state_feedback, design_integral_ctrl, and design_observer,
%   use verify_solution to confirm everything matches.
%
%   INPUTS:
%     A                  — n-by-n system matrix
%     B                  — n-by-1 input vector
%     C                  — 1-by-n output vector
%     K                  — 1-by-n state-feedback gain (or [] to skip)
%     ke                 — scalar integral gain (or [] to skip integral check)
%     L                  — n-by-1 observer gain (or [] to skip observer check)
%     expected_cl_poles  — expected closed-loop poles (or [] to skip)
%     expected_obs_poles — expected observer poles (or [] to skip)
%
%   OUTPUT:
%     result — struct with fields:
%       .cl_pass        — true if CL poles match expected (within tolerance)
%       .obs_pass       — true if observer poles match expected
%       .actual_cl      — actual closed-loop poles
%       .actual_obs     — actual observer poles
%       .cl_error       — max absolute error in CL poles
%       .obs_error      — max absolute error in observer poles
%
%   EXAMPLE:
%     A = [0 1; -15 -6]; B = [0; 0.5]; C = [1 0];
%     K = [1650, 68]; L = [394; 37621];
%     expected_cl = [-20+20.97j, -20-20.97j];
%     expected_obs = [-200+209.8j, -200-209.8j];
%     r = verify_solution(A, B, C, K, [], L, expected_cl, expected_obs);
%     assert(r.cl_pass && r.obs_pass);
%
%   See also: design_state_feedback, design_observer, design_integral_ctrl

% ---- Initialize result struct ----
result = struct();
result.cl_pass = true;
result.obs_pass = true;
result.actual_cl = [];
result.actual_obs = [];
result.cl_error = 0;
result.obs_error = 0;

n = size(A, 1);
tol = 1.0; % tolerance for pole matching (accounts for rounding in specs)

% ---- Closed-loop pole verification ----
if ~isempty(K) && ~isempty(expected_cl_poles)
    expected_cl_poles = expected_cl_poles(:);
    K = K(:).';  % ensure row vector

    if ~isempty(ke) && ke ~= 0
        % Integral control: augmented system
        %   A_cl = [A-BK, B*ke; -C, 0]
        n_aug = n + 1;
        A_cl = [A - B * K, B * ke; -C, 0];
        actual_cl = sort(eig(A_cl));
    else
        % Standard state feedback: A_cl = A - B*K
        A_cl = A - B * K;
        actual_cl = sort(eig(A_cl));
    end

    result.actual_cl = actual_cl;

    % Match poles (sorted by real then imaginary part)
    expected_sorted = sort(expected_cl_poles);
    % Compute minimum-distance matching error
    cl_err = max(abs(actual_cl - expected_sorted));
    result.cl_error = cl_err;
    result.cl_pass = (cl_err < tol);
end

% ---- Observer pole verification ----
if ~isempty(L) && ~isempty(expected_obs_poles)
    expected_obs_poles = expected_obs_poles(:);
    L = L(:);  % ensure column vector

    A_obs = A - L * C;
    actual_obs = sort(eig(A_obs));
    result.actual_obs = actual_obs;

    expected_obs_sorted = sort(expected_obs_poles);
    obs_err = max(abs(actual_obs - expected_obs_sorted));
    result.obs_error = obs_err;
    result.obs_pass = (obs_err < tol);
end
end
