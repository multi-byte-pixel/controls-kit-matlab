function [K, ke, cl_poles] = design_integral_ctrl(A, B, C, desired_poles)
% DESIGN_INTEGRAL_CTRL  Design state feedback with integral control.
%
% Augments the system with an integrator state to eliminate steady-state error.
%
% INPUTS:
%   A             - system matrix (n x n)
%   B             - input matrix (n x 1)
%   C             - output matrix (1 x n)
%   desired_poles - desired closed-loop poles (n+1 values) as row/column vector
%
% OUTPUTS:
%   K        - state feedback gain (1 x n)
%   ke       - integral gain (scalar)
%   cl_poles - actual closed-loop poles of augmented system
%
% Augmented plant: A_aug = [A, zeros(n,1); -C, 0], B_aug = [B; 0]
% Control law: u = -Kx + ke*xN (xN = integral of tracking error)
% Closed-loop augmented A: A_aug - B_aug*K_aug, K_aug = [K, -ke]

n = size(A, 1);
desired_poles = desired_poles(:).';  % ensure row vector

% Build augmented system matrices
A_aug = [A, zeros(n, 1); -C, 0];
B_aug = [B; 0];

% Place poles of augmented closed-loop system
try
    K_aug = place(A_aug, B_aug, desired_poles);
catch
    K_aug = acker(A_aug, B_aug, desired_poles);
end

K  = K_aug(1:n);
ke = -K_aug(n+1);  % sign convention: u = -Kx + ke*xN

cl_poles = eig(A_aug - B_aug * K_aug);

end
