function [is_controllable, CM, rank_CM] = check_controllability(A, B)
% CHECK_CONTROLLABILITY  Determine if a state-space system is controllable.
%
%   [is_controllable, CM, rank_CM] = check_controllability(A, B)
%
%   A system (A, B) is controllable if and only if the controllability
%   matrix CM = [B, AB, A^2B, ..., A^{n-1}B] has full row rank (rank = n).
%
%   Controllability means every state can be driven to any desired value
%   in finite time using the input u. If the system is not controllable,
%   some internal states cannot be influenced by the input — this makes
%   pole placement via state feedback impossible.
%
%   INPUTS:
%     A  — n-by-n system (state) matrix
%     B  — n-by-m input matrix (m inputs; typically m=1 for SISO)
%
%   OUTPUTS:
%     is_controllable — logical true if rank(CM) == n
%     CM              — n-by-(n*m) controllability matrix
%     rank_CM         — numerical rank of CM
%
%   EXAMPLE:
%     A = [0 1; -2 -3]; B = [1; -1];
%     [ctrl, CM, r] = check_controllability(A, B);
%     % ctrl = false, r = 1 (uncontrollable)
%
%   COMMON MISTAKES:
%     - Forgetting that rank deficiency means some modes are unreachable.
%     - Using numerical rank without tolerance for ill-conditioned matrices.
%     - Confusing controllability matrix with observability matrix (transpose
%       relationship: controllability of (A, B) ↔ observability of (A', B')).
%
%   MATLAB EQUIVALENT:
%     CM = ctrb(A, B);        % Control System Toolbox
%     rank(CM)                % Check rank
%
%   See also: check_observability, design_state_feedback

% ---- Input validation ----
if ~ismatrix(A) || size(A, 1) ~= size(A, 2)
    error('A must be a square matrix.');
end
n = size(A, 1);

if size(B, 1) ~= n
    error('B must have the same number of rows as A (%d).', n);
end

% ---- Build controllability matrix: CM = [B, AB, A^2B, ..., A^{n-1}B] ----
%   Each column block A^k * B shows how the input propagates through the
%   system after k time steps. If all n directions in state space are
%   spanned by these columns, the system is controllable.
m = size(B, 2);
CM = zeros(n, n * m);
CM(:, 1:m) = B;

for k = 1:(n - 1)
    % A^k * B computed iteratively: A * (A^{k-1} * B)
    CM(:, k*m + 1 : (k+1)*m) = A * CM(:, (k-1)*m + 1 : k*m);
end

% ---- Rank test ----
%   Full rank (= n) means all state directions are reachable.
rank_CM = rank(CM);
is_controllable = (rank_CM == n);
end
