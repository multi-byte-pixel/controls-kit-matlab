function [L, obs_poles] = design_observer(A, C, desired_obs_poles)
% DESIGN_OBSERVER  Pick an observer gain L to estimate the state.
%
%   [L, obs_poles] = design_observer(A, C, desired_obs_poles)
%
%   Beginner version:
%     An observer is a “state guesser”: it uses your measurements y to
%     estimate the full state x.
%     This function picks L so the estimation error goes away quickly.
%
%   When to use this:
%     Use this after you have (A,C) and you want an estimate of x when you
%     can only measure y.
%
%   The estimation error e = x - x_hat evolves as:
%     e_dot = (A - L*C) * e
%
%   The gain L is chosen so that the eigenvalues of (A - L*C) equal
%   the desired observer pole locations. Observer poles are typically
%   placed 5-10x further left in the s-plane than the controller poles,
%   so the observer converges much faster than the controlled response.
%
%   INPUTS:
%     A                 — n-by-n system matrix
%     C                 — 1-by-n output vector (SISO assumed)
%     desired_obs_poles — length-n vector of desired observer poles
%                         (complex poles must be in conjugate pairs)
%
%   OUTPUTS:
%     L         — n-by-1 observer gain vector
%     obs_poles — actual eigenvalues of (A - L*C), for verification
%
%   DESIGN METHOD (Transpose Trick):
%     Observer design for (A, C) is mathematically dual to state-feedback
%     design for (A', C'). That is:
%       L = place(A', C', desired_obs_poles)'
%     This works because eig(A - L*C) = eig(A' - C'*L'), and placing
%     poles of (A' - C'*L') is a standard feedback problem.
%
%   OBSERVER CANONICAL FORM SHORTCUT:
%     When A is in observer canonical form:
%       A = [-a_{n-1} 1 0; -a_{n-2} 0 1; ...; -a_0 0 0], C = [1 0 ... 0]
%     The observer gains can be found by direct coefficient matching:
%       det(sI - (A - LC)) = s^n + (a_{n-1}+l1)*s^{n-1} + ... + (a0+ln)
%     Each l_i simply shifts one coefficient of the characteristic polynomial.
%
%   EXAMPLE (D1 — M10 S12.5 P1):
%     A = [-10 1; -21 0]; C = [1 0];
%     desired = [-100+50j, -100-50j];
%     [L, obs_poles] = design_observer(A, C, desired);
%     % L ≈ [190; 12479]
%
%   COMMON MISTAKES:
%     - Forgetting to check observability. If (A, C) is not observable,
%       observer design is impossible.
%     - Not placing observer poles fast enough (use 5-10x rule of thumb).
%     - Sign confusion: error dynamics are A - L*C (not A + L*C).
%
%   See also: check_observability, design_state_feedback, verify_solution

% ---- Input validation ----
if ~ismatrix(A) || size(A, 1) ~= size(A, 2)
    error('A must be a square matrix (n-by-n).');
end
n = size(A, 1);

if size(C, 1) ~= 1 || size(C, 2) ~= n
    error('C must be a 1-by-%d row vector (single output / SISO).', n);
end

desired_obs_poles = desired_obs_poles(:);
if numel(desired_obs_poles) ~= n
    error('desired_obs_poles must have exactly %d elements (one per state).', n);
end

% ---- Observability check ----
%   Observer design requires the system to be observable.
OM = zeros(n, n);
OM(1, :) = C;
for k = 2:n
    OM(k, :) = OM(k-1, :) * A;
end
if rank(OM) < n
    error('System (A,C) is not observable, so an observer cannot be designed. (Tip: run check_observability(A,C).)');
end

% ---- Observer gain via transpose trick ----
%   L = place(A', C', poles)'
%   This exploits duality: observability of (A,C) ↔ controllability of (A',C').
try
    L = place(A', C', desired_obs_poles)';
catch
    % Fall back to acker() for repeated poles
    L = acker(A', C', desired_obs_poles)';
end

% Ensure L is a column vector
L = L(:);

% ---- Verification ----
obs_poles = eig(A - L * C);
obs_poles = sort(obs_poles);
end
