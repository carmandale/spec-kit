# Feature Specification: Session Context Preservation

**Feature Branch**: `002-session-context`
**Created**: 2025-10-19
**Status**: Draft
**Input**: User description: "Session Context Preservation - Auto-capture learnings and context"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Developer Approaching Token Limit (Priority: P1)

A developer is working through a complex feature with an AI agent (Claude, Codex, Factory Droid) and receives a warning that the session is approaching the token context limit. They need to capture critical learnings, decisions, and next steps before starting a fresh session.

**Why this priority**: Context loss is the most common pain point when working with AI agents on complex multi-session features. Without this, developers lose hours of accumulated knowledge.

**Independent Test**: Run a long session with multiple file edits and decisions. At 80% token usage, trigger `/speckit.session-summary` and verify the generated file contains all key decisions, problems solved, and next steps.

**Acceptance Scenarios**:

1. **Given** a developer is at 80% token usage during feature development, **When** they run `/speckit.session-summary`, **Then** the system generates a structured markdown file containing discoveries, decisions, problems solved, and next steps with file references.
2. **Given** a session summary has been generated, **When** the developer starts a fresh session and points to the summary, **Then** the AI agent can continue work without requiring the developer to manually re-explain context.

---

### User Story 2 - Planning Phase Context Handoff (Priority: P2)

A developer completes the `/speckit.specify` phase with one AI agent (e.g., Codex) and needs to hand off context to another agent (e.g., Claude) for the `/speckit.plan` phase. The planning agent needs clear context about interview answers, requirements decisions, and constitutional constraints.

**Why this priority**: Multi-agent workflows are common in spec-kit. Each agent needs clear context from previous phases without requiring the user to manually reconstruct conversations.

**Independent Test**: Complete a `/speckit.specify` session, generate context file, then start a fresh `/speckit.plan` session with the context file. Verify the planning agent has full context without user intervention.

**Acceptance Scenarios**:

1. **Given** a developer completes `/speckit.specify` with interview mode, **When** the system auto-generates `interview.md` in the feature's specs directory, **Then** the file contains all Q&A pairs with timestamps and user decisions.
2. **Given** a planning agent starts with `SESSION-CONTEXT-###.md`, **When** it reviews the context file, **Then** it can answer "What are the key requirements?" and "What constraints apply?" without asking the user.

---

### User Story 3 - Implementation Knowledge Capture (Priority: P3)

A developer implements multiple tasks during `/speckit.implement` and encounters several problems, makes architectural decisions, and discovers edge cases. They need these captured automatically for PR descriptions, documentation updates, and knowledge sharing with the team.

**Why this priority**: Implementation sessions generate valuable institutional knowledge that's often lost. Capturing this enables better PRs, documentation, and team learning.

**Independent Test**: Implement 5 tasks with at least 2 problems and 3 decisions. Run `/speckit.session-summary --type implementation`. Verify the output contains all problems, solutions, decisions, and affected files.

**Acceptance Scenarios**:

1. **Given** a developer implements 10 tasks in a session, **When** they run `/speckit.session-summary --type implementation`, **Then** the output includes a checklist of completed tasks with file:line references for each change.
2. **Given** implementation notes are generated, **When** the developer creates a PR, **Then** they can copy relevant sections directly into the PR description without manual reconstruction.

---

### User Story 4 - Multi-Project Knowledge Transfer (Priority: P3)

A developer works on two projects (e.g., spec-kit and PfizerOutdoCancerV2) in the same session, discovers patterns in one that apply to the other (e.g., multi-agent installation, worktree bugs), and needs these learnings captured for both projects.

**Why this priority**: Cross-project insights are valuable but often lost when context is scattered across multiple conversations. Structured capture enables knowledge reuse.

**Independent Test**: Work on two projects in a session, make discoveries relevant to both. Run `/speckit.session-summary --type research`. Verify the output sections clearly separate project-specific vs. cross-project learnings.

**Acceptance Scenarios**:

1. **Given** a developer tests feature in Project A and discovers bugs affecting Project B, **When** they generate session summary, **Then** the output includes a "Cross-Project Insights" section listing relevant findings for each project.
2. **Given** session summary contains cross-project patterns, **When** shared with team, **Then** other developers can apply insights to their projects without duplicating discovery work.

