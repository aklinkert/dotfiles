function gen-selfsigned-cert {
    local domain="$1"
    if [ "${domain}" == "" ]; then
        echo "Usage: ${0} <domain>"
        return
    fi

    docker run --rm \
        -e "SSL_SUBJECT=${domain}" \
        -e "CA_SUBJECT=${domain}" \
        -e "CA_EXPIRE=3650" \
        -e "SSL_SIZE=4096" \
        -e "SSL_DNS=*.${domain}" \
        paulczar/omgwtfssl
}

function kube-watch-all-without-kube-system {
  kube-watch-all-without kube-system
}

function kube-watch-all-without {
  local interval="${KUBE_WATCH_INTERVAL:-1}"
  local cmdLine="kubectl get pods --all-namespaces ${filters}"

  for filter in "$@"; do
    cmdLine="${cmdLine} | grep -v \"${filter}\""
  done
  watch -n "${interval}" "${cmdLine}"
}

function kube-delete-pods {
    local namespace="$1"
    local name="$2"
    if [ "${name}" == "" ]; then
        echo "Usage: kube-delete-pods <namespace> <name-filter>"
	return
    fi

    kubectl get pods -n "${namespace}" | grep "${name}" | awk '{{ print $1 }}' | xargs kubectl -n "${namespace}" delete pod "${@:3}"
}

function kube-port-forward {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: kube-port-forward <namespace> <deployment> <port>"
        return
    fi

    local namespace="$1"
    local deployment="$2"
    local port="$3"
    
    # Get pod name safely without eval
    local pod_name=$(kubectl get pods -n "$namespace" | grep "$deployment" | head -n 1 | awk '{ print $1 }')
    
    if [ -z "$pod_name" ]; then
        echo "Error: No pod found matching deployment '$deployment' in namespace '$namespace'"
        return 1
    fi
    
    echo "Executing: kubectl -n $namespace port-forward $pod_name $port"
    kubectl -n "$namespace" port-forward "$pod_name" "$port"
}

function kube-scale-all {
    local namespace="$1"
    local replicas="$2"
    if [ "${replicas}" == "" ]; then
        echo "Usage: kube-scale-all <namespace> <replicas>"
        return
    fi

    kubectl get -n "${namespace}" --no-headers deploy | first_col | xargs kubectl -n "${namespace}" scale --replicas="${replicas}" deployment
}

function docker-clean-images {
    docker images -f dangling=true -q | xargs docker rmi -f
}

function docker-delete-images {
    if [ "${1}" == "" ]; then echo "Please pass a name pattern for grep"; return; fi

    echo "Deleting the following images:"
    docker images | grep "$1" | awk '{ print $1 }' | tr '\n' ' '
    docker images | grep "$1" | awk '{ print $3 }' | xargs docker rmi -f
}

function docker-delete-all-images {
    read -r -p "Are you FUCKING SURE? There is no way back! " -n 1 reply
    echo    # (optional) move to a new line
    if [[ ! $reply =~ ^[Yy]$ ]]; then
      return
    fi

    docker images -q | xargs docker rmi -f
}

function docker-remove-status {
    docker ps --filter status=$1 -q | xargs docker rm -f
}

function docker-remove-stopped {
    docker-remove-status exited
}

function docker-remove-all {
    docker ps -a -q | xargs docker rm -f
}

function docker-stop-all {
    docker ps --filter status=running -q | xargs docker stop
}

function hash-key {
    echo -n "${1}" | openssl dgst -sha256 | cut -c-9
}

function gobuild-linux {
    CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-s' -installsuffix cgo -o "$(basename "$PWD")" .
}

function http-server {
    PORT="${PORT:-8080}"
    docker rm http-server || true
    echo "Server listening on http://localhost:${PORT}"
    docker run --name http-server -it -p "${PORT}:80"  -v "$(pwd):/usr/share/nginx/html:ro" nginx:alpine
}

