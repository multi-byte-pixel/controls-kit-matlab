function [A, B, C] = tf2ss_phase(num, den)
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

A = [zeros(n - 1, 1), eye(n - 1); -fliplr(den(2:end))];
B = [zeros(n - 1, 1); 1];
C = fliplr(num_padded(2:end));
end
