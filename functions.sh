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

    kubectl get pods -n "${namespace}" | grep "${name}" | awk '{{ print $1 }}' | xargs kubectl -n "${namespace}" delete pod ${@:3}
}

function kube-port-forward {
    if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
        echo "Usage: kube-port-forward <namespace> <deployment> <port>"
        return
    fi

    local command="kubectl -n "$1" port-forward $(kubectl get pods -n $1 | grep $2 | head -n 1 | awk '{ print $1 }') $3"
    echo "executing ${command}"

    eval ${command}
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
    read -p "Are you FUCKING SURE? There is no way back! " -n 1 -r
    echo    # (optional) move to a new line
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
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
    echo "Server listening on http://localhost:${PORT} "
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

    if ! [[ $color =~ '^[0-9]$' ]] ; then
       case $(echo $color | tr '[:upper:]' '[:lower:]') in
        black) color=0 ;;
        red) color=1 ;;
        green) color=2 ;;
        yellow) color=3 ;;
        blue) color=4 ;;
        magenta) color=5 ;;
        cyan) color=6 ;;
        white|*) color=7 ;; # white or invalid color
       esac
    fi

    tput setaf $color
    echo $exp
    tput sgr0
}

function reverse-rename-files {
  local search=$1
  local replace=$2

  if [ -z "$1" ] || [ -z "$2" ]; then
      echo "Usage: reverse-rename-files <search> <replace>"
      return
  fi

  find . -iname "*${search}*" -exec rename "s/${search}/${replace}/" '{}' \;
}

function go-cover {
	go test -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out
}