function uuid-and-copy {
    uuidgen | awk '{print tolower($0)}' | xargs echo -n | pbcopy
}

function clear-dns-cache {
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
    echo "DNS cache flushed"
}

# colorize stdin according to parameter passed
# Shamelessly stolen from https://stackoverflow.com/a/23006365
function echoc {
    local color=$1
    local exp=$2

    # Map colour names to codes. Numeric input passes through untouched.
    case $color in
        ''|*[!0-9]*)
            # Lowercase only if tr is available; PATH may be munged (direnv etc).
            command -v tr >/dev/null 2>&1 && color=$(echo "$color" | tr '[:upper:]' '[:lower:]')
            case $color in
                black) color=0 ;;
                red) color=1 ;;
                green) color=2 ;;
                yellow) color=3 ;;
                blue) color=4 ;;
                magenta) color=5 ;;
                cyan) color=6 ;;
                white|*) color=7 ;; # white or invalid color
            esac
            ;;
    esac

    # Fall back to plain output when tput is unavailable.
    if command -v tput >/dev/null 2>&1; then
        tput setaf "$color"
        echo "$exp"
        tput sgr0
    else
        echo "$exp"
    fi
}

function rename-files-recursive {
  local search=$1
  local replace=$2

  if [ -z "$1" ] || [ -z "$2" ]; then
      echo "Usage: rename-files-recursive <search> <replace>"
      return
  fi

  find . -iname "*${search}*" -exec rename "s/${search}/${replace}/" '{}' \;
}

function go-cover {
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out
}

function split-images-raw {
	mkdir JPG RAW
	mv *.JPG JPG/
	 mv *ARW RAW/
}

function random-string {
	if [ -z "$1" ]; then
		echoc red "No length given"
	fi

	cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | fold -w "${1}" | head -n 1 | tr -d '\n'
}

function restart-until-stopped {
  echoc blue "Executing command until stopped:"
  echoc blue "$*"
  while true; do
    "$@"
    exitcode=$?
    echo "Exit code: $exitcode"
    test $exitcode -gt 128 && break
    sleep 1
  done
}

function fix-owner {
  if [ "${1}" == "" ]; then echo "Please pass a chown target"; return; fi

  echoc blue "Updating ${1} to be owned by ${USER}:${USER}"

  sudo chown -R "${USER}:${USER}" "${1}"
}

function date-iso {
  date '+%F-%H-%M-%S'
}

function export-dotenv-file {
	local dotenv_file="$1"
	
	if [ -z "$dotenv_file" ]; then
		echo "Usage: export-dotenv-file <path-to-.env-file>"
		return 1
	fi
	
	if [ ! -f "$dotenv_file" ]; then
		echo "Error: File '$dotenv_file' does not exist"
		return 1
	fi
	
	if [ ! -r "$dotenv_file" ]; then
		echo "Error: File '$dotenv_file' is not readable"
		return 1
	fi
	
	# Source the file and export variables safely
	set -a  # automatically export all variables
	source "$dotenv_file"
	set +a
}

# source: https://josh.fail/2021/using-direnv-to-set-a-custom-git-email-for-work-projects/
function set_git_author {
  local email="$1" name="$2"

  if [[ -z "$email" ]] || [[ -z "$name" ]]; then
    >&2 echo "Couldn't set git author!"
    return 1
  fi

  export GIT_COMMITTER_NAME="$name"
  export GIT_COMMITTER_EMAIL="$email"
  export GIT_AUTHOR_NAME="$name"
  export GIT_AUTHOR_EMAIL="$email"
  export GIT_COMMIT_GPG_KEY_ID="$email"
}

function asdf-install-plugins {
    # Read the .tool-versions file
    while read -r line; do
        # Extract the tool name
        tool=$(echo $line | awk '{print $1}')

        # Update the tool to the latest version
        echo "installing $tool"
        asdf plugin add $tool
    done < .tool-versions

    echo "All plugins have been installed."
}

