# CLAUDE.md

Read `agents.md` at the start of every session. It contains:
- **Session start protocol** — how to orient yourself and identify what the user needs
- **Development workflow** — branching, verification, rendering, commit, push
- **Numerical verification protocol** — mandatory arithmetic checks that must be executed (not just reasoned about) before any commit
- **Task history** — check `taskdescriptions/<country>/` for prior instructions and decisions

The verification protocol exists because a calculation bug shipped to production despite an agent claiming to have verified all calculations. Do not skip it.
