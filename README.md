# dotfiles

[![lint](https://github.com/aklinkert/dotfiles/actions/workflows/lint.yml/badge.svg)](https://github.com/aklinkert/dotfiles/actions/workflows/lint.yml)

Personal shell dotfiles for bash and zsh on macOS and Linux: shared aliases and functions, git config, readline/htop
settings, SSH config, [liquidprompt](https://github.com/nojhan/liquidprompt) (git submodule) and the Claude Code user
config in `.claude/`.

## Install

```shell
git clone --recurse-submodules git@github.com:aklinkert/dotfiles.git ~/dotfiles
~/dotfiles/linkfiles.sh
```

The repo must live in `~/dotfiles`. `linkfiles.sh` moves any existing files into `~/dotfiles_old` and symlinks
`.bash_profile`, `.zshrc`, `.gitconfig`, `.gitignore_global`, `.inputrc`, `.htoprc`, `.jshintrc`, `.direnvrc`,
`.default-npm-packages`, `functions.sh`, `shell_common.sh` and `git-completion.bash` into `~`, links liquidprompt and
`ssh/config`, and links the entries of `.claude/` (agents, commands, rules, hooks, skills, `CLAUDE.md`,
`settings.json`, statusline) into `~/.claude`. It is safe to re-run.

`switch-shell.sh` helps switching the login shell between bash and zsh.

## Layout

- `shell_common.sh`, `functions.sh`, `darwin_common.sh`, `linux_common.sh`: config shared by both shells
- `.bash_profile`, `bash/`: bash specifics
- `.zshrc`, `zsh/`: zsh specifics
- `.claude/`: Claude Code user config (symlinked to `~/.claude`)

## Lint

CI runs `shellcheck` on the repo's own bash scripts (vendored code and zsh files are excluded; see
`.github/workflows/lint.yml`). Documented rule exclusions live in `.shellcheckrc`.
