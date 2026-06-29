# Solution Architect Output Contract

## Input Confirmation
Agent receives: Approved feature proposal file from `docs/features/approved/<feature-slug>.md`

Agent must validate:
- Proposal is in `docs/features/approved/` (not proposals/)
- All mandatory sections from AgileMaster approval are present
- Requested Output Depth is explicit

## Output Generation
Agent creates or updates files under: `docs/feature-plans/<feature-slug>/`

### File 1: `00-brief.md`
**Purpose:** Executive summary and scope boundary.
- Problem statement (why this feature matters now)
- Business goal alignment
- Strict scope boundaries (In Scope vs Out of Scope)
- Key constraints (time, compatibility, hardware/resource, tooling)
- Assumptions
- Open questions (if any)

### File 2: `01-solution-plan.md`
**Purpose:** Detailed technical architecture and design.
- Proposed architectural approach
- Alternatives considered (2-3 maximum) with trade-offs
- Chosen approach and justification
- Component/module impact (what changes, what's added)
- Data-flow and interface impact
- Memory layout and register mapping (MMIO) implications
- Hardware-software contract adjustments
- Target environment specifics (QEMU vs Verilator vs Physical FPGA)
- Non-functional implications (performance, timing, resource utilization)
- High-level phase plan

### File 3: `02-rollout-test-doc-plan.md`
**Purpose:** Step-by-step execution and validation strategy.
- Rollout phases (sequential, incremental order)
- Detailed steps per phase (what gets implemented, tested, verified)
- Validation/testing strategy per phase (simulation, integration, unit tests)
- Risks and rollback guidance
- Explicit documentation update tasks:
  - Which files need updates (current-architecture.md, hw-sw-contract.md, repository-map.md)
  - When in the rollout each doc update occurs
  - What specific sections/content must be added or modified
- Success criteria per phase

### File 4: `03-dev-agent-prompts.md`
**Purpose:** Highly contextual, modular prompts for development agents.
- Phase-1 development prompt (detailed, modular, low-hallucination context)
- Phase-2+ development prompts (if applicable)
- Post-implementation documentation update prompt (e.g., update current-architecture.md with new module description)
- Documentation/code consistency validation prompt
- Each prompt must include:
  - Clear acceptance criteria
  - Relevant file references
  - Links to technical decisions or constraints

### File 5: `04-decision-log.md`
**Purpose:** Architectural Decision Log (mini-ADR).
- Timestamped decisions with context
- Trade-offs evaluated and rationale for chosen path
- Deferred decisions (with reason for deferral)
- Follow-up actions or open questions for PO
- References to hardware constraints or contract implications

## Presentation Style
- Present all files in chat using clear Markdown formatting.
- Explicitly state the destination path for each file.
- Highlight any ambiguities or questions requiring PO clarification before implementation.
- Confirm adherence to requested Output Depth.

## Validation Before Output
Agent must:
1. **Flag ambiguities:** If requirements or hardware constraints are ambiguous, present clarifying questions to the PO before generating the full plan.
2. **Validate scope:** Confirm no scope drift or uncontrolled redesign.
3. **Cross-check contracts:** Verify no unresolved conflicts with hw-sw-contract.md or current-architecture.md.
4. **Confirm depth:** Ensure output matches requested Output Depth level.
