# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Development Commands

### Local Development & Testing

```bash
# Install dependencies
uv sync

# Run CLI locally (development)
uv run specify --help
uv run specify init test-project
uv run specify check

# Test with specific AI assistant
uv run specify init test-project --ai claude --debug
uv run specify init . --ai claude          # Current directory
uv run specify init --here --ai copilot    # Alternative syntax
```

### Installation Methods

```bash
# Option 1: Persistent installation (recommended)
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git

# Option 2: One-time usage
uvx --from git+https://github.com/github/spec-kit.git specify init <PROJECT_NAME>

# Upgrade existing installation
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git
```

### Agent Context Updates

```bash
# Update agent context files (bash/zsh)
./scripts/bash/update-agent-context.sh claude

# PowerShell
./scripts/powershell/update-agent-context.ps1 claude
```

## Architecture Overview

### Single-File CLI Design

The entire CLI is contained in `src/specify_cli/__init__.py` (~1,126 lines). This deliberate design keeps the codebase simple and maintainable:

- **AGENT_CONFIG**: Central configuration mapping 12+ AI agents to folders, install URLs, and CLI requirements
- **StepTracker**: Hierarchical progress tracking with Rich UI updates
- **Template System**: Downloads templates from GitHub releases and extracts them with directory flattening
- **Cross-platform Support**: Handles both bash/PowerShell scripts and Unix/Windows differences

### Key Components

- `src/specify_cli/__init__.py` - Complete CLI implementation
- `templates/` - Templates packaged as GitHub release assets
- `scripts/bash/` & `scripts/powershell/` - Cross-platform utility scripts
- `memory/constitution.md` - Development principles template (Articles I-IX)
- `.github/workflows/` - Release automation and packaging

### Template Distribution

Templates are packaged as ZIP files per agent/script combination during GitHub releases:
- Pattern: `spec-kit-template-{agent}-{script}.zip` (e.g., `spec-kit-template-claude-sh.zip`)
- CLI automatically downloads from latest release via GitHub API
- Supports GitHub token authentication for corporate environments

## Spec-Driven Development (SDD) Workflow

After running `specify init`, projects get these slash commands for structured development:

### Core Workflow (Sequential)

1. **`/speckit.constitution`** - Establish governing principles (Article I-IX framework)
2. **`/speckit.specify`** - Define WHAT to build (requirements, user stories)
   - Creates feature branch (e.g., `001-feature-name`)
   - Creates `specs/001-feature-name/spec.md`
   - Automatically creates git worktree at `.worktrees/001-feature-name/`
3. **`/speckit.plan`** - Define HOW to build (tech stack, architecture)
4. **`/speckit.tasks`** - Break down into actionable, parallelizable tasks
5. **`/speckit.implement`** - Execute all tasks following the plan

### Optional Quality Commands

- **`/speckit.clarify`** - Structured questioning to resolve ambiguities (before `/speckit.plan`)
- **`/speckit.analyze`** - Cross-artifact consistency validation (after `/speckit.tasks`)
- **`/speckit.checklist`** - Generate quality validation checklists

### Git Worktree Support

Automatic parallel development workflow:
- **Main repo**: Refine specifications, update plans
- **Worktree** (`.worktrees/001-feature/`): Implement features, run tests

```bash
# Example parallel workflow
# Terminal 1 (main repo)
cd /path/to/spec-kit
claude  # Work on specs/001-feature/spec.md

# Terminal 2 (worktree) 
cd /path/to/spec-kit/.worktrees/001-feature
claude  # Implement code, run tests
```

## AI Agent Integration

### AGENT_CONFIG System

The CLI supports 12+ AI agents through unified configuration in `src/specify_cli/__init__.py`:

```python
AGENT_CONFIG = {
    "claude": {
        "name": "Claude Code",
        "folder": ".claude/",
        "install_url": "https://docs.anthropic.com/en/docs/claude-code/setup",
        "requires_cli": True,
    },
    # ... 11 more agents
}
```

### Critical Design Principle

**Always use the actual CLI executable name as the AGENT_CONFIG key**, not a shortened version:
- ✅ Use `"cursor-agent"` (matches actual CLI tool)
- ❌ Don't use `"cursor"` as shortcut

This eliminates special-case mappings throughout the codebase.

### Agent Categories & Formats

**CLI-Based Agents** (require tool installation):
- Claude Code, Gemini CLI, Qwen Code, opencode, Codex CLI, etc.
- Use Markdown format with `$ARGUMENTS` placeholders

**IDE-Based Agents** (built into editors):
- GitHub Copilot, Windsurf, Kilo Code, Roo Code
- No CLI tool checks required

**Command File Formats**:
- **Markdown**: `$ARGUMENTS`, `{SCRIPT}`, `__AGENT__` placeholders
- **TOML**: `{{args}}` placeholders (Gemini, Qwen)

### Adding New AI Agent Support

When adding a new agent, update ALL of these locations:

1. **AGENT_CONFIG** in `src/specify_cli/__init__.py`
2. **CLI help text** in `init()` command
3. **README.md** supported agents table
4. **Release scripts**: `.github/workflows/scripts/create-release-packages.sh`
5. **Agent context scripts**: Both bash and PowerShell versions
6. **Version bump**: `pyproject.toml` version and `CHANGELOG.md` entry

See `AGENTS.md` for complete step-by-step integration guide.

## Constitutional Framework

Projects use `memory/constitution.md` template with immutable development principles:
- **Article I**: Library-First Principle
- **Article II**: CLI Interface Mandate
- **Article III**: Test-First Imperative (TDD non-negotiable)
- **Articles VII-VIII**: Simplicity & Anti-Abstraction
- **Article IX**: Integration-First Testing

These principles are enforced through implementation plan templates with "Phase -1 Gates".

## Testing & Validation

### Pre-PR Testing Checklist

- [ ] `uv run specify init test-project --ai claude` succeeds
- [ ] Test `--here` mode in empty directory
- [ ] Verify template extraction creates proper `.specify/` structure
- [ ] Confirm slash commands appear in AI agent after initialization
- [ ] Test with `--debug` flag for network/extraction issues

### Common Development Patterns

**Environment Variables**:
- `SPECIFY_FEATURE`: Override feature detection for non-Git workflows
- `GH_TOKEN`/`GITHUB_TOKEN`: GitHub API authentication
- `CODEX_HOME`: Required for Codex CLI (auto-generated setup instruction)

**Security Notice**: Agent folders may contain credentials - CLI displays warning to add to `.gitignore`

## Common Pitfalls

- Don't break single-file CLI architecture (`__init__.py` contains everything)
- Don't modify constitution.md without understanding immutable principles
- Don't add dependencies without strong justification
- Don't use shorthand AGENT_CONFIG keys - use actual executable names
- Don't forget to update ALL agent integration points when adding new agents
- Test on both Unix and Windows when modifying scripts/paths

## Key Files Reference

- `src/specify_cli/__init__.py` - Complete CLI implementation
- `AGENTS.md` - Comprehensive agent integration guide
- `CLAUDE.md` - Development context and architecture details
- `memory/constitution.md` - Development principles template
- `spec-driven.md` - Deep dive into SDD methodology
- `templates/` - Command templates and project scaffolding