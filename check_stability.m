function [is_stable, eigenvalues, n_rhp, n_lhp, n_jw] = check_stability(A)
% CHECK_STABILITY  Check stability of a system via eigenvalues of A.
%
% INPUT:
%   A - system matrix (n x n)
%
% OUTPUTS:
%   is_stable  - true if all eigenvalues have Re < 0
%   eigenvalues - eigenvalues of A
%   n_rhp      - number of right-half-plane eigenvalues (Re > 0)
%   n_lhp      - number of left-half-plane eigenvalues (Re < 0)
%   n_jw       - number of imaginary-axis eigenvalues (Re == 0)

tol = 1e-8;
eigenvalues = eig(A);
re = real(eigenvalues);

n_rhp = sum(re > tol);
n_lhp = sum(re < -tol);
n_jw  = sum(abs(re) <= tol);

is_stable = (n_rhp == 0) && (n_jw == 0);

end
