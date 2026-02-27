# CONTROL THEORY TEST PREP - UNIFIED CONTEXT DOCUMENT

## Structure
- **PART 1:** Roadmap and Copilot Instructions (consume first)
- **PART 2:** Guide / Report / Summary (reference as needed)
- **PART 3:** Converted Source Materials (consume only when indicated)
- **PART 4:** Python Verification Tools (use to test MATLAB outputs)

---

# PART 1: ROADMAP AND COPILOT INSTRUCTIONS

## Copilot Context Management Rules

**IMPORTANT: This document is structured for token-efficient consumption.**

1. **PART 1 (Roadmap):** Always consume. Contains the development plan and test specs.
2. **PART 2 (Guide/Summary):** Consume for orientation. Contains indexed topic taxonomy, formula reference, verified answer key, and textbook excerpts.
3. **PART 3 (Sources):** Do NOT consume unless specifically directed (e.g., "See Source M08-CN"). Each source is tagged with an ID for selective loading.
4. **PART 4 (Python Tools):** Consume when developing or testing MATLAB. Contains NumPy-based verification functions that serve as ground truth.

**Delegation Rule:** When a task only requires info from the summary (Part 2), do not load source materials. Only load a specific source section when:
- Implementing a tool for that problem type
- Debugging a discrepancy
- The user explicitly requests it

---

## Test/Spec-Driven Development Plan for MATLAB Tools

### Development Philosophy

Each MATLAB tool will be developed with:
1. **Spec:** Clear input/output contract with types
2. **Test Cases:** Derived from verified exercise answers (ground truth)
3. **Implementation:** MATLAB function
4. **Validation:** Cross-check against Python verification tools (Part 4)

### Tool Development Order (Dependencies Flow)

```
Phase 1 (Foundation - No Dependencies):
  T1: specs_to_poles.m
  T2: tf2ss_phase.m
  T3: tf2ss_observer_canon.m
  T4: check_stability.m

Phase 2 (Depends on Phase 1):
  T5: check_controllability.m
  T6: check_observability.m
  T7: design_state_feedback.m  (uses T1, T2)

Phase 3 (Depends on Phase 2):
  T8: design_observer.m  (uses T1, T3, T6)
  T9: design_integral_ctrl.m  (uses T1, T7)

Phase 4 (Integration):
  T10: verify_solution.m  (uses all above)
  T11: full_system_design.m  (orchestrator)
```

---

### T1: specs_to_poles.m

**Purpose:** Convert transient response specifications to desired pole locations.

**Spec:**
```matlab
function [poles, zeta, wn, sigma, wd] = specs_to_poles(Ts, OS_pct, spec_type)
% INPUTS:
%   Ts       - settling time (seconds) OR peak time if spec_type='Tp'
%   OS_pct   - percent overshoot (e.g., 10 for 10%)
%   spec_type - 'Ts' (default) or 'Tp'
% OUTPUTS:
%   poles  - complex conjugate pair [s1; s2]
%   zeta   - damping ratio
%   wn     - natural frequency
%   sigma  - real part magnitude
%   wd     - damped natural frequency
```

**Test Cases:**
```matlab
%% Test 1: 10% OS, 0.5s Ts (from M08/M10 exercises)
[p, z, wn, sig, wd] = specs_to_poles(0.5, 10, 'Ts');
assert(abs(z - 0.5912) < 0.001, 'zeta mismatch');
assert(abs(sig - 8.0) < 0.01, 'sigma mismatch');
assert(abs(wn - 13.533) < 0.01, 'wn mismatch');

%% Test 2: 5% OS, 0.3s Tp (from M09 P2)
[p, z, wn, sig, wd] = specs_to_poles(0.3, 5, 'Tp');
assert(abs(z - 0.6901) < 0.001, 'zeta mismatch');
assert(abs(wd - 10.472) < 0.01, 'wd mismatch');

%% Test 3: 15% OS, 0.75s Ts (from M09 P3)
[p, z, wn, sig, wd] = specs_to_poles(0.75, 15, 'Ts');
assert(abs(z - 0.5169) < 0.001);
assert(abs(sig - 5.333) < 0.01);

%% Test 4: 5% OS, 0.2s Ts (from M09 P4)
[p, z, wn, sig, wd] = specs_to_poles(0.2, 5, 'Ts');
assert(abs(sig - 20.0) < 0.01);

%% Test 5: 20% OS, 0.55s Ts (from integral control handout)
[p, z, wn, sig, wd] = specs_to_poles(0.55, 20, 'Ts');
assert(abs(z - 0.456) < 0.001);
```

---

### T2: tf2ss_phase.m

**Purpose:** Convert transfer function to state-space in phase-variable form.

**Spec:**
```matlab
function [A, B, C] = tf2ss_phase(num, den)
% INPUTS:
%   num - numerator coefficients (highest power first)
%   den - denominator coefficients (highest power first)
% OUTPUTS:
%   A, B, C - state-space matrices in phase-variable form
%   Convention: B = [0;...;0;1], numerator gain absorbed into C
```

**Test Cases:**
```matlab
%% Test 1: No zeros, 4th order (M08 S3.5 P1)
% G(s) = 100 / (s^4 + 20s^3 + 10s^2 + 7s + 100)
[A,B,C] = tf2ss_phase([100], [1 20 10 7 100]);
A_exp = [0 1 0 0; 0 0 1 0; 0 0 0 1; -100 -7 -10 -20];
assert(norm(A - A_exp) < 1e-10);
assert(isequal(B, [0;0;0;1]));
assert(norm(C - [100 0 0 0]) < 1e-10);

%% Test 2: With zeros (M08 S3.5 P4)
% G(s) = (8s + 10) / (s^4 + 5s^3 + s^2 + 5s + 13)
[A,B,C] = tf2ss_phase([8 10], [1 5 1 5 13]);
assert(norm(C - [10 8 0 0]) < 1e-10);

%% Test 3: 5th order with zeros (M08 S3.5 P5)
[A,B,C] = tf2ss_phase([1 2 12 7 6], [1 9 13 8 0 0]);
assert(norm(C - [6 7 12 2 1]) < 1e-10);
```

