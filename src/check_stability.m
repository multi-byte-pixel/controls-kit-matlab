function [is_stable, eigenvalues, n_rhp, n_lhp, n_jw] = check_stability(A)
if ~ismatrix(A) || size(A, 1) ~= size(A, 2)
    error('A must be a square matrix.');
end

eigenvalues = eig(A);
tol = 1e-9;

n_rhp = sum(real(eigenvalues) > tol);
n_lhp = sum(real(eigenvalues) < -tol);
n_jw = sum(abs(real(eigenvalues)) <= tol);

is_stable = (n_rhp == 0) && (n_jw == 0);
end
