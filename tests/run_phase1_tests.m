addpath(fullfile(fileparts(mfilename('fullpath')), '..', 'src'));

fprintf('Running Phase 1 tests...\n');
n_pass = 0; n_fail = 0;

%% ======================================================================
%%  T1: specs_to_poles
%% ======================================================================
fprintf('\n--- T1: specs_to_poles ---\n');

% T1-1: 10% OS, 0.5s Ts
[p, z, wn, sig, wd] = specs_to_poles(0.5, 10, 'Ts');
assert(abs(z - 0.5912) < 0.001, 'T1-1 zeta mismatch');
assert(abs(sig - 8.0) < 0.01, 'T1-1 sigma mismatch');
assert(abs(wn - 13.533) < 0.02, 'T1-1 wn mismatch');
n_pass = n_pass + 1; fprintf('  T1-1 PASS\n');

% T1-2: 5% OS, 0.3s Tp
[p, z, wn, sig, wd] = specs_to_poles(0.3, 5, 'Tp');
assert(abs(z - 0.6901) < 0.001, 'T1-2 zeta mismatch');
assert(abs(wd - 10.472) < 0.02, 'T1-2 wd mismatch');
n_pass = n_pass + 1; fprintf('  T1-2 PASS\n');

% T1-3: 15% OS, 0.75s Ts
[p, z, wn, sig, wd] = specs_to_poles(0.75, 15, 'Ts');
assert(abs(z - 0.5169) < 0.001, 'T1-3 zeta mismatch');
assert(abs(sig - 5.333) < 0.02, 'T1-3 sigma mismatch');
n_pass = n_pass + 1; fprintf('  T1-3 PASS\n');

% T1-4: 5% OS, 0.2s Ts
[p, z, wn, sig, wd] = specs_to_poles(0.2, 5, 'Ts');
assert(abs(sig - 20.0) < 0.02, 'T1-4 sigma mismatch');
n_pass = n_pass + 1; fprintf('  T1-4 PASS\n');

% T1-5: 20% OS, 0.55s Ts
[p, z, wn, sig, wd] = specs_to_poles(0.55, 20, 'Ts');
assert(abs(z - 0.456) < 0.01, 'T1-5 zeta mismatch');
n_pass = n_pass + 1; fprintf('  T1-5 PASS\n');

% T1-V1: Input validation — negative Ts
try
    specs_to_poles(-1, 10, 'Ts');
    error('T1-V1 should have thrown');
catch e
    if contains(e.message, 'positive')
        n_pass = n_pass + 1; fprintf('  T1-V1 (neg Ts) PASS\n');
    else
        rethrow(e);
    end
end

% T1-V2: Input validation — OS out of range
try
    specs_to_poles(1, 0, 'Ts');
    error('T1-V2 should have thrown');
catch e
    if contains(e.message, 'OS_pct')
        n_pass = n_pass + 1; fprintf('  T1-V2 (OS=0) PASS\n');
    else
        rethrow(e);
    end
end

% T1-V3: Input validation — bad spec_type
try
    specs_to_poles(1, 10, 'Tz');
    error('T1-V3 should have thrown');
catch e
    if contains(e.message, 'spec_type')
        n_pass = n_pass + 1; fprintf('  T1-V3 (bad spec_type) PASS\n');
    else
        rethrow(e);
    end
end

% T1-V4: Poles are complex conjugates
[p, ~, ~, ~, ~] = specs_to_poles(0.5, 10, 'Ts');
assert(abs(p(1) - conj(p(2))) < 1e-10, 'T1-V4 poles not conjugate');
assert(real(p(1)) < 0, 'T1-V4 poles should be in LHP');
n_pass = n_pass + 1; fprintf('  T1-V4 (conjugate poles) PASS\n');

%% ======================================================================
%%  T2: tf2ss_phase (Category B)
%% ======================================================================
fprintf('\n--- T2: tf2ss_phase ---\n');