---

### T3: tf2ss_observer_canon.m

**Purpose:** Convert transfer function to observer canonical form.

**Spec:**
```matlab
function [A, B, C] = tf2ss_observer_canon(num, den)
% Observer canonical: A is LEFT companion matrix
%   A(i,1) = -a_{n-i}, A has 1s on superdiagonal
%   C = [1 0 ... 0]
```

**Test Cases:**
```matlab
%% Test 1: From observer design handout
% G(s) = (s^2+7s+2)/(s^3+9s^2+26s+24)
[A,B,C] = tf2ss_observer_canon([1 7 2], [1 9 26 24]);
A_exp = [-9 1 0; -26 0 1; -24 0 0];
assert(norm(A - A_exp) < 1e-10);
assert(isequal(C, [1 0 0]));

%% Test 2: From M10 exercise P4
% G(s) = 23/((s+1)(s+2)(s+5)) = 23/(s^3+8s^2+17s+10)
[A,B,C] = tf2ss_observer_canon([23], [1 8 17 10]);
assert(norm(A - [-8 1 0; -17 0 1; -10 0 0]) < 1e-10);
```

---

### T4: check_stability.m

**Spec:**
```matlab
function [is_stable, eigenvalues, n_rhp, n_lhp, n_jw] = check_stability(A)
```

**Test Cases:**
```matlab
%% Test 1: M08 S6.5 P1 - 2 RHP, 1 LHP
A = [0 1 3; 2 2 -4; 1 -4 3];
[stable, eigs, rhp, lhp, jw] = check_stability(A);
assert(~stable); assert(rhp==2); assert(lhp==1);

%% Test 2: M08 S6.5 P3 - stable
A = [0 1 0; 0 1 3; -3 -4 -5];
[stable, ~,~,~,~] = check_stability(A);
assert(stable);

%% Test 3: Stability handout - unstable
A = [3 0 4; 0 4 4; 3 2 12];
[stable,~,~,~,~] = check_stability(A);
assert(~stable);

%% Test 4: Stability handout - stable
A = [0 1; -10 -5];
[stable,~,~,~,~] = check_stability(A);
assert(stable);
```

---

### T5: check_controllability.m

**Spec:**
```matlab
function [is_controllable, CM, rank_CM] = check_controllability(A, B)
```

**Test Cases:**
```matlab
%% Test 1: M09 S12.3 P1 - uncontrollable
A = [0 1; -2 -3]; B = [1; -1];
[ctrl, CM, r] = check_controllability(A, B);
assert(~ctrl); assert(r == 1);

%% Test 2: Diagonal uncontrollable (M09 class notes)
A = [-5 0 0; 0 -4 0; 0 0 -3]; B = [0; 1; 1];
[ctrl, ~, r] = check_controllability(A, B);
assert(~ctrl);
```

---

### T6: check_observability.m

**Spec:**
```matlab
function [is_observable, OM, rank_OM] = check_observability(A, C)
```

**Test Cases:**
```matlab
%% Test 1: M10 S12.6 - observable
A = [-10 1; -21 0]; C = [1 0];
[obs, OM, r] = check_observability(A, C);
assert(obs); assert(r == 2);

%% Test 2: M10 S12.6 P2 - not observable
A = [2 0 0; 0 7 3; 0 10 1]; C = [0 0 1];
[obs, ~, r] = check_observability(A, C);
assert(~obs); assert(r == 2);

%% Test 3: Observability handout (4th order)
A = [0 1 0 0; -11 -7 9 4; 0 0 0 1; 9 4 -9 -4];
C = [0 0 1 0];
[obs, ~, r] = check_observability(A, C);
assert(obs); assert(r == 4);
```

---

### T7: design_state_feedback.m

**Spec:**
```matlab
function [K, cl_poles] = design_state_feedback(A, B, desired_poles)
% Uses coefficient matching AND validates with place() as cross-check
```

**Test Cases:**
```matlab
%% Test 1: M09 P4 - 2nd order SMD
A = [0 1; -15 -6]; B = [0; 0.5];
desired = [-20+20.9738i, -20-20.9738i];
[K, ~] = design_state_feedback(A, B, desired);
assert(abs(K(1) - 1650) < 5);
assert(abs(K(2) - 68.0) < 0.5);

%% Test 2: M09 P3 - 3rd order (B=[0;0;1])
A = [0 1 0; 0 0 1; -64 -56 -14]; B = [0;0;1];
desired = [-5.333+8.832i, -5.333-8.832i, -53.33];
[K, ~] = design_state_feedback(A, B, desired);
assert(abs(K(1) - 5610) < 20);
assert(abs(K(2) - 619) < 5);
assert(abs(K(3) - 50) < 1);

%% Test 3: M09 class notes
A = [0 1 0; 0 0 1; 0 -200 -30]; B = [0;0;1];
desired = [-62.5, -12.5+24.3i, -12.5-24.3i];
[K, ~] = design_state_feedback(A, B, desired);
assert(abs(K(1) - 46700) < 100);
assert(abs(K(2) - 2110) < 10);
assert(abs(K(3) - 57.4) < 0.5);
```

---

### T8: design_observer.m

**Spec:**
```matlab
function [L, obs_poles] = design_observer(A, C, desired_obs_poles)
```

