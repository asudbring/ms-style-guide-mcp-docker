# MCP Server Auto-Installer for VS Code (Windows)
# This script automatically installs the Microsoft Style Guide MCP server configuration

param(
    [switch]$Force,
    [switch]$Quiet
)

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

# Function to test if VS Code is installed
function Test-VSCodeInstalled {
    $vscodePaths = @(
        "${env:LOCALAPPDATA}\Programs\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles}\Microsoft VS Code\Code.exe",
        "${env:ProgramFiles(x86)}\Microsoft VS Code\Code.exe"
    )
    
    foreach ($path in $vscodePaths) {
        if (Test-Path $path) {
            return $true
        }
    }
    
    # Also check if 'code' command is available in PATH
    try {
        $null = Get-Command code -ErrorAction Stop
        return $true
    }
    catch {
        return $false
    }
}

# Function to get VS Code user settings directory
function Get-VSCodeUserDir {
    $userDir = "$env:APPDATA\Code\User"
    if (-not (Test-Path $userDir)) {
        New-Item -Path $userDir -ItemType Directory -Force | Out-Null
        Write-ColorOutput "Created VS Code user directory: $userDir" "Yellow"
    }
    return $userDir
}

# Function to backup existing mcp.json
function Backup-ExistingConfig {
    param([string]$ConfigPath)
    
    if (Test-Path $ConfigPath) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupPath = "$ConfigPath.backup_$timestamp"
        Copy-Item $ConfigPath $backupPath
        Write-ColorOutput "Backed up existing configuration to: $backupPath" "Yellow"
    }
}

# Function to merge MCP configurations
function Merge-MCPConfig {
    param(
        [string]$ExistingConfigPath,
        [hashtable]$NewServerConfig
    )
    
    if (Test-Path $ExistingConfigPath) {
        try {
            $existingContent = Get-Content $ExistingConfigPath -Raw | ConvertFrom-Json
            
            # Ensure servers object exists
            if (-not $existingContent.servers) {
                $existingContent | Add-Member -NotePropertyName "servers" -NotePropertyValue @{}
            }
            
            # Add or update our server configuration
            $existingContent.servers | Add-Member -NotePropertyName "microsoft-style-guide-docker" -NotePropertyValue $NewServerConfig -Force
            
            return $existingContent
        }
        catch {
            Write-ColorOutput "Warning: Could not parse existing configuration. Creating new one." "Yellow"
            return @{
                servers = @{
                    "microsoft-style-guide-docker" = $NewServerConfig
                }
            }
        }
    }
    else {
        return @{
            servers = @{
                "microsoft-style-guide-docker" = $NewServerConfig
            }
        }
    }
}

# Function to update Copilot Chat settings
function Update-CopilotChatSettings {
    param([string]$UserDir)
    
    $settingsPath = Join-Path $UserDir "settings.json"
    $copilotSettings = @{
        "github.copilot.chat.experimental.mcp.servers" = @{
            "microsoft-style-guide-docker" = @{
                "enabled" = $true
                "description" = "Microsoft Style Guide analyzer"
                "icon" = '$(book)'
                "quickActions" = @{
                    "analyze" = @{
                        "label" = "Analyze with Style Guide"
                        "command" = "analyze_content"
                        "description" = "Check content against Microsoft Style Guide"
                    }
                    "improve" = @{
                        "label" = "Suggest Improvements"
                        "command" = "suggest_improvements"
                        "description" = "Get improvement suggestions"
                    }
                    "guidelines" = @{
                        "label" = "Get Guidelines"
                        "command" = "get_style_guidelines"
                        "description" = "View style guidelines"
                    }
                }
            }
        }
        "github.copilot.chat.experimental.mcp.enabled" = $true
    }
    
    try {
        if (Test-Path $settingsPath) {
            # Merge with existing settings
            $existingSettings = Get-Content $settingsPath -Raw | ConvertFrom-Json
            
            # Add Copilot Chat MCP settings
            foreach ($key in $copilotSettings.Keys) {
                $existingSettings | Add-Member -NotePropertyName $key -NotePropertyValue $copilotSettings[$key] -Force
            }
            
            $finalSettings = $existingSettings
        }
        else {
            $finalSettings = $copilotSettings
        }
        
        # Write updated settings
        $jsonContent = $finalSettings | ConvertTo-Json -Depth 10
        Set-Content -Path $settingsPath -Value $jsonContent -Encoding UTF8
        
        Write-ColorOutput "Updated Copilot Chat settings in settings.json" "Green"
    }
    catch {
        Write-ColorOutput "Warning: Could not update Copilot Chat settings: $($_.Exception.Message)" "Yellow"
    }
}

