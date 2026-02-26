function [is_controllable, CM, rank_CM] = check_controllability(A, B)
% CHECK_CONTROLLABILITY  Check controllability of system (A, B).
%
% INPUTS:
%   A - system matrix (n x n)
%   B - input matrix (n x m)
%
% OUTPUTS:
%   is_controllable - true if rank of controllability matrix equals n
%   CM              - controllability matrix [B, AB, ..., A^{n-1}B]
%   rank_CM         - rank of controllability matrix

n = size(A, 1);
CM = ctrb(A, B);
rank_CM = rank(CM);
is_controllable = (rank_CM == n);

end
