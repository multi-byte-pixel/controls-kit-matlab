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