---

### Edge Cases

- **Session has no significant context**: System generates minimal summary with warning "Session contains primarily routine work with no major decisions"
- **Multiple features worked on in single session**: Auto-detect feature directories and prompt user to select which feature(s) the summary applies to
- **Session includes sensitive information** (API keys, credentials): Detect common patterns and warn user to review before committing summary file
- **Output file already exists at target path**: Prompt user with options: [Overwrite | Append timestamp | Cancel]
- **Session contains mixture of specification, planning, and implementation**: Auto-detect phase transitions and structure summary accordingly
- **User forgets to run summary before context limit**: At 95% token usage, automatically generate emergency summary and display path

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a `/speckit.session-summary` slash command that generates structured markdown files capturing session learnings
- **FR-002**: System MUST support type flags: `--type [feature|bug|research|planning|implementation|general]` to structure output appropriately
- **FR-003**: System MUST auto-detect feature context by examining current git branch and specs/ directories to determine appropriate save location
- **FR-004**: System MUST capture key information: discoveries, decisions, problems solved, files modified, next steps, cross-references to specifications
- **FR-005**: System MUST detect token usage approaching limit (80% threshold) and prompt user to generate summary before context loss
- **FR-006**: System MUST generate output in consistent markdown format with sections: Summary, Key Decisions, Problems Solved, Files Modified, Next Steps, Cross-References
- **FR-007**: System MUST preserve file:line references when capturing code changes (e.g., "Fixed worktree bug in create-new-feature.sh:177-209")
- **FR-008**: System MUST auto-integrate with workflow commands: `/speckit.specify` generates `interview.md`, `/speckit.plan` generates `planning-decisions.md`, `/speckit.implement` generates `implementation-notes.md`
- **FR-009**: System MUST support manual output path override via `--output [path]` flag for custom save locations
- **FR-010**: System MUST include metadata header: session date, feature branch, AI agent used, approximate token usage, session duration
- **FR-011**: System MUST detect sensitive information patterns (API keys, tokens, passwords) and warn user before writing file
- **FR-012**: System MUST support multiple file formats: `--format [markdown|json|yaml]` with markdown as default

### Key Entities

- **SessionSummary**: Structured representation of session context containing metadata, sections (decisions, problems, files), and references to related artifacts
- **ContextMetadata**: Session information including date, feature branch, AI agent, token usage estimate, duration, workflow phase
- **LearningEntry**: Individual discovery, decision, or problem with description, timestamp, category, and file references
- **FileReference**: Specific code location with file path, line numbers, change description, and relation to feature requirements
- **CrossReference**: Link between session artifacts and existing specs, plans, tasks, or constitution articles

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can generate comprehensive session summary in under 10 seconds with single command invocation
- **SC-002**: Fresh AI agent session can continue work effectively using only the generated summary file (no additional user explanation needed)
- **SC-003**: 90% of generated summaries contain sufficient context that team members unfamiliar with the work can understand decisions made
- **SC-004**: Summary files capture 100% of explicit decisions and problems discussed during session (verified by manual review)
- **SC-005**: Auto-integration with `/speckit.specify`, `/speckit.plan`, `/speckit.implement` generates phase-specific context files without manual command invocation
- **SC-006**: Token limit warning (80% threshold) prevents context loss in 100% of long-running sessions
- **SC-007**: Generated files require minimal manual editing (<5 minutes) before being suitable for team documentation or PR descriptions

## Implementation Notes

### Command Syntax

```bash
# Basic usage (auto-detects context)
/speckit.session-summary

# Specify type for structured output
/speckit.session-summary --type planning
/speckit.session-summary --type implementation
/speckit.session-summary --type research

# Custom output path
/speckit.session-summary --output path/to/custom-learnings.md

# Specify format
/speckit.session-summary --format json
```

### Auto-Integration Points

- **During `/speckit.specify`**: Auto-save `interview.md` to `specs/###-feature/` containing Q&A pairs
- **During `/speckit.plan`**: Auto-save `planning-decisions.md` to `specs/###-feature/` containing architecture choices and tech stack decisions
- **During `/speckit.implement`**: Auto-save `implementation-notes.md` to `specs/###-feature/` containing task completion, problems solved, and code locations

