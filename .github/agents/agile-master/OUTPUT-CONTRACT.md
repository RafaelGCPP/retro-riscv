# AgileMaster Output Contract

The agent must return one of these outcomes for each validated proposal file:

## 🟢 STATUS: APPROVED
- **Response must include:**
  - Summary of validated checkpoints
  - Confirmation that all mandatory sections are complete and clear
  - Confirmation of architecture consistency (cite references or note "no conflict found")
  - Captured output depth level for architect
  - **Technical Debt Notes:** Proactive suggestions for opportunistic cleanups or refactoring related to touched components (if applicable)
  - **Handoff Action:** Explicit confirmation that file is ready to move to `docs/features/approved/` or hand to Solution Architect. Specify depth expected for design.

## 🟡 STATUS: NEEDS REVISION
- **Response must include:**
  - List of deficiencies (missing sections, vague content, untestable acceptance criteria)
  - Actionable request: concrete instruction for each missing/inconsistent item
  - Acceptance bar: explicit criteria for re-validation
  - Next step: PO action (file update required, then re-request validation)

## 🔴 STATUS: ARCHITECTURAL CONFLICT
- **Response must include:**
  - Conflict explanation: cite specific architecture file/section and describe structural collision clearly
  - Why this blocks architect handoff
  - Escalation request: ask PO for strategic decision (adjust proposal scope or update architecture baseline)
  - Path forward: decision options presented objectively

## Style Rules
- Be objective and concise.
- Use document/checklist language, not implementation language.
- Never provide architecture solution design or coding instructions.
- Use markdown formatting for readability.