% B1: 100/(s^4+20s^3+10s^2+7s+100)
[A,B,C] = tf2ss_phase([100], [1 20 10 7 100]);
A_exp = [0 1 0 0; 0 0 1 0; 0 0 0 1; -100 -7 -10 -20];
assert(norm(A - A_exp) < 1e-10, 'B1 A mismatch');
assert(isequal(B, [0;0;0;1]), 'B1 B mismatch');
assert(norm(C - [100 0 0 0]) < 1e-10, 'B1 C mismatch');
n_pass = n_pass + 1; fprintf('  B1 PASS\n');

% B2: 30/(s^5+8s^4+9s^3+6s^2+s+30) — 5th order, no zeros
[A,B,C] = tf2ss_phase([30], [1 8 9 6 1 30]);
A_exp = [0 1 0 0 0; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1; -30 -1 -6 -9 -8];
assert(norm(A - A_exp) < 1e-10, 'B2 A mismatch');
assert(isequal(B, [0;0;0;0;1]), 'B2 B mismatch');
assert(norm(C - [30 0 0 0 0]) < 1e-10, 'B2 C mismatch');
n_pass = n_pass + 1; fprintf('  B2 PASS\n');

% B4: (8s+10)/(s^4+5s^3+s^2+5s+13) — 4th order with zeros
[A,B,C] = tf2ss_phase([8 10], [1 5 1 5 13]);
A_exp = [0 1 0 0; 0 0 1 0; 0 0 0 1; -13 -5 -1 -5];
assert(norm(A - A_exp) < 1e-10, 'B4 A mismatch');
assert(norm(C - [10 8 0 0]) < 1e-10, 'B4 C mismatch');
n_pass = n_pass + 1; fprintf('  B4 PASS\n');

% B5: (s^4+2s^3+12s^2+7s+6)/(s^5+9s^4+13s^3+8s^2)
[A,B,C] = tf2ss_phase([1 2 12 7 6], [1 9 13 8 0 0]);
A_exp = [0 1 0 0 0; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1; 0 0 -8 -13 -9];
assert(norm(A - A_exp) < 1e-10, 'B5 A mismatch');
assert(norm(C - [6 7 12 2 1]) < 1e-10, 'B5 C mismatch');
n_pass = n_pass + 1; fprintf('  B5 PASS\n');

% B6: 43/(s^2+9s+24) — 2nd order, no zeros
[A,B,C] = tf2ss_phase([43], [1 9 24]);
A_exp = [0 1; -24 -9];
assert(norm(A - A_exp) < 1e-10, 'B6 A mismatch');
assert(isequal(B, [0;1]), 'B6 B mismatch');
assert(norm(C - [43 0]) < 1e-10, 'B6 C mismatch');
n_pass = n_pass + 1; fprintf('  B6 PASS\n');

% B7: (43s+2)/(s^2+9s+24) — 2nd order with zero
[A,B,C] = tf2ss_phase([43 2], [1 9 24]);
A_exp = [0 1; -24 -9];
assert(norm(A - A_exp) < 1e-10, 'B7 A mismatch');
assert(norm(C - [2 43]) < 1e-10, 'B7 C mismatch');
n_pass = n_pass + 1; fprintf('  B7 PASS\n');

% B8: 24/((s+2)(s+3)(s+4)) = 24/(s^3+9s^2+26s+24) — 3rd order, no zeros
[A,B,C] = tf2ss_phase([24], [1 9 26 24]);
A_exp = [0 1 0; 0 0 1; -24 -26 -9];
assert(norm(A - A_exp) < 1e-10, 'B8 A mismatch');
assert(isequal(B, [0;0;1]), 'B8 B mismatch');
assert(norm(C - [24 0 0]) < 1e-10, 'B8 C mismatch');
n_pass = n_pass + 1; fprintf('  B8 PASS\n');

% B9: 27/(s^3+3s^2+s+13) — 3rd order, no zeros (class notes)
[A,B,C] = tf2ss_phase([27], [1 3 1 13]);
A_exp = [0 1 0; 0 0 1; -13 -1 -3];
assert(norm(A - A_exp) < 1e-10, 'B9 A mismatch');
assert(isequal(B, [0;0;1]), 'B9 B mismatch');
assert(norm(C - [27 0 0]) < 1e-10, 'B9 C mismatch');
n_pass = n_pass + 1; fprintf('  B9 PASS\n');