### Output Structure Example

```markdown
# Session Summary: [Feature Name or Description]

**Session Date**: 2025-10-19
**Feature Branch**: 002-session-context
**AI Agent**: Claude Code
**Token Usage**: ~75,000 / 1,000,000 (7.5%)
**Duration**: ~2.5 hours
**Phase**: Implementation

## Key Discoveries

1. **Multi-Agent Command Discovery**: Found that Codex requires `.codex/prompts/` (not `.codex/commands/`) and CODEX_HOME env var
   - **Impact**: Critical for Feature 002 multi-agent installer
   - **Reference**: Feature 002 spec, SESSION-2025-10-19-LEARNINGS.md:8-34

2. **Worktree Branch Checkout Bug**: Script checked out new branch then tried to create worktree for same branch
   - **Impact**: Blocked real-world testing on PfizerOutdoCancerV2
   - **Fix**: Capture original branch, switch back before worktree creation
   - **Reference**: create-new-feature.sh:177-209

## Problems Solved

1. **Problem**: Worktree creation failed with "branch already in use" error
   - **Root Cause**: Git doesn't allow branch to be checked out in multiple places
   - **Solution**: Switch to original branch before creating worktree for new branch
   - **Files Modified**: create-new-feature.sh:177-209, create-new-feature.ps1
   - **Testing**: Verified on spec-kit and PfizerOutdoCancerV2

2. **Problem**: Codex commands not discoverable after installation
   - **Root Cause**: Directory mismatch (.codex/commands/ vs .codex/prompts/)
   - **Solution**: Use correct directory and format (H1 headers, not YAML frontmatter)
   - **Files Modified**: Manual installation in .codex/prompts/

## Files Modified

- `.specify/scripts/bash/create-new-feature.sh` (lines 177-209) - Worktree fix
- `.specify/scripts/powershell/create-new-feature.ps1` - Worktree fix (PowerShell version)
- `PfizerOutdoCancerV2/.specify/memory/constitution.md` (v1.0.0 → v1.1.0) - Added Article VIII
- `PfizerOutdoCancerV2/AGENTS.md` (lines 307-367) - Added spec-kit section
- `PfizerOutdoCancerV2/.codex/prompts/` - Installed 8 spec-kit commands

## Next Steps

1. **Immediate**: Complete Feature 005 specification and implementation
2. **Feature 002**: Update spec based on multi-agent learnings
3. **Feature 004**: Create spec using interview mode insights
4. **Feature 003**: Run `/speckit.plan` with Codex using SESSION-CONTEXT-003.md
5. **Testing**: Verify Feature 005 by capturing today's session as test case

## Cross-References

- **Constitution**: Article VIII (Evidence-Based Changes and Apple Pattern Compliance)
- **Features**: 002 (agent-installer), 003 (startup-loading), 004 (interview-mode), 005 (session-context)
- **Memory Files**: SESSION-2025-10-19-LEARNINGS.md, SESSION-CONTEXT-003.md
```

### Multi-Agent Format Support

The command must generate appropriate formats for different AI agents:

- **Claude**: YAML frontmatter in `.claude/commands/`
- **Codex**: H1 headers in `.codex/prompts/` with CODEX_HOME support
- **Factory Droid**: H1 headers in `.factory/commands/`

The spec-kit installer should handle format conversion automatically during `specify init`.

### Token Usage Detection

- Monitor token usage throughout session
- At 80% threshold: Display warning with `/speckit.session-summary` suggestion
- At 95% threshold: Auto-generate emergency summary and display path
- Include usage estimate in summary metadata for future reference

### Sensitive Information Detection

Use pattern matching to detect common sensitive patterns:
- API keys: `api[_-]?key.*[=:]\s*[A-Za-z0-9]{20,}`
- Tokens: `token.*[=:]\s*[A-Za-z0-9]{20,}`
- Passwords: `password.*[=:]\s*\S+`
- Private paths: `/Users/[^/]+/` (consider adding to .gitignore)

Display warning before writing file if patterns detected.
