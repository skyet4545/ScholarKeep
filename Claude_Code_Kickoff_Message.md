# Claude Code — Kickoff Message

> Copy everything in the box below and paste it as your **first message** to Claude Code, after you've opened it inside your project folder (the folder that contains `FL_ESA_Receipt_Tracker_Build_Prompt.md`). It tells Claude Code exactly how to start so it doesn't try to build everything at once.

---

```
You're going to help me build an iOS app. The complete spec is in this folder:
FL_ESA_Receipt_Tracker_Build_Prompt.md — read it in full before doing anything.

A few ground rules so we stay on track:

1. Build it MILESTONE BY MILESTONE, in the order given in the spec (Section 15).
   Start with Milestone 1 (Foundations) only. Do not jump ahead.

2. Before you start coding a milestone, briefly tell me your plan for it and
   list the files you'll create or change. Wait for my "go" before writing code.

3. When you finish a milestone, stop and check your work against that
   milestone's "done when" criteria (and the Acceptance Criteria in Section 17).
   Tell me what's done and what's left, then wait before starting the next one.

4. Two hard constraints from the spec, do not violate them:
   - This is a STANDALONE companion app. Do NOT build any integration with
     EMA, Step Up For Students, AAA, MyScholarShop, or any state/portal API.
     There is no public API. All statuses and balances are entered by the parent.
   - Do NOT hard-code the eligibility rules in Swift. Load them from the
     versioned JSON ruleset described in the spec (seed JSON is in Appendix A).

5. Tech stack is fixed: native iOS, Swift + SwiftUI, iOS 17+, SwiftData for
   local storage, optional CloudKit backup, Apple Vision for on-device OCR.
   No third-party analytics, tracking, or ad SDKs.

6. Set up a git repo early and commit after each working milestone, so I can
   roll back if something breaks.

Now: read the spec, confirm you understand the two hard constraints in your own
words, and give me your plan for Milestone 1.
```

---

### After Milestone 1, for each following milestone just say:

```
Milestone 1 looks good. Proceed to Milestone 2 (Capture & OCR). Same rules:
show me your plan and the files first, then wait for my go.
```

### Tips for keeping it on track

- **One milestone per session is fine.** If a session gets long or Claude Code seems to be losing the thread, finish the current milestone, commit to git, then start a fresh session and say: *"Read the spec file again and the current code, then continue with Milestone N."*
- **Always ask it to build and run.** After it writes code, say *"Build this in the simulator and fix any errors before telling me it's done."* Claude Code can run the build and read the errors itself.
- **Make it test the eligibility engine.** Say *"Run the unit tests from the Appendix B test table and show me the results."* That's the riskiest logic, so verify it early.
