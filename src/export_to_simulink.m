function export_to_simulink(result, specs, use_integral, obs_mult)
% EXPORT_TO_SIMULINK  Export design variables to workspace and print Simulink checklist.
%
%   export_to_simulink(result, specs, use_integral, obs_mult)
%
%   Called automatically by exam_wizard.  Can also be called manually
%   after running full_system_design:
%
%     result = full_system_design(num, den, specs);
%     export_to_simulink(result, specs, specs.use_integral, specs.obs_multiplier);
%
%   WHAT THIS DOES:
%     1. Assigns A, B, C, D, K, L (and Ki if integral) to the MATLAB base
%        workspace, ready to be referenced by variable name in Simulink
%        block dialog boxes.
%     2. Prints a block-connection checklist tailored to whether integral
%        action is included.
%     3. Lists all assumptions so you can flag inconsistencies before sim.
%
%   WORKSPACE VARIABLES ASSIGNED:
%     A, B, C, D          — state-space matrices (phase-variable form)
%     K                   — state-feedback row vector  (1-by-n)
%     L                   — observer column vector     (n-by-1)
%     Ki                  — integral gain scalar (only if use_integral)
%     poles               — desired closed-loop pole locations
%     obs_poles           — desired observer pole locations
%     specs               — specs struct passed in
%     wizard_result       — the full result struct from full_system_design
%
%   See also: exam_wizard, full_system_design, verify_solution

n_sys = size(result.A_phase, 1);
D = zeros(size(result.C_phase, 1), size(result.B_phase, 2));

% ---- Assign to MATLAB base workspace ----
assignin('base', 'A',            result.A_phase);
assignin('base', 'B',            result.B_phase);
assignin('base', 'C',            result.C_phase);
assignin('base', 'D',            D);
assignin('base', 'K',            result.K);
assignin('base', 'L',            result.L);
assignin('base', 'poles',        result.desired_poles);
assignin('base', 'obs_poles',    result.desired_obs_poles);
assignin('base', 'specs',        specs);
assignin('base', 'wizard_result', result);

if ~isempty(result.ke)
    assignin('base', 'Ki', result.ke);
end

% ---- Print export package ----
fprintf('\n');
fprintf('=====================================================\n');
fprintf('   SIMULINK EXPORT PACKAGE\n');
fprintf('=====================================================\n\n');

fprintf('Workspace variables now available:\n\n');
fprintf('  %-14s  %s\n', 'Variable', 'Description');
fprintf('  %-14s  %s\n', repmat('-',1,14), repmat('-',1,40));
fprintf('  %-14s  State matrix (%d x %d)\n',      'A', n_sys, n_sys);
fprintf('  %-14s  Input matrix (%d x 1)\n',       'B', n_sys);
fprintf('  %-14s  Output matrix (1 x %d)\n',      'C', n_sys);
fprintf('  %-14s  Direct term matrix (zeros)\n',  'D');
fprintf('  %-14s  State-feedback gain (1 x %d)\n','K', n_sys);
fprintf('  %-14s  Observer gain (%d x 1)\n',      'L', n_sys);
if ~isempty(result.ke)
    fprintf('  %-14s  Integral gain scalar\n',    'Ki');
end
fprintf('  %-14s  Desired CL poles (%d x 1)\n',  'poles', n_sys);
fprintf('  %-14s  Desired observer poles\n',      'obs_poles');
fprintf('  %-14s  Full design result struct\n\n', 'wizard_result');

fprintf('Values:\n');
fprintf('  A =\n'); disp(result.A_phase);
fprintf('  B'' = [%s]\n', num2str(result.B_phase', '%.6g '));
fprintf('  C  = [%s]\n', num2str(result.C_phase, '%.6g '));
fprintf('  K  = [%s]\n', num2str(result.K, '%.6g '));
fprintf('  L'' = [%s]\n\n', num2str(result.L', '%.6g '));
if ~isempty(result.ke)
    fprintf('  Ki = %.6g\n\n', result.ke);
end

% ---- Simulink block-connection checklist ----
fprintf('Simulink Block-Connection Checklist\n');
fprintf('(tick each box as you connect blocks)\n\n');

if use_integral
    fprintf('  System type: State feedback with integral control + observer\n\n');

    fprintf('  [ ] Plant  (State-Space block)\n');
    fprintf('      Parameters: A=A, B=B, C=C, D=D\n');
    fprintf('      Input:  control signal u\n');
    fprintf('      Output: measured output y\n\n');

    fprintf('  [ ] Observer  (State-Space block)\n');
    fprintf('      A_obs = A - L*C      Enter in MATLAB: A - L*C\n');
    fprintf('      B_obs = [B, L]       Enter in MATLAB: [B, L]\n');
    fprintf('      C_obs = eye(%d)\n', n_sys);
    fprintf('      D_obs = zeros(%d,2)\n', n_sys);
    fprintf('      Inputs:  [u ; y_plant]  (Mux two signals)\n');
    fprintf('      Output:  x_hat  (%d-element state estimate)\n\n', n_sys);

    fprintf('  [ ] State-feedback gain  (Gain block)\n');
    fprintf('      Value: K\n');
    fprintf('      Input: x_hat from observer\n');
    fprintf('      Output: K*x_hat  (negate at the summing junction)\n\n');

    fprintf('  [ ] Error integrator  (Integrator block -> Gain block)\n');
    fprintf('      Error signal: e = r - y  (summing junction: +-)\n');
    fprintf('      Integrator output goes into a Gain block with value Ki\n\n');

    fprintf('  [ ] Control summing junction\n');
    fprintf('      u = -K*x_hat + Ki * integral(e)\n\n');
else
    fprintf('  System type: State feedback + observer  (no integral action)\n\n');

    fprintf('  [ ] Plant  (State-Space block)\n');
    fprintf('      Parameters: A=A, B=B, C=C, D=D\n');
    fprintf('      Input:  control signal u\n');
    fprintf('      Output: measured output y\n\n');

    fprintf('  [ ] Observer  (State-Space block)\n');
    fprintf('      A_obs = A - L*C      Enter in MATLAB: A - L*C\n');
    fprintf('      B_obs = [B, L]       Enter in MATLAB: [B, L]\n');
    fprintf('      C_obs = eye(%d)\n', n_sys);
    fprintf('      D_obs = zeros(%d,2)\n', n_sys);
    fprintf('      Inputs:  [u ; y_plant]  (Mux two signals)\n');
    fprintf('      Output:  x_hat  (%d-element state estimate)\n\n', n_sys);

    fprintf('  [ ] State-feedback gain  (Gain block)\n');
    fprintf('      Value: K\n');
    fprintf('      Input: x_hat from observer\n');
    fprintf('      Output: K*x_hat  (negate at control summing junction)\n\n');

    fprintf('  [ ] Control summing junction\n');
    fprintf('      u = r - K*x_hat\n\n');
end

fprintf('Assumptions\n');
fprintf('  * SISO plant (single input, single output)\n');
fprintf('  * Strictly proper G(s): degree(num) < degree(den)\n');
fprintf('  * Continuous-time linear time-invariant system\n');
fprintf('  * State feedback uses phase-variable realization\n');
fprintf('  * Observer uses observer-canonical realization\n');
fprintf('  * Observer poles are placed %gx faster than CL poles\n', obs_mult);
if ~isempty(result.ke)
    fprintf('  * Integral action gives zero steady-state error to step input\n');
end
fprintf('\n');
end
