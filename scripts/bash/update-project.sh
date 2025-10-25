#!/bin/bash
# update-project.sh - Update an existing project with latest spec-kit commands and scripts
#
# Usage: ./update-project.sh [OPTIONS] <project-path>
#
# Updates only spec-kit infrastructure files (commands, scripts, templates).
# Preserves project-specific files (specs, constitution, customizations).
#
# Options:
#   --dry-run    Show what would be updated without making changes
#   --backup     Create timestamped backup before updating (default: true)
#   --no-backup  Skip backup creation
#   --verbose    Show detailed output
#   --help       Display this help message
#
# Examples:
#   ./update-project.sh ~/projects/my-app
#   ./update-project.sh --dry-run ../PfizerOutdoCancerV2
#   ./update-project.sh --no-backup --verbose /path/to/project

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default options
DRY_RUN=false
CREATE_BACKUP=true
VERBOSE=false

# Get the directory where this script lives (spec-kit root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPECKIT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Counters
UPDATED_COUNT=0
SKIPPED_COUNT=0
CREATED_COUNT=0

# Usage message
usage() {
    echo "Usage: $0 [OPTIONS] <project-path>"
    echo ""
    echo "Update an existing project with latest spec-kit commands and scripts."
    echo ""
    echo "Options:"
    echo "  --dry-run     Show what would be updated without making changes"
    echo "  --backup      Create timestamped backup before updating (default)"
    echo "  --no-backup   Skip backup creation"
    echo "  --verbose     Show detailed output"
    echo "  --help        Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 ~/projects/my-app"
    echo "  $0 --dry-run ../PfizerOutdoCancerV2"
    echo "  $0 --no-backup --verbose /path/to/project"
}

# Parse arguments
PROJECT_PATH=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --backup)
            CREATE_BACKUP=true
            shift
            ;;
        --no-backup)
            CREATE_BACKUP=false
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            if [[ -z "$PROJECT_PATH" ]]; then
                PROJECT_PATH="$1"
            else
                echo -e "${RED}Error: Multiple project paths specified${NC}"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate project path
if [[ -z "$PROJECT_PATH" ]]; then
    echo -e "${RED}Error: Project path required${NC}"
    usage
    exit 1
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo -e "${RED}Error: Project path does not exist: $PROJECT_PATH${NC}"
    exit 1
fi

# Convert to absolute path
PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"

# Logging helpers
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo "  $1"
    fi
}

# Backup function
create_backup() {
    local src="$1"
    local timestamp=$(date +%Y%m%d-%H%M%S)
    local backup_dir="${PROJECT_PATH}/.specify/backups/${timestamp}"

    if [[ "$CREATE_BACKUP" == false ]]; then
        return
    fi

    if [[ -f "$src" ]]; then
        local rel_path="${src#$PROJECT_PATH/}"
        local backup_path="${backup_dir}/${rel_path}"
        local backup_parent="$(dirname "$backup_path")"

        if [[ "$DRY_RUN" == false ]]; then
            mkdir -p "$backup_parent"
            cp "$src" "$backup_path"
            log_verbose "Backed up: $rel_path"
        fi
    fi
}

# Copy file with backup
copy_file() {
    local src="$1"
    local dest="$2"
    local file_type="${3:-file}"

    if [[ ! -f "$src" ]]; then
        log_verbose "Source does not exist: $src"
        return
    fi

    local dest_dir="$(dirname "$dest")"
    local rel_dest="${dest#$PROJECT_PATH/}"

    # Check if destination exists and is different
    if [[ -f "$dest" ]]; then
        if cmp -s "$src" "$dest"; then
            log_verbose "Unchanged: $rel_dest"
            ((SKIPPED_COUNT++))
            return
        fi

        # File exists and is different - backup and update
        create_backup "$dest"

        if [[ "$DRY_RUN" == true ]]; then
            log_warning "[DRY RUN] Would update: $rel_dest"
        else
            cp "$src" "$dest"
            log_success "Updated: $rel_dest"
        fi
        ((UPDATED_COUNT++))
    else
        # File doesn't exist - create new
        if [[ "$DRY_RUN" == true ]]; then
            log_info "[DRY RUN] Would create: $rel_dest"
        else
            mkdir -p "$dest_dir"
            cp "$src" "$dest"
            log_success "Created: $rel_dest"
        fi
        ((CREATED_COUNT++))
    fi
}

