#!/usr/bin/env zsh

# Enable colors in man command
# https://www.howtogeek.com/683134/how-to-display-man-pages-in-color-on-linux/
man() {
    LESS_TERMCAP_mb=$(tput bold; tput setaf 1) \
    LESS_TERMCAP_md=$(tput bold; tput setaf 1) \
    LESS_TERMCAP_me=$(tput sgr0) \
    LESS_TERMCAP_se=$(tput sgr0) \
    LESS_TERMCAP_so=$(tput bold; tput setaf 3; tput setab 4) \
    LESS_TERMCAP_ue=$(tput sgr0) \
    LESS_TERMCAP_us=$(tput smul; tput bold; tput setaf 2) \
    LESS_TERMCAP_mr=$(tput rev) \
    LESS_TERMCAP_mh=$(tput dim) \
    LESS_TERMCAP_ZN=$(tput ssubm) \
    LESS_TERMCAP_ZV=$(tput rsubm) \
    LESS_TERMCAP_ZO=$(tput ssupm) \
    LESS_TERMCAP_ZW=$(tput rsupm) \
    GROFF_NO_SGR=1 \
    command man "$@"
}

# Determine size of a file or total size of a directory
# Usage: fs [path]
fs() {
    if du -b /dev/null > /dev/null 2>&1; then
        local arg=-sbh;
    else
        local arg=-sh;
    fi
    if [[ -n "$@" ]]; then
        du $arg -- "$@";
    else
        du $arg .[^.]* ./*;
    fi;
}

# Display gzip compression ratio of a file, directory, or string
# Usage: gz <file|dir|string>
gz() {
    local input
    local origsize
    local gzipsize
    local ratio

    if [ -z "$1" ]; then
        return
    fi

    if [ -d "$1" ]; then
        input=$(mktemp)
        tar -cf - "$1" | gzip -c > "$input"
        origsize=$(du -sb "$1" 2>/dev/null | awk '{print $1}')
        if [ -z "$origsize" ]; then
            origsize=$(du -sk "$1" | awk '{print $1}')
            origsize=$((origsize * 1024))
        fi
        gzipsize=$(wc -c < "$input")
    else
        if [ -f "$1" ]; then
            input="$1"
        else
            input=$(mktemp)
            printf "%s\n" "$@" > "$input"
        fi
        origsize=$(wc -c < "$input")
        gzipsize=$(gzip -c < "$input" | wc -c)
    fi

    ratio=$(awk "BEGIN {printf \"%.2f\", $gzipsize * 100 / $origsize}")
    orig_human=$(numfmt --to=iec "$origsize" | xargs)
    gzip_human=$(numfmt --to=iec "$gzipsize" | xargs)

    printf "orig: %d bytes (%s)\ngzip: %d bytes (%s) (%.2f%%)\n" \
        "$origsize" "$orig_human" \
        "$gzipsize" "$gzip_human" \
        "$ratio"

    [[ "$input" == /tmp/* ]] && rm -f "$input"
}

# Remove node_modules directories
# Usage: npmRemove [-dry]
npmRemove() {
    if [ "$1" = "--help" ]; then
        echo "Remove node_modules directories"
        echo ""
        echo "Usage: npmRemove [-dry]"
        echo "If the -dry option is provided, it displays the sizes of all node_modules directories."
        echo "Otherwise, it removes all node_modules directories in the current directory and its subdirectories."
        return
    fi

    if [ "$1" = "-dry" ]; then
        find . -name "node_modules" -type d -prune -exec du -chs {} +
    else
        find . -name "node_modules" -type d -prune -exec rm -rf {} +
    fi
}

# Generate a random alphanumeric password
# Usage: pw [length] (defaults to 24)
pw() {
    local length=${1:-24}
    LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c "$length"
    echo
}

# Dump current Homebrew packages to the dotfiles brewfile
# Usage: backup-brewfile [path]
backup-brewfile() {
    local backup_path=${1:-~/.dotfiles/brewfile}
    brew bundle dump --file="$backup_path" --force --no-vscode
    echo "Brewfile backed up to $backup_path (without VSCode extensions)"
}

# Start a simple Python HTTP server
# Usage: http-server [port] (defaults to 8000)
http-server() {
    local port=${1:-8000}
    python3 -m http.server "$port"
}

# Kill the process listening on a given TCP port
# Usage: kill-service-with-port <port>
kill-service-with-port() {
    local port=${1}
    if [ -z "$port" ]; then
        echo "Usage: kill-service-with-port <port>"
        return 1
    fi

    local pid=$(lsof -tiTCP:"$port" -sTCP:LISTEN)
    if [ -z "$pid" ]; then
        echo "No process found listening on port $port"
        return 1
    fi
    kill "$pid"
}

# Interactive terminal stopwatch
# Usage: timer (Stop with Ctrl-D)
timer() {
    zmodload zsh/datetime

    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local spinner_pid=""
    local timer_status
    local -F start_time=$EPOCHREALTIME
    local -F elapsed_seconds

    printf 'Timer started. Stop with Ctrl-D.\n'
    if [[ -t 2 ]]; then
        (
            while true; do
                for frame in "${frames[@]}"; do
                    printf '\r%s' "$frame" >&2
                    sleep 0.1
                done
            done
        ) </dev/null &!
        spinner_pid=$!
    fi

    \cat
    timer_status=$?
    elapsed_seconds=$((EPOCHREALTIME - start_time))

    if [[ -n "$spinner_pid" ]]; then
        kill "$spinner_pid" 2>/dev/null
        wait "$spinner_pid" 2>/dev/null
        printf '\r\033[K' >&2
    fi

    if (( timer_status == 0 )); then
        printf '%.2fs\n' "$elapsed_seconds"
    fi

    return "$timer_status"
}
