#!/bin/bash
############################
# linkfiles.sh
# This script creates symlinks from the home directory to dotfiles in ~/dotfiles
# Supports both bash and zsh configurations
############################

########## Variables

dir=~/dotfiles                    # dotfiles directory
olddir=~/dotfiles_old             # old dotfiles backup directory

# Files/folders to symlink in homedir
# Now includes both .bash_profile and .zshrc for dual shell support
files=".gitignore_global .gitconfig .bash_profile .zshrc functions.sh shell_common.sh git-completion.bash .htoprc .inputrc .jshintrc .direnvrc"

##########

# Create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

# Change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# Move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks
echo "Moving any existing dotfiles from ~ to $olddir"
for file in $files; do
    if [ -f ~/$file ] || [ -L ~/$file ]; then
      echo "  Backing up ~/$file"
      mv ~/$file ~/dotfiles_old/$file
    fi

    echo "  Creating symlink from $dir/$file to ~/$file"
    ln -s $dir/$file ~/$file
done

# Link liquidprompt (for bash)
if [ ! -L ~/liquidprompt ]; then
    ln -s $dir/liquidprompt/liquidprompt ~/liquidprompt
    echo "Creating symlink to liquidprompt in home directory."
fi

# Set up SSH directory and config
mkdir -p -m 0700 ~/.ssh
ln -sf $dir/ssh/config ~/.ssh/config
echo "Creating symlink to ssh config file."

########## Claude user-space config

claude_home=~/.claude
claude_dotfiles=$dir/.claude
claude_backup=$olddir/.claude

mkdir -p "$claude_dotfiles" "$claude_backup"

# Helper: backup + move + symlink a single path under ~/.claude
link_claude_entry() {
    local rel="$1"                          # e.g. agents, CLAUDE.md, skills/drawio
    local src="$claude_home/$rel"
    local dst="$claude_dotfiles/$rel"
    local bak="$claude_backup/$rel"

    # Already correctly symlinked
    if [ -L "$src" ] && [ "$(readlink "$src")" = "$dst" ]; then
        echo "  ~/.claude/$rel already linked"
        return 0
    fi

    mkdir -p "$(dirname "$bak")" "$(dirname "$dst")"

    if [ -e "$src" ] || [ -L "$src" ]; then
        if [ -e "$dst" ]; then
            # dotfiles copy already exists — back up home version, replace with symlink
            echo "  Backing up ~/.claude/$rel (dotfiles copy exists)"
            rm -rf "$bak"
            mv "$src" "$bak"
        else
            echo "  Moving ~/.claude/$rel -> dotfiles"
            # Stash a backup copy first, then move into dotfiles
            cp -a "$src" "$bak"
            mv "$src" "$dst"
        fi
    fi

    if [ ! -e "$dst" ]; then
        echo "  WARN: $dst missing, skipping link"
        return 0
    fi

    ln -snf "$dst" "$src"
    echo "  Linked ~/.claude/$rel -> $dst"
}

echo ""
echo "Linking Claude user-space config (~/.claude)"

# Top-level dirs and files
for entry in agents commands rules hooks CLAUDE.md settings.json statusline-command.sh; do
    link_claude_entry "$entry"
done

# Skills: only real (non-symlink) children, preserve plugin symlinks in place
mkdir -p "$claude_dotfiles/skills"
if [ -d "$claude_home/skills" ]; then
    for skill_path in "$claude_home/skills"/*; do
        [ -e "$skill_path" ] || continue
        # Skip symlinks (plugin-provided skills point at ~/.agents/skills/*)
        if [ -L "$skill_path" ]; then
            echo "  Skipping plugin symlink: $skill_path"
            continue
        fi
        skill_name="$(basename "$skill_path")"
        link_claude_entry "skills/$skill_name"
    done
fi

echo "...Claude user-space linked"

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Dotfiles are now symlinked!"
echo ""
echo "Shell configuration:"
echo "  - Bash: ~/.bash_profile (symlinked)"
echo "  - Zsh:  ~/.zshrc (symlinked)"
echo "  - Shared config: ~/dotfiles/shell_common.sh"
echo "  - Shared functions: ~/dotfiles/functions.sh"
echo ""
echo "To switch your default shell:"
echo "  - To zsh: chsh -s /bin/zsh"
echo "  - To bash: chsh -s /bin/bash"
echo ""
echo "Both shells are fully configured and ready to use!"
echo ""