function asdf-update-tools {
    # Read the .tool-versions file
    while read -r line; do
        # Extract the tool name
        tool=$(echo $line | awk '{print $1}')

        # Update the tool to the latest version
        echo "installing $tool"
        asdf install $tool latest
        asdf set $tool latest
    done < .tool-versions

    echo "All tools have been updated to their latest versions."
}

function find-process-on-port {
	local port="$1"
	sudo lsof -i :$port
}

# Cleanup stale Claude Code git worktrees under <repo>/.claude/worktrees.
# Stale = dangling admin ref (dir gone), branch fully merged into the default
# branch, or an orphaned directory with no matching worktree registration.
# Dry-run by default; pass --force / -f to actually delete.
function claude-worktree-clean {
	local force=0 apply=0 arg
	for arg in "$@"; do
		case "$arg" in
			--apply|-y)   apply=1 ;;
			--force|-f)   force=1; apply=1 ;;
			--dry-run|-n) apply=0 ;;
			-h|--help)
				echo "Usage: claude-worktree-clean [--apply|-y] [--force|-f] [--dry-run|-n]"
				echo "  Cleans stale .claude/worktrees and prunes git worktree refs."
				echo "  Stale = dangling ref (dir gone), branch merged, or orphan dir."
				echo ""
				echo "  (default)      dry-run; show the safe cleanup plan"
				echo "  --apply, -y    apply safe cleanup; keep unmerged worktrees"
				echo "  --force, -f    also remove unmerged/dirty worktrees (implies --apply)"
				echo "  --dry-run, -n  never delete (combine with --force to preview it)"
				return 0
				;;
			*)
				echoc red "Unknown option: ${arg}"
				return 1
				;;
		esac
	done
	local dry_run=1
	[ "$apply" -eq 1 ] && dry_run=0

	# Resolve git to an absolute path up front. Some repos (e.g. direnv-managed)
	# mutate PATH mid-command, so a bare `git` can vanish between calls; an
	# absolute binary keeps working regardless. All git calls below use $GIT.
	local GIT
	GIT=$(command -v git 2>/dev/null) || {
		echoc red "git not found in PATH — aborting"
		return 1
	}

	local repo_root
	repo_root=$("$GIT" rev-parse --show-toplevel 2>/dev/null) || {
		echoc red "Not inside a git repository"
		return 1
	}

	local wt_dir="${repo_root}/.claude/worktrees"

	# Capture the worktree registry ONCE up front. If this fails we must abort —
	# an empty list would make every directory look like an orphan and could
	# delete active worktrees. Never proceed on a failed/empty listing.
	local wt_porcelain
	wt_porcelain=$("$GIT" worktree list --porcelain) || {
		echoc red "Failed to list git worktrees — aborting"
		return 1
	}
	if [ -z "$wt_porcelain" ]; then
		echoc red "Empty git worktree listing — aborting (refusing to treat all dirs as orphans)"
		return 1
	fi

	# Pre-build the registered-paths list with pure shell (no external tools, so
	# orphan detection below can't be fooled by a tool disappearing mid-run).
	local wt_registered="" _l
	while IFS= read -r _l; do
		case "$_l" in
			worktree\ *) wt_registered="${wt_registered}${_l#worktree }
" ;;
		esac
	done <<EOF
