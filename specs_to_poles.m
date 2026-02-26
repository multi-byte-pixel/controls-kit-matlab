function [poles, zeta, wn, sigma, wd] = specs_to_poles(Ts, OS_pct, spec_type)
% SPECS_TO_POLES  Convert transient response specifications to desired pole locations.
%
% INPUTS:
%   Ts       - settling time (seconds) OR peak time if spec_type='Tp'
%   OS_pct   - percent overshoot (e.g., 10 for 10%)
%   spec_type - 'Ts' (default) or 'Tp'
%
% OUTPUTS:
%   poles  - complex conjugate pair [s1; s2]
%   zeta   - damping ratio
%   wn     - natural frequency
%   sigma  - real part magnitude (zeta * wn)
%   wd     - damped natural frequency

if nargin < 3
    spec_type = 'Ts';
end

% Damping ratio from percent overshoot
zeta = -log(OS_pct / 100) / sqrt(pi^2 + log(OS_pct / 100)^2);

if strcmpi(spec_type, 'Tp')
    % Peak time given: wd = pi / Tp
    wd = pi / Ts;
    % wn from wd and zeta
    wn = wd / sqrt(1 - zeta^2);
    sigma = zeta * wn;
else
    % Settling time given: sigma = 4 / Ts
    sigma = 4 / Ts;
    wn = sigma / zeta;
    wd = wn * sqrt(1 - zeta^2);
end

poles = [-sigma + 1j*wd; -sigma - 1j*wd];
end
