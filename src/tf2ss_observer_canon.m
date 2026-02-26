function [A, B, C] = tf2ss_observer_canon(num, den)
if isempty(num) || isempty(den)
    error('num and den must be non-empty vectors.');
end
if den(1) == 0
    error('The leading denominator coefficient must be non-zero.');
end

den = den(:).';
num = num(:).';

den = den / den(1);
num = num / den(1);

n = numel(den) - 1;
num_order = numel(num) - 1;

if num_order >= n
    error('Only strictly proper transfer functions are supported (degree(num) < degree(den)).');
end

num_padded = [zeros(1, n - num_order), num];

A = zeros(n, n);
A(:, 1) = -den(2:end).';
A(1:n-1, 2:n) = eye(n - 1);

B = num_padded(2:end).';
C = [1, zeros(1, n - 1)];
end
