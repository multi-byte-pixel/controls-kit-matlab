function [poles, zeta, wn, sigma, wd] = specs_to_poles(Ts, OS_pct, spec_type)
if nargin < 3 || isempty(spec_type)
    spec_type = 'Ts';
end

if ~isscalar(Ts) || ~isfinite(Ts) || Ts <= 0
    error('Ts/Tp must be a positive finite scalar.');
end
if ~isscalar(OS_pct) || ~isfinite(OS_pct) || OS_pct <= 0 || OS_pct >= 100
    error('OS_pct must be a finite scalar in the open interval (0, 100).');
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
        error('spec_type must be either ''Ts'' or ''Tp''.');
end

poles = [-sigma + 1i * wd; -sigma - 1i * wd];
end
