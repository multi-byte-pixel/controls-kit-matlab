function [A, B, C] = tf2ss_observer_canon(num, den)
% TF2SS_OBSERVER_CANON  Convert transfer function to observer canonical form.
%
% INPUTS:
%   num - numerator coefficients (highest power first)
%   den - denominator coefficients (highest power first)
%
% OUTPUTS:
%   A, B, C - state-space matrices in observer canonical form
%   Observer canonical: A is left companion matrix with 1s on superdiagonal
%   C = [1 0 ... 0]

% Normalize denominator (leading coefficient = 1)
scale = den(1);
den = den(:).' / scale;
num = num(:).' / scale;

n = length(den) - 1;  % system order

% Pad numerator to length n+1
num_full = [zeros(1, n+1 - length(num)), num];

% Observer canonical A: left companion matrix
% A(i,1) = -a_{n-i}, i.e. row 1 has -a_{n-1}, row 2 has -a_{n-2}, ..., row n has -a_0
% 1s on the superdiagonal
A = zeros(n, n);
A(:, 1) = -den(2:end).';   % first column: row i gets -den(i+1) = -a_{n-i}
for i = 1:n-1
    A(i, i+1) = 1;
end

% B vector from numerator coefficients (excluding leading term)
% b_i = num(n-i+1) - a_i * num(1), but for strictly proper or proper:
% Standard observer canonical B: [b_{n-1} - d*a_{n-1}; ...; b_0 - d*a_0]
% where d = num_full(1) (leading term of numerator)
d = num_full(1);
B = zeros(n, 1);
for i = 1:n
    B(i) = num_full(i+1) - d * den(i+1);
end

% C = [1 0 ... 0]
C = [1, zeros(1, n-1)];

end