**Test Cases:**
```matlab
%% Test 1: M10 S12.5 P1
A = [-10 1; -21 0]; C = [1 0];
desired = [-100+50i, -100-50i];
[L, ~] = design_observer(A, C, desired);
assert(abs(L(1) - 190) < 1);
assert(abs(L(2) - 12479) < 5);

%% Test 2: M10 S12.5 P3
A = [0 1; -21 -10]; C = [25 0];
desired = [-80+109.15i, -80-109.15i];
[L, ~] = design_observer(A, C, desired);
assert(abs(L(1) - 6.00) < 0.1);
assert(abs(L(2) - 672) < 5);

%% Test 3: Observer handout (3rd order, observer canonical)
A_obs = [-8 1 0; -17 0 1; -10 0 0]; C_obs = [1 0 0];
desired = [-10, -5+2i, -5-2i];
[L, ~] = design_observer(A_obs, C_obs, desired);
assert(abs(L(1) - 12) < 1);
assert(abs(L(2) - 112) < 5);
assert(abs(L(3) - 280) < 5);
```

---

### T9: design_integral_ctrl.m

**Spec:**
```matlab
function [K, ke, cl_poles] = design_integral_ctrl(A, B, C, desired_poles)
% Constructs augmented system and solves for [K, ke]
```

**Test Cases:**
```matlab
%% Test 1: M10 S12.8 P1 cancel zero
A=[0 1;2 1]; B=[0;1]; C=[2 1];
desired = [-2, -8+10.915i, -8-10.915i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired);
assert(abs(K(1) - 34) < 1);
assert(abs(K(2) - 19) < 0.5);
assert(abs(ke - 183) < 2);

%% Test 2: M10 S12.8 P2 cancel zero
A=[0 1;-10 -7]; B=[0;1]; C=[3 1];
desired = [-3, -8+10.915i, -8-10.915i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired);
assert(abs(K(1) - 38) < 1);
assert(abs(K(2) - 12) < 0.5);
assert(abs(ke - 183) < 2);

%% Test 3: DC motor integral control handout
A = [0 1; 0 -5/3]; B = [0; 5/12]; C = [1 0];
desired = [-40, -7.27+14.2i, -7.27-14.2i];
[K, ke, ~] = design_integral_ctrl(A, B, C, desired);
assert(abs(K(1) - 2007) < 10);
assert(abs(K(2) - 126.9) < 1);
assert(abs(ke - 24430) < 50);
```

---

### T10: verify_solution.m

**Spec:**
```matlab
function result = verify_solution(A, B, C, K, ke, L, expected_cl_poles, expected_obs_poles)
% Comprehensive verification: computes actual poles and compares
% Returns struct with: pass/fail, actual CL poles, actual obs poles, error magnitudes
```

---

## Textbook MATLAB Command Reference

*Excerpted from: "An Introduction to Control Theory Applications with Matlab" (Moysis et al., 2015)*

### Chapter 7: State Space Systems - Key Commands

```matlab
sys = ss(A, B, C, D);          % Create state-space system (D=[] for no feedforward)
[A,B,C,D] = tf2ss(num, den);   % TF -> SS (NOTE: MATLAB controller canonical, not same as phase var)
[num,den] = ss2tf(A,B,C,D);    % SS -> TF
sys_tf = tf(sys_ss);            % Object conversion
sys_ss = ss(sys_tf);            % Object conversion
[A,B,C,D] = ssdata(sys);       % Extract matrices from ss object
```

### Chapter 8: Pole Placement - Key Commands

```matlab
eig(A)                          % Eigenvalues of A (= system poles)
pole(sys)                       % Poles of system object
CM = ctrb(A, B);                % Controllability matrix
rank(CM)                        % Must equal n for controllable
K = place(A, B, desired_poles); % Pole placement (no repeated poles)
K = acker(A, B, desired_poles); % Ackermann formula (SISO only, allows repeated)
A_cl = A - B*K;                 % Closed-loop system matrix
eig(A_cl)                       % Verify closed-loop poles
```

### Chapter 9: Observer Design - Key Commands

```matlab
OM = obsv(A, C);                % Observability matrix
rank(OM)                        % Must equal n for observable
L = place(A', C', obs_poles)';  % Observer gain via transpose trick
A_obs = A - L*C;                % Observer error dynamics matrix
eig(A_obs)                      % Verify observer poles
```


---

# PART 2: GUIDE / REPORT / SUMMARY

## File Registry (15 Files - Duplicate Tracker)

| # | Filename | ID | Type | Topics |
|---|---------|-----|------|--------|
| 1 | module08_classNotes.pdf | M08-CN | Class Notes | Sec 3.1-4, 3.5, 6.5 |
| 2 | module10_exercises.pdf | M10-EX | Exercises+Answers | Sec 12.5, 12.6, 12.8 |
| 3 | observability_handout.pdf | OBS-HO | Handout | Observability |
| 4 | integralControl_handout.pdf | INT-HO | Handout | Integral control |
| 5 | observerDesign_handout.pdf | OBSD-HO | Handout | Observer design |
| 6 | module10_classNotes.pdf | M10-CN | Class Notes | Sec 12.5, 12.6, 12.8 |
| 7 | module08_exercises_withAnswers.pdf | M08-EXA | Exercises+Answers | Sec 3.1-4, 3.5, 6.5 |
| 8 | module08_exercises.pdf | M08-EX | Exercises Only | Sec 3.1-4, 3.5, 6.5 |
| 9 | module09_exercises.pdf | M09-EX | Exercises Only | Sec 12.2, 12.3 |
| 10 | module09_classNotes.pdf | M09-CN | Class Notes | Sec 12.2, 12.3 |
| 11 | module09_exercises_withAnswers.pdf | M09-EXA | Exercises+Answers | Sec 12.2, 12.3 |
| 12 | introductionToStateSpaceModeling_handout.pdf | INTRO-HO | Handout | SS modeling intro |
| 13 | stabilityInStateSpace_handout.pdf | STAB-HO | Handout | Eigenvalue stability |
| 14 | convertingTransferFunctionsToStateSpace_handout.pdf | TF-HO | Handout | Phase variables, TF->SS |
| 15 | An-introduction-to-Control-Theory-Applications-with-Matlab.pdf | TEXTBOOK | Textbook | Ch 1-15 (MATLAB reference) |

