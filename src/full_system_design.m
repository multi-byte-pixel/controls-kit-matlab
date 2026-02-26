function result = full_system_design(num, den, specs)
% FULL_SYSTEM_DESIGN  End-to-end control system design orchestrator.
%
%   result = full_system_design(num, den, specs)
%
%   Given a transfer function G(s) = num(s)/den(s) and performance specs,
%   this function performs the complete design workflow:
%     1. Convert TF to state-space (phase-variable and observer canonical)
%     2. Check controllability and observability
%     3. Compute desired poles from transient specs
%     4. Design state-feedback gain K (pole placement)
%     5. Design observer gain L (poles placed obs_multiplier × further left)
%     6. Optionally design integral control (if specs.use_integral = true)
%     7. Verify all designs
%
%   INPUTS:
%     num  — numerator polynomial coefficients (highest power first)
%     den  — denominator polynomial coefficients (highest power first)
%     specs — struct with fields:
%       .OS_pct          — percent overshoot (e.g., 10 for 10%)
%       .Ts or .Tp       — settling time or peak time (seconds)
%       .spec_type       — 'Ts' (default) or 'Tp'
%       .obs_multiplier  — multiplier for observer poles (default: 10)
%       .extra_pole_mult — multiplier for 3rd pole if plant order > 2
%                          (default: 10, places extra pole at -mult*sigma)
%       .use_integral    — logical, design integral control (default: false)
%
%   OUTPUT:
%     result — struct with all design products:
%       .A_phase, .B_phase, .C_phase   — phase-variable SS
%       .A_obs, .B_obs, .C_obs         — observer canonical SS
%       .is_controllable               — logical
%       .is_observable                  — logical
%       .desired_poles                  — desired CL poles
%       .K                             — state-feedback gain
%       .cl_poles                      — actual closed-loop poles
%       .desired_obs_poles             — desired observer poles
%       .L                             — observer gain
%       .obs_poles                     — actual observer poles
%       .ke                            — integral gain (if applicable)
%       .verification                  — verify_solution output
%
%   EXAMPLE:
%     num = [0.5]; den = [1 6 15];
%     specs.OS_pct = 5; specs.Ts = 0.2; specs.spec_type = 'Ts';
%     specs.obs_multiplier = 10;
%     r = full_system_design(num, den, specs);
%
%   See also: specs_to_poles, tf2ss_phase, tf2ss_observer_canon,
%             check_controllability, check_observability,
%             design_state_feedback, design_observer, design_integral_ctrl,
%             verify_solution

% ---- Default specs ----
if ~isfield(specs, 'spec_type'),       specs.spec_type = 'Ts';    end
if ~isfield(specs, 'obs_multiplier'),  specs.obs_multiplier = 10; end
if ~isfield(specs, 'extra_pole_mult'), specs.extra_pole_mult = 10; end
if ~isfield(specs, 'use_integral'),    specs.use_integral = false; end

% Determine the settling/peak time value
if isfield(specs, 'Ts')
    time_val = specs.Ts;
elseif isfield(specs, 'Tp')
    time_val = specs.Tp;
else
    error('specs must contain either .Ts or .Tp');
end

% ---- Step 1: Convert TF to state-space ----
%   Phase-variable form is used for state-feedback design (B = [0;...;1]).
%   Observer canonical form is used for observer design (C = [1 0 ... 0]).
result.A_phase = []; result.B_phase = []; result.C_phase = [];
result.A_obs = []; result.B_obs = []; result.C_obs = [];

[result.A_phase, result.B_phase, result.C_phase] = tf2ss_phase(num, den);
[result.A_obs, result.B_obs, result.C_obs] = tf2ss_observer_canon(num, den);

n = size(result.A_phase, 1); % system order

% ---- Step 2: Check controllability and observability ----
[result.is_controllable, ~, ~] = check_controllability(result.A_phase, result.B_phase);
[result.is_observable, ~, ~] = check_observability(result.A_obs, result.C_obs);

