% EXAM_WIZARD  Interactive Q&A wizard for state-space control system design.
%
%   Run from the MATLAB Command Window (repo root open in VS Code):
%     run('src/exam_wizard.m')
%
%   Or, from the VS Code integrated terminal (interactive mode, not -batch):
%     matlab -nosplash -nodesktop -r "cd('<repo_root>'); run('src/exam_wizard.m'); exit"
%
%   The wizard walks you through:
%     1. Transfer function entry and validation
%     2. Performance specs (OS%, Ts or Tp)
%     3. Integral action and observer speed options
%     4. Confirm then run the full design pipeline
%     5. Print exam-ready results and a Simulink export package
%     6. Optionally save all variables to design.mat
%
%   All design variables (A, B, C, D, K, L, Ki, poles, specs) are placed
%   into the MATLAB base workspace so you can use them in Simulink blocks
%   immediately after the wizard finishes.

% Add src/ to path so helper functions are reachable.
addpath(fileparts(mfilename('fullpath')));

clc;
fprintf('\n');
fprintf('=====================================================\n');
fprintf('   Exam Q&A Wizard  — State-Space Design Kit\n');
fprintf('=====================================================\n');
fprintf('Answer each question, then press Enter.\n');
fprintf('Type  q  at any prompt to quit.\n\n');

% ================================================================
%  STEP 1 — Transfer function
% ================================================================
fprintf('-- Step 1: Transfer Function --\n');
fprintf('\n');
fprintf('Enter coefficients highest power first, separated by spaces.\n');
fprintf('\n');
fprintf('  Example:  G(s) = 0.5 / (s^2 + 6s + 15)\n');
fprintf('            num = 0.5\n');
fprintf('            den = 1 6 15\n\n');

num = wiz_get_vector('  num > ');
den = wiz_get_vector('  den > ');

% Validate
if isempty(num) || isempty(den)
    error('exam_wizard:badInput', 'Coefficients cannot be empty.');
end
if den(1) == 0
    error('exam_wizard:badInput', ...
        'Leading denominator coefficient must be non-zero (den(1) ~= 0).');
end

num_order = numel(num) - 1;
den_order = numel(den) - 1;
if num_order >= den_order
    error('exam_wizard:notStrictlyProper', ...
        ['Transfer function must be strictly proper.\n' ...
         '  Got: degree(num)=%d, degree(den)=%d.\n' ...
         '  Require degree(num) < degree(den).'], num_order, den_order);
end

fprintf('\n  OK — G(s) = ( %s ) / ( %s )\n', ...
    wiz_poly2str(num), wiz_poly2str(den));
fprintf('  System order: %d\n\n', den_order);

% ================================================================
%  STEP 2 — Performance specs
% ================================================================
fprintf('-- Step 2: Performance Specs --\n\n');

OS_pct = wiz_get_scalar('  Overshoot OS_pct in percent   (e.g. 10 for 10%%) > ');
if OS_pct <= 0 || OS_pct >= 100
    error('exam_wizard:badSpec', 'OS_pct must be strictly between 0 and 100.');
end

fprintf('\n  Spec type options:\n');
fprintf('    Ts  = settling time  (use the 4/sigma rule)\n');
fprintf('    Tp  = peak time      (time to first overshoot peak)\n\n');
spec_type = wiz_get_choice('  Spec type [Ts / Tp] > ', {'Ts','Tp'});
time_val  = wiz_get_scalar(sprintf('  %s value in seconds > ', spec_type));
if time_val <= 0
    error('exam_wizard:badSpec', 'Time value must be positive.');
end

fprintf('\n  OK — %.4g%% overshoot, %s = %.4g s\n\n', OS_pct, spec_type, time_val);

% ================================================================
%  STEP 3 — Observer and integral options
% ================================================================
fprintf('-- Step 3: Observer and Integral Options --\n\n');

integral_raw = wiz_get_choice( ...
    '  Include integral action for zero steady-state error? [yes / no] > ', ...
    {'yes','y','no','n',''});
use_integral = ismember(lower(strtrim(integral_raw)), {'yes','y'});

obs_raw = input('  Observer speed factor (default 5, press Enter to skip) > ', 's');
if isempty(strtrim(obs_raw))
    obs_mult = 5;
