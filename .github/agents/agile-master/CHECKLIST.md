# AgileMaster Validation Checklist

## Structural Completeness
- [ ] Proposal file location: `docs/features/proposals/{name}`
- [ ] Feature Name section populated and clear.
- [ ] Business Goal section populated with objective value statement.
- [ ] Priority clearly specified (P0/P1/P2).
- [ ] In Scope section with concrete, verifiable items.
- [ ] Out of Scope section with explicit boundary statements.
- [ ] Constraints section complete (time, compatibility, hardware/resource, tooling).
- [ ] Acceptance Expectations section with measurable criteria.
- [ ] Requested Output Depth explicitly declared.

## Quality and Clarity
- [ ] Business Goal explains "why now" with clear business value.
- [ ] In Scope and Out of Scope do not overlap.
- [ ] Acceptance Expectations are observable and testable (not implementation-specific).
- [ ] Dependencies section identifies current required features and anticipated future impacts.
- [ ] Priority is coherent with stated urgency and value.

## Architecture Consistency
- [ ] No conflict with `docs/architecture/current-architecture.md`.
- [ ] No conflict with `docs/architecture/hw-sw-contract.md`.
- [ ] Repository impact is comprehensible via `docs/architecture/repository-map.md`.

## Technical Debt & Hotspot Analysis
- [ ] Proposal identifies if it touches code hotspots or legacy structures.
- [ ] Opportunistic cleanup suggestions captured in validation notes (if applicable).

## Validation Outcome
- [ ] Single validation response generated.
- [ ] Approval status clearly indicated (🟢 APPROVED / 🟡 NEEDS REVISION / 🔴 ARCHITECTURAL CONFLICT).
- [ ] Next action for PO or architect explicitly stated.
