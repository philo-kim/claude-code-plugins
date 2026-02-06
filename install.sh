#!/bin/bash

# Claude Code Plugins Installer
# Usage: ./install.sh <plugin-name> or ./install.sh all

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGINS_DIR="$SCRIPT_DIR/plugins"
TARGET_DIR="$HOME/.claude/plugins"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Available plugins
AVAILABLE_PLUGINS=(
    "twophone"
    "ddd"
    "health"
)

show_help() {
    echo "Claude Code Plugins Installer"
    echo ""
    echo "Usage:"
    echo "  ./install.sh <plugin-name>    Install a specific plugin"
    echo "  ./install.sh all              Install all plugins"
    echo "  ./install.sh list             List available plugins"
    echo "  ./install.sh uninstall <name> Uninstall a plugin"
    echo ""
    echo "Available plugins:"
    for plugin in "${AVAILABLE_PLUGINS[@]}"; do
        echo "  - $plugin"
    done
}

list_plugins() {
    echo "Available plugins:"
    echo ""
    for plugin in "${AVAILABLE_PLUGINS[@]}"; do
        if [ -d "$TARGET_DIR/$plugin" ]; then
            echo -e "  ${GREEN}●${NC} $plugin (installed)"
        else
            echo -e "  ${YELLOW}○${NC} $plugin"
        fi
    done
}

install_plugin() {
    local plugin_name=$1

    if [ ! -d "$PLUGINS_DIR/$plugin_name" ]; then
        echo -e "${RED}Error: Plugin '$plugin_name' not found${NC}"
        return 1
    fi

    # Create target directory if not exists
    mkdir -p "$TARGET_DIR"

    # Copy plugin
    if [ -d "$TARGET_DIR/$plugin_name" ]; then
        echo -e "${YELLOW}Plugin '$plugin_name' already exists. Updating...${NC}"
        rm -rf "$TARGET_DIR/$plugin_name"
    fi

    cp -r "$PLUGINS_DIR/$plugin_name" "$TARGET_DIR/$plugin_name"
    echo -e "${GREEN}✓ Installed '$plugin_name' to $TARGET_DIR/$plugin_name${NC}"
}

uninstall_plugin() {
    local plugin_name=$1

    if [ -d "$TARGET_DIR/$plugin_name" ]; then
        rm -rf "$TARGET_DIR/$plugin_name"
        echo -e "${GREEN}✓ Uninstalled '$plugin_name'${NC}"
    else
        echo -e "${YELLOW}Plugin '$plugin_name' is not installed${NC}"
    fi
}

install_all() {
    echo "Installing all plugins..."
    echo ""
    for plugin in "${AVAILABLE_PLUGINS[@]}"; do
        install_plugin "$plugin"
    done
    echo ""
    echo -e "${GREEN}All plugins installed!${NC}"
}

# Main
case "$1" in
    ""|"-h"|"--help"|"help")
        show_help
        ;;
    "list")
        list_plugins
        ;;
    "all")
        install_all
        ;;
    "uninstall")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Please specify a plugin name${NC}"
            exit 1
        fi
        uninstall_plugin "$2"
        ;;
    *)
        install_plugin "$1"
        ;;
esac