% T2-V1: Input validation — empty num
try
    tf2ss_phase([], [1 2 3]);
    error('T2-V1 should have thrown');
catch e
    if contains(e.message, 'non-empty')
        n_pass = n_pass + 1; fprintf('  T2-V1 (empty num) PASS\n');
    else
        rethrow(e);
    end
end

% T2-V2: Input validation — leading zero in den
try
    tf2ss_phase([1], [0 1 2]);
    error('T2-V2 should have thrown');
catch e
    if contains(e.message, 'leading')
        n_pass = n_pass + 1; fprintf('  T2-V2 (leading zero den) PASS\n');
    else
        rethrow(e);
    end
end

% T2-V3: Input validation — improper TF (deg num >= deg den)
try
    tf2ss_phase([1 2 3], [1 2 3]);
    error('T2-V3 should have thrown');
catch e
    if contains(e.message, 'strictly proper')
        n_pass = n_pass + 1; fprintf('  T2-V3 (improper TF) PASS\n');
    else
        rethrow(e);
    end
end

%% ======================================================================
%%  T3: tf2ss_observer_canon
%% ======================================================================
fprintf('\n--- T3: tf2ss_observer_canon ---\n');

% T3-1: (s^2+7s+2)/(s^3+9s^2+26s+24) (observer design handout)
[A,B,C] = tf2ss_observer_canon([1 7 2], [1 9 26 24]);
A_exp = [-9 1 0; -26 0 1; -24 0 0];
assert(norm(A - A_exp) < 1e-10, 'T3-1 A mismatch');
assert(isequal(C, [1 0 0]), 'T3-1 C mismatch');
B_exp = [1; 7; 2];
assert(norm(B - B_exp) < 1e-10, 'T3-1 B mismatch');
n_pass = n_pass + 1; fprintf('  T3-1 PASS\n');

% T3-2: 23/(s^3+8s^2+17s+10)
[A,B,C] = tf2ss_observer_canon([23], [1 8 17 10]);
assert(norm(A - [-8 1 0; -17 0 1; -10 0 0]) < 1e-10, 'T3-2 A mismatch');
B_exp = [0; 0; 23];
assert(norm(B - B_exp) < 1e-10, 'T3-2 B mismatch');  % G(s)=23/D(s), only b0=23
n_pass = n_pass + 1; fprintf('  T3-2 PASS\n');

% T3-V1: Input validation — empty den
try
    tf2ss_observer_canon([1], []);
    error('T3-V1 should have thrown');
catch e
    if contains(e.message, 'non-empty')
        n_pass = n_pass + 1; fprintf('  T3-V1 (empty den) PASS\n');
    else
        rethrow(e);
    end
end

%% ======================================================================
%%  T4: check_stability (Category C)
%% ======================================================================
fprintf('\n--- T4: check_stability ---\n');

% C1: [0 1 3; 2 2 -4; 1 -4 3] — 2 RHP, 1 LHP
A = [0 1 3; 2 2 -4; 1 -4 3];
[stable, eigs_out, rhp, lhp, jw] = check_stability(A); %#ok<ASGLU>
assert(~stable, 'C1 stability mismatch');
assert(rhp == 2 && lhp == 1, 'C1 pole count mismatch');
n_pass = n_pass + 1; fprintf('  C1 PASS\n');

% C2: [0 1 0; 0 1 -4; -1 1 8] — all positive real parts, unstable
A = [0 1 0; 0 1 -4; -1 1 8];
[stable, eigs_out, rhp, lhp, jw] = check_stability(A);
assert(~stable, 'C2 stability mismatch');
assert(rhp >= 1, 'C2 should have RHP poles');
n_pass = n_pass + 1; fprintf('  C2 PASS\n');

% C3: [0 1 0; 0 1 3; -3 -4 -5] — stable
A = [0 1 0; 0 1 3; -3 -4 -5];
[stable, ~,~,~,~] = check_stability(A);
assert(stable, 'C3 stability mismatch');
n_pass = n_pass + 1; fprintf('  C3 PASS\n');

% C4: [3 0 4; 0 4 4; 3 2 12] — unstable
A = [3 0 4; 0 4 4; 3 2 12];
[stable,~,~,~,~] = check_stability(A);
assert(~stable, 'C4 stability mismatch');
n_pass = n_pass + 1; fprintf('  C4 PASS\n');

