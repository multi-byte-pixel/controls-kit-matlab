function [A, B, C] = tf2ss_phase(num, den)
% TF2SS_PHASE  Convert transfer function to state-space in phase-variable form.
%
% INPUTS:
%   num - numerator coefficients (highest power first)
%   den - denominator coefficients (highest power first)
%
% OUTPUTS:
%   A, B, C - state-space matrices in phase-variable form
%   Convention: B = [0;...;0;1], numerator gain absorbed into C

% Normalize denominator (leading coefficient = 1)
scale = den(1);
den = den(:).' / scale;
num = num(:).' / scale;

n = length(den) - 1;  % system order

% Build companion matrix A (last row = negative den coefficients, reversed)
A = [zeros(n-1, 1), eye(n-1); -den(end:-1:2)];

% B vector: [0; 0; ...; 1]
B = [zeros(n-1, 1); 1];

% C vector: numerator coefficients zero-padded to length n (lowest power first)
% num is highest power first, need to pad to length n+1 then drop leading term
% Note: requires a proper transfer function (length(num) <= length(den))
num_full = [zeros(1, n+1 - length(num)), num];
% Drop leading term (coefficient of s^n in numerator, which is 0 for proper sys)
% The C vector entries correspond to [b0, b1, ..., b_{n-1}] (lowest power first)
C = num_full(end:-1:2);

end
