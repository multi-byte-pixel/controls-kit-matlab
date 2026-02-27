function [is_stable, eigenvalues, n_rhp, n_lhp, n_jw] = check_stability(A)
% CHECK_STABILITY  Quick stability check using eigenvalues.
%
%   [is_stable, eigenvalues, n_rhp, n_lhp, n_jw] = check_stability(A)
%
%   Beginner version:
%     For a continuous-time system x_dot = A x, the system is stable if all
%     eigenvalues of A have negative real parts.
%
%   Outputs:
%     eigenvalues — eig(A)
%     n_rhp       — count with real part > 0 (unstable)
%     n_jw        — count with real part ~ 0 (marginal)
if ~ismatrix(A) || size(A, 1) ~= size(A, 2)
    error('A must be a square matrix (n-by-n).');
end

eigenvalues = eig(A);
tol = 1e-9;

n_rhp = sum(real(eigenvalues) > tol);
n_lhp = sum(real(eigenvalues) < -tol);
n_jw = sum(abs(real(eigenvalues)) <= tol);

is_stable = (n_rhp == 0) && (n_jw == 0);
end