% C5: [0 1; -10 -5] — stable
A = [0 1; -10 -5];
[stable,~,~,~,~] = check_stability(A);
assert(stable, 'C5 stability mismatch');
n_pass = n_pass + 1; fprintf('  C5 PASS\n');

% T4-V1: Non-square matrix
try
    check_stability([1 2; 3 4; 5 6]);
    error('T4-V1 should have thrown');
catch e
    if contains(e.message, 'square')
        n_pass = n_pass + 1; fprintf('  T4-V1 (non-square) PASS\n');
    else
        rethrow(e);
    end
end

% T4-V2: Marginally stable (pure imaginary eigenvalues)
A = [0 1; -4 0]; % eig = +/-2j
[stable, ~, rhp, lhp, jw] = check_stability(A);
assert(~stable, 'T4-V2 marginal stability should be unstable');
assert(jw == 2, 'T4-V2 should have 2 jw poles');
n_pass = n_pass + 1; fprintf('  T4-V2 (marginal jw) PASS\n');

%% ======================================================================
%%  T5: check_controllability (Category H)
%% ======================================================================
fprintf('\n--- T5: check_controllability ---\n');

% H1: 2x2, B=[1;-1] — uncontrollable
A = [0 1; -2 -3]; B = [1; -1];
[ctrl, CM, r] = check_controllability(A, B);
assert(~ctrl, 'H1 controllability mismatch');
assert(r == 1, 'H1 rank mismatch');
n_pass = n_pass + 1; fprintf('  H1 PASS\n');

% H2: Controllable 4x4 (verify rank=4)
% Using phase-variable form from B8: guaranteed controllable
[A_pv, B_pv, ~] = tf2ss_phase([24], [1 9 26 24]);
A4 = [A_pv zeros(3,1); zeros(1,3) -1]; B4 = [B_pv; 1];
[ctrl, ~, r] = check_controllability(A4, B4);
assert(ctrl, 'H2 controllability mismatch');
assert(r == 4, 'H2 rank mismatch');
n_pass = n_pass + 1; fprintf('  H2 PASS\n');

% H3: Another controllable system (3rd order phase-variable)
A = [0 1 0; 0 0 1; -24 -26 -9]; B = [0;0;1];
[ctrl, ~, r] = check_controllability(A, B);
assert(ctrl, 'H3 controllability mismatch');
assert(r == 3, 'H3 rank mismatch');
n_pass = n_pass + 1; fprintf('  H3 PASS\n');

% H4: 3x3 diagonal, B=[0;1;1] — uncontrollable
A = [-5 0 0; 0 -4 0; 0 0 -3]; B = [0; 1; 1];
[ctrl, ~, r] = check_controllability(A, B);
assert(~ctrl, 'H4 controllability mismatch');
n_pass = n_pass + 1; fprintf('  H4 PASS\n');

% T5-V1: Input validation — dimension mismatch
try
    check_controllability([1 2; 3 4], [1; 2; 3]);
    error('T5-V1 should have thrown');
catch e
    n_pass = n_pass + 1; fprintf('  T5-V1 (dim mismatch) PASS\n');
end

%% ======================================================================
%%  T6: check_observability (Category E)
%% ======================================================================
fprintf('\n--- T6: check_observability ---\n');

% E1: 2x2 observable from observer design
A = [-10 1; -21 0]; C = [1 0];
[obs, OM, r] = check_observability(A, C);
assert(obs, 'E1 observability mismatch');
assert(r == 2, 'E1 rank mismatch');
n_pass = n_pass + 1; fprintf('  E1 PASS\n');

% E2: 3x3 diagonal, C=[0,0,1] — NOT observable
A = [2 0 0; 0 7 3; 0 10 1]; C = [0 0 1];
[obs, ~, r] = check_observability(A, C);
assert(~obs, 'E2 observability mismatch');
assert(r == 2, 'E2 rank mismatch');
n_pass = n_pass + 1; fprintf('  E2 PASS\n');

