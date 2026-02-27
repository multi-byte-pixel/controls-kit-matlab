function [A, B, C] = tf2ss_observer_canon(num, den)
% TF2SS_OBSERVER_CANON  Transfer function -> observer canonical form.
%
%   [A, B, C] = tf2ss_observer_canon(num, den)
%
%   Beginner version:
%     Same idea as tf2ss_phase, but returns a different (equivalent)
%     state-space model that is often convenient for observer design.
%
%   Important idea:
%     Different state-space realizations can describe the same transfer
%     function (same input/output behavior), even if the internal matrices
%     and state variables are different.
%
%     Same input/output behavior (same transfer function):
%       u  ---->  [ Realization 1: (A,B,C) ]  ---->  y
%       u  ---->  [ Realization 2: (A~,B~,C~) ] ---->  y
%
%     Both blocks have the same G(s), but use different state coordinates.
%
%   Doc link: docs/Exam3Prep/pdf/convertingTransferFunctionsToStateSpace_handout.pdf
if isempty(num) || isempty(den)
    error('num and den must be non-empty coefficient vectors (highest power first).');
end
if den(1) == 0
    error('The leading denominator coefficient must be non-zero (den(1) ~= 0).');
end

den = den(:).';
num = num(:).';

den = den / den(1);
num = num / den(1);

n = numel(den) - 1;
num_order = numel(num) - 1;

if num_order >= n
    error('Only strictly proper transfer functions are supported: degree(num) < degree(den).');
end

num_padded = [zeros(1, n - num_order), num];

A = zeros(n, n);
A(:, 1) = -den(2:end).';
A(1:n-1, 2:n) = eye(n - 1);

B = num_padded(2:end).';
C = [1, zeros(1, n - 1)];
end
