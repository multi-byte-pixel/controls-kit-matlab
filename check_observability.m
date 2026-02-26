function [is_observable, OM, rank_OM] = check_observability(A, C)
% CHECK_OBSERVABILITY  Check observability of system (A, C).
%
% INPUTS:
%   A - system matrix (n x n)
%   C - output matrix (p x n)
%
% OUTPUTS:
%   is_observable - true if rank of observability matrix equals n
%   OM            - observability matrix [C; CA; ...; CA^{n-1}]
%   rank_OM       - rank of observability matrix

n = size(A, 1);
OM = obsv(A, C);
rank_OM = rank(OM);
is_observable = (rank_OM == n);

end
