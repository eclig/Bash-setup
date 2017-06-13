# -*- shell-script -*-

set -o noclobber
shopt -s checkwinsize
shopt -s cdable_vars

shopt -s extglob
shopt -s globstar

[[ -z $USER && -n $USERNAME ]] && export USER="$USERNAME"
[[ -z $USER && -n $LOGNAME  ]] && export USER="$LOGNAME"
[[ -z $LOGNAME && -n $USER  ]] && export LOGNAME="$USER"

add_to_path () {
    local dir="$1";
    local pathvar="${2:-PATH}"

    case ":${!pathvar}:" in
        *":${dir%/}:"* ) return 2;;
    esac

    if [[ -d "$dir" ]]; then
        eval $pathvar=\"$dir${!pathvar:+:${!pathvar}}\"
        return 0
    else
        return 1
    fi
}

add_to_path /bin
add_to_path /usr/bin
add_to_path /usr/local/bin

add_to_path ~/.bin/share
add_to_path "~/.bin/$HOSTTYPE-$OSTYPE"

export EDITOR=emacsclient

export ACK_OPTIONS='--nogroup --with-filename --smart-case'
if [[ -n "$INSIDE_EMACS" ]]; then
    ACK_OPTIONS="--nofilter $ACK_OPTIONS"
fi

inside_emacs () {
    test -n "$INSIDE_EMACS"
}

agentize () {
    local SSH_AGENT_CONFIG="$HOME/.ssh_agent_session"

    if [[ -e "$SSH_AGENT_CONFIG" ]]; then
        . "$SSH_AGENT_CONFIG" > /dev/null
    fi

    ## `ssh-add' returns 2 if it can not connect to the authentication agent.
    if [[ -z "$SSH_AUTH_SOCK" ]] || \
        { ssh-add -l > /dev/null 2>&1; test $? -eq 2; }; then
        local SSH_AGENT_DATA="$(ssh-agent -s)"
        local UMASK_SAVE="$(umask -p)"
        umask 077
        echo "$SSH_AGENT_DATA" >| "$SSH_AGENT_CONFIG"
        $UMASK_SAVE
        eval $SSH_AGENT_DATA  > /dev/null
    fi

    [[ -n "$INSIDE_EMACS" && -n "$SSH_AUTH_SOCK" && -n "$SSH_AGENT_PID" ]] && \
        type -t esetenv > /dev/null 2>&1 && \
        esetenv SSH_AUTH_SOCK SSH_AGENT_PID

    echo Agent pid $SSH_AGENT_PID
}

###
CDPATH=.:..:~

cdd () {
    local start dirname 

    if [[ $# -eq 0 ]]; then
        echo 'missing args...' >&2
        return 1
    elif [[ $# -eq 1 ]]; then
        start="."
        dirname="$1"
    elif [[ $# -eq 2 ]]; then
        start="$1"
        dirname="$2"
    else
        echo 'too many args...' >&2
        return 1
    fi

    local -a dirs=()
    local line
    for line in $(find "$start" -type d -iname "$dirname" 2>/dev/null | head -n 10 | sort); do
        dirs=(${dirs[@]} "$line")
    done

    case ${#dirs[@]} in
        0)
            false
            ;;
        1) 
            cd "${dirs[@]}"
            ;;
        *)
            select dir in "${dirs[@]}" ; do
                cd "$dir"
                break
            done
            ;;
    esac
}

hash () {
    ## accepts "hash foo=/path/to/foo" as zsh does
    if [[ $# -eq 1 && $1 == *=* ]]; then
        builtin hash -p "${1#*=}" "${1%%=*}"
    else
        builtin hash "$@"
    fi
}

#
ee () { . ~/.ee.sh $* ; }

dump-shell-state () {
    echo '## Completion'
    complete -r
    echo '## Options settings'
    set +o
    echo '## Bash specific options'
    shopt -p
    echo '## Variables and functions'
    typeset -p
    echo '## Exported variables'
    export -p
    echo '## Read-only variables'
    readonly -p
    echo '## Trap settings'
    trap -p
    echo '## Umask'
    umask -p
    echo -e '\n## EOF'
}

if [[ -f ~/.bash.d/inputrc ]]; then
    export INPUTRC=~/.bash.d/inputrc
fi

if [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
fi

PS1='\! \w\$ '

if [[ -d ~/.bash.d ]]; then
    for f in ~/.bash.d/*.bash; do
        . "$f"
    done
    unset -v f
fi

if inside_emacs && type -t emacs_sync_pwd > /dev/null 2>&1; then
    PS1="\\[\$(emacs_sync_pwd)\\]"${PS1}
fi

if [[ -d ~/Computing/TeX/local-lib ]]; then
    export TEXINPUTS=~/Computing/TeX/local-lib//:
fi

## http://www.reddit.com/r/commandline/comments/12g76v/how_to_automatically_source_zshrc_in_all_open/
## kill -USR1 $(ps -s | awk '/\/bash$/ {print $1}') 2> /dev/null
trap "source ~/.bash.d/bashrc" USR1

## Local Variables:
## page-delimiter: "^#+\f"
## End:
