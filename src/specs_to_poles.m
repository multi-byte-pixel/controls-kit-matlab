function [poles, zeta, wn, sigma, wd] = specs_to_poles(Ts, OS_pct, spec_type)
% SPECS_TO_POLES  Convert time/overshoot specs into 2nd-order poles.
%
%   [poles, zeta, wn, sigma, wd] = specs_to_poles(Ts_or_Tp, OS_pct, spec_type)
%
%   Beginner version:
%     If you know “how much overshoot” and “how fast” you want the response,
%     this computes a standard pair of complex poles that match those specs.
%
%   Notes:
%     - spec_type = 'Ts' uses settling time (typical in controls classes)
%     - spec_type = 'Tp' uses peak time
if nargin < 3 || isempty(spec_type)
    spec_type = 'Ts';
end

if ~isscalar(Ts) || ~isfinite(Ts) || Ts <= 0
    error('Ts/Tp must be a positive finite number (in seconds).');
end
if ~isscalar(OS_pct) || ~isfinite(OS_pct) || OS_pct <= 0 || OS_pct >= 100
    error('OS_pct must be a number strictly between 0 and 100 (percent overshoot).');
end

log_term = log(OS_pct / 100);
zeta = -log_term / sqrt(pi^2 + log_term^2);

switch lower(spec_type)
    case 'ts'
        sigma = 4 / Ts;
        wn = sigma / zeta;
        wd = wn * sqrt(1 - zeta^2);
    case 'tp'
        wd = pi / Ts;
        wn = wd / sqrt(1 - zeta^2);
        sigma = zeta * wn;
    otherwise
        error('spec_type must be ''Ts'' (settling time) or ''Tp'' (peak time).');
end

poles = [-sigma + 1i * wd; -sigma - 1i * wd];
end
