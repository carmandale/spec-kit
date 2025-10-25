---
description: Generate structured session summary capturing learnings, decisions, problems solved, and next steps.
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The `/speckit.session-summary` command generates a structured markdown file capturing the key information from the current development session. This includes discoveries, decisions, problems solved, files modified, and next steps.

### Command Syntax

```bash
/speckit.session-summary [--type TYPE] [--output PATH] [--format FORMAT]

Options:
  --type TYPE       Session type: feature|bug|research|planning|implementation|general (default: auto-detect)
  --output PATH     Custom output path (default: auto-detect based on feature context)
  --format FORMAT   Output format: markdown|json|yaml (default: markdown)
```

### Output Location Strategy

The command saves summaries to different locations based on context:

**Feature-Specific Work** (on branch `###-feature-name`):
```
specs/###-feature-name/session-summary-YYYY-MM-DD.md
```

**Non-Feature Work** (on main/master or no feature context):
```
sessions/YYYY-MM-DD-{type}.md
```

Where `{type}` is one of:
- `research` - Exploring codebase, investigating patterns, learning
- `bug` - Debugging, troubleshooting, fixing issues
- `exploration` - Experimenting, prototyping, testing ideas
- `documentation` - Writing docs, updating README, adding comments
- `general` - Miscellaneous work not fitting other categories

**Directory Management**:
- `sessions/` directory is auto-created if it doesn't exist
- `sessions/` is automatically added to `.gitignore` (personal notes, not committed)
- `specs/` summaries are committed to git (part of feature documentation)

**Example Paths**:
```
project-root/
├── sessions/               # Non-feature summaries (gitignored)
│   ├── 2025-10-21-research.md
│   ├── 2025-10-19-bug.md
│   └── 2025-10-15-exploration.md
├── specs/                  # Feature-specific (committed to git)
│   └── 001-user-auth/
│       └── session-summary-2025-10-21.md
└── memory/                 # Permanent artifacts (committed)
    └── constitution.md
```

### Execution Flow