## Topic Taxonomy and Question Type Index

### Category A: State-Space from Physical Systems (Sec 3.1-4)

**What to know:** Derive x_dot = Ax + Bu, y = Cx from equations of motion.
**Skills:** FBDs, EOMs, state variable selection (positions + velocities), A/B/C construction.

| ID | System Type | Output | Source |
|----|-------------|--------|--------|
| A1 | Two-block translational (m-k-c) | Acceleration of right mass | M08-EX P1 |
| A2 | Two-tank fluid system | Height difference h1-h2 | M08-EX P2 |
| A3 | Rotational system | Wall torque from damper | M08-EX P3 |
| A4 | Spring-damper (zero mass) | Spring/damper force | INTRO-HO Ex1 |
| A5 | Spring-mass-damper | Spring + damper forces | INTRO-HO Ex2 |
| A6 | Gear train rotational | theta_3 via gear ratio | INTRO-HO Ex3 |
| A7 | Two-mass spring-damper (class) | x2 position | M08-CN |

### Category B: TF to Phase-Variable Form (Sec 3.5)

**What to know:** Convert G(s)=N(s)/D(s) to SS. Convention: B=[0;...;0;1], gain in C.

| ID | Transfer Function | Order | Zeros? | Source |
|----|------------------|-------|--------|--------|
| B1 | 100/(s^4+20s^3+10s^2+7s+100) | 4 | No | M08-EX |
| B2 | 30/(s^5+8s^4+9s^3+6s^2+s+30) | 5 | No | M08-EX |
| B3 | Theta_m/E_a (DC motor parametric) | 2 | No | M08-EX |
| B4 | (8s+10)/(s^4+5s^3+s^2+5s+13) | 4 | Yes | M08-EX |
| B5 | (s^4+2s^3+12s^2+7s+6)/(s^5+9s^4+13s^3+8s^2) | 5 | Yes | M08-EX |
| B6 | 43/(s^2+9s+24) | 2 | No | TF-HO |
| B7 | (43s+2)/(s^2+9s+24) | 2 | Yes | TF-HO |
| B8 | 24/((s+2)(s+3)(s+4)) cascade | 3 | Alt | TF-HO |
| B9 | 27/(s^3+3s^2+s+13) | 3 | No | M08-CN |

### Category C: Stability via Eigenvalues (Sec 6.5)

**What to know:** Stable iff all eigenvalues of A have Re < 0.

| ID | System | Result | Source |
|----|--------|--------|--------|
| C1 | 3x3: [0 1 3; 2 2 -4; 1 -4 3] | 2 RHP, 1 LHP | M08-EX P1 |
| C2 | 3x3: [0 1 0; 0 1 -4; -1 1 8] | eig=0.54,1.0,7.5 unstable | M08-EX P2 |
| C3 | 3x3: [0 1 0; 0 1 3; -3 -4 -5] | Stable: -0.68+/-j1.7, -2.6 | M08-EX P3 |
| C4 | 3x3: [3 0 4; 0 4 4; 3 2 12] | Unstable: 1.4, 3.7, 14 | STAB-HO |
| C5 | 2x2: [0 1; -10 -5] | Stable: -2.5+/-j1.9 | STAB-HO |

### Category G: State-Variable Feedback Design (Sec 12.2)

**What to know:** u = r - Kx, system becomes A-BK. Match CE coefficients.

| ID | Plant | Specs | K | Source |
|----|-------|-------|---|--------|
| G1 | Two-DOF SMD (parametric) | Symbolic | Parametric | M09-EX P1 |
| G2 | 100(s+10)/(s(s+3)(s+12)) | 5% OS, Tp=0.3s | [2090, 373, 15.0] | M09-EX P2 |
| G3 | 20/((s+2)(s+4)(s+8)) | 15% OS, Ts=0.75s, 10x | [5610, 619, 50] | M09-EX P3 |
| G4 | SMD: K=30,D=12,M=2 | 5% OS, Ts=0.2s | [1650, 68.0] | M09-EX P4 |
| G5 | 1/(s^3+30s^2+200s) | Match PD poles, 5x | [46700, 2110, 57.4] | M09-CN |

### Category H: Controllability (Sec 12.3)

**What to know:** rank(C_M) = n where C_M = [B, AB, ..., A^{n-1}B].

| ID | System | Controllable? | Rank | Source |
|----|--------|--------------|------|--------|
| H1 | 2x2, B=[1;-1] | No | 1 | M09-EX P1 |
| H2 | 4x4 block diagram | Yes | 4 | M09-EX P2 |
| H3 | 4x4 block diagram | Yes | 4 | M09-EX P3 |
| H4 | 3x3 diagonal, B=[0;1;1] | No | <3 | M09-CN |

### Category D: Observer Design (Sec 12.5)

**What to know:** Design L so eig(A-LC) ~10x further left than eig(A-BK).

| ID | Order | L | Status | Source |
|----|-------|---|--------|--------|
| D1 | 2nd | [190, 12479] | Verified | M10-EX P1 |
| D2 | 2nd | [472, 76790] | Verified | M10-EX P2 |
| D3 | 2nd | [6.00, 672] | Verified | M10-EX P3 |
| D4 | 3rd | **CORRECTED: [92, 4983, 124990]** | Fixed | M10-EX P4 |
| D5 | 3rd | [12, 112, 280] | Verified | OBSD-HO |
| D6 | 2nd | [394, 37621] | Verified | M10-CN |

### Category E: Observability (Sec 12.6)

**What to know:** rank(O_M) = n where O_M = [C; CA; ...; CA^{n-1}].

| ID | System | Observable? | Source |
|----|--------|------------|--------|
| E1 | All 4 systems from D1-D4 | Yes (full rank) | M10-EX |
| E2 | 3x3 diagonal, C=[0,0,1] | No (x1 decoupled) | M10-EX |
| E3 | 4x4 SMD | Yes (rank=4) | OBS-HO |

