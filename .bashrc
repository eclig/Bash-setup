# -*- shell-script -*-

shopt -s extglob

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

if [[ -f ~/.bash.d/emacs.bash ]]; then
    . ~/.bash.d/emacs.bash
fi

GREP_OPTIONS='--binary-files=without-match --color --exclude=tags'
for pattern in .cvs .git .hg .svn; do
    GREP_OPTIONS="$GREP_OPTIONS --exclude-dir=$pattern"
done
export GREP_OPTIONS

export ACK_OPTIONS='--nogroup --with-filename --smart-case'
if [[ -n "$INSIDE_EMACS" ]]; then
    ACK_OPTIONS="--nofilter $ACK_OPTIONS"
fi

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

cygpath2w32 () {
    cygpath --windows "$1" | sed -e 's|\\|/|g';
}

agentize () {
    local SSH_AGENT_CONFIG="$HOME/.ssh_agent_session"

    if [[ -e "$SSH_AGENT_CONFIG" ]]; then
        . "$SSH_AGENT_CONFIG" > /dev/null
    fi

    if [[ -z "$SSH_AUTH_SOCK" ]] || \
        ! ssh-add -l > /dev/null 2>&1; then
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

prompt_command () {
    check_exit_status;          # MUST BE THE FIRST COMMAND HERE!

    local xtrace_status=$(shopt -p -o xtrace)
    set +o xtrace
    if [[ "$PWD" == "$HOME" ]]; then
        term_title '~';
    else
        term_title "${PWD##*/}";
    fi;
    type -t z > /dev/null 2>&1 && \
        z --add "$(pwd -P)"
    history -a                  # append history to the history file
    $xtrace_status
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

### History

shopt -s histappend      # appends rather than overwriting the history
shopt -s cmdhist         # save multi-line entries as one command

if [[ -d ~/.bash.d ]]; then
    HISTFILE="$HOME/.bash.d/history"
fi

HISTSIZE=40960
HISTFILESIZE=1000000
HISTIGNORE=" *:&:?:??:ls *:fc *:ee *:h *:e *:exit:history:help *:type *"


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
        history | awk -v w="$*" 'BEGIN{split(w,q)} {m=1; for (i in q) {if (match($0,q[i]) == 0) {m=0; break}}; if (m != 0) print $0}'
    fi
}

history_compress () {
    ## http://mywiki.wooledge.org/BashFAQ/088
    awk 'NR==FNR && !/^#/{lines[$0]=FNR;next} lines[$0]==FNR' "$HISTFILE" "$HISTFILE" > "$HISTFILE.compressed$$" && mv "$HISTFILE.compressed$$" "$HISTFILE"
}

###
if [[ -f ~/.bash.d/cd.bash ]]; then
    . ~/.bash.d/cd.bash
    alias d='dirs -v'
fi

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

if [[ -f /etc/bash_completion ]]; then
    . /etc/bash_completion
fi

for f in ccm.bash vcs.bash z.bash; do
    if [[ -f ~/.bash.d/"$f" ]]; then
        . ~/.bash.d/"$f"
    fi
done

if type -t hostname > /dev/null 2>&1 &&
   [[ $(hostname --domain) == toptica.com && 
      -f ~/.bash.d/toptica.bash ]]; then
    . ~/.bash.d/toptica.bash
fi
    
if [[ -n "$BMW" && -f ~/.bash.d/bmw.bash ]]; then
    . ~/.bash.d/bmw.bash
fi
    
if running_cygwin && type -t cygpath2w32 > /dev/null 2>&1; then
    PS1='\[\e[1;34m\]$(cygpath2w32 "${PWD/#$HOME/~}")\[\e[0m\]\$ '
else
    PS1='\[\e[1;34m\]\w\[\e[0m\]\$ '
fi

if inside_emacs && type -t emacs_sync_pwd > /dev/null 2>&1; then
    PS1="\\[\$(emacs_sync_pwd)\\]${PS1}"
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
