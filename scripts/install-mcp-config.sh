#!/bin/bash

# MCP Server Auto-Installer for VS Code (Linux/macOS)
# This script automatically installs the Microsoft Style Guide MCP server configuration

set -e

# Default options
FORCE=false
QUIET=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE=true
            shift
            ;;
        --quiet|-q)
            QUIET=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  --force, -f    Force installation, overwrite existing configuration"
            echo "  --quiet, -q    Run in quiet mode with minimal output"
            echo "  --help, -h     Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Function to write colored output
write_color() {
    local message="$1"
    local color="$2"
    
    if [[ "$QUIET" != "true" ]]; then
        case $color in
            "red")    echo -e "\033[31m$message\033[0m" ;;
            "green")  echo -e "\033[32m$message\033[0m" ;;
            "yellow") echo -e "\033[33m$message\033[0m" ;;
            "blue")   echo -e "\033[34m$message\033[0m" ;;
            "cyan")   echo -e "\033[36m$message\033[0m" ;;
            "gray")   echo -e "\033[90m$message\033[0m" ;;
            *)        echo "$message" ;;
        esac
    fi
}

# Function to test if VS Code is installed
test_vscode_installed() {
    # Check common installation paths
    local vscode_paths=(
        "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        "/usr/local/bin/code"
        "/usr/bin/code"
        "/snap/bin/code"
        "$HOME/.local/bin/code"
    )
    
    for path in "${vscode_paths[@]}"; do
        if [[ -x "$path" ]]; then
            return 0
        fi
    done
    
    # Check if 'code' command is available in PATH
    if command -v code >/dev/null 2>&1; then
        return 0
    fi
    
    return 1
}

# Function to get VS Code user settings directory
get_vscode_user_dir() {
    local user_dir
    
    case "$(uname -s)" in
        Darwin*)
            user_dir="$HOME/Library/Application Support/Code/User"
            ;;
        Linux*)
            user_dir="$HOME/.config/Code/User"
            ;;
        *)
            write_color "❌ Unsupported operating system" "red"
            exit 1
            ;;
    esac
    
    # Create directory if it doesn't exist
    if [[ ! -d "$user_dir" ]]; then
        mkdir -p "$user_dir"
        write_color "📁 Created VS Code user directory: $user_dir" "yellow"
    fi
    
    echo "$user_dir"
}

# Function to backup existing mcp.json
backup_existing_config() {
    local config_path="$1"
    
    if [[ -f "$config_path" ]]; then
        local timestamp=$(date +"%Y%m%d_%H%M%S")
        local backup_path="${config_path}.backup_${timestamp}"
        cp "$config_path" "$backup_path"
        write_color "💾 Backed up existing configuration to: $backup_path" "yellow"
        return 0
    fi
    return 1
}

# Function to merge MCP configurations using jq
merge_mcp_config() {
    local existing_config_path="$1"
    local new_server_config="$2"
    
    if [[ -f "$existing_config_path" ]]; then
        if command -v jq >/dev/null 2>&1; then
            # Use jq for proper JSON merging
            local merged_config
            merged_config=$(jq --argjson newserver "$new_server_config" \
                '.servers["microsoft-style-guide-docker"] = $newserver' \
                "$existing_config_path" 2>/dev/null || echo '{"servers":{"microsoft-style-guide-docker":'"$new_server_config"'}}')
            echo "$merged_config"
        else
            # Fallback: create new configuration
            write_color "⚠️  jq not found. Creating new configuration." "yellow"
            echo '{"servers":{"microsoft-style-guide-docker":'"$new_server_config"'}}'
        fi
    else
        echo '{"servers":{"microsoft-style-guide-docker":'"$new_server_config"'}}'
    fi
}

# Function to update Copilot Chat settings
update_copilot_chat_settings() {
    local user_dir="$1"
    local settings_path="$user_dir/settings.json"
    
    # Create Copilot Chat settings
    local copilot_settings
    read -r -d '' copilot_settings << 'EOF' || true
{
  "github.copilot.chat.experimental.mcp.enabled": true,
  "github.copilot.chat.experimental.mcp.servers": {
    "microsoft-style-guide-docker": {
      "enabled": true,
      "description": "Microsoft Style Guide analyzer",
      "icon": "$(book)",
      "quickActions": {
        "analyze": {
          "label": "Analyze with Style Guide",
          "command": "analyze_content",
          "description": "Check content against Microsoft Style Guide"
        },
        "improve": {
          "label": "Suggest Improvements", 
          "command": "suggest_improvements",
          "description": "Get improvement suggestions"
        },
        "guidelines": {
          "label": "Get Guidelines",
          "command": "get_style_guidelines",
          "description": "View style guidelines"
        }
      }
    }
  }
}
EOF
    
    if [[ -f "$settings_path" ]]; then
        # Merge with existing settings using jq if available
        if command -v jq >/dev/null 2>&1; then
            local merged_settings
            merged_settings=$(jq -s '.[0] * .[1]' "$settings_path" <(echo "$copilot_settings") 2>/dev/null || echo "$copilot_settings")
            echo "$merged_settings" | jq '.' > "$settings_path"
        else
            write_color "⚠️  jq not found. Manual merge required for Copilot Chat settings." "yellow"
            return 1
        fi
    else
        # Create new settings file
        echo "$copilot_settings" | jq '.' > "$settings_path" 2>/dev/null || echo "$copilot_settings" > "$settings_path"
    fi
    
    write_color "✅ Updated Copilot Chat settings in settings.json" "green"
}