### Category F: Integral Control (Sec 12.8)

**What to know:** Augmented system [A-BK, Bk_e; -C, 0]. Eliminates SSE.

| ID | Plant | Strategy | K, ke | Status | Source |
|----|-------|----------|-------|--------|--------|
| F1 | (s+2)/(s^2-s-2) | Cancel zero | K=[34,19], ke=183 | Verified | M10-EX |
| F2 | (s+2)/(s^2-s-2) | 5x pole | **CORRECTED: K=[-1628,49], ke=2442** | Fixed | M10-EX |
| F3 | (s+3)/(s^2+7s+10) | Cancel zero | K=[38,12], ke=183 | Verified | M10-EX |
| F4 | (s+3)/(s^2+7s+10) | 5x pole | **CORRECTED: K=[-1628,49], ke=2442** | Fixed | M10-EX |
| F5 | DC motor | Custom | K=[2007,126.9], ke=24430 | Verified | INT-HO |

---

## Verified Answer Key - Error Summary

**Module 08:** All 11 answers CORRECT.
**Module 09:** All 7 answers CORRECT. Note: uses B=[0;...;0;1] convention.
**Module 10:** 2 errors found and corrected:

**Error 1 - Sec 12.5 P4:** Observer gain L for G(s)=23/((s+1)(s+2)(s+5))
- Given: L=[84, 3590, 61800] produces poles at -40.7, -25.7+/-j29.3
- **Correct: L=[92, 4983, 124990]** produces specified poles -50, -25+/-j43.3

**Error 2 - Sec 12.8 P2 (5x option):** Integral control for G(s)=(s+3)/(s^2+7s+10)
- Given: K=[813, 49], ke=2440 produces poles at -26.8+/-j49.2, -2.3
- **Correct: K=[-1628, 49], ke=2442** produces desired poles -40, -8+/-j10.9
- Root cause: omitted k_e from s^1 coefficient in CE

---

## Key Formulas Quick Reference

### Second-Order Specifications
```
zeta = -ln(OS%/100) / sqrt(pi^2 + ln^2(OS%/100))
wn = 4 / (Ts * zeta)             % for settling time
wn = pi / (Tp * sqrt(1-zeta^2))  % for peak time
sigma = zeta * wn
wd = wn * sqrt(1 - zeta^2)
Desired poles: s = -sigma +/- j*wd
```

### Phase-Variable Form (No Zeros): G(s) = b0/D(s)
```
A = [0 1 0 ...; 0 0 1 ...; ...; -a0 -a1 ... -a_{n-1}]
B = [0; 0; ...; 1]
C = [b0 0 ... 0]
```

### Phase-Variable Form (With Zeros): G(s) = N(s)/D(s)
```
A = same (from denominator)
B = [0; 0; ...; 1]
C = [b0 b1 ... b_m 0 ... 0]  % numerator coeffs, zero-padded
```

### Observer Canonical Form
```
A = [-a_{n-1} 1 0 ...; -a_{n-2} 0 1 ...; ...; -a0 0 ... 0]
C = [1 0 ... 0]
```

### State Feedback: x_dot = (A-BK)x + Br
### Controllability: rank([B, AB, ..., A^{n-1}B]) = n
### Observability: rank([C; CA; ...; CA^{n-1}]) = n
### Observer: e_dot = (A-LC)e, place eig(A-LC) ~10x left of eig(A-BK)

### Observer Design (Observer Canonical)
```
det(sI-(A-LC)) = s^n + (a_{n-1}+l1)*s^{n-1} + ... + (a0+ln) = 0
```

### Integral Control Augmented System
```
[x_dot  ]   [A-BK    Bk_e] [x  ]   [0]
[x_N_dot] = [-C      0   ] [x_N] + [1] r
```


---

# PART 3: CONVERTED SOURCE MATERIALS

> **COPILOT:** Do not consume this section unless directed to a specific source by ID.
> Source IDs: M08-CN, M08-EX, M08-EXA, M09-CN, M09-EX, M09-EXA,
> M10-CN, M10-EX, INTRO-HO, STAB-HO, TF-HO, OBS-HO, OBSD-HO, INT-HO

---

## [SOURCE: M08-CN] Module 08 Class Notes

### Sec 3.1-4: State-Space Representation

State-space representation includes state variables and input.
Write a first-order diff. eq. for each state variable in terms of state variables + input.

**Example:** Two-mass spring-damper with x2 as output.

EOM:
```
f - (k1+k2)*x1 - (c1+c2)*v1 + k2*x2 + c2*v2 = m1*a1
k2*x1 + c2*v1 - (k2+k3)*x2 - (c2+c3)*v2 = m2*a2
```

State vector: x_bar = [x1, v1, x2, v2]^T, u = f, y = x2
```
A = [0            1             0             0           ;
     -(k1+k2)/m1  -(c1+c2)/m1   k2/m1         c2/m1      ;
     0            0             0             1           ;
     k2/m2        c2/m2         -(k2+k3)/m2   -(c2+c3)/m2]
B = [0; 1/m1; 0; 0]
C = [0 0 1 0]
```

### Sec 3.5: Phase Variables

**No-zeros:** G(s) = 27/(s^3 + 3s^2 + s + 13)
```
A = [0 1 0; 0 0 1; -13 -1 -3]
B = [0; 0; 27]
C = [1 0 0]
```

**With-zeros:** G(s) = (b2*s^2+b1*s+b0)/(s^3+a2*s^2+a1*s+a0)
```
A = [0 1 0; 0 0 1; -a0 -a1 -a2]
B = [0; 0; 1]
C = [b0 b1 b2]
```

### Sec 6.5: Stability
```
A = [0 1; -75 -3]
lambda^2 + 3*lambda + 75 = 0
lambda = -1.5 +/- 8.53j --> STABLE
```