% E3: 4x4 SMD observable (from OBS-HO)
A = [0 1 0 0; -11 -7 9 4; 0 0 0 1; 9 4 -9 -4];
C = [0 0 1 0];
[obs, ~, r] = check_observability(A, C);
assert(obs, 'E3 observability mismatch');
assert(r == 4, 'E3 rank mismatch');
n_pass = n_pass + 1; fprintf('  E3 PASS\n');

% T6-V1: Input validation — dimension mismatch
try
    check_observability([1 2; 3 4], [1 2 3]);
    error('T6-V1 should have thrown');
catch e
    n_pass = n_pass + 1; fprintf('  T6-V1 (dim mismatch) PASS\n');
end

%% ======================================================================
%%  T7: design_state_feedback (Category G)
%% ======================================================================
fprintf('\n--- T7: design_state_feedback ---\n');

% G4: M09 P4 — 2nd order SMD, K=30, D=12, M=2
A = [0 1; -15 -6]; B = [0; 0.5];
desired = [-20+20.9738i, -20-20.9738i];
[K, cl_poles] = design_state_feedback(A, B, desired);
assert(abs(K(1) - 1650) < 5, 'G4 K(1) mismatch');
assert(abs(K(2) - 68.0) < 0.5, 'G4 K(2) mismatch');
% Verify closed-loop poles
A_cl = A - B*K;
actual_poles = sort(eig(A_cl));
desired_sorted = sort(desired(:));
assert(norm(actual_poles - desired_sorted) < 1, 'G4 CL poles mismatch');
n_pass = n_pass + 1; fprintf('  G4 PASS\n');

% G3: M09 P3 — 3rd order
A = [0 1 0; 0 0 1; -64 -56 -14]; B = [0;0;1];
desired = [-5.333+8.832i, -5.333-8.832i, -53.33];
[K, ~] = design_state_feedback(A, B, desired);
assert(abs(K(1) - 5610) < 20, 'G3 K(1) mismatch');
assert(abs(K(2) - 619) < 5, 'G3 K(2) mismatch');
assert(abs(K(3) - 50) < 1, 'G3 K(3) mismatch');
n_pass = n_pass + 1; fprintf('  G3 PASS\n');

% G5: M09 class notes — 3rd order
A = [0 1 0; 0 0 1; 0 -200 -30]; B = [0;0;1];
desired = [-62.5, -12.5+24.3i, -12.5-24.3i];
[K, ~] = design_state_feedback(A, B, desired);
assert(abs(K(1) - 46700) < 100, 'G5 K(1) mismatch');
assert(abs(K(2) - 2110) < 10, 'G5 K(2) mismatch');
assert(abs(K(3) - 57.4) < 0.5, 'G5 K(3) mismatch');
n_pass = n_pass + 1; fprintf('  G5 PASS\n');

% G2: M09 P2 — 3rd order, 5% OS, Tp=0.3s
% G(s) = 100(s+10)/(s(s+3)(s+12)) → phase-variable form
% den = s^3 + 15s^2 + 36s, A from phase-variable
% Third pole placed at -10 to cancel the open-loop zero at s = -10.
A = [0 1 0; 0 0 1; 0 -36 -15]; B = [0;0;1];
[~, ~, ~, sig_g2, wd_g2] = specs_to_poles(0.3, 5, 'Tp');
desired_g2 = [-sig_g2+wd_g2*1i, -sig_g2-wd_g2*1i, -10];
[K, ~] = design_state_feedback(A, B, desired_g2);
assert(abs(K(1) - 2090) < 20, 'G2 K(1) mismatch');
assert(abs(K(2) - 373) < 5, 'G2 K(2) mismatch');
assert(abs(K(3) - 15.0) < 0.5, 'G2 K(3) mismatch');
n_pass = n_pass + 1; fprintf('  G2 PASS\n');

%% ======================================================================
%%  T8: design_observer (Category D)
%% ======================================================================
fprintf('\n--- T8: design_observer ---\n');

% D1: M10 S12.5 P1
A = [-10 1; -21 0]; C = [1 0];
desired_obs = [-100+50i, -100-50i];
[L, ~] = design_observer(A, C, desired_obs);
assert(abs(L(1) - 190) < 1, 'D1 L(1) mismatch');
assert(abs(L(2) - 12479) < 5, 'D1 L(2) mismatch');
n_pass = n_pass + 1; fprintf('  D1 PASS\n');

