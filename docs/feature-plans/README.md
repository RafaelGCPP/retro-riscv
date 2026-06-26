# Feature Plans

This directory stores architecture-first plans for PO-prioritized features.

## Workflow
1. Create a folder: `docs/feature-plans/<feature-slug>/`
2. Resolve clarification gaps in the originating issue comments before finalizing the plan files.
3. Fill required plan files (`00` to `04`).
4. When issue discussion is needed, summarize decisions in the plan and link back to the issue thread instead of storing open questions in the architecture docs.
5. Hand off implementation using prompts in `03-dev-agent-prompts.md`.
6. Ensure post-implementation docs are updated.
7. Validate no contract/documentation drift.

## Naming
Use lowercase kebab-case for `<feature-slug>`.
Example: `uart-rx-interrupts`