---

## [SOURCE: M08-EXA] Module 08 Exercises with Answers

### Sec 3.1-4

**P1:** Two-block system, acceleration output
```
A = [0 1 0 0; -1 -1 1 1; 0 0 0 1; 1 1 -1 -1]
B = [0; 1; 0; 0],  C = [1 1 -1 -1]
```

**P2:** Two-tank system, height difference output
```
A = [-g/(A1*R1), g/(A1*R1); g/(A2*R1), -g/(A2*(R1+R2))]
B = [1/(rho*A1); 0],  C = [1 -1]
```

**P3:** Rotational system, wall torque output
```
A = [0 1 0 0; -9/5 -9/5 9/5 1/5; 0 0 0 1; 3 1/3 -4 -1/3]
B = [0; 0; 0; 1/3],  C = [0 8 0 0]
```

### Sec 3.5

**P1:** G(s)=100/(s^4+20s^3+10s^2+7s+100)
```
A = [0 1 0 0; 0 0 1 0; 0 0 0 1; -100 -7 -10 -20]
B = [0;0;0;100],  C = [1 0 0 0]
```

**P2:** G(s)=30/(s^5+8s^4+9s^3+6s^2+s+30)
```
A = [0 1 0 0 0; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1; -30 -1 -6 -9 -8]
B = [0;0;0;0;30],  C = [1 0 0 0 0]
```

**P3:** DC Motor: A=[0,1; 0,-(Dm+Kt*Kb/Ra)/Jm], B=[0; Kt/(Ra*Jm)], C=[0 1]

**P4:** G(s)=(8s+10)/(s^4+5s^3+s^2+5s+13)
```
A = [0 1 0 0; 0 0 1 0; 0 0 0 1; -13 -5 -1 -5]
B = [0;0;0;1],  C = [10 8 0 0]
```

**P5:** G(s)=(s^4+2s^3+12s^2+7s+6)/(s^5+9s^4+13s^3+8s^2)
```
A = [0 1 0 0 0; 0 0 1 0 0; 0 0 0 1 0; 0 0 0 0 1; 0 0 -8 -13 -9]
B = [0;0;0;0;1],  C = [6 7 12 2 1]
```

### Sec 6.5

**P1:** A=[0 1 3;2 2 -4;1 -4 3] --> 1 LHP, 2 RHP
**P2:** A=[0 1 0;0 1 -4;-1 1 8] --> eig = 0.54, 1.0, 7.5
**P3:** A=[0 1 0;0 1 3;-3 -4 -5] --> eig = -0.68+/-j1.7, -2.6 STABLE

---

## [SOURCE: M09-CN] Module 09 Class Notes

### Sec 12.2: State-Variable Feedback

u = r - Kx --> x_dot = (A-BK)x + Br

**Procedure:**
1. Write CP: det(lambda*I - (A-BK)) with unknown k_i
2. Desired poles --> desired CP
3. Match coefficients --> solve for K

**Example:** G_p = 1/(s^3+30s^2+200s)
```
A = [0 1 0; 0 0 1; 0 -200 -30],  B = [0;0;1],  C = [1 0 0]
CE: lambda^3 + (30+k3)*lambda^2 + (200+k2)*lambda + k1
Desired: lambda^3 + 87.4*lambda^2 + 2310*lambda + 46700
K = [46700, 2110, 57.4]
```

### Sec 12.3: Controllability

rank(C_M) = n iff controllable, C_M = [B, AB, ..., A^{n-1}B]

**Uncontrollable example:**
```
A = [-5 0 0; 0 -4 0; 0 0 -3],  B = [0;1;1]
C_M = [0 0 0; 1 -4 16; 1 -3 9]
rank < 3 --> uncontrollable
```

---

## [SOURCE: M09-EXA] Module 09 Exercises with Answers

**P1:** Two-DOF SMD parametric (see source for full matrices)
**P2:** K = [2090, 373, 15.0] for 100(s+10)/(s(s+3)(s+12)), 5% OS, Tp=0.3s
**P3:** K = [5610, 619, 50] for 20/((s+2)(s+4)(s+8)), 15% OS, Ts=0.75s, 10x
**P4:** K = [1650, 68.0] for SMD K=30,D=12,M=2, 5% OS, Ts=0.2s
**Sec 12.3 P1:** CM=[1 -1;-1 1], rank=1, uncontrollable
**Sec 12.3 P2:** rank(CM)=4, controllable
**Sec 12.3 P3:** rank(CM)=4, controllable

---

## [SOURCE: M10-CN] Module 10 Class Notes

### Sec 12.5: Observer Design

x_hat_dot = A*x_hat + B*u + L*(y - y_hat)
Error: e_dot = (A-LC)*e. Place eig(A-LC) ~10x left of eig(A-BK).

**Example:**
```
A=[0 1;-15 -6], B=[0;1/2], C=[1 0], K=[1650, 68.0]
CL poles: -20+/-j20.98, Observer poles: -200+/-j209.8
det(sI-(A-LC)) = s^2 + (l1+6)s + 6l1+15+l2
L = [394, 37621]
```

### Sec 12.6: Observability

O_M = [C; CA; ...; CA^{n-1}], observable iff rank = n

### Sec 12.8: Integral Control

Augmented: [x_dot; x_N_dot] = [A-BK, Bk_e; -C, 0][x; x_N] + [0; 1]r

**Example:**
```
A=[0 1;-15 -6], B=[0;1/2], C=[1 0]
CE: s^3 + (6+k2/2)s^2 + (15+k1/2)s + ke/2
Desired: s=-100, -20+/-j20.98
K = [9650, 268], ke = 167980
```

---

## [SOURCE: M10-EX] Module 10 Exercises with Answers

### Sec 12.5

