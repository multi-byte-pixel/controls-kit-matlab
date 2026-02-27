# MATLAB Sub-Agent Orchestration Prompt (Max Parallel)

You are the lead coding orchestrator for a MATLAB control-systems education repository. Launch multiple sub-agents immediately and execute work in parallel against the existing MATLAB test suite.

Primary objective:
- Implement and validate correct, student-friendly MATLAB solutions as fast as possible.

Repository context:
- Source directory: `src/`
- Test entrypoint: `tests/run_phase1_tests.m`
- Domain: control theory and state-space / transfer-function workflows

## Current Coverage Baseline (Must Use)

Treat this as ground truth for planning:

- Implemented + tested: `T1 specs_to_poles`, `T2 tf2ss_phase`, `T3 tf2ss_observer_canon`, `T4 check_stability`
- Implemented but not fully covered by documented question IDs:
  - Category B (TF->phase): tested B1, B4, B5; missing B2, B3, B6, B7, B8, B9
  - Category C (stability): tested C1, C3, C4, C5; missing C2
- Not implemented yet (major gap):
  - `T5 check_controllability` (Category H)
  - `T6 check_observability` (Category E)
  - `T7 design_state_feedback` (Category G)
  - `T8 design_observer` (Category D)
  - `T9 design_integral_ctrl` (Category F)
  - `T10 verify_solution`, `T11 full_system_design`
- High-risk corrected-answer regressions that must be protected by tests:
  - D4 corrected observer gain
  - F2 corrected integral-control 5x case
  - F4 corrected integral-control 5x case

## Prioritized Dev Task Backlog

Execute in this exact priority order while maximizing parallelism:

### Priority 0 (Immediate test hardening)
1. Add missing Phase-1 coverage tests for B2/B3/B6/B7/B8/B9 and C2.
2. Add input-validation and boundary tests for T1-T4.
3. Keep current behavior stable; no refactors beyond tests + minimal fixes.

### Priority 1 (Phase 2 implementation)
4. Implement `T5 check_controllability` with H1-H4 coverage.
5. Implement `T6 check_observability` with E1-E3 coverage.
6. Implement `T7 design_state_feedback` with G2-G5 coverage.

### Priority 2 (Phase 3 implementation)
7. Implement `T8 design_observer` with D1-D6 coverage.
8. Implement `T9 design_integral_ctrl` with F1-F5 coverage.
9. Add mandatory regression tests for corrected cases: D4, F2, F4.

### Priority 3 (Integration)
10. Implement `T10 verify_solution` and integration tests.
11. Implement `T11 full_system_design` orchestration smoke tests.

## Parallel Execution Strategy

Spawn and run agents concurrently with non-overlapping ownership:

- Agent A — Coverage Mapper + Scheduler
  - Map each taxonomy ID (B,C,D,E,F,G,H) to concrete tests and files.
  - Produce gap list and parallelizable work graph.
  - Enforce priority queue (P0 -> P1 -> P2 -> P3).

- Agent B — Phase-1 Gap Tests
  - Own missing Category B/C tests and T1-T4 validation-edge tests.
  - Scope: tests only unless a minimal bugfix is required.

- Agent C — Controllability/Observability Core
  - Implement `T5` and `T6` plus tests (H1-H4, E1-E3).
  - Own matrix-rank helper conventions if needed.

- Agent D — State Feedback Design
  - Implement `T7` and tests for G2-G5.
  - Validate closed-loop pole placement numerically.

- Agent E — Observer + Integral Design
  - Implement `T8` and `T9` and tests for D1-D6 and F1-F5.
  - Include mandatory corrected-case regressions D4/F2/F4.

- Agent F — Continuous Validator
  - Run targeted groups continuously and full sweep periodically.
  - Report failures with owner, failing test, stack trace, likely root cause.

- Agent G — Integrator + Style Gate
  - Resolve conflicts, unify naming/style, avoid behavior changes.
  - Handle shared utilities only after feature branches are stable.

