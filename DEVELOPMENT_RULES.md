Development Rules & Action Plan
Core Principle
THINK → READ → THINK → EXECUTE
Every change must follow this cycle to avoid rushed or inconsistent code.

1. Stack & Scope
Mobile: Flutter (with Provider for state management).

Backend: Laravel (serves APIs for mobile).

Database: PostgreSQL (Dockerized).

Users: Mobile App has Users + Organisers roles.

APIs: Laravel provides endpoints for Flutter app consumption.

Region: Pan-African system (not Kenya-specific).

2. Core Development Process
Step 1: THINK
Understand the requirement.

Identify dependencies and impact.

Plan approach mentally before touching code.

Step 2: READ
Review relevant files.

Check existing patterns, conventions, and flows.

Avoid duplication.

Step 3: THINK (Re-evaluate)
With new context, refine the approach.

Check alignment with architecture.

Anticipate edge cases.

Step 4: EXECUTE
Implement minimal, clean solution.

Follow codebase patterns.

Prioritize maintainability.

3. Coding Rules
No over-engineering → keep solutions simple.

Consistency first → follow existing naming, foldering, and design.

Context awareness → never change in isolation without reading dependencies.

Minimal navigation → keep UI clean, avoid unnecessary clutter.

User-centric terminology → use inclusive names (“Listings” instead of “Events”).

File size rule → max 350 lines per file. Split if larger.

No unnecessary files → update existing ones unless a new file is essential.

4. AI/Developer Task Protocol
To prevent mistakes, hallucinations, or unapproved rewrites:

4.1 Lock Task Scope
Each task must include:

Objective: Single sentence describing the task.

Constraints: Explicit “Do Not Change” list.

Completion Criteria: Exact definition of “done.”

✅ Example:
TASK: Fix null pointer bug in processOrder().
DO NOT: Modify unrelated functions or rename parameters.
DONE WHEN: processOrder() passes test cases A, B, C without errors.

4.2 Echo Back Understanding
Before executing, AI/developer must restate the task in their own words.

If wrong → get correction before starting.

4.3 Stepwise Execution
Break into micro-commits:

Identify minimal change.

Apply only that.

Stop & confirm.

❌ Never rewrite unrelated code.

4.4 Zero Unrequested Changes
Only touch code explicitly requested.

If something else seems necessary → ask for approval first.

4.5 No Speculative Fixes
Never guess requirements.

If unclear, ask questions before coding.

4.6 Loop Prevention
Max 3 attempts at solving a subtask.

If still failing → stop & request guidance.

4.7 Verification Before Delivery
Before marking task “done”:

Re-read original request.

Confirm constraints were respected.

List exact changes made.

Confirm nothing else was modified.

5. AI Collaboration (Vibe Coding)
When pairing with AI (Claude/ChatGPT):

Context is king → always provide project background.

Architecture first → agree on structure before coding.

Why before How → AI must explain reasoning before implementation.

Break down tasks → avoid “big-bang” code dumps.

Review & refine → never accept code blindly; give feedback.

Permission management → AI must ask before making major file or schema changes.

Embrace testing → test after every change.

Revert when necessary → roll back unwanted AI changes quickly.

✅ With this structure, you now have:

Clear human coding rules (simplicity, consistency, file size, naming).

AI usage protocol (stepwise, scoped, verified).

Process cycle (THINK → READ → THINK → EXECUTE).