function [A, B, C] = tf2ss_phase(num, den)
% TF2SS_PHASE  Transfer function -> phase-variable state-space form.
%
%   [A, B, C] = tf2ss_phase(num, den)
%
%   Beginner version:
%     Converts a transfer function G(s) = num(s)/den(s) into a state-space
%     model x_dot = A x + B u, y = C x.
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
%     Both blocks have the same G(s) = Y(s)/U(s), but use different state
%     coordinates (x vs x~), so the numbers inside A,B,C can change.
%
%   Doc link: docs/Exam3Prep/pdf/convertingTransferFunctionsToStateSpace_handout.pdf
%
%   Note (optional):
%     “Phase-variable form” is a standard companion-form realization where
%     B is [0; 0; ...; 1].
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

A = [zeros(n - 1, 1), eye(n - 1); -fliplr(den(2:end))];
B = [zeros(n - 1, 1); 1];
C = fliplr(num_padded(2:end));
end
