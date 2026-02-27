
---

# ADDENDUM: REVISIONS AND STOP-GATE

## Revision 1: Textbook File Size

The companion textbook ("An Introduction to Control Theory Applications with Matlab")
is **2.8 MB** (not 256 MB as initially estimated). This makes it feasible to include
as direct context alongside this document. The MATLAB command excerpts in Part 1 remain
the primary quick reference, but the full textbook can now be loaded for deeper examples.

## Revision 2: STOP-GATE — Missing Sources Required Before MATLAB Phase

**Status (2026-02-26): RESOLVED.** The required files are now present under
`docs/Exam 3 Prep/Exam 3 Prep/`, so MATLAB tool development may proceed.

### Previously Missing Files (Now Present)

| File | Size | Expected Category | Status |
|------|------|------------------|
| controllability_handout.pdf | 295 KB | H: Controllability | Found |
| controllerDesign_handout.pdf | 354 KB | G: State Feedback Design | Found |
| MTRE6000 - Question 2 - Controllability Quiz (Isabella Cabal...) | 429 KB | H: Controllability (quiz) | Found |
| Remaining module and handout PDFs | ? | Unknown | Found (multiple files) |
| Referenced images/diagrams | ? | Various (physical system figures) | Found (image set present) |

### Required Action

Proceed with Phase 1 implementation:

1. `specs_to_poles.m`
2. `tf2ss_phase.m`
3. `tf2ss_observer_canon.m`
4. `check_stability.m`

### Updated File Registry

The nested `Exam 3 Prep` source folder now contains the expected controllability,
controller design, observability, and module files needed to continue.

---

*End of addendum.*
