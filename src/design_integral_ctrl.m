function [K, ke, cl_poles] = design_integral_ctrl(A, B, C, desired_poles)
% DESIGN_INTEGRAL_CTRL  Design integral control to eliminate steady-state error.
%
%   [K, ke, cl_poles] = design_integral_ctrl(A, B, C, desired_poles)
%
%   Standard state feedback (u = r - Kx) cannot guarantee zero steady-state
%   error for step inputs. Integral control adds an extra state x_N that
%   accumulates the error between the reference r and the output y:
%
%     x_N_dot = r - C*x  (integrator of tracking error)
%     u = -K*x + ke*x_N  (control law with integral action)
%
%   The augmented closed-loop system becomes:
%
%     [x_dot  ]   [A - B*K   B*ke] [x  ]   [0]
%     [xN_dot ] = [-C        0   ] [xN ] + [1] * r
%
%   The gains [K, ke] are chosen so that the eigenvalues of the augmented
%   system matrix match desired_poles (which has n+1 entries, where n is
%   the order of the original system).
%
%   INPUTS:
%     A             — n-by-n system matrix
%     B             — n-by-1 input vector
%     C             — 1-by-n output vector
%     desired_poles — length-(n+1) vector of desired augmented CL poles
%                     (includes the integrator pole)
%
%   OUTPUTS:
%     K        — 1-by-n state-feedback gain for the original states
%     ke       — scalar integral gain
%     cl_poles — actual eigenvalues of the augmented CL system
%
%   DESIGN METHOD:
%     1. Form the augmented system matrices:
%          A_aug = [A, zeros(n,1); -C, 0]
%          B_aug = [B; 0]
%     2. Use pole placement on (A_aug, B_aug) to find K_aug = [K, -ke].
%        The sign convention is: u = -K_aug * [x; xN], which gives
%        u = -K*x + ke*xN (note the +ke because K_aug's last element
%        is -ke).
%
%   EXAMPLE (F1 — cancel zero):
%     A = [0 1; 2 1]; B = [0; 1]; C = [2 1];
%     desired = [-2, -8+10.915j, -8-10.915j];
%     [K, ke, cl] = design_integral_ctrl(A, B, C, desired);
%     % K ≈ [34, 19], ke ≈ 183
%
%   WHY INTEGRAL CONTROL?
%     - Proportional feedback alone leaves a steady-state offset.
%     - The integrator "remembers" past error and keeps adjusting u
%       until y matches r exactly (for step inputs).
%     - Trade-off: adding an integrator increases system order by 1,
%       so you need one more desired pole.
%
%   COMMON MISTAKES:
%     - Forgetting that desired_poles has (n+1) entries, not n.
%     - Sign error in augmented system: the integrator row is [-C, 0],
%       and ke enters with a positive sign in the control law.
%     - Not including ke in ALL coefficient equations when matching
%       the characteristic polynomial (this caused the F2/F4 textbook
%       errors that were corrected in this repository).
%
%   See also: design_state_feedback, design_observer, verify_solution

% ---- Input validation ----
if ~ismatrix(A) || size(A, 1) ~= size(A, 2)
    error('A must be a square matrix.');
end
n = size(A, 1);

if size(B, 1) ~= n || size(B, 2) ~= 1
    error('B must be an n-by-1 column vector.');
end

if size(C, 1) ~= 1 || size(C, 2) ~= n
    error('C must be a 1-by-n row vector.');
end

desired_poles = desired_poles(:);
if numel(desired_poles) ~= n + 1
    error('desired_poles must have exactly %d elements (n+1 for augmented system).', n + 1);
end

% ---- Build augmented system ----
%   Augmented state: [x; x_N] where x_N is the integrator state.
%
%   A_aug = [A       0  ]    B_aug = [B]
%           [-C      0  ]            [0]
%
%   The control law u = -K*x + ke*x_N can be written as
%   u = -[K, -ke] * [x; x_N], so we place poles of
%   A_aug - B_aug * [K, -ke].
A_aug = [A, zeros(n, 1); -C, 0];
B_aug = [B; 0];

% ---- Controllability check on augmented system ----
n_aug = n + 1;
CM_aug = zeros(n_aug, n_aug);
CM_aug(:, 1) = B_aug;
for k = 2:n_aug
    CM_aug(:, k) = A_aug * CM_aug(:, k-1);
end
if rank(CM_aug) < n_aug
    error('Augmented system is not controllable. Integral control design is impossible.');
end

% ---- Pole placement on augmented system ----
try
    K_aug = place(A_aug, B_aug, desired_poles);
catch
    K_aug = acker(A_aug, B_aug, desired_poles);
end

% ---- Extract K and ke ----
%   K_aug = [K, -ke], so ke = -K_aug(end)
K = K_aug(1:n);
ke = -K_aug(end);

% ---- Verification ----
%   Build the actual augmented CL matrix and check eigenvalues.
%   CL: A_aug - B_aug * K_aug
A_cl_aug = A_aug - B_aug * K_aug;
cl_poles = eig(A_cl_aug);
cl_poles = sort(cl_poles);
end
