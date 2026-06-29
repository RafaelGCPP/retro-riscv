# Solution Architect Validation Checklist

## Input Validation
- [ ] Approved feature proposal file located in `docs/features/approved/`.
- [ ] Proposal contains all mandatory sections from AgileMaster validation.
- [ ] Requested Output Depth is explicit (high-level only / high-level + execution-minimum detail).

## Scope Discipline
- [ ] Feature scope is explicitly bounded and non-overlapping with related features.
- [ ] Out-of-scope items are clearly listed and justified.
- [ ] No uncontrolled full-system redesign drift.

## Architecture Assessment
- [ ] Current-state impact on `current-architecture.md` identified.
- [ ] Impact on `hw-sw-contract.md` (registers, MMIO, memory layout) identified.
- [ ] Impact on `repository-map.md` (new modules, code paths) identified.
- [ ] Backward compatibility risks and mitigations documented.
- [ ] Hardware-software contract gaps (if any) explicitly noted.

## Technical Design Quality
- [ ] Phases are incremental, implementable, and sequentially ordered.
- [ ] Critical technical decisions documented with rationale (alternatives considered).
- [ ] Risks and mitigations explicitly stated.
- [ ] Acceptance criteria are objective and testable (not implementation-specific).
- [ ] Output depth adheres to PO's requested level.

## Documentation Governance
- [ ] `current-architecture.md` update requirements identified and mapped to rollout phase.
- [ ] `repository-map.md` update requirements identified and mapped to rollout phase.
- [ ] `hw-sw-contract.md` update requirements identified and mapped to rollout phase.
- [ ] Doc update tasks are explicit in dev prompts.

## Dev Agent Handoff Quality
- [ ] Phase-scoped dev prompts are explicit and actionable (high-context, low-hallucination).
- [ ] Doc/code consistency validation prompt is included.
- [ ] Decision log is initialized with key trade-offs.
- [ ] Open questions are captured for PO follow-up.

## Output Completeness
- [ ] All five mandatory files generated under `docs/feature-plans/<feature-slug>/`:
  - [ ] `00-brief.md`
  - [ ] `01-solution-plan.md`
  - [ ] `02-rollout-test-doc-plan.md`
  - [ ] `03-dev-agent-prompts.md`
  - [ ] `04-decision-log.md`
