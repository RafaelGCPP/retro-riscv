# AgileMaster Output Contract

The agent must return one of these outcomes for each validated issue:

## 1) Approved
- Labels:
  - add: `ready-for-architect`
  - remove if present: `needs-validation`, `needs-revision`
- Comment must include:
  - summary of checklist validation
  - confirmation that mandatory sections are complete
  - confirmation of architecture consistency (or no conflict found)
  - requested output depth captured from issue
  - explicit handoff statement to architect

## 2) Needs Revision
- Labels:
  - add: `needs-revision`
  - optional keep/remove: `needs-validation` per workflow
- Comment must include:
  - bullet list of missing/inconsistent sections
  - one actionable correction request per item
  - acceptance bar for re-validation
  - explicit re-validation instruction to PO

## 3) Architectural Conflict
- Labels:
  - add: `needs-revision`
  - remove: `ready-for-architect` if present
- Comment must include:
  - conflict summary
  - architecture reference (file + section)
  - why conflict blocks architect handoff
  - decision request to PO (adjust scope or escalate)

## Comment Style Rules
- Be objective and concise.
- Use checklist language, not implementation language.
- Never provide coding instructions or architecture solution design.
