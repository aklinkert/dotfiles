#!/bin/bash
# Shell switching helper script
# Source this or run it to switch between bash and zsh

show_current_shell() {
    echo "Current shell: $SHELL"
    echo "Running in: $(ps -p $$ -o comm=)"
}

switch_to_zsh() {
    echo "Switching default shell to zsh..."
    chsh -s /bin/zsh
    echo "✅ Default shell changed to zsh"
    echo "⚠️  You need to restart your terminal for this to take effect"
    echo ""
    echo "To try zsh now without restarting, just type: zsh"
}

switch_to_bash() {
    echo "Switching default shell to bash..."
    chsh -s /bin/bash
    echo "✅ Default shell changed to bash"
    echo "⚠️  You need to restart your terminal for this to take effect"
    echo ""
    echo "To try bash now without restarting, just type: bash"
}

# Main menu
if [ "$1" = "zsh" ]; then
    switch_to_zsh
elif [ "$1" = "bash" ]; then
    switch_to_bash
else
    echo "=== Shell Switcher ==="
    echo ""
    show_current_shell
    echo ""
    echo "Usage:"
    echo "  $0 zsh     # Switch default shell to zsh"
    echo "  $0 bash    # Switch default shell to bash"
    echo ""
    echo "Or just try a shell without changing default:"
    echo "  zsh        # Start zsh session"
    echo "  bash       # Start bash session"
    echo "  exit       # Return to previous shell"
fi
