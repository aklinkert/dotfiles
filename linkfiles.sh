#!/bin/bash
############################
# linkfiles.sh
# This script creates symlinks from the home directory to any desired dotfiles in ~/dotfiles
############################

########## Variables

dir=~/dotfiles                    # dotfiles directory
olddir=~/dotfiles_old             # old dotfiles backup directory

# list of files/folders to symlink in homedir
files=".gitignore_global .bash_profile git-completion.bash .htoprc .inputrc"

##########

# create dotfiles_old in homedir
echo "Creating $olddir for backup of any existing dotfiles in ~"
mkdir -p $olddir
echo "...done"

# change to the dotfiles directory
echo "Changing to the $dir directory"
cd $dir
echo "...done"

# move any existing dotfiles in homedir to dotfiles_old directory, then create symlinks 
for file in $files; do
    echo "Moving any existing dotfiles from ~ to $olddir"
    mv ~/$file ~/dotfiles_old/
    echo "Creating symlink to $file in home directory."
    ln -s $dir/$file ~/$file
done

ln -s $dir/liquidprompt/liquidprompt ~/liquidprompt
echo "Creating symlink to liquidprompt in home directory."

mkdir -p -m 0700 ~/.ssh
ln -sf $dir/ssh/config ~/.ssh/config
echo "Creating symlink to ssh config file."

echo "done!"