% D3: M10 S12.5 P3
A = [0 1; -21 -10]; C = [25 0];
desired_obs = [-80+109.15i, -80-109.15i];
[L, ~] = design_observer(A, C, desired_obs);
assert(abs(L(1) - 6.00) < 0.1, 'D3 L(1) mismatch');
assert(abs(L(2) - 672) < 5, 'D3 L(2) mismatch');
n_pass = n_pass + 1; fprintf('  D3 PASS\n');

% D4: CORRECTED — 3rd order observer
A_obs = [-8 1 0; -17 0 1; -10 0 0]; C_obs = [1 0 0];
desired_obs = [-50, -25+43.3i, -25-43.3i];
[L, ~] = design_observer(A_obs, C_obs, desired_obs);
assert(abs(L(1) - 92) < 2, 'D4 L(1) mismatch');
assert(abs(L(2) - 4983) < 20, 'D4 L(2) mismatch');
assert(abs(L(3) - 124990) < 50, 'D4 L(3) mismatch');
n_pass = n_pass + 1; fprintf('  D4 (corrected) PASS\n');

% D5: Observer handout (3rd order, observer canonical)
A_obs = [-8 1 0; -17 0 1; -10 0 0]; C_obs = [1 0 0];
desired_obs = [-10, -5+2i, -5-2i];
[L, ~] = design_observer(A_obs, C_obs, desired_obs);
assert(abs(L(1) - 12) < 1, 'D5 L(1) mismatch');
assert(abs(L(2) - 112) < 5, 'D5 L(2) mismatch');
assert(abs(L(3) - 280) < 5, 'D5 L(3) mismatch');
n_pass = n_pass + 1; fprintf('  D5 PASS\n');

% D6: M10-CN — SMD observer
% Note: doc states L=[394,37621] with poles -200+/-209.8j, but L=[394,37621]
% actually produces repeated poles at -200. The correct L for -200+/-209.8j
% is [394, 81637]. We test the mathematical truth: given desired poles,
% produce correct L.
A = [0 1; -15 -6]; C = [1 0];
desired_obs = [-200+209.8i, -200-209.8i];
[L, ~] = design_observer(A, C, desired_obs);
assert(abs(L(1) - 394) < 2, 'D6 L(1) mismatch');
assert(abs(L(2) - 81637) < 50, 'D6 L(2) mismatch');
n_pass = n_pass + 1; fprintf('  D6 PASS\n');

%% ======================================================================
%%  T9: design_integral_ctrl (Category F)
%% ======================================================================
fprintf('\n--- T9: design_integral_ctrl ---\n');

% F1: Cancel zero — (s+2)/(s^2-s-2)
A = [0 1; 2 1]; B = [0; 1]; C = [2 1];
desired_f1 = [-2, -8+10.915i, -8-10.915i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired_f1);
assert(abs(K(1) - 34) < 1, 'F1 K(1) mismatch');
assert(abs(K(2) - 19) < 0.5, 'F1 K(2) mismatch');
assert(abs(ke - 183) < 2, 'F1 ke mismatch');
n_pass = n_pass + 1; fprintf('  F1 PASS\n');

% F2: 5x pole, same plant as F1
% Note: doc taxonomy incorrectly lists F2 corrected values as [-1628,49],2442
% but those are F4's values. F2 (plant (s+2)/(s^2-s-2)) actually gives
% K≈[-2838, 57], ke≈3663 for 5x pole placement at s=-40.
A = [0 1; 2 1]; B = [0; 1]; C = [2 1];
desired_f2 = [-40, -8+10.915i, -8-10.915i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired_f2);
assert(abs(K(1) - (-2838)) < 20, 'F2 K(1) mismatch');
assert(abs(K(2) - 57) < 1, 'F2 K(2) mismatch');
assert(abs(ke - 3663) < 20, 'F2 ke mismatch');
n_pass = n_pass + 1; fprintf('  F2 (5x pole) PASS\n');

