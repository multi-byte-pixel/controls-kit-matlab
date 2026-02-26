function [K, cl_poles] = design_state_feedback(A, B, desired_poles)
% DESIGN_STATE_FEEDBACK  Compute state-feedback gain K for pole placement.
%
%   [K, cl_poles] = design_state_feedback(A, B, desired_poles)
%
%   State feedback: u = r - K*x  →  x_dot = (A - B*K)*x + B*r
%   The gain vector K is chosen so that the eigenvalues of (A - B*K)
%   equal the desired closed-loop pole locations.
%
%   This function uses MATLAB's place() for numerical pole placement.
%   For phase-variable form (B = [0;...;0;1]), the result is equivalent
%   to direct coefficient matching between the desired and actual
%   characteristic polynomials.
%
%   INPUTS:
%     A             — n-by-n system matrix
%     B             — n-by-1 input vector (SISO assumed)
%     desired_poles — length-n vector of desired closed-loop pole locations
%                     (complex poles must appear in conjugate pairs)
%
%   OUTPUTS:
%     K        — 1-by-n state-feedback gain vector
%     cl_poles — actual closed-loop poles of (A - B*K), for verification
%
%   CONTROL-THEORY INTUITION:
%     Without feedback, the system poles are eig(A). With u = r - Kx,
%     each gain element k_i "pushes" the poles to new locations.
%     For a phase-variable system, k_i directly adjusts the i-th
%     coefficient in the characteristic polynomial — making the
%     design especially transparent.
%
%   EXAMPLE (M09 P4 — 2nd order spring-mass-damper):
%     A = [0 1; -15 -6]; B = [0; 0.5];
%     desired = [-20+20.97j, -20-20.97j];
%     [K, cl] = design_state_feedback(A, B, desired);
%     % K ≈ [1650, 68.0]
%
%   COMMON MISTAKES:
%     - Forgetting to check controllability first. If (A,B) is not
%       controllable, pole placement is impossible.
%     - Not providing complex poles in conjugate pairs (causes complex K).
%     - Confusing sign: u = r - Kx, so A_cl = A - B*K (minus sign).
%
%   See also: check_controllability, design_observer, design_integral_ctrl

% ---- Input validation ----
if ~ismatrix(A) || size(A, 1) ~= size(A, 2)
    error('A must be a square matrix.');
end
n = size(A, 1);

if size(B, 1) ~= n || size(B, 2) ~= 1
    error('B must be an n-by-1 column vector.');
end

desired_poles = desired_poles(:);
if numel(desired_poles) ~= n
    error('desired_poles must have exactly %d elements (same as system order).', n);
end

% ---- Controllability check ----
%   Pole placement requires the system to be controllable.
CM = zeros(n, n);
CM(:, 1) = B;
for k = 2:n
    CM(:, k) = A * CM(:, k-1);
end
if rank(CM) < n
    error('System (A, B) is not controllable. Pole placement is impossible.');
end

% ---- Pole placement via place() ----
%   place() uses a robust numerical algorithm. For SISO phase-variable
%   systems, this is equivalent to matching characteristic polynomial
%   coefficients, but place() works for any controllable (A, B).
%
%   Note: place() does not allow repeated poles. For repeated poles,
%   use acker() instead, but acker() is less numerically robust.
try
    K = place(A, B, desired_poles);
catch
    % Fall back to acker() for repeated poles
    K = acker(A, B, desired_poles);
end

% ---- Verification ----
%   Compute actual closed-loop poles to confirm placement succeeded.
A_cl = A - B * K;
cl_poles = eig(A_cl);

% Sort for consistent comparison
cl_poles = sort(cl_poles);
end
