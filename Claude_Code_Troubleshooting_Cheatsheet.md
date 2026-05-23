# Claude Code — "If It Gets Stuck" Cheat Sheet

A plain-language guide for what to do when something goes sideways while building the app. You don't need to be a developer to use these — most are just things you type to Claude Code.

---

## First, the golden rules

- **Commit working code to git after every milestone.** Tell Claude Code: *"Commit this to git with a clear message."* If anything breaks later, you can always go back. This is your safety net.
- **When in doubt, make it run the app.** Say: *"Build and run this in the simulator and fix any errors before continuing."* Claude Code can read its own build errors and fix them.
- **Smaller asks = better results.** If a request is going badly, undo and ask for a smaller piece.

---

## Common situations & exactly what to say

**It starts building everything at once / jumps ahead.**
> Stop. Per the spec we build one milestone at a time. Roll back to just Milestone [N], and show me your plan before writing more code.

**It tries to connect to EMA / Step Up / a real account or balance.**
> That violates a hard constraint in the spec — there is no public API and this is a standalone tracker. Remove any integration code. All statuses and balances are entered manually by the parent.

**It hard-codes the eligibility rules into Swift.**
> The rules must come from the versioned JSON ruleset (Appendix A of the spec), not be hard-coded. Refactor so the eligibility engine reads the JSON.

**The build fails / there are red errors in Xcode.**
> The build is failing. Read the full error output, explain the cause in plain English, and fix it. Then build again to confirm it's clean.

**It says it's done but you're not sure it actually works.**
> Before we call this done, run it in the simulator, walk me through testing [the feature], and run the unit tests. Show me the results.

**The eligibility check gives wrong answers** (e.g., approves something it shouldn't).
> Run the Appendix B test cases. For any that fail, show me the input, the expected result, and the actual result, then fix the engine.

**It loses track / starts contradicting earlier work** (usually after a long session).
> Finish + commit the current piece, then start a **new** Claude Code session and say:
> *"Read FL_ESA_Receipt_Tracker_Build_Prompt.md and the existing code in this folder, summarize where the project stands, then continue with Milestone [N]."*

**A change broke something that used to work.**
> That change broke [feature] which worked before. Revert it (or use git to go back to the last working commit) and try a different approach.

**It keeps going in circles on the same bug.**
> We've tried this a few times. Step back: list 3 possible causes, add some logging/print statements to figure out which one it is, then fix the confirmed cause.

**You don't understand what it just did.**
> Explain what you just changed and why, in plain language, as if I'm not a developer.

---

## iOS-specific gotchas

- **"No such module" / can't find a framework** → usually a missing capability or import. Say: *"Add the required capability/import and explain what it's for."*
- **Camera or photo features crash on the simulator** → the simulator has no real camera; OCR/scanning must be tested on a **real iPhone**. Say: *"Make this degrade gracefully in the simulator and tell me which features need a physical device to test."*
- **iCloud backup not syncing** → CloudKit needs the iCloud capability turned on and you signed into iCloud on the device. Say: *"Walk me through the iCloud/CloudKit setup steps I need to do in Xcode and on my device."*
- **App won't install on your phone** → that's the Apple Developer signing step. Say: *"Walk me through signing the app with my Apple ID so I can run it on my own iPhone."*

---

## When to step away from Claude Code and get a human

Most things Claude Code can handle. Consider a developer's help (or Apple's docs/forums) if: you're stuck on Apple Developer account / App Store submission paperwork, you hit a paid-account or legal/privacy-policy requirement, or the same problem persists across multiple fresh sessions. Those are usually account/policy issues, not code issues.

---

## Quick reference — useful things to type

| You want to… | Say this |
|---|---|
| Save progress safely | "Commit this to git with a clear message." |
| Undo a bad change | "Revert that / go back to the last working commit." |
| Verify it works | "Build and run it, then walk me through testing." |
| Resume in a fresh session | "Read the spec and existing code, summarize status, continue Milestone N." |
| Slow it down | "Show me your plan and the files you'll change before writing code." |
| Understand a change | "Explain what you did in plain language." |