else
    obs_mult = str2double(obs_raw);
    if isnan(obs_mult) || obs_mult <= 0
        fprintf('  Could not parse, using default 5.\n');
        obs_mult = 5;
    end
end

fprintf('\n  OK — Integral action: %s | Observer speed: %gx\n\n', ...
    wiz_yesno_str(use_integral), obs_mult);

% ================================================================
%  STEP 4 — Confirm
% ================================================================
fprintf('-- Step 4: Confirm Before Computing --\n\n');
fprintf('  Transfer function:\n');
fprintf('    G(s) = ( %s ) / ( %s )\n', wiz_poly2str(num), wiz_poly2str(den));
fprintf('  Specs:\n');
fprintf('    OS_pct = %.4g %%\n', OS_pct);
fprintf('    %s     = %.4g s\n', spec_type, time_val);
fprintf('  Options:\n');
fprintf('    Integral action : %s\n', wiz_yesno_str(use_integral));
fprintf('    Observer factor : %g\n\n', obs_mult);

confirm = wiz_get_choice('  Proceed? [yes / no] > ', {'yes','y','no','n'});
if ismember(lower(strtrim(confirm)), {'no','n'})
    fprintf('\n  Cancelled. Re-run exam_wizard to start over.\n\n');
    return;
end

% ================================================================
%  STEP 5 — Run the design pipeline
% ================================================================
fprintf('\n-- Step 5: Running Design Pipeline --\n\n');

specs.OS_pct        = OS_pct;
specs.(spec_type)   = time_val;
specs.spec_type     = spec_type;
specs.obs_multiplier = obs_mult;
specs.use_integral  = use_integral;

result = full_system_design(num, den, specs);

n_sys = size(result.A_phase, 1);

% ================================================================
%  STEP 6 — Exam-ready output
% ================================================================
fprintf('\n');
fprintf('=====================================================\n');
fprintf('   DESIGN RESULTS\n');
fprintf('=====================================================\n\n');

fprintf('Parsed Inputs\n');
fprintf('  G(s) = ( %s ) / ( %s )\n', wiz_poly2str(num), wiz_poly2str(den));
fprintf('  OS_pct = %.4g %%, %s = %.4g s\n', OS_pct, spec_type, time_val);
fprintf('  Integral action: %s  |  Observer factor: %g\n\n', ...
    wiz_yesno_str(use_integral), obs_mult);

fprintf('Computed Design\n');
fprintf('  zeta  = %.4f        wn    = %.4f rad/s\n', result.zeta, result.wn);
fprintf('  sigma = %.4f        wd    = %.4f rad/s\n', result.sigma, result.wd);
fprintf('\n  Target closed-loop poles:\n');
for k = 1:numel(result.desired_poles)
    fprintf('    p%d = %s\n', k, wiz_cpx_str(result.desired_poles(k)));
end
fprintf('\n  K  = [%s]\n', num2str(result.K, '%.6g '));
if ~isempty(result.ke)
    fprintf('  Ki = %.6g\n', result.ke);
end
fprintf('\n  Target observer poles:\n');
for k = 1:numel(result.desired_obs_poles)
    fprintf('    p%d = %s\n', k, wiz_cpx_str(result.desired_obs_poles(k)));
