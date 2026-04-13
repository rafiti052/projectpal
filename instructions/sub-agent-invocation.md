<!-- Ownership: Layer 1 sub-agent contracts live here; source text originates in CLAUDE.md and is loaded when agent orchestration detail is needed. -->

# Sub-Agent Invocation

Use the **Agent** tool (not Task) to invoke all sub-agents. Agent is always available — Task requires schema loading and should not be used here.

Six sub-agents are active in the pipeline. All receive their input inline — never by file reference alone.

---

### 1. Complexity Classifier
Invoked at Phase 0 completion (see Phase 0 Protocol above).
```
Agent(Cynefin Classifier):
  input:  prompts/cynefin-classify.md + Phase 0 transcript (inline)
  output: complexity zone, confidence, plain-terms summary, route sentence
```

---

### 2. PRD Generator
Invoked at Phase 1 (see Phase 1 Discovery Protocol above).
```
Agent(PRD Generator):
  input:  prompts/prd-generate.md + transcript + confirmed complexity assessment
          + Parking Lot items (phase:prd) + MemPalace results (inline)
  output: complete PRD document with YAML frontmatter
```
Pre-debate brevity audit: always run the brevity audit before Critic/Judge. If output remains >2,000 words after the audit, surface warning before debate.

---

### 3. Critic
Invoked at Phase 2. Skipped for Clear path problems.
```
Agent(Critic):
  input:  prompts/critic-agent.md + full PRD text (inline)
  output: structured review with verdict [PASS | PASS WITH REVISIONS | NEEDS REWORK]
```

---

### 4. Judge
Invoked at Phase 2, only after Critic returns PASS or PASS WITH REVISIONS.
```
Agent(Judge):
  input:  prompts/judge-agent.md + full PRD text + Critic output (inline)
  output: Judge Deliberation + Final PRD (Debated) under exact header ## Final PRD (Debated)
```

**6-step debate protocol:**
```
Step 1: PRD Generator sub-agent completes → brevity audit → word count check → saved to artifacts
Step 2: If >2,000 words after brevity audit: warn user before proceeding
        Agent(Critic) receives: critic-agent.md + full PRD text (inline)
Step 3: Pal captures Critic output
Step 4: NEEDS REWORK routing:
        - PASS or PASS WITH REVISIONS → proceed to Step 5
        - NEEDS REWORK → stop, surface Critic's top issue, revise PRD. Return to Phase 1.
Step 5: Agent(Judge) receives: judge-agent.md + full PRD text + Critic output (inline)
Step 6: Pal saves debated PRD (status: debated) → presents at Phase 3 checkpoint with a short summary of the Judge result
        - Blockers must be answered explicitly before proceeding
        - Non-blocker concerns must be surfaced one by one and explicitly passed, revised, or deferred by the user
        - After the summary, ask only one question at a time
```

**Re-debate rule:** If a debated PRD is changed before Checkpoint 1 approval, and the change is substantial enough to alter a requirement, persona, assumption, success criterion, risk, or scope boundary, return the PRD to Phase 2 and rerun Critic and Judge before presenting it again. Minor wording cleanup that preserves meaning does not require a fresh debate pass.

---

### 5. Tech Spec Generator
Invoked at Phase 4 when the route is Needs a plan (see Phase 4 Tech Spec Protocol above).
```
Agent(Tech Spec Generator):
  input:  prompts/tech-spec-generate.md + full approved PRD text
          + MemPalace results + Parking Lot items (phase:4 / phase:tech-spec) (inline)
  output: complete tech spec document with YAML frontmatter
```

---

### 6. Ticket Generator
Invoked at Phase 6 after the last planning checkpoint is approved.
```
Agent(Ticket Generator):
  input:  prompts/tickets-generate.md + full approved tech spec text
          + Parking Lot items (phase:6 / phase:execution) (inline)
  output: complete ordered ticket set, one ticket per Implementation Plan item
```

**Phase 6 ticket protocol:**
```
Step 1: Read the approved planning artifact set
        - Needs a plan: read approved tech spec from .projectpal/artifacts/tech-spec/<name>.md
        - Clear path: derive tickets from the approved PRD and the already-bounded route
Step 2: Read Parking Lot items tagged phase:6 or phase:execution
Step 3: Agent(Ticket Generator) receives: tickets-generate.md + spec + parking lot (inline)
Step 4: Pal captures ticket set output
Step 5: Save each ticket as individual file: .projectpal/artifacts/tickets/<project-id>-NNN.md
        (zero-padded 3-digit numbers, e.g. myproject-001.md)
Step 6: Proceed to Phase 7 Implementation Protocol
```

For Clear path problems: keep the PRD Generator, skip Critic, Judge, and Tech Spec Generator, then move through Phase 3 → Phase 6 → Phase 7 → Phase 8.