if ~result.is_controllable
    warning('System is NOT controllable — state feedback design will fail.');
end
if ~result.is_observable
    warning('System is NOT observable — observer design will fail.');
end

% ---- Step 3: Compute desired poles from specs ----
[dom_poles, zeta, wn, sigma, wd] = specs_to_poles(time_val, specs.OS_pct, specs.spec_type);

% For systems of order > 2, place extra poles far to the left
% so they don't affect the dominant second-order response.
if n == 2
    desired_poles = dom_poles;
elseif n > 2
    extra_poles = -specs.extra_pole_mult * sigma * ones(n - 2, 1);
    % Slightly separate repeated extra poles for place()
    for k = 2:length(extra_poles)
        extra_poles(k) = extra_poles(k) * (1 + 0.01 * k);
    end
    desired_poles = [dom_poles; extra_poles];
else
    error('System order must be at least 2.');
end

result.desired_poles = desired_poles;
result.zeta = zeta;
result.wn = wn;
result.sigma = sigma;
result.wd = wd;

% ---- Step 4: Design state-feedback K (phase-variable form) ----
[result.K, result.cl_poles] = design_state_feedback(result.A_phase, result.B_phase, desired_poles);

% ---- Step 5: Design observer L (observer canonical form) ----
%   Observer poles are placed obs_multiplier × further left.
obs_sigma = specs.obs_multiplier * sigma;
obs_wd = specs.obs_multiplier * wd;
dom_obs_poles = [-obs_sigma + 1i*obs_wd; -obs_sigma - 1i*obs_wd];

if n == 2
    desired_obs_poles = dom_obs_poles;
elseif n > 2
    extra_obs_poles = -specs.obs_multiplier * specs.extra_pole_mult * sigma * ones(n - 2, 1);
    for k = 2:length(extra_obs_poles)
        extra_obs_poles(k) = extra_obs_poles(k) * (1 + 0.01 * k);
    end
    desired_obs_poles = [dom_obs_poles; extra_obs_poles];
end

result.desired_obs_poles = desired_obs_poles;
[result.L, result.obs_poles] = design_observer(result.A_obs, result.C_obs, desired_obs_poles);

% ---- Step 6: Optional integral control ----
result.ke = [];
if specs.use_integral
    % For integral control, we need (n+1) desired poles.
    % Add one more pole at the integrator location.
    int_extra_pole = -specs.extra_pole_mult * sigma;
    int_desired = [desired_poles; int_extra_pole];
    [result.K, result.ke, result.cl_poles] = design_integral_ctrl( ...
        result.A_phase, result.B_phase, result.C_phase, int_desired);
end

% ---- Step 7: Verification ----
result.verification = verify_solution( ...
    result.A_phase, result.B_phase, result.C_phase, ...
    result.K, result.ke, result.L, ...
    result.cl_poles, result.obs_poles);

% ---- Summary output ----
fprintf('--- Full System Design Summary ---\n');
fprintf('System order: %d\n', n);
fprintf('Controllable: %s\n', mat2str(result.is_controllable));
fprintf('Observable:   %s\n', mat2str(result.is_observable));
fprintf('K = [%s]\n', num2str(result.K, '%.4f '));
if ~isempty(result.ke)
    fprintf('ke = %.4f\n', result.ke);
end
fprintf('L = [%s]\n', num2str(result.L', '%.4f '));
fprintf('CL poles: ');
disp(result.cl_poles');
fprintf('Obs poles: ');
disp(result.obs_poles');
fprintf('Verification: CL %s, Obs %s\n', ...
    iff(result.verification.cl_pass, 'PASS', 'FAIL'), ...
    iff(result.verification.obs_pass, 'PASS', 'FAIL'));
end

function out = iff(cond, a, b)
% Simple inline conditional (MATLAB lacks ternary operator)
    if cond
        out = a;
    else
        out = b;
    end
end