# Function to check if VS Code is running
is_vscode_running() {
    if pgrep -x "code" >/dev/null || pgrep -f "Visual Studio Code" >/dev/null; then
        return 0
    fi
    return 1
}

# Main installation logic
main() {
    write_color "🚀 Microsoft Style Guide MCP Server Auto-Installer" "cyan"
    write_color "=================================================" "cyan"
    write_color ""
    
    # Check if VS Code is installed
    if ! test_vscode_installed; then
        write_color "❌ VS Code is not installed or not found in PATH" "red"
        write_color "Please install VS Code first: https://code.visualstudio.com/" "yellow"
        exit 1
    fi
    write_color "✅ VS Code installation detected" "green"
    
    # Get VS Code user directory
    local user_dir
    user_dir=$(get_vscode_user_dir)
    local mcp_config_path="$user_dir/mcp.json"
    
    write_color "📁 VS Code user directory: $user_dir" "cyan"
    write_color "📄 MCP config path: $mcp_config_path" "cyan"
    
    # Check if configuration already exists
    if [[ -f "$mcp_config_path" ]] && [[ "$FORCE" != "true" ]]; then
        write_color "⚠️  MCP configuration already exists" "yellow"
        if [[ "$QUIET" != "true" ]]; then
            read -p "Do you want to merge with existing configuration? (y/N): " response
            if [[ "${response,,}" != "y" ]]; then
                write_color "Installation cancelled by user." "yellow"
                exit 0
            fi
        else
            write_color "Use --force to overwrite existing configuration" "yellow"
            exit 1
        fi
    fi
    
    # Backup existing configuration if it exists
    if [[ -f "$mcp_config_path" ]]; then
        backup_existing_config "$mcp_config_path"
    fi
    
    # Define the new server configuration (simplified for better compatibility)
    local server_config
    read -r -d '' server_config << 'EOF' || true
{
  "type": "http",
  "url": "https://localhost/mcp"
}
EOF
    
    # Merge or create configuration
    local final_config
    final_config=$(merge_mcp_config "$mcp_config_path" "$server_config")
    
    # Write the configuration with proper formatting
    if command -v jq >/dev/null 2>&1; then
        echo "$final_config" | jq '.' > "$mcp_config_path"
    else
        echo "$final_config" > "$mcp_config_path"
    fi
    
    write_color "✅ MCP configuration installed successfully!" "green"
    
    # Update Copilot Chat settings
    write_color "🔧 Configuring Copilot Chat integration..." "cyan"
    if update_copilot_chat_settings "$user_dir"; then
        write_color "✅ Copilot Chat integration configured!" "green"
    else
        write_color "⚠️  Copilot Chat settings may need manual configuration" "yellow"
    fi
    
    write_color ""
    write_color "📋 Next steps:" "white"
    write_color "1. Restart VS Code to load the new configuration" "white"
    write_color "2. Ensure the MCP extension is installed in VS Code" "white"
    write_color "3. Look for 'Microsoft Style Guide' in Copilot Chat's @ menu" "white"
    write_color "4. Test with: @microsoft-style-guide-docker analyze \"Your text here\"" "white"
    write_color "5. Or use quick actions: Analyze, Improve, Guidelines" "white"
    write_color ""
    write_color "🔧 Verification commands:" "white"
    write_color "  curl -k https://localhost/health" "gray"
    write_color "  curl -k -X POST https://localhost/mcp/initialize -H \"Content-Type: application/json\"" "gray"
    write_color ""
    
    # Check if VS Code is currently running
    if is_vscode_running; then
        write_color "⚠️  VS Code is currently running. Please restart it to apply changes." "yellow"
        if [[ "$QUIET" != "true" ]]; then
            read -p "Do you want to restart VS Code now? (y/N): " restart
            if [[ "${restart,,}" == "y" ]]; then
                write_color "🔄 Restarting VS Code..." "cyan"
                pkill -f "Visual Studio Code" 2>/dev/null || pkill -x "code" 2>/dev/null || true
                sleep 2
                if command -v code >/dev/null 2>&1; then
                    nohup code >/dev/null 2>&1 &
                fi
            fi
        fi
    fi
    
    write_color "✅ Installation completed successfully!" "green"
}

# Run main function
main "$@"