1. **Parse Arguments**:
   - Extract `--type`, `--output`, and `--format` flags from user input
   - If `--type` not specified, auto-detect from context (current branch, recent commands)
   - If `--output` not specified, determine save location:
     - If on feature branch (###-feature-name), save to `specs/###-feature-name/session-summary-YYYY-MM-DD.md`
     - If on main/master or no feature context:
       - Auto-detect session type (research, bug, exploration, documentation, general)
       - Save to `sessions/YYYY-MM-DD-{type}.md`
       - Create `sessions/` directory if it doesn't exist
       - Add `sessions/` to `.gitignore` if not already present
     - For planning phase, suggest `specs/###-feature-name/planning-decisions.md`
     - For implementation phase, suggest `specs/###-feature-name/implementation-notes.md`

2. **Prepare Output Directory** (if using `sessions/` directory):
   - Check if `sessions/` directory exists at repository root
   - If not, create it: `mkdir -p sessions/`
   - Check if `.gitignore` contains `sessions/`
   - If not, append `sessions/` to `.gitignore` with comment:
     ```
     # Session summaries (personal notes, not committed)
     sessions/
     ```
   - Display notice: "📁 Created sessions/ directory (added to .gitignore)"

3. **Gather Session Context**:
   - Current date and time
   - Feature branch name (if applicable)
   - AI agent being used (Claude, Codex, Factory Droid, etc.)
   - Token usage estimate (from system information if available)
   - Session duration estimate (if possible)
   - Current workflow phase (specify, plan, tasks, implement, general)

4. **Analyze Conversation History** (Review all messages in current session):

   **Key Discoveries Section**:
   - Identify important revelations, insights, or findings
   - Look for phrases like "discovered", "found", "realized", "learned"
   - Extract technical discoveries (bugs, patterns, workarounds)
   - Note impact on feature/project
   - Include file/line references where applicable

   **Problems Solved Section**:
   - Identify errors, bugs, or blockers encountered
   - Extract root causes and solutions applied
   - List files modified to fix each problem
   - Include testing/verification steps taken
   - Reference error messages and log lines

   **Key Decisions Section**:
   - Identify architectural choices made
   - Capture trade-off discussions and final choices
   - Document "why" behind non-obvious decisions
   - Note alternatives considered and reasons for rejection
   - Include constitutional references (if applicable)

   **Files Modified Section**:
   - List all files created or edited
   - Include line ranges for significant changes
   - Brief description of change purpose
   - Link changes to requirements or problems solved

   **Next Steps Section**:
   - Extract explicit TODOs and action items
   - Identify pending decisions or clarifications needed
   - List follow-up work required
   - Note dependencies or blockers
   - Reference related features or issues

5. **Check for Sensitive Information**:
   - Scan generated content for patterns:
     - API keys: `api[_-]?key.*[=:]\s*[A-Za-z0-9]{20,}`
     - Tokens: `token.*[=:]\s*[A-Za-z0-9]{20,}`
     - Passwords: `password.*[=:]\s*\S+`
     - Private file paths: `/Users/[^/]+/`, `/home/[^/]+/`
   - If sensitive patterns detected:
     - Display warning: "⚠️ Potential sensitive information detected in summary"
     - List pattern types found (not actual values)
     - Recommend review before committing

6. **Generate Output** (Using appropriate format):

   **Markdown Format** (default):
   ```markdown
   # Session Summary: [Feature Name or General Description]

   **Session Date**: YYYY-MM-DD
   **Feature Branch**: [branch-name or N/A]
   **AI Agent**: [Claude Code | Codex CLI | Factory Droid | etc.]
   **Token Usage**: [estimate if available, e.g., "~75,000 / 1,000,000 (7.5%)"]
   **Duration**: [estimate if possible, e.g., "~2.5 hours"]
   **Phase**: [Specification | Planning | Implementation | General]

   ## Key Discoveries

   1. **[Discovery Title]**: [Brief description]
      - **Impact**: [How this affects the project]
      - **Reference**: [Related files, features, or documentation]

   [Repeat for each discovery]

   ## Problems Solved

   1. **Problem**: [Brief description of issue]
      - **Root Cause**: [Why it happened]
      - **Solution**: [How it was fixed]
      - **Files Modified**: [List of files with line ranges]
      - **Testing**: [Verification steps taken]

   [Repeat for each problem]

   ## Key Decisions

   1. **Decision**: [What was decided]
      - **Context**: [Why decision was needed]
      - **Alternatives Considered**: [Other options evaluated]
      - **Rationale**: [Why this choice was made]
      - **Reference**: [Related specs, constitution articles, or documentation]

   [Repeat for each decision]

   ## Files Modified

   - `path/to/file.ext` (lines X-Y) - [Brief description of changes]
   - `path/to/file2.ext` - [Brief description of changes]

   [List all modified files with locations and descriptions]

   ## Next Steps

   1. **[Action Item]**: [Description and context]
   2. **[Action Item]**: [Description and context]

   [List all pending tasks and follow-up work]

   ## Cross-References

   - **Constitution**: [Relevant articles if applicable]
   - **Features**: [Related feature numbers and names]
   - **Specs**: [Links to specification files]
   - **External Resources**: [Apple sample projects, documentation, etc.]
   ```

   **JSON Format** (if --format json):
   ```json
   {
     "metadata": {
       "session_date": "YYYY-MM-DD",
       "feature_branch": "branch-name or null",
       "ai_agent": "Claude Code",
       "token_usage": "estimate or null",
       "duration": "estimate or null",
       "phase": "Planning"
     },
     "discoveries": [
       {
         "title": "Discovery title",
         "description": "Brief description",
         "impact": "How this affects the project",
         "references": ["file1.ext", "feature-002"]
       }
     ],
     "problems": [
       {
         "description": "Problem description",
         "root_cause": "Why it happened",
         "solution": "How it was fixed",
         "files_modified": ["file1.ext:10-20", "file2.ext"],
         "testing": "Verification steps"
       }
     ],
     "decisions": [
       {
         "decision": "What was decided",
         "context": "Why decision was needed",
         "alternatives": ["Option A", "Option B"],
         "rationale": "Why this choice",
         "references": ["constitution.md:Article-VIII"]
       }
     ],
     "files_modified": [
       {
         "path": "path/to/file.ext",
         "lines": "10-20",
         "description": "Change description"
       }
     ],
     "next_steps": [
       "Action item 1",
       "Action item 2"
     ],
     "cross_references": {
       "constitution": ["Article VIII"],
       "features": ["002-agent-installer", "003-startup-loading"],
       "specs": ["specs/002-agent-installer/spec.md"],
       "external": ["Apple Petite Asteroids sample"]
     }
   }
   ```

   **YAML Format** (if --format yaml):
   Similar structure to JSON but in YAML syntax

7. **Write Output File**:
   - Check if output file already exists at target path
   - If exists, prompt user:
     ```
     File already exists: [path]

     Choose action:
       1) Overwrite - Replace existing file
       2) Append timestamp - Save as [filename]-HHMMSS.md
       3) Cancel - Exit without saving

     Your choice (1-3):
     ```
   - Write file to chosen location
   - Set appropriate file permissions

8. **Report Completion**:
   ```
   ✅ Session summary generated!

   📄 File: [absolute path to output file]
   📊 Captured: [N discoveries, M problems, P decisions]
   📝 Modified files: [count]
   ⚠️  Warnings: [any warnings about sensitive data or issues]

   Next steps:
   - Review file for accuracy and sensitive information
   - Consider adding to git (or .gitignore if contains private paths)
   - Use this file to continue work in a fresh session
   ```

## Auto-Integration with Workflow Commands

The session-summary functionality is automatically integrated into core workflow commands:

- **During `/speckit.specify`**: After completing specification, auto-generate `specs/###-feature/interview.md` containing all Q&A pairs from the specification process
- **During `/speckit.plan`**: After completing planning, auto-generate `specs/###-feature/planning-decisions.md` containing architecture choices, tech stack decisions, and trade-offs
- **During `/speckit.implement`**: After completing implementation, auto-generate `specs/###-feature/implementation-notes.md` containing task completion details, problems solved, and code locations

These auto-generated files use the same structure as manual session summaries but are filtered to include only information relevant to that workflow phase.

## Token Usage Warning

Monitor token usage throughout the session:

- **At 80% token usage**: Display warning message:
  ```
  ⚠️ Token Usage Warning: 80% of context limit reached

  Consider running /speckit.session-summary to capture session learnings before context loss.

  Current usage: ~800,000 / 1,000,000 tokens
  Remaining: ~200,000 tokens
  ```

- **At 95% token usage**: Auto-generate emergency summary:
  ```
  🚨 CRITICAL: Token limit approaching (95%)

  Auto-generating emergency session summary...

  ✅ Summary saved to: [path]

  Recommend starting fresh session and loading this summary for context.
  ```

## Edge Cases

- **Empty or routine session**: If analysis finds no significant discoveries, decisions, or problems, generate minimal summary with note:
  ```markdown
  # Session Summary: [Date]

  **Note**: This session contained primarily routine work with no major discoveries, decisions, or problems documented.

  ## Files Modified

  [List modified files]

  ## Next Steps

  [Extract any TODOs mentioned]
  ```
  Save to `sessions/YYYY-MM-DD-general.md` if no feature context.

- **Multiple features in single session**: If user worked on multiple feature branches, prompt:
  ```
  Multiple features detected in session:
  - 002-agent-installer
  - 003-startup-loading

  Select target(s) for summary:
    1) 002-agent-installer only (saves to specs/002-agent-installer/)
    2) 003-startup-loading only (saves to specs/003-startup-loading/)
    3) Both (generate separate summaries in respective specs/ dirs)
    4) General (saves to sessions/, cross-feature work)

  Your choice (1-4):
  ```

- **Sensitive information detected**: Display warning before writing:
  ```
  ⚠️ SENSITIVE INFORMATION DETECTED

  The summary contains potential sensitive patterns:
  - API keys or tokens (2 occurrences)
  - Private file paths (5 occurrences)

  Recommendations:
  - Review file before committing to git
  - Consider adding to .gitignore if contains credentials
  - Redact sensitive values before sharing with team

  Proceed with writing file? (y/n):
  ```

## Quality Guidelines

When generating session summaries:

1. **Be Specific**: Include file:line references, not just file names
2. **Capture Context**: Explain "why" decisions were made, not just "what"
3. **Preserve Evidence**: Quote error messages, log lines, and key user statements
4. **Link to Artifacts**: Reference related specs, plans, tasks, and constitution articles
5. **Structure for Reuse**: Make it easy for fresh AI session to load and continue work
6. **Minimize Noise**: Exclude trivial edits, formatting changes, and routine operations
7. **Highlight Impact**: Emphasize discoveries and decisions that affect multiple features or projects

## Examples

**Example 1: Feature Development Session**

Input:
```
/speckit.session-summary --type feature
```

Output saved to `specs/002-agent-installer/session-summary-2025-10-19.md` containing discoveries about multi-agent command formats, Codex requirements, and installation workflow updates.

**Example 2: Bug Fix Session**

Input:
```
/speckit.session-summary --type bug
```

Output saved to `sessions/2025-10-19-bug.md` containing problem analysis, root cause, solution applied, testing verification, and affected files. If this was for a specific GitHub issue, could use `--output sessions/2025-10-19-bug-123.md`.

**Example 3: Cross-Project Research**

Input:
```
/speckit.session-summary --type research
```

Output saved to `sessions/2025-10-19-research.md` containing insights discovered while testing features across spec-kit and PfizerOutdoCancerV2 projects, including cross-project patterns and integration points.
