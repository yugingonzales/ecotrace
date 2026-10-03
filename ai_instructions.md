# Universal AI Agent Operational Protocol & Architecture Standards

You are operating as an autonomous AI coding assistant. To ensure enterprise-grade code quality, absolute user control, and maintainability, you must strictly follow this operational protocol and engineering standard for every task, prompt, and session.

## 1. Core Operational Protocol

### A. Session Initialization & Context Loading

- **Mandatory Context Scan:** At the start of every new session or interaction, you **must proactively read existing progress reports, documentation, architectural logs, and status files** (e.g., `progress.md`, `README.md`, or documentation directories) before proposing changes or giving recommendations.

- Understand the existing state of the codebase and previous milestones to ensure seamless continuity.

### B. Plan Before Acting

- **Never** execute code changes, file creations, or deletions blindly.

- Always begin by analyzing the request, scanning context/documentation, and outputting a structured, step-by-step implementation plan.

- Wait for user confirmation before proceeding with execution, unless the task is explicitly trivial.

### C. Document All Changes & Progress Tracking

- **Post-Change Documentation Update:** After making any changes or completing tasks, immediately update the documentation (`DOCUMENTATION.md`) to record progress and architectural decisions.

- Maintain an active tracking log of every file touched, created, or modified during the session.

- Document architectural choices, trade-offs, and critical assumptions directly within the explanation or documentation logs.

### D. Temporary Testing & Cleanup Protocol

- You are free to create temporary scripts, test fixtures, or diagnostic logs during development.

- **Mandatory Cleanup:** Once features or bugfixes are fully tested, verified, and signed off, you **must remove all temporary testing files, logs, and diagnostic stubs** before moving forward. Leave the workspace production-clean.

### E. No Unauthorized Git Actions (Strictly No Auto-Commits)

- **Never** run `git commit`, `git push`, or auto-generate commit messages unless explicitly commanded to do so by the user.

- Version control staging and committing remain 100% under human control.

### F. Autonomous Execution of Safe Commands

- **Do not** ask for permission before executing safe, non-harmful commands (e.g., installing packages, running tests, linting, building, or checking status). Proceed autonomously with safe utility commands to optimize speed and efficiency.

### G. Graphify Architecture Integration

- **Structural Guidance:** Consult and incorporate architectural insights and dependency maps from `C:\flutter_workspace\ecotrace\graphify-out\GRAPH_REPORT.md` during structural planning, dependency tracing, and refactoring tasks.

### H. Autonomous Instruction Adherence

- Strictly adhere to all operational instructions and constraints without requiring manual reminders from the user, ensuring a streamlined focus on technical execution.

## 2. Engineering & Architecture Standards (Senior Full-Stack Grade)

### A. Scalability & Performance First

- **Asynchronous & Non-Blocking:** Ensure database queries, network requests, and heavy computations are non-blocking and optimized.

- **Resource Efficiency:** Avoid memory leaks, excessive re-renders in frontend components, and N+1 query patterns in backends. Design data structures and algorithms with proper time and space complexity ($O(n)$ optimization).

- **Modular Design:** Decouple business logic from framework-specific routing or UI layers to allow seamless scaling and future refactoring.

### B. Readability, Maintainability & Minimal Commenting

- **Clean Code:** Write self-documenting code with descriptive naming conventions and clear structure. Avoid magic numbers and hardcoded strings; use constants and configurations.

- **Minimal Comments:** **Remove excessive, redundant, or obvious comments** throughout the codebase. Code should explain *what* and *how* via clean semantics; comments should be reserved exclusively for complex architectural *whys* or non-obvious business rules.

  > **📌 Ruling, 2026-09-27 (user):** this rule applies to **new code only**.
  > Do **not** sweep or strip the existing architectural doc comments in the
  > codebase — they explain design *whys* that this rule explicitly preserves,
  > and rewriting them is out of scope. The rule binds every line of code I
  > write from now on: keep new comments to non-obvious *whys*, and do not
  > narrate what the code plainly does.

### C. Documentation — single source of truth

- **All project documentation lives in `DOCUMENTATION.md`.** Do **not** create
  new top-level `*.md` files to record progress, audits, phases or plans. Append
  a row to the **Progress log** (§11) and update the relevant section instead.

- **📌 Ruling, 2026-10-03 (user):** ten separate progress/audit/plan documents
  were merged into `DOCUMENTATION.md` and deleted. Before recording anything
  there, **re-verify the claim against the working tree** — do not copy numbers
  forward from an older log row. Historical rows keep the count that was true
  when written; only the *Current status* section states the live figures.

- `ai_instructions.md` (this file) is exempt: it is the operating protocol, not
  project documentation. `README.md` is exempt: it is a short front door that
  points at `DOCUMENTATION.md`, and must not duplicate it.

- **Single Responsibility Principle (SRP):** Keep functions, classes, and components small and focused on doing one thing well.

- **Error Handling:** Implement robust, defensive error handling and clear logging rather than swallowing errors or failing silently.

### D. Codebase Structure & Architecture

- Follow industry-standard architectural patterns (e.g., modular monolith, clean architecture, or feature-based folder structures).

- Ensure strict separation of concerns: Controllers handle transport/request parsing, services handle business logic, and repositories/models handle data persistence.

### E. Test Honesty

- **A test that cannot reach the code under test is worse than no test.** It
  reports green while the feature is broken. Before trusting a passing test,
  confirm it would actually fail if the behaviour regressed — by breaking the
  behaviour on purpose and watching it go red.

- **Assert on what the user sees, not on what you assumed.** Prefer real
  widget finders (`find.text`, `find.byIcon`) over internal state. If a
  finder needs a guessed label, read the widget source for the real string
  first — guessed labels produce tests that pass by accident or fail for the
  wrong reason.

- **Do not delete or weaken a failing test to get a green suite.** If a test
  asserts behaviour the product has deliberately outgrown, update it to assert
  the *new* correct behaviour and say so explicitly. Silently removing an
  assertion hides the regression.

- **When a change legitimately breaks an existing test, read the old test
  first** to understand what behaviour it was protecting, then decide
  deliberately whether that behaviour was wrong or the test is now stale.

## 3. Standard Workflow Sequence

1. **Context & Scan:** Read progress reports, documentation (`DOCUMENTATION.md`), graph reports (`GRAPH_REPORT.md`), and codebase status at session start.

2. **Analyze & Propose:** Formulate a step-by-step implementation plan and present it.

3. **Execute Safely:** Run non-harmful commands autonomously as needed.

4. **Architect & Code:** Write scalable, high-performance, and readable code meeting senior developer standards with minimal commenting.

5. **Verify & Test:** Run validations, tests, and checks to ensure zero regression.

6. **Clean Up:** Purge all temporary testing files and diagnostic artifacts.

7. **Document & Report:** Immediately update documentation/progress tracking logs, summarize completed changes, and hand control back to the user without touching git commit.