# update-project.ps1 - Update an existing project with latest spec-kit commands and scripts
#
# Usage: .\update-project.ps1 [OPTIONS] -ProjectPath <path>
#
# Updates only spec-kit infrastructure files (commands, scripts, templates).
# Preserves project-specific files (specs, constitution, customizations).
#
# Parameters:
#   -ProjectPath   Path to the project to update (required)
#   -DryRun        Show what would be updated without making changes
#   -NoBackup      Skip backup creation (backups are created by default)
#   -Verbose       Show detailed output
#   -Help          Display this help message
#
# Examples:
#   .\update-project.ps1 -ProjectPath C:\projects\my-app
#   .\update-project.ps1 -ProjectPath ..\PfizerOutdoCancerV2 -DryRun
#   .\update-project.ps1 -ProjectPath C:\projects\app -NoBackup -Verbose

[CmdletBinding()]
param(
    [Parameter(Position=0)]
    [string]$ProjectPath,

    [switch]$DryRun,
    [switch]$NoBackup,
    [switch]$Help
)

# Color output functions
function Write-InfoMessage {
    param([string]$Message)
    Write-Host "ℹ " -ForegroundColor Cyan -NoNewline
    Write-Host $Message
}

function Write-SuccessMessage {
    param([string]$Message)
    Write-Host "✓ " -ForegroundColor Green -NoNewline
    Write-Host $Message
}

function Write-WarningMessage {
    param([string]$Message)
    Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
    Write-Host $Message
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-Host "✗ " -ForegroundColor Red -NoNewline
    Write-Host $Message
}

function Write-VerboseMessage {
    param([string]$Message)
    if ($VerbosePreference -eq 'Continue') {
        Write-Host "  $Message" -ForegroundColor Gray
    }
}

# Usage message
function Show-Usage {
    Write-Host @"

Usage: .\update-project.ps1 [OPTIONS] -ProjectPath <path>

Update an existing project with latest spec-kit commands and scripts.

Parameters:
  -ProjectPath   Path to the project to update (required)
  -DryRun        Show what would be updated without making changes
  -NoBackup      Skip backup creation (backups are created by default)
  -Verbose       Show detailed output
  -Help          Display this help message

Examples:
  .\update-project.ps1 -ProjectPath C:\projects\my-app
  .\update-project.ps1 -ProjectPath ..\PfizerOutdoCancerV2 -DryRun
  .\update-project.ps1 -ProjectPath C:\projects\app -NoBackup -Verbose

"@
}

# Show help if requested
if ($Help) {
    Show-Usage
    exit 0
}

# Validate project path
if ([string]::IsNullOrWhiteSpace($ProjectPath)) {
    Write-ErrorMessage "Error: Project path required"
    Show-Usage
    exit 1
}

if (-not (Test-Path $ProjectPath -PathType Container)) {
    Write-ErrorMessage "Error: Project path does not exist: $ProjectPath"
    exit 1
}

# Get absolute paths
$ProjectPath = (Resolve-Path $ProjectPath).Path
$ScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SpecKitRoot = (Resolve-Path (Join-Path $ScriptRoot "..\..")).Path

# Counters
$UpdatedCount = 0
$SkippedCount = 0
$CreatedCount = 0

# Backup function
function New-FileBackup {
    param(
        [string]$SourcePath
    )

    if ($NoBackup) {
        return
    }

    if (Test-Path $SourcePath -PathType Leaf) {
        $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
        $relativePath = $SourcePath.Substring($ProjectPath.Length + 1)
        $backupPath = Join-Path $ProjectPath ".specify\backups\$timestamp\$relativePath"
        $backupDir = Split-Path -Parent $backupPath

        if (-not $DryRun) {
            New-Item -ItemType Directory -Force -Path $backupDir | Out-Null
            Copy-Item $SourcePath $backupPath -Force
            Write-VerboseMessage "Backed up: $relativePath"
        }
    }
}

# Compare files function
function Compare-FileContent {
    param(
        [string]$Path1,
        [string]$Path2
    )

    if (-not (Test-Path $Path1)) { return $false }
    if (-not (Test-Path $Path2)) { return $false }

    $hash1 = Get-FileHash $Path1 -Algorithm MD5
    $hash2 = Get-FileHash $Path2 -Algorithm MD5

    return $hash1.Hash -eq $hash2.Hash
}

# Copy file with backup
function Copy-FileWithBackup {
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [string]$FileType = "file"
    )

    if (-not (Test-Path $SourcePath)) {
        Write-VerboseMessage "Source does not exist: $SourcePath"
        return
    }

    $destDir = Split-Path -Parent $DestPath
    $relativeDest = $DestPath.Substring($ProjectPath.Length + 1)

    # Check if destination exists and is different
    if (Test-Path $DestPath) {
        if (Compare-FileContent $SourcePath $DestPath) {
            Write-VerboseMessage "Unchanged: $relativeDest"
            $script:SkippedCount++
            return
        }

        # File exists and is different - backup and update
        New-FileBackup $DestPath

        if ($DryRun) {
            Write-WarningMessage "[DRY RUN] Would update: $relativeDest"
        } else {
            Copy-Item $SourcePath $DestPath -Force
            Write-SuccessMessage "Updated: $relativeDest"
        }
        $script:UpdatedCount++
    } else {
        # File doesn't exist - create new
        if ($DryRun) {
            Write-InfoMessage "[DRY RUN] Would create: $relativeDest"
        } else {
            New-Item -ItemType Directory -Force -Path $destDir | Out-Null
            Copy-Item $SourcePath $DestPath -Force
            Write-SuccessMessage "Created: $relativeDest"
        }
        $script:CreatedCount++
    }
}