${wt_porcelain}
EOF

	# Resolve default branch (origin/HEAD, else current branch).
	local default_branch
	default_branch=$("$GIT" symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null)
	default_branch="${default_branch#origin/}"
	[ -z "$default_branch" ] && default_branch=$("$GIT" rev-parse --abbrev-ref HEAD 2>/dev/null)

	echoc blue "Claude worktree cleanup in ${repo_root}"
	echoc blue "  worktree dir:   ${wt_dir}"
	echoc blue "  default branch: ${default_branch}"
	[ "$dry_run" -eq 1 ] && echoc yellow "  DRY-RUN (pass --apply to delete)"

	# Delete a branch only when it is safe (merged) or explicitly forced; an
	# unmerged branch may hold the only copy of work, so keep + warn instead.
	_claude_wt_drop_branch() {
		local b="$1"
		[ -z "$b" ] && return
		if [ "$force" -eq 1 ] || "$GIT" merge-base --is-ancestor "$b" "$default_branch" 2>/dev/null; then
			[ "$dry_run" -eq 1 ] && { echo "          would delete branch '${b}'"; return; }
			"$GIT" branch -D "$b" 2>/dev/null
		else
			echoc yellow "          kept branch '${b}' (unmerged) — delete manually if unwanted"
		fi
	}

	# 1. Iterate registered worktrees under .claude/worktrees (BEFORE prune, so
	#    dangling entries are still listed and their branches handled safely).
	local path="" branch="" line
	_claude_wt_consider() {
		local p="$1" b="$2"
		[ -z "$p" ] && return
		# only touch worktrees living under .claude/worktrees
		case "$p" in
			"${wt_dir}/"*) ;;
			*) return ;;
		esac

		local reason=""
		if [ ! -d "$p" ]; then
			reason="missing dir (dangling)"
		elif [ -n "$b" ] && "$GIT" merge-base --is-ancestor "$b" "$default_branch" 2>/dev/null; then
			reason="branch '${b}' merged into ${default_branch}"
		elif [ "$force" -eq 1 ]; then
			reason="forced"
		else
			echoc yellow "  keep:   ${p} (branch '${b:-detached}' not merged; use --force)"
			return
		fi

		if [ "$dry_run" -eq 1 ]; then
			echoc green "  remove: ${p} (${reason})"
			_claude_wt_drop_branch "$b"
			return
		fi

		echoc green "  removing: ${p} (${reason})"
		# --force handles dirty trees and dangling (missing-dir) worktrees.
		if [ "$force" -eq 1 ] || [ ! -d "$p" ]; then
			"$GIT" worktree remove --force "$p" 2>/dev/null || rm -rf "$p"
		else
			"$GIT" worktree remove "$p" 2>/dev/null || {
				echoc red "    failed (dirty/locked?) — skipping; rerun with --force"
				return
			}
		fi
		_claude_wt_drop_branch "$b"
	}

	while IFS= read -r line; do
		case "$line" in
			worktree\ *) path="${line#worktree }" ;;
			branch\ *)   branch="${line#branch refs/heads/}" ;;
			"")          _claude_wt_consider "$path" "$branch"; path=""; branch="" ;;
		esac
	done <<EOF
${wt_porcelain}
EOF
	_claude_wt_consider "$path" "$branch"  # trailing block
	unset -f _claude_wt_consider _claude_wt_drop_branch

	# 2. Prune any remaining admin refs whose directory is gone (safety net).
	if [ "$dry_run" -eq 1 ]; then
		"$GIT" worktree prune --dry-run --verbose
	else
		"$GIT" worktree prune --verbose
	fi

	# 3. Remove orphaned directories with no matching worktree registration.
	#    Membership is tested in pure shell against the pre-built registry, so a
	#    missing tool can never silently empty the registry and flag live dirs.
	if [ -d "$wt_dir" ]; then
		local d r matched
		for d in "$wt_dir"/*; do
			[ -d "$d" ] || continue
			matched=0
			while IFS= read -r r; do
				[ "$r" = "$d" ] && { matched=1; break; }
			done <<EOF
${wt_registered}
EOF
			[ "$matched" -eq 1 ] && continue
			if [ "$dry_run" -eq 1 ]; then
				echoc green "  remove orphan dir: ${d}"
			else
				echoc green "  removing orphan dir: ${d}"
				rm -rf "$d"
			fi
		done
		# drop the worktrees dir entirely if now empty
		rmdir "$wt_dir" 2>/dev/null
	fi

	echoc blue "Done."
}