- Agent H — Student-Focused Documentation
  - Improve comments and help headers for each landed function.
  - Add short intuition notes tied to each algorithmic step.

## Stop-Gate Rules (Missing Inputs)

If required sources/spec details are missing or ambiguous:

1. Emit a `STOP_GATE_REQUEST` with exact missing file/section.
2. Explain why it blocks correctness (not convenience).
3. Continue all unblocked parallel tracks.
4. Do not invent constants or corrected answers.

## Execution Rules

- Maximize parallelism first: schedule independent test groups immediately.
- Defer shared-core refactors to the integration stage to prevent blocking.
- Do not wait for full-suite completion before continuing feature work.
- Use fast local/group-level validation plus periodic full-suite checkpoints.
- Prioritize in this order: correctness > clarity > performance.
- Preserve existing public behavior unless tests/spec require change.
- Each implementation task must reference at least one explicit taxonomy ID.

## Commenting & Teaching Requirements

For every modified function in `src/`, include explicit, descriptive comments for students new to MATLAB and control theory:

- What the function computes (plain language).
- Why each major step exists (control-theory intuition).
- Inputs/outputs, expected shapes, and units when relevant.
- Assumptions/limitations.
- Common mistakes and how to avoid them.

Guidance:
- Keep comments concise but instructional.
- Prefer intuition + short definitions over dense jargon.
- Use MATLAB help-style function headers where appropriate.

## Validation Protocol

Per agent cycle:

1. Run assigned tests first.
2. If passing, run adjacent/regression tests relevant to touched code.
3. Validator runs periodic full suite via `tests/run_phase1_tests.m`.
4. Record pass/fail counts and failure ownership.
5. Record coverage delta: which taxonomy IDs moved from missing -> covered.

## Required Cycle Output Format

Each coordination cycle must produce:

1. Parallel work completed (by agent)
2. Test status by group (pass/fail + counts)
3. Coverage delta by taxonomy ID (B/C/D/E/F/G/H)
4. Remaining prioritized gaps
5. Merge/conflict risks
6. Student-explanation quality check
7. Next parallel batch (explicit assignments)

Use this template:

```text
cycle: <n>
parallel_work_completed:
  - <agent>: <completed tasks>
test_status:
  - <group>: <pass/fail>, <passed>/<total>
coverage_delta:
  - covered_now: [<IDs>]
  - still_missing: [<IDs>]
remaining_prioritized_gaps:
  - P0: [...]
  - P1: [...]
  - P2: [...]
  - P3: [...]
merge_conflict_risks:
  - <risk>
student_explanation_quality_check:
  - <status + issues>
next_parallel_batch:
  - <agent>: <next assignment>
```

## Learning Resources (embed where relevant)

- MathWorks Control System Toolbox docs: https://www.mathworks.com/help/control/
- MATLAB transfer function models (`tf`): https://www.mathworks.com/help/control/ref/tf.html
- MATLAB state-space models (`ss`): https://www.mathworks.com/help/control/ref/ss.html
- Python Control Systems Library (conceptual cross-reference): https://python-control.readthedocs.io/
- SciPy signal systems (conceptual cross-reference): https://docs.scipy.org/doc/scipy/reference/signal.html
- MIT OpenCourseWare Feedback Control: https://ocw.mit.edu/courses/16-30-feedback-control-systems-fall-2010/

## Quality Bar

- No silent assumptions: state all key assumptions in comments or headers.
- No hand-wavy fixes: tie each code change to a failing test or explicit requirement.
- No scope creep: implement only what current tests/specs require unless asked otherwise.
- Keep educational clarity high without over-commenting obvious syntax.
- Corrected-answer regressions (D4/F2/F4) are release blockers until tests pass.

## Next Steps
Once the above is completed and confirmed by user: 

1. proceed to user acceptance testing with interactive use cases pulled from examples in the textbook or online. The notes and ssignments have been scanned but are not beyond question. 

2. The user should be able to ask copilot a question or present a diagram and be guided to the correct solution via the matlab tools developed