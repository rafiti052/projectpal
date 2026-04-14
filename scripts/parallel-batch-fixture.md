---
project: parallel-batch-fixture
phase: 7
type: ticket-bundle
status: fixture
created: 2026-04-10T22:05:00Z
---

## Summary
This fixture models one parallel-ready batch and one blocked dependency path for Phase 7.
It exists to verify wave scheduling, exclusive write ownership, bridge-save milestones, and final integration reporting in one repeatable bundle.

## Coverage Check
- Implementation Plan step 3 maps to tickets 101 and 102
- Implementation Plan step 4 maps to ticket 103
- Implementation Plan step 6 maps to ticket 104
- Implementation Plan step 7 maps to tickets 105 and 106

## Waves

### Wave A
- Entry criteria: fixture bundle is loaded and no earlier wave exists
- Exit criteria: runnable tickets are complete or deferred, and blocked tickets explain the boundary or dependency that stopped them
- Tickets: 101, 102, 103, 104
- Role slots: builder

### Wave B
- Entry criteria: Wave A exit criteria are satisfied
- Exit criteria: regression verification is recorded and the integration report is filled in
- Tickets: 105, 106
- Role slots: builder, verifier optional

## Ownership Boundaries
- Ticket 101 exclusively owns `prompts/tickets-generate.md`
- Ticket 102 exclusively owns `scripts/projectpal-flow.sh`
- Ticket 103 is blocked until tickets 101 and 102 are complete
- Ticket 104 owns `.projectpal/state.yml` for bridge-sync milestone updates
- Ticket 105 owns `scripts/projectpal-flow-tests.sh`
- Ticket 106 owns verification notes only

## Final Integration Report
- Wave summaries:
  - Wave A schedules one allowed parallel pair and one blocked dependency path
  - Wave B verifies the regression fixture and records the close result
- Active owners:
  - Wave A: builder
  - Wave B: builder, verifier optional
- Ownership collisions:
  - Expected ownership collisions: none when exclusive write boundaries are respected
- Blocked items:
  - Ticket 103 remains blocked until tickets 101 and 102 complete
- Verification results:
  - Record helper test output and any bridge-sync assertions
- Final batch status:
  - The batch closes only after the report is filled in and the verification result is recorded