# Main installation logic
try {
    Write-ColorOutput "🚀 Microsoft Style Guide MCP Server Auto-Installer" "Cyan"
    Write-ColorOutput "=================================================" "Cyan"
    Write-ColorOutput ""
    
    # Check if VS Code is installed
    if (-not (Test-VSCodeInstalled)) {
        Write-ColorOutput "❌ VS Code is not installed or not found in PATH" "Red"
        Write-ColorOutput "Please install VS Code first: https://code.visualstudio.com/" "Yellow"
        exit 1
    }
    Write-ColorOutput "✅ VS Code installation detected" "Green"
    
    # Get VS Code user directory
    $userDir = Get-VSCodeUserDir
    $mcpConfigPath = Join-Path $userDir "mcp.json"
    
    Write-ColorOutput "📁 VS Code user directory: $userDir" "Cyan"
    Write-ColorOutput "📄 MCP config path: $mcpConfigPath" "Cyan"
    
    # Check if configuration already exists
    $configExists = Test-Path $mcpConfigPath
    if ($configExists -and -not $Force) {
        Write-ColorOutput "⚠️  MCP configuration already exists" "Yellow"
        $response = Read-Host "Do you want to merge with existing configuration? (y/N)"
        if ($response.ToLower() -ne 'y') {
            Write-ColorOutput "Installation cancelled by user." "Yellow"
            exit 0
        }
    }
    
    # Backup existing configuration if it exists
    if ($configExists) {
        Backup-ExistingConfig -ConfigPath $mcpConfigPath
    }
    
    # Define the new server configuration (simplified for better compatibility)
    $serverConfig = @{
        type = "http"
        url = "https://localhost/mcp"
    }
    
    # Merge or create configuration
    $finalConfig = Merge-MCPConfig -ExistingConfigPath $mcpConfigPath -NewServerConfig $serverConfig
    
    # Write the configuration
    $jsonContent = $finalConfig | ConvertTo-Json -Depth 10
    Set-Content -Path $mcpConfigPath -Value $jsonContent -Encoding UTF8
    
    Write-ColorOutput "✅ MCP configuration installed successfully!" "Green"
    
    # Update Copilot Chat settings
    Write-ColorOutput "🔧 Configuring Copilot Chat integration..." "Cyan"
    Update-CopilotChatSettings -UserDir $userDir
    
    Write-ColorOutput ""
    Write-ColorOutput "📋 Next steps:" "White"
    Write-ColorOutput "1. Restart VS Code to load the new configuration" "White"
    Write-ColorOutput "2. Ensure the MCP extension is installed in VS Code" "White"
    Write-ColorOutput "3. Look for 'Microsoft Style Guide' in Copilot Chat's @ menu" "White"
    Write-ColorOutput "4. Test with: @microsoft-style-guide-docker analyze `"Your text here`"" "White"
    Write-ColorOutput "5. Or use quick actions: Analyze, Improve, Guidelines" "White"
    Write-ColorOutput ""
    Write-ColorOutput "🔧 Verification commands:" "White"
    Write-ColorOutput "  curl -k https://localhost/health" "Gray"
    Write-ColorOutput "  curl -k -X POST https://localhost/mcp -H `"Content-Type: application/json`" -d '{`"jsonrpc`":`"2.0`",`"id`":1,`"method`":`"tools/list`",`"params`":{}}''" "Gray"
    Write-ColorOutput ""
    
    # Check if VS Code is currently running
    $vscodeProcesses = Get-Process -Name "Code" -ErrorAction SilentlyContinue
    if ($vscodeProcesses) {
        Write-ColorOutput "⚠️  VS Code is currently running. Please restart it to apply changes." "Yellow"
        if (-not $Quiet) {
            $restart = Read-Host "Do you want to restart VS Code now? (y/N)"
            if ($restart.ToLower() -eq 'y') {
                Write-ColorOutput "🔄 Restarting VS Code..." "Cyan"
                $vscodeProcesses | ForEach-Object { $_.CloseMainWindow() }
                Start-Sleep -Seconds 2
                Start-Process "code"
            }
        }
    }
    
    Write-ColorOutput "✅ Installation completed successfully!" "Green"
}
catch {
    Write-ColorOutput "❌ Installation failed: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Please check the error and try again." "Yellow"
    exit 1
}
