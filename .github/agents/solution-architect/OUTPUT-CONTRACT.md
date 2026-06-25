# Output Contract

For each feature, generate these files under:
`docs/feature-plans/<feature-slug>/`

## 00-brief.md
- Problem statement
- Goal
- Scope / Out of scope
- Constraints
- Assumptions
- Open questions

## 01-solution-plan.md
- Proposed architecture approach
- Alternatives considered (2-3 max)
- Chosen approach and rationale
- Component/module impact
- Interface/data-flow impact
- Non-functional implications
- Phase plan

## 02-rollout-test-doc-plan.md
- Rollout steps by phase
- Validation/testing strategy (high-level)
- Risks + rollback guidance
- Documentation updates required (explicit file list)

## 03-dev-agent-prompts.md
- Prompt to implement phase 1
- Prompt to implement phase 2 (if applicable)
- Prompt to update docs post-implementation
- Prompt to validate doc/code contract consistency

## 04-decision-log.md
- Timestamped decisions
- Trade-offs
- Deferred decisions
- Follow-ups