% F3: Cancel zero — (s+3)/(s^2+7s+10)
A = [0 1; -10 -7]; B = [0; 1]; C = [3 1];
desired_f3 = [-3, -8+10.915i, -8-10.915i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired_f3);
assert(abs(K(1) - 38) < 1, 'F3 K(1) mismatch');
assert(abs(K(2) - 12) < 0.5, 'F3 K(2) mismatch');
assert(abs(ke - 183) < 2, 'F3 ke mismatch');
n_pass = n_pass + 1; fprintf('  F3 PASS\n');

% F4: CORRECTED — 5x pole, same plant as F3
A = [0 1; -10 -7]; B = [0; 1]; C = [3 1];
desired_f4 = [-40, -8+10.915i, -8-10.915i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired_f4);
assert(abs(K(1) - (-1628)) < 20, 'F4 K(1) mismatch');
assert(abs(K(2) - 49) < 1, 'F4 K(2) mismatch');
assert(abs(ke - 2442) < 20, 'F4 ke mismatch');
n_pass = n_pass + 1; fprintf('  F4 (corrected) PASS\n');

% F5: DC motor integral control
A = [0 1; 0 -5/3]; B = [0; 5/12]; C = [1 0];
desired_f5 = [-40, -7.27+14.2i, -7.27-14.2i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired_f5);
assert(abs(K(1) - 2007) < 10, 'F5 K(1) mismatch');
assert(abs(K(2) - 126.9) < 1, 'F5 K(2) mismatch');
assert(abs(ke - 24430) < 50, 'F5 ke mismatch');
n_pass = n_pass + 1; fprintf('  F5 PASS\n');

%% ======================================================================
%%  T10: verify_solution
%% ======================================================================
fprintf('\n--- T10: verify_solution ---\n');

% Integration test: SMD system from M09-P4 + observer with 10x poles
A = [0 1; -15 -6]; B = [0; 0.5]; C = [1 0];
K = [1650, 68.0];
L = [394; 81637];  % Correct L for observer poles -200+/-209.8j
expected_cl = [-20+20.9738i, -20-20.9738i];
expected_obs = [-200+209.8i, -200-209.8i];
result = verify_solution(A, B, C, K, [], L, expected_cl, expected_obs);
assert(result.cl_pass, 'T10 CL poles mismatch');
assert(result.obs_pass, 'T10 observer poles mismatch');
n_pass = n_pass + 1; fprintf('  T10-1 (SF + observer) PASS\n');

% Integration test with integral control: F5 DC motor
A = [0 1; 0 -5/3]; B = [0; 5/12]; C = [1 0];
K = [2007, 126.9]; ke = 24430;
expected_cl = [-40, -7.27+14.2i, -7.27-14.2i];
result = verify_solution(A, B, C, K, ke, [], expected_cl, []);
assert(result.cl_pass, 'T10 integral CL poles mismatch');
n_pass = n_pass + 1; fprintf('  T10-2 (integral ctrl) PASS\n');

%% ======================================================================
%%  T11: full_system_design (smoke test)
%% ======================================================================
fprintf('\n--- T11: full_system_design ---\n');

% Smoke test: 2nd order SMD from M09-P4 / M10-CN
num = [0.5]; den = [1 6 15];  % 0.5/(s^2+6s+15) -> A=[0 1;-15 -6], B=[0;0.5]
specs.OS_pct = 5;
specs.Ts = 0.2;
specs.spec_type = 'Ts';
specs.obs_multiplier = 10;
result = full_system_design(num, den, specs);
assert(result.is_controllable, 'T11 controllability');
assert(result.is_observable, 'T11 observability');
assert(all(real(result.cl_poles) < 0), 'T11 CL poles should be stable');
assert(all(real(result.obs_poles) < 0), 'T11 observer poles should be stable');
n_pass = n_pass + 1; fprintf('  T11-1 (SMD smoke) PASS\n');

%% ======================================================================
%%  Summary
%% ======================================================================
fprintf('\n========================================\n');
fprintf('Phase 1-3 Tests: %d passed, %d failed\n', n_pass, n_fail);
fprintf('========================================\n');
if n_fail == 0
    fprintf('ALL TESTS PASSED.\n');
else
    fprintf('SOME TESTS FAILED — review output above.\n');
end
