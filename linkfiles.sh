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