end
fprintf('\n  L  = [%s]''\n', num2str(result.L', '%.6g '));

fprintf('\nVerification\n');
fprintf('  Closed-loop poles : %s  (max error = %.3g)\n', ...
    wiz_pass_str(result.verification.cl_pass), result.verification.cl_error);
fprintf('  Observer    poles : %s  (max error = %.3g)\n', ...
    wiz_pass_str(result.verification.obs_pass), result.verification.obs_error);

if ~result.verification.cl_pass || ~result.verification.obs_pass
    fprintf('\n  WARNING: Verification failed — check your specs or system model.\n');
end

% ================================================================
%  STEP 7 — Simulink export package
% ================================================================
export_to_simulink(result, specs, use_integral, obs_mult);

% ================================================================
%  STEP 8 — Optionally save .mat
% ================================================================
save_raw = wiz_get_choice( ...
    '\nSave workspace variables to design.mat? [yes / no] > ', ...
    {'yes','y','no','n'});
if ismember(lower(strtrim(save_raw)), {'yes','y'})
    mat_path = fullfile(pwd, 'design.mat');
    D_export = zeros(size(result.C_phase, 1), size(result.B_phase, 2));
    A_export = result.A_phase; B_export = result.B_phase;
    C_export = result.C_phase; K_export = result.K;
    L_export = result.L; poles_export = result.desired_poles;
    obs_poles_export = result.desired_obs_poles;

    if ~isempty(result.ke)
        Ki_export = result.ke;
        save(mat_path, 'A_export','B_export','C_export','D_export', ...
            'K_export','L_export','Ki_export','poles_export', ...
            'obs_poles_export','specs');
    else
        save(mat_path, 'A_export','B_export','C_export','D_export', ...
            'K_export','L_export','poles_export', ...
            'obs_poles_export','specs');
    end
    fprintf('\n  Saved to  %s\n', mat_path);
    fprintf('  Variable names: A_export, B_export, C_export, D_export,\n');
    fprintf('                  K_export, L_export, poles_export, obs_poles_export, specs\n');
    if ~isempty(result.ke)
        fprintf('                  Ki_export\n');
    end
end

fprintf('\nDone. Inspect  wizard_result  in the workspace for all design details.\n\n');

% ================================================================
%  LOCAL HELPER FUNCTIONS
% ================================================================

function v = wiz_get_vector(prompt_str)
% Read a space-separated list of numbers from the user.
    while true
        raw = input(prompt_str, 's');
        if strcmp(strtrim(raw), 'q')
            error('exam_wizard:quit', 'Wizard quit by user.');
        end
        v = str2num(raw); %#ok<ST2NM>
        if ~isempty(v)
            return;
        end
        fprintf('  Could not parse. Enter space-separated numbers, e.g.  1 6 15\n');
    end
end

function v = wiz_get_scalar(prompt_str)
% Read a single number from the user.
    while true
        raw = input(prompt_str, 's');
        if strcmp(strtrim(raw), 'q')
            error('exam_wizard:quit', 'Wizard quit by user.');
        end
        v = str2double(raw);
        if ~isnan(v)
            return;
        end
        fprintf('  Could not parse a number. Try again.\n');
    end
end

function v = wiz_get_choice(prompt_str, valid_choices)
% Read one of a fixed set of choices from the user (case-insensitive).
    while true
        raw = input(prompt_str, 's');
        if strcmp(strtrim(raw), 'q')
            error('exam_wizard:quit', 'Wizard quit by user.');
        end
        if ismember(lower(strtrim(raw)), lower(valid_choices))
            v = raw;
            return;
        end
        fprintf('  Invalid. Please enter one of: %s\n', strjoin(valid_choices, ' / '));
    end
end

function s = wiz_poly2str(c)
% Return a readable polynomial string from a coefficient vector.
%   e.g.  [1 6 15]  ->  's^2 + 6 s + 15'
    n = numel(c) - 1;
    terms = {};
    for k = 1:numel(c)
        coeff = c(k);
        power = n - k + 1;
        if coeff == 0; continue; end
        if power == 0
            terms{end+1} = sprintf('%.6g', coeff); %#ok<AGROW>
        elseif power == 1
            if coeff == 1
                terms{end+1} = 's'; %#ok<AGROW>
            else
                terms{end+1} = sprintf('%.6g s', coeff); %#ok<AGROW>
            end
        else
            if coeff == 1
                terms{end+1} = sprintf('s^%d', power); %#ok<AGROW>
            else
                terms{end+1} = sprintf('%.6g s^%d', coeff, power); %#ok<AGROW>
            end
        end
    end
    if isempty(terms)
        s = '0';
    else
        s = strjoin(terms, ' + ');
    end
end

function s = wiz_cpx_str(z)
% Format a complex number as "a + bi" or "a - bi".
    re = real(z); im = imag(z);
    if im == 0
        s = sprintf('%.6g', re);
    elseif im > 0
        s = sprintf('%.6g + %.6gi', re, im);
    else
        s = sprintf('%.6g - %.6gi', re, abs(im));
    end
end

function s = wiz_yesno_str(flag)
    if flag; s = 'yes'; else; s = 'no'; end
end

function s = wiz_pass_str(flag)
    if flag; s = 'PASS'; else; s = 'FAIL'; end
end
