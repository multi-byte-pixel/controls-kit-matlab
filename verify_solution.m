function result = verify_solution(A, B, C, K, ke, L, expected_cl_poles, expected_obs_poles)
% VERIFY_SOLUTION  Comprehensive verification of state feedback + observer design.
%
% INPUTS:
%   A                 - system matrix (n x n)
%   B                 - input matrix (n x 1)
%   C                 - output matrix (1 x n)
%   K                 - state feedback gain (1 x n), [] to skip CL check
%   ke                - integral gain (scalar), [] to skip integral check
%   L                 - observer gain (n x 1), [] to skip observer check
%   expected_cl_poles - expected closed-loop poles (may be [] to skip)
%   expected_obs_poles - expected observer poles (may be [] to skip)
%
% OUTPUT:
%   result - struct with fields:
%     .pass            - overall pass/fail
%     .cl_poles_actual - actual closed-loop eigenvalues
%     .obs_poles_actual - actual observer eigenvalues
%     .cl_pole_errors  - magnitude errors vs expected CL poles
%     .obs_pole_errors - magnitude errors vs expected obs poles

result.pass = true;
result.cl_poles_actual = [];
result.obs_poles_actual = [];
result.cl_pole_errors = [];
result.obs_pole_errors = [];

n = size(A, 1);

% ----- Closed-loop poles -----
if ~isempty(K)
    if ~isempty(ke)
        % Integral control: augmented system
        A_aug = [A, zeros(n, 1); -C, 0];
        B_aug = [B; 0];
        K_aug = [K, -ke];
        A_cl = A_aug - B_aug * K_aug;
    else
        A_cl = A - B * K;
    end
    result.cl_poles_actual = sort(eig(A_cl), 'ComparisonMethod', 'real');

    if ~isempty(expected_cl_poles)
        exp_sorted = sort(expected_cl_poles(:), 'ComparisonMethod', 'real');
        act_sorted = result.cl_poles_actual;
        if length(act_sorted) == length(exp_sorted)
            result.cl_pole_errors = abs(act_sorted - exp_sorted);
            if any(result.cl_pole_errors > 1e-4 * max(1, max(abs(exp_sorted))))
                result.pass = false;
                fprintf('WARNING: Closed-loop pole mismatch detected.\n');
            end
        end
    end
end

% ----- Observer poles -----
if ~isempty(L)
    A_obs = A - L * C;
    result.obs_poles_actual = sort(eig(A_obs), 'ComparisonMethod', 'real');

    if ~isempty(expected_obs_poles)
        exp_sorted = sort(expected_obs_poles(:), 'ComparisonMethod', 'real');
        act_sorted = result.obs_poles_actual;
        if length(act_sorted) == length(exp_sorted)
            result.obs_pole_errors = abs(act_sorted - exp_sorted);
            if any(result.obs_pole_errors > 1e-4 * max(1, max(abs(exp_sorted))))
                result.pass = false;
                fprintf('WARNING: Observer pole mismatch detected.\n');
            end
        end
    end
end

if result.pass
    fprintf('verify_solution: PASS\n');
else
    fprintf('verify_solution: FAIL\n');
end

end