**P1:** A=[-10 1;-21 0], C=[1 0], poles -100+/-50j --> L=[190, 12479]
**P2:** A=[-8 1;-210 0], K=[12,2] --> L=[472, 76790]
**P3:** A=[0 1;-21 -10], C=[25 0], 0.5s Ts 10% OS --> K=[162,6.00], L=[6.00,672]
**P4:** G(s)=23/((s+1)(s+2)(s+5)), poles -50,-25+/-j43.3
  GIVEN (WRONG): L=[84, 3590, 61800]
  **CORRECTED: L=[92, 4983, 124990]**

### Sec 12.6

OM1=[[1 0];[-10 1]] rank=2; OM2=[[1 0];[-8 1]] rank=2
OM3=[[25 0];[0 25]] rank=2; OM4=eye(3) rank=3
P2: A=[2 0 0;0 7 3;0 10 1], C=[0 0 1] --> NOT observable, rank=2

### Sec 12.8

**P1:** G(s)=(s+2)/(s^2-s-2), A=[0 1;2 1], B=[0;1], C=[2 1]
  Cancel: K=[34,19], ke=183 (CORRECT)
  5x: K=[-2840,57], ke=3660 (approximate, use with caution)

**P2:** G(s)=(s+3)/(s^2+7s+10), A=[0 1;-10 -7], B=[0;1], C=[3 1]
  Cancel: K=[38,12], ke=183 (CORRECT)
  5x: GIVEN K=[813,49], ke=2440 (WRONG)
  **CORRECTED: K=[-1628,49], ke=2442**

---

## [SOURCE: INTRO-HO] Introduction to State-Space Modeling Handout

**General Form:** x_dot = Ax + Bu, y = Cx + Du

**Ex1 (Spring-Damper, m=0):**
```
x_dot = -(k/c)*x + (1/c)*f
Outputs: f_s=k*x, f_c=-k*x+f, v=x_dot
```

**Ex2 (Spring-Mass-Damper):**
```
A = [0 1; -k/m -c/m],  B = [0; 1/m],  C = [k 0; 0 c]
```

**Ex3 (Gear Train):**
```
Je=2.22, De=1.44, ke=0.444
A = [0 1; -0.200 -0.650],  B = [0; 0.450],  C = [0.0833 0]
```

---

## [SOURCE: STAB-HO] Stability in State Space Handout

Eigenvalues of A = poles of TF. Stable iff all Re(lambda) < 0.

**Ex1 (Unstable):** A=[3 0 4;0 4 4;3 2 12], lambda=1.4, 3.7, 14
**Ex2 (Stable):** A=[0 1;-10 -5], lambda=-2.5+/-j1.9

MATLAB: `eig(A)`, `sys=ss(A,B,C,[])`, `step(sys)`

---

## [SOURCE: TF-HO] Converting TF to State Space Handout

**Phase variables:** x1=y, x2=dy/dt, ..., xn=d^{n-1}y/dt^{n-1}

**Ex1 (no zeros):** G(s)=43/(s^2+9s+24)
```
A=[0 1;-24 -9], B=[0;43], C=[1 0]
```

**Ex2 (with zeros):** G(s)=(43s+2)/(s^2+9s+24)
```
A=[0 1;-24 -9], B=[0;1], C=[2 43]
```

**Ex3 (cascade form):** G(s)=24/((s+2)(s+3)(s+4))
```
A=[-4 1 0; 0 -3 1; 0 0 -2], B=[0;0;24], C=[1 0 0]
```

---

## [SOURCE: OBS-HO] Observability Handout

Observable iff rank(O_M)=n, O_M=[C; CA; ...; CA^{n-1}]

**Diagonal inspection:**
- C=[1 1 1]: all states in output --> observable
- C=[0 1 1]: x1 missing --> NOT observable

**4th order example:**
```
A=[0 1 0 0;-11 -7 9 4;0 0 0 1;9 4 -9 -4], C=[0 0 1 0]
K1=2,D1=3,M1=1,K2=9,D2=4,M2=1
OM = [0 0 1 0; 0 0 0 1; 9 4 -9 -4; -80 -35 72 23]
rank=4 --> OBSERVABLE
```

---

## [SOURCE: OBSD-HO] Observer Design Handout

**Basic observer:** x_hat_dot = A*x_hat + B*u (too slow - same dynamics as plant)
**Improved:** x_hat_dot = A*x_hat + B*u + L*(y-y_hat), error: e_dot = (A-LC)*e

**Observer canonical advantage:**
det(sI-(A-LC)) = s^n + (a_{n-1}+l1)*s^{n-1} + ... + (a0+ln) = 0

**Example:** G(s)=(s+4)/((s+1)(s+2)(s+5)), observer canonical:
```
A=[-8 1 0;-17 0 1;-10 0 0], B=[0;1;4], C=[1 0 0]
CL poles: -4, -1+/-j2. Observer poles: -5+/-j2, -10
det = s^3 + (8+l1)s^2 + (17+l2)s + (10+l3)
Desired: s^3 + 20s^2 + 129s + 290
L = [12, 112, 280]
```

---

## [SOURCE: INT-HO] Integral Control Handout

**Motivation:** State feedback leaves SSE. Add integrator: x_N = integral(r-Cx)dt

**Augmented system:**
```
[x_dot  ]   [A-BK  Bke ] [x  ]   [0]
[xN_dot ] = [-C    0   ] [xN ] + [1] r
```

**DC Motor example:**
```
A=[0 1;0 -5/3], B=[0;5/12], C=[1 0]
CE: s^3 + (5/3+5k2/12)s^2 + (5k1/12)s + 5ke/12
Desired: s=-7.27+/-j14.2, s=-40
K = [2007, 126.9], ke = 24430
```


---

# PART 4: PYTHON VERIFICATION TOOLS

> **COPILOT:** Use these to validate MATLAB implementations.

