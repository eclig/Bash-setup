# -*- shell-script -*-

[[ -z $USER && -n $USERNAME ]] && export USER="$USERNAME"
[[ -z $USER && -n $LOGNAME  ]] && export USER="$LOGNAME"
[[ -z $LOGNAME && -n $USER  ]] && export LOGNAME="$USER"

PS1='\[\e[1;34m\]\w\[\e[0m\]\$ '

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

inside_emacs () { 
    test -n "$INSIDE_EMACS"
}

running_cygwin () { 
    [[ ${OSTYPE} == cygwin ]]
}

running_msys () { 
    [[ ${OSTYPE} == msys ]]
}

term_title () { 
    case "$TERM" in 
        *xterm* | rxvt | dtter | kterm | Eterm)
            echo -en "\e]0;$*\a"
        ;;
        *screen*)
            echo -en "\ek$*\e\\"
        ;;
    esac
}

emacs_sync_pwd () { 
    local cwd;
    if running_cygwin; then
        cwd="$(cygpath -w "$PWD" | sed -e 's/\\/\//g')";
    elif running_msys; then
        cwd="$(echo "$PWD" | sed -e 's|^/\\(.\\)/|\\1:/|')";
    else
        cwd="$PWD";
    fi;
    if inside_emacs; then
        echo -en "\e|CWD:$cwd|";
    fi
}

emacs_setenv () {
    local evalstr;
    for varvalue in "$@"; do
        local var=${varvalue%%=*}
        local value=${varvalue#*=}
        if [[ -z "${value}" ]]; then
            value="nil"
        else
            if [[ "${value}" == "${var}" ]]; then
                value="${!var}"
            fi
            value="\"$(printf "%q" "${value}")\""
        fi

        evalstr="${evalstr} (setenv \"${var}\" ${value})"
    done
    ${EMACSCLIENT:-emacsclient} --eval "(progn$evalstr)"
}

agentize () {
    if [[ -z "$SSH_AUTH_SOCK" ]]; then
        eval $(ssh-agent -s)
    fi

    [[ -n "$SSH_AUTH_SOCK" && -n "$SSH_AGENT_PID" ]] && \
        emacs_setenv SSH_AUTH_SOCK SSH_AGENT_PID
}

prompt_command () {
    check_exit_status;          # MUST BE THE FIRST COMMAND HERE!

    set +x                      # in case the previous command used 'set -x'
    if [[ "$PWD" == "$HOME" ]]; then
        term_title '~';
    else
        term_title "${PWD##*/}";
    fi;
    inside_emacs && emacs_sync_pwd
}

PROMPT_COMMAND=prompt_command

check_exit_status () { 
    local status="$?";
    local signal="";
    if [ ${status} -ne 0 ] && [ ${status} != 128 ]; then
        if [ ${status} -gt 128 ]; then
            signal="$(builtin kill -l $((${status} - 128)) 2>/dev/null)";
            if [ "$signal" ]; then
                signal="($signal)";
            fi;
        fi;
        echo -e "[Last command exited with status ${RED}${status}${NO_COLOUR}${signal}]" 1>&2;
    fi;
    return 0
}

HISTSIZE=1024
HISTFILESIZE=40960
HISTIGNORE="&:?:??:ls *:exit"

shopt -s histappend

shopt -s extglob

if [[ -f ~/.bash.d/cd.bash ]]; then
    . ~/.bash.d/cd.bash
    alias d='cdhist'
fi

CDPATH=.:..:~

h () { 
    ## needs the extglob shell option set!
    if ! shopt -q extglob; then
        echo "sorry, need the option \`extglob' set!" >&2
        return 2
    fi

    if [[ -z "$1" ]]; then
        history 20
    elif [[ $# -eq 1 && "$1" == +([[:digit:]]) ]]; then
        history $1
    else
        history | grep "$@"
    fi
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

mk () { 
    test -f make.bat || return 42;
    nice -n 20 ./make.bat "$@"
}


desktop () {
        explorer "${USERPROFILE}\\Desktop\\$1"
}

cutfn () {

    local contents;

    test -z "$1" && set $PWD

    for p in $*; do
        contents=($contents $(cygpath --absolute --windows $p | sed -e 's/\\/\//g'))
    done

    echo -n $contents | putclip
    return 0
}

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

if [[ -f ~/.bash.d/aliases ]]; then
    . ~/.bash.d/aliases
elif [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi

for f in ccm.bash; do
    if [[ -f ~/.bash.d/"$f" ]]; then
        . ~/.bash.d/"$f"
    fi
done
