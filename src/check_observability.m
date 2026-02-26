function [is_observable, OM, rank_OM] = check_observability(A, C)
% CHECK_OBSERVABILITY  Determine if a state-space system is observable.
%
%   [is_observable, OM, rank_OM] = check_observability(A, C)
%
%   A system (A, C) is observable if and only if the observability matrix
%   OM = [C; CA; CA^2; ...; CA^{n-1}] has full column rank (rank = n).
%
%   Observability means every initial state x(0) can be uniquely determined
%   from the output y(t) and input u(t). If the system is not observable,
%   some internal states are "hidden" from the output — this makes observer
%   (state estimator) design impossible for those modes.
%
%   INPUTS:
%     A  — n-by-n system (state) matrix
%     C  — p-by-n output matrix (p outputs; typically p=1 for SISO)
%
%   OUTPUTS:
%     is_observable — logical true if rank(OM) == n
%     OM            — (n*p)-by-n observability matrix
%     rank_OM       — numerical rank of OM
%
%   EXAMPLE:
%     A = [-10 1; -21 0]; C = [1 0];
%     [obs, OM, r] = check_observability(A, C);
%     % obs = true, r = 2 (fully observable)
%
%   DUALITY WITH CONTROLLABILITY:
%     (A, C) is observable ⟺ (A', C') is controllable.
%     This is why observer gain L is computed via place(A', C', poles)'.
%
%   COMMON MISTAKES:
%     - Confusing rows and columns: OM stacks C, CA, CA^2, ... as ROWS.
%     - For diagonal A, check that C "sees" every eigenvalue (mode).
%       Example: A = diag([-1,-2,-3]), C = [0 0 1] → x1, x2 are hidden.
%
%   MATLAB EQUIVALENT:
%     OM = obsv(A, C);
%     rank(OM)
%
%   See also: check_controllability, design_observer

% ---- Input validation ----
if ~ismatrix(A) || size(A, 1) ~= size(A, 2)
    error('A must be a square matrix.');
end
n = size(A, 1);

if size(C, 2) ~= n
    error('C must have the same number of columns as A (%d).', n);
end

% ---- Build observability matrix: OM = [C; CA; CA^2; ...; CA^{n-1}] ----
%   Each row block CA^k shows what the output reveals about the state
%   after k time steps. If all n state directions appear in at least one
%   row, the system is observable.
p = size(C, 1);
OM = zeros(n * p, n);
OM(1:p, :) = C;

for k = 1:(n - 1)
    % CA^k computed iteratively: (CA^{k-1}) * A
    OM(k*p + 1 : (k+1)*p, :) = OM((k-1)*p + 1 : k*p, :) * A;
end

% ---- Rank test ----
%   Full rank (= n) means every state can be reconstructed from outputs.
rank_OM = rank(OM);
is_observable = (rank_OM == n);
end