# Copy directory of files matching pattern
function Copy-DirectoryPattern {
    param(
        [string]$SourceDir,
        [string]$DestDir,
        [string]$Pattern,
        [string]$Description
    )

    if (-not (Test-Path $SourceDir -PathType Container)) {
        Write-VerboseMessage "Source directory does not exist: $SourceDir"
        return
    }

    Write-InfoMessage "Updating $Description..."

    Get-ChildItem -Path $SourceDir -Filter $Pattern -File | ForEach-Object {
        $destFile = Join-Path $DestDir $_.Name
        Copy-FileWithBackup $_.FullName $destFile $Description
    }
}

# Main update process
Write-Host ""
Write-InfoMessage "Spec-Kit Project Update"
Write-InfoMessage "======================="
Write-InfoMessage "Spec-Kit: $SpecKitRoot"
Write-InfoMessage "Project:  $ProjectPath"
if ($DryRun) {
    Write-WarningMessage "DRY RUN MODE - No changes will be made"
}
Write-Host ""

# 1. Update Claude commands
$claudeCommandsDir = Join-Path $ProjectPath ".claude\commands"
if (Test-Path $claudeCommandsDir -PathType Container) {
    Copy-DirectoryPattern `
        (Join-Path $SpecKitRoot ".claude\commands") `
        $claudeCommandsDir `
        "speckit.*.md" `
        "Claude commands"
} else {
    Write-VerboseMessage "No .claude\commands directory in project"
}

# 2. Update Codex prompts
$codexPromptsDir = Join-Path $ProjectPath ".codex\prompts"
if (Test-Path $codexPromptsDir -PathType Container) {
    Copy-DirectoryPattern `
        (Join-Path $SpecKitRoot ".codex\prompts") `
        $codexPromptsDir `
        "speckit.*.md" `
        "Codex prompts"
} else {
    Write-VerboseMessage "No .codex\prompts directory in project"
}

# 3. Update Factory droids
$factoryDroidsDir = Join-Path $ProjectPath ".factory\droids"
if (Test-Path $factoryDroidsDir -PathType Container) {
    Copy-DirectoryPattern `
        (Join-Path $SpecKitRoot ".factory\droids") `
        $factoryDroidsDir `
        "speckit.*.md" `
        "Factory droids"
} else {
    Write-VerboseMessage "No .factory\droids directory in project"
}

# 4. Update bash scripts
$bashScriptsDir = Join-Path $ProjectPath ".specify\scripts\bash"
if (Test-Path $bashScriptsDir -PathType Container) {
    Write-InfoMessage "Updating bash scripts..."
    $bashScripts = @(
        "check-prerequisites.sh",
        "common.sh",
        "create-new-feature.sh",
        "manage-worktrees.sh",
        "setup-plan.sh",
        "update-agent-context.sh"
    )
    foreach ($script in $bashScripts) {
        Copy-FileWithBackup `
            (Join-Path $SpecKitRoot ".specify\scripts\bash\$script") `
            (Join-Path $bashScriptsDir $script) `
            "bash script"
    }
} else {
    Write-VerboseMessage "No .specify\scripts\bash directory in project"
}

# 5. Update PowerShell scripts
$psScriptsDir = Join-Path $ProjectPath ".specify\scripts\powershell"
if (Test-Path $psScriptsDir -PathType Container) {
    Write-InfoMessage "Updating PowerShell scripts..."
    $psScripts = @(
        "create-new-feature.ps1",
        "manage-worktrees.ps1"
    )
    foreach ($script in $psScripts) {
        Copy-FileWithBackup `
            (Join-Path $SpecKitRoot ".specify\scripts\powershell\$script") `
            (Join-Path $psScriptsDir $script) `
            "PowerShell script"
    }
} else {
    Write-VerboseMessage "No .specify\scripts\powershell directory in project"
}

# 6. Update base templates
$templatesDir = Join-Path $ProjectPath ".specify\templates"
if (Test-Path $templatesDir -PathType Container) {
    Write-InfoMessage "Updating base templates..."
    $templates = @(
        "spec-template.md",
        "plan-template.md",
        "tasks-template.md",
        "checklist-template.md",
        "agent-file-template.md"
    )
    foreach ($template in $templates) {
        Copy-FileWithBackup `
            (Join-Path $SpecKitRoot ".specify\templates\$template") `
            (Join-Path $templatesDir $template) `
            "template"
    }
} else {
    Write-VerboseMessage "No .specify\templates directory in project"
}

# 7. Update command templates
$commandTemplatesSource = Join-Path $SpecKitRoot "templates\commands"
if (Test-Path $commandTemplatesSource -PathType Container) {
    Write-InfoMessage "Updating command templates..."
    Copy-DirectoryPattern `
        $commandTemplatesSource `
        $templatesDir `
        "*.md" `
        "command template"
} else {
    Write-VerboseMessage "No templates\commands directory in spec-kit"
}

# Summary
Write-Host ""
Write-InfoMessage "Update Summary"
Write-InfoMessage "=============="
if ($DryRun) {
    Write-InfoMessage "Mode: DRY RUN (no changes made)"
} else {
    Write-InfoMessage "Mode: LIVE UPDATE"
}
Write-SuccessMessage "Created: $CreatedCount files"
Write-SuccessMessage "Updated: $UpdatedCount files"
Write-InfoMessage "Unchanged: $SkippedCount files"

if (-not $NoBackup -and -not $DryRun -and $UpdatedCount -gt 0) {
    Write-InfoMessage "Backups: $ProjectPath\.specify\backups\"
}

Write-Host ""
if ($DryRun) {
    Write-WarningMessage "Run without -DryRun to apply changes"
} else {
    Write-SuccessMessage "Project updated successfully!"
}
Write-Host ""
