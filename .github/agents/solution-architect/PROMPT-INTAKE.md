# Intake Inputs (File-Based Approved Proposal)

## Trigger Context
- Input source: Approved feature proposal file from `docs/features/approved/`
- File path: `docs/features/approved/<feature-slug>.md`
- Approval source: AgileMaster validation (🟢 APPROVED status)

## Proposal Metadata (Extracted from File)
- Feature Name:
- Feature Slug (for output path `docs/feature-plans/<feature-slug>/`):
- Business Goal:
- Priority (P0/P1/P2):

## Mandatory Sections Verified (from AgileMaster)
- In Scope:
- Out of Scope:
- Constraints:
  - time:
  - compatibility:
  - hardware/resource:
  - tooling:
- Dependencies or Related Features:
  - current features (required for this work):
  - possible future features (to consider for future-proofing):
- Acceptance Expectations:
- Requested Output Depth:
  - [ ] high-level only
  - [ ] high-level + execution-minimum detail

## Architecture References
- `docs/architecture/current-architecture.md` (current state)
- `docs/architecture/hw-sw-contract.md` (hardware-software contract)
- `docs/architecture/repository-map.md` (code structure and module map)

## Architect's Initial Assessment
- Scope clarity: (OK / needs clarification)
- Hardware-software contract conflicts: (none / specify)
- Ambiguities requiring PO input:
- Preliminary risk flags:

## Design Output Destination
- Target folder: `docs/feature-plans/<feature-slug>/`
- Expected files:
  - `00-brief.md`
  - `01-solution-plan.md`
  - `02-rollout-test-doc-plan.md`
  - `03-dev-agent-prompts.md`
  - `04-decision-log.md`