```python
import numpy as np
from numpy.linalg import eigvals, matrix_rank

def specs_to_poles(spec_value, os_pct, spec_type='Ts'):
    """Convert transient specs to desired pole locations."""
    zeta = -np.log(os_pct/100) / np.sqrt(np.pi**2 + np.log(os_pct/100)**2)
    if spec_type == 'Ts':
        sigma = 4.0 / spec_value
        wn = sigma / zeta
    elif spec_type == 'Tp':
        wd = np.pi / spec_value
        wn = wd / np.sqrt(1 - zeta**2)
        sigma = zeta * wn
    wd = wn * np.sqrt(1 - zeta**2)
    poles = np.array([-sigma + 1j*wd, -sigma - 1j*wd])
    return poles, zeta, wn, sigma, wd

def tf2ss_phase(num, den):
    """TF to phase-variable SS. Convention: B=[0;...;1], gain in C."""
    n = len(den) - 1
    den = np.array(den, dtype=float)
    num = np.array(num, dtype=float)
    if den[0] != 1:
        num = num / den[0]
        den = den / den[0]
    A = np.zeros((n, n))
    for i in range(n-1):
        A[i, i+1] = 1.0
    for i in range(n):
        A[n-1, i] = -den[n-i]
    B = np.zeros((n, 1))
    B[n-1, 0] = 1.0
    C = np.zeros((1, n))
    num_padded = np.zeros(n)
    for i, c in enumerate(reversed(num)):
        num_padded[i] = c
    C[0, :] = num_padded
    return A, B, C

def check_stability(A):
    """Check stability via eigenvalues."""
    eigs = eigvals(A)
    tol = 1e-10
    n_rhp = sum(1 for e in eigs if e.real > tol)
    n_lhp = sum(1 for e in eigs if e.real < -tol)
    n_jw = sum(1 for e in eigs if abs(e.real) <= tol)
    is_stable = (n_rhp == 0) and (n_jw == 0)
    return is_stable, eigs, n_rhp, n_lhp, n_jw

def check_controllability(A, B):
    """Check controllability via rank of [B AB ... A^{n-1}B]."""
    n = A.shape[0]
    CM = B.copy()
    Ak = np.eye(n)
    for i in range(1, n):
        Ak = Ak @ A
        CM = np.hstack([CM, Ak @ B])
    r = matrix_rank(CM)
    return r == n, CM, r

def check_observability(A, C):
    """Check observability via rank of [C; CA; ...; CA^{n-1}]."""
    n = A.shape[0]
    OM = C.copy()
    Ak = np.eye(n)
    for i in range(1, n):
        Ak = Ak @ A
        OM = np.vstack([OM, C @ Ak])
    r = matrix_rank(OM)
    return r == n, OM, r

def verify_state_feedback(A, B, K, expected_poles):
    """Verify A-BK has expected poles."""
    K = np.atleast_2d(K)
    A_cl = A - B @ K
    actual = np.sort_complex(eigvals(A_cl))
    expected = np.sort_complex(np.array(expected_poles))
    return np.allclose(actual, expected, atol=0.5), actual

def verify_observer(A, C, L, expected_poles):
    """Verify A-LC has expected observer poles."""
    L = np.atleast_2d(L).T if np.ndim(L) == 1 else L
    C = np.atleast_2d(C)
    A_obs = A - L @ C
    actual = np.sort_complex(eigvals(A_obs))
    expected = np.sort_complex(np.array(expected_poles))
    return np.allclose(actual, expected, atol=0.5), actual

def verify_integral_ctrl(A, B, C, K, ke, expected_poles):
    """Verify augmented system poles for integral control."""
    K = np.atleast_2d(K)
    C = np.atleast_2d(C)
    top_left = A - B @ K
    top_right = B * ke
    bot_left = -C
    bot_right = np.zeros((1, 1))
    Aug = np.block([[top_left, top_right], [bot_left, bot_right]])
    actual = np.sort_complex(eigvals(Aug))
    expected = np.sort_complex(np.array(expected_poles))
    return np.allclose(actual, expected, atol=1.0), actual

# ============ SELF-TEST ============
if __name__ == '__main__':
    # T1
    p, z, wn, sig, wd = specs_to_poles(0.5, 10, 'Ts')
    assert abs(z - 0.5912) < 0.001
    print("T1 PASS: specs_to_poles")

    # T4
    s, e, r, l, j = check_stability(np.array([[0,1,3],[2,2,-4],[1,-4,3]]))
    assert not s and r == 2 and l == 1
    print("T4 PASS: check_stability")

    # T5
    ctrl, CM, r = check_controllability(np.array([[0,1],[-2,-3]]), np.array([[1],[-1]]))
    assert not ctrl and r == 1
    print("T5 PASS: check_controllability")

    # T6
    obs, OM, r = check_observability(np.array([[-10,1],[-21,0]]), np.array([[1,0]]))
    assert obs and r == 2
    print("T6 PASS: check_observability")

    # T7
    m, p = verify_state_feedback(
        np.array([[0,1],[-15,-6]]), np.array([[0],[0.5]]),
        np.array([[1650, 68.0]]), [-20+20.9738j, -20-20.9738j])
    assert m
    print("T7 PASS: verify_state_feedback")

    # T8
    m, p = verify_observer(
        np.array([[-10,1],[-21,0]]), np.array([[1,0]]),
        np.array([190, 12479]), [-100+50j, -100-50j])
    assert m
    print("T8 PASS: verify_observer")

    # T9
    m, p = verify_integral_ctrl(
        np.array([[0,1],[2,1]]), np.array([[0],[1]]), np.array([[2,1]]),
        np.array([[34, 19.0]]), 183, [-2, -8+10.915j, -8-10.915j])
    assert m
    print("T9 PASS: verify_integral_ctrl")

    print("\n=== ALL PYTHON VERIFICATION TESTS PASSED ===")
```

---

*End of document. 14 source sections indexed + textbook excerpts. 15 files tracked. No duplicates.*