# Copy directory of files matching pattern
copy_directory_pattern() {
    local src_dir="$1"
    local dest_dir="$2"
    local pattern="$3"
    local description="$4"

    if [[ ! -d "$src_dir" ]]; then
        log_verbose "Source directory does not exist: $src_dir"
        return
    fi

    log_info "Updating $description..."

    # Use find to locate files matching pattern
    while IFS= read -r -d '' src_file; do
        local filename="$(basename "$src_file")"
        local dest_file="${dest_dir}/${filename}"
        copy_file "$src_file" "$dest_file" "$description"
    done < <(find "$src_dir" -maxdepth 1 -name "$pattern" -type f -print0)
}

# Main update process
echo ""
log_info "Spec-Kit Project Update"
log_info "======================="
log_info "Spec-Kit: $SPECKIT_ROOT"
log_info "Project:  $PROJECT_PATH"
if [[ "$DRY_RUN" == true ]]; then
    log_warning "DRY RUN MODE - No changes will be made"
fi
echo ""

# 1. Update Claude commands
if [[ -d "$PROJECT_PATH/.claude/commands" ]]; then
    copy_directory_pattern \
        "$SPECKIT_ROOT/.claude/commands" \
        "$PROJECT_PATH/.claude/commands" \
        "speckit.*.md" \
        "Claude commands"
else
    log_verbose "No .claude/commands directory in project"
fi

# 2. Update Codex prompts
if [[ -d "$PROJECT_PATH/.codex/prompts" ]]; then
    copy_directory_pattern \
        "$SPECKIT_ROOT/.codex/prompts" \
        "$PROJECT_PATH/.codex/prompts" \
        "speckit.*.md" \
        "Codex prompts"
else
    log_verbose "No .codex/prompts directory in project"
fi

# 3. Update Factory droids
if [[ -d "$PROJECT_PATH/.factory/droids" ]]; then
    copy_directory_pattern \
        "$SPECKIT_ROOT/.factory/droids" \
        "$PROJECT_PATH/.factory/droids" \
        "speckit.*.md" \
        "Factory droids"
else
    log_verbose "No .factory/droids directory in project"
fi

# 4. Update bash scripts
if [[ -d "$PROJECT_PATH/.specify/scripts/bash" ]]; then
    log_info "Updating bash scripts..."
    for script in check-prerequisites.sh common.sh create-new-feature.sh manage-worktrees.sh setup-plan.sh update-agent-context.sh; do
        copy_file \
            "$SPECKIT_ROOT/.specify/scripts/bash/$script" \
            "$PROJECT_PATH/.specify/scripts/bash/$script" \
            "bash script"
    done
else
    log_verbose "No .specify/scripts/bash directory in project"
fi

# 5. Update PowerShell scripts
if [[ -d "$PROJECT_PATH/.specify/scripts/powershell" ]]; then
    log_info "Updating PowerShell scripts..."
    for script in create-new-feature.ps1 manage-worktrees.ps1; do
        copy_file \
            "$SPECKIT_ROOT/.specify/scripts/powershell/$script" \
            "$PROJECT_PATH/.specify/scripts/powershell/$script" \
            "PowerShell script"
    done
else
    log_verbose "No .specify/scripts/powershell directory in project"
fi

# 6. Update base templates (preserve user customizations by only updating if source is newer)
if [[ -d "$PROJECT_PATH/.specify/templates" ]]; then
    log_info "Updating base templates..."
    for template in spec-template.md plan-template.md tasks-template.md checklist-template.md agent-file-template.md; do
        copy_file \
            "$SPECKIT_ROOT/.specify/templates/$template" \
            "$PROJECT_PATH/.specify/templates/$template" \
            "template"
    done
else
    log_verbose "No .specify/templates directory in project"
fi

# 7. Update command templates
if [[ -d "$SPECKIT_ROOT/templates/commands" ]]; then
    log_info "Updating command templates..."
    copy_directory_pattern \
        "$SPECKIT_ROOT/templates/commands" \
        "$PROJECT_PATH/.specify/templates" \
        "*.md" \
        "command template"
else
    log_verbose "No templates/commands directory in spec-kit"
fi

# Summary
echo ""
log_info "Update Summary"
log_info "=============="
if [[ "$DRY_RUN" == true ]]; then
    log_info "Mode: DRY RUN (no changes made)"
else
    log_info "Mode: LIVE UPDATE"
fi
log_success "Created: $CREATED_COUNT files"
log_success "Updated: $UPDATED_COUNT files"
log_info "Unchanged: $SKIPPED_COUNT files"

if [[ "$CREATE_BACKUP" == true && "$DRY_RUN" == false && ($UPDATED_COUNT -gt 0) ]]; then
    log_info "Backups: $PROJECT_PATH/.specify/backups/"
fi

echo ""
if [[ "$DRY_RUN" == true ]]; then
    log_warning "Run without --dry-run to apply changes"
else
    log_success "Project updated successfully!"
fi
echo ""
