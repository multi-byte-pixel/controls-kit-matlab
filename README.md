# controls-kit-matlab
Controls Problem Solver Tools

## MATLAB + VS Code Setup (Windows)

This project is tested with MATLAB from the VS Code terminal using batch mode.

### 1) Install prerequisites

- Install MATLAB (for example `R2025b`) using the MathWorks installer.
- In VS Code, install the official MATLAB extension: `mathworks.language-matlab`.

### 2) Verify MATLAB is installed

In a terminal:

```powershell
where.exe matlab
```

Alternative (PowerShell-native):

```powershell
(Get-Command matlab).Source
```

If MATLAB is not found, use the full executable path:

```powershell
"C:\Program Files\MATLAB\R2025b\bin\matlab.exe" -batch "disp('MATLAB_CONNECTED')"
```

Expected output includes:

```text
MATLAB_CONNECTED
```

### 3) (Recommended) Add MATLAB to PATH

Add this directory to your **User PATH**:

```text
C:\Program Files\MATLAB\R2025b\bin
```

Then fully restart VS Code.

### 4) Run project tests from VS Code terminal

From the repo root:

```powershell
matlab -batch "run('tests/run_phase1_tests.m')"
```

If PATH is not configured yet:

```powershell
"C:\Program Files\MATLAB\R2025b\bin\matlab.exe" -batch "run('tests/run_phase1_tests.m')"
```

Expected output includes:

```text
Running Phase 1 tests...
All Phase 1 tests passed.
```

### 5) Notes

- This workflow is Windows-first.
- Commands are intentionally batch/non-interactive for consistent terminal execution in VS Code.

## VS Code one-click tasks (Windows)

You can run MATLAB from **Terminal > Run Task** with two tasks:

- Run Phase 1 test suite
- Run current MATLAB file

Create `.vscode/tasks.json` with:

```json
{
	"version": "2.0.0",
	"tasks": [
		{
			"label": "MATLAB: Run Phase 1 Tests",
			"type": "shell",
			"command": "C:\\Program Files\\MATLAB\\R2025b\\bin\\matlab.exe",
			"args": [
				"-batch",
				"run('tests/run_phase1_tests.m')"
			],
			"group": "test",
			"problemMatcher": []
		},
		{
			"label": "MATLAB: Run Active File",
			"type": "shell",
			"command": "C:\\Program Files\\MATLAB\\R2025b\\bin\\matlab.exe",
			"args": [
				"-batch",
				"run('${file}')"
			],
			"problemMatcher": []
		}
	]
}
```

If MATLAB is already on PATH, you can replace the `command` value with `matlab`.

The `.vscode/tasks.json` file in this repo already has all three tasks configured, including the interactive Exam Wizard. Open it from **Terminal > Run Task**.

## Exam Q&A Wizard

The wizard collects your problem data, runs the full design pipeline, and gives you exam-ready output plus a Simulink export package — no manual scripting required.

### Option A — VS Code Task (recommended)

1. Open this repo in VS Code.
2. Open **Terminal > Run Task**.
3. Select **MATLAB: Exam Wizard (interactive)**.
4. Answer the prompts that appear in the integrated terminal.

> The wizard task uses `matlab -nosplash -nodesktop -r "..."` so that `input()` prompts
> work in the VS Code terminal.  Do **not** use the `-batch` flag for this task.

### Option B — MATLAB Command Window

Open MATLAB, `cd` to the repo root, then:

```matlab
run('src/exam_wizard.m')
```

### Option C — Copilot Chat

Open **Copilot Chat** in VS Code and paste the contents of
`docs/copilot/exam_qna_wizard_prompt.md` as your first message.
Copilot will ask the same questions and can also accept an uploaded exam image
to prefill values.

### What the wizard produces

After answering the prompts the wizard:

1. Runs `full_system_design(num, den, specs)` (the full pipeline).
2. Prints **Parsed Inputs**, **Computed Design**, and **Verification** (PASS/FAIL).
3. Assigns these variables directly to the MATLAB workspace:

   | Variable | Contents |
   |---|---|
   | `A`, `B`, `C`, `D` | State-space matrices (phase-variable form) |
   | `K` | State-feedback gain row vector |
   | `L` | Observer gain column vector |
   | `Ki` | Integral gain scalar (only if integral action selected) |
   | `poles` | Desired closed-loop poles |
   | `obs_poles` | Desired observer poles |
   | `specs` | Specs struct |
   | `wizard_result` | Full result struct (all intermediate values) |

4. Prints a **Simulink block-connection checklist** with exact parameter
   expressions to copy into block dialog boxes (e.g. `A - L*C`).
5. Optionally saves all variables to `design.mat` for use in a Simulink model.

### Typical student workflow

```text
1. Run the wizard (VS Code task or MATLAB Command Window).
2. Answer 6-7 prompts (takes ~1 minute).
3. Copy K, L (Ki) values onto your exam answer sheet.
4. Open your Simulink model, reference A/B/C/D/K/L by name in block dialogs.
5. Run the simulation — verify step response matches specs.
```

## Guided Tour of `src/`

Each file in [`src/`](src/) is a self-contained MATLAB function with a detailed header comment explaining what it does, how it works, and common mistakes. Below is a quick map to help you navigate the toolkit.

### Orchestrator

| File | What it does |
|---|---|
| [`full_system_design.m`](src/full_system_design.m) | End-to-end pipeline: converts a transfer function, checks controllability/observability, computes desired poles, designs K and L (and optionally Ki), then verifies everything. Start here to see how all the pieces fit together. |
| [`exam_wizard.m`](src/exam_wizard.m) | Interactive Q&A script that walks you through entering a transfer function, performance specs, and options, then calls `full_system_design` and prints exam-ready results plus a Simulink checklist. |

### Transfer-Function → State-Space Conversion

| File | What it does |
|---|---|
| [`tf2ss_phase.m`](src/tf2ss_phase.m) | Converts G(s) = num(s)/den(s) into **phase-variable** (companion) form — the realization used for state-feedback design because `B = [0;…;0;1]`. |
| [`tf2ss_observer_canon.m`](src/tf2ss_observer_canon.m) | Converts the same transfer function into **observer canonical** form — the realization used for observer design because `C = [1 0 … 0]`. |

### Performance Specs → Pole Locations

| File | What it does |
|---|---|
| [`specs_to_poles.m`](src/specs_to_poles.m) | Turns overshoot (OS%) and a time spec (settling time Ts or peak time Tp) into the dominant second-order complex pole pair, plus intermediate values ζ, ωn, σ, ωd. |

### Controller & Observer Design

| File | What it does |
|---|---|
| [`design_state_feedback.m`](src/design_state_feedback.m) | Computes the state-feedback gain **K** via pole placement so that `eig(A − B·K)` matches your desired poles. Includes control-theory intuition, a worked example, and a list of common mistakes. |
| [`design_observer.m`](src/design_observer.m) | Computes the observer gain **L** via the transpose trick (`place(A′, C′, poles)′`) so that the estimation-error dynamics `A − L·C` converge quickly. Explains the duality between observability and controllability. |
| [`design_integral_ctrl.m`](src/design_integral_ctrl.m) | Augments the system with an integrator state and finds `[K, ke]` so that steady-state tracking error is zero for step inputs. Explains the augmented-system construction and the sign convention for ke. |

### System Analysis

| File | What it does |
|---|---|
| [`check_controllability.m`](src/check_controllability.m) | Builds the controllability matrix `CM = [B, AB, …, A^{n-1}B]` and checks whether `rank(CM) = n`. Required before state-feedback design. |
| [`check_observability.m`](src/check_observability.m) | Builds the observability matrix `OM = [C; CA; …; CA^{n-1}]` and checks whether `rank(OM) = n`. Required before observer design. |
| [`check_stability.m`](src/check_stability.m) | Checks open-loop stability by inspecting `eig(A)` — counts right-half-plane, left-half-plane, and imaginary-axis poles. |

### Verification & Export

| File | What it does |
|---|---|
| [`verify_solution.m`](src/verify_solution.m) | Confirms that the designed gains K (and optional ke) and L actually produce the expected closed-loop and observer poles, returning PASS/FAIL flags and maximum pole errors. |
| [`export_to_simulink.m`](src/export_to_simulink.m) | Assigns all design variables (A, B, C, D, K, L, Ki, poles) to the MATLAB base workspace and prints a step-by-step Simulink block-connection checklist. |
