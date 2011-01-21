# -*- shell-script -*-

[[ -z $USER && -n $USERNAME ]] && export USER="$USERNAME"
[[ -z $USER && -n $LOGNAME  ]] && export USER="$LOGNAME"
[[ -z $LOGNAME && -n $USER  ]] && export LOGNAME="$USER"

PS1='\[\e[1;34m\]\w\[\e[0m\]\$ '

PATH=/usr/local/bin:/usr/bin:/bin:"$PATH"

[[ -d ~/.bin/share ]] && PATH=~/.bin/share:"$PATH"
[[ -d ~/.bin/$HOSTTYPE-$OSTYPE ]] && PATH=~/.bin/$HOSTTYPE-$OSTYPE:"$PATH"

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
    else
        if running_msys; then
            cwd="$(echo "$PWD" | sed -e 's|^/\\(.\\)/|\\1:/|')";
        else
            cwd="$PWD";
        fi;
    fi;
    if inside_emacs; then
        echo -en "\e|CWD:$cwd|";
    fi
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

HISTSIZE=2048
HISTFILESIZE=1024
HISTIGNORE="&:ls:ls *:[bf]g:exit"

shopt -s extglob

CDPATH=.:..:~

cd () { 
    typeset -i cdlen i;
    typeset t;
    if [[ -n "$CDHISTFILE" && -r "$CDHISTFILE" ]]; then
        typeset CDHIST;
        i=-1;
        while read t; do
            CDHIST[i=i+1]="$t";
        done <$CDHISTFILE;
    fi;
    if [[ "${CDHIST[0]}" != "$PWD" && -n "$PWD" ]]; then
        _cdins "$PWD";
    fi;
    cdlen=${#CDHIST[*]};
    if [ $# -eq 0 ]; then
        builtin cd;
    else
        if [ $# -eq 1 ]; then
            case "$1" in 
                -)
                    if [[ "$OLDPWD" = "" && -n $((cdlen > 1)) ]]; then
                        builtin cd "${CDHIST[1]}" && pwd;
                    else
                        builtin cd -;
                    fi
                ;;
                -[[:digit:]]|-[[:digit:]][[:digit:]])
                    if (((i=${1#-}) < cdlen)); then
                        builtin cd "${CDHIST[i]}" && pwd;
                    else
                        echo $FUNCNAME: not enough elements in stack 1>&2;
                        return 1;
                    fi
                ;;
                -*)
                    for ((i=0 ; i < cdlen ; i=i+1))
                    do
                        if [[ ${CDHIST[i]} == *${1#-}* ]]; then
                            builtin cd "${CDHIST[i]}" && pwd;
                            break;
                        fi;
                    done;
                    if ((i >= cdlen)); then
                        echo $FUNCNAME: no directory found matching \'${1#-}\' 1>&2;
                        return 1;
                    fi
                ;;
                *)
                    if [ -f "$1" ]; then
                        ${FUNCNAME} "${1%/*}" && pwd;
                    else
                        builtin cd "$1";
                    fi
                ;;
            esac;
        else
            if [ $# -eq 2 ]; then
                builtin cd "${PWD//$1/$2}" && pwd;
            else
                echo $FUNCNAME: too many arguments 1>&2;
                return 1;
            fi;
        fi;
    fi;
    _cdins "$PWD";
    if [ -n "$CDHISTFILE" ]; then
        for ((i=0 ; i < ${#CDHIST[*]} ; i=i+1))
        do
            printf "%q\n" "${CDHIST[i]}";
        done >$CDHISTFILE;
    fi
}

_cdins () { 
    typeset -i i;
    for ((i=0 ; i < ${#CDHIST[*]} ; i=i+1)); do
        if [ "${CDHIST[$i]}" = "$1" ]; then
            break;
        fi;
    done;
    if ((i > ${CDHISTSIZE:-22})); then
        i=${CDHISTSIZE:-22};
    fi;
    while (((i=i-1) >= 0)); do
        CDHIST[i+1]=${CDHIST[i]};
    done;
    CDHIST[0]="$1"
}

cdhist () {
    typeset -i i;
    for ((i=0 ; i < ${#CDHIST[*]} ; i=i+1)); do
        printf "%2d: %s\n" $i ${CDHIST[$i]//${HOME}/~}
    done
}

alias d='cdhist'

h () { 
    local first=-100;
    if [[ -z "$1" ]]; then
        fc -l;
    else
        if [[ $# -gt 3 ]]; then
            echo $FUNCNAME: too many arguments 1>&2;
            return 1;
        else
            if [[ "$1" == -h || "$1" == --help ]]; then
                cat  <<EOF
USAGE:
    $FUNCNAME <range>
    $FUNCNAME <searchstring> <range>

RANGE:
    1                     the whole history
    -<n>                  offset to the current history number (default: ${first})
    <[-]first> [<last>]   history items between <first> and <last>

EXAMPLES:
    $FUNCNAME -250   # list last 250 history items
    $FUNCNAME make   # list history items matching 'make'
    $FUNCNAME bash -250 # list last 250 items matching 'bash'
    $FUNCNAME foo 1 99
EOF
            else
                if [[ "$1" == [[:digit:]]+ ]]; then
                    if [[ -z "$2" ]]; then
                        fc -l "$1";
                    else
                        if [[ "$2" == [[:digit:]] ]]; then
                            if [[ -n "$3" ]]; then
                                fc -l "$1" "$2" | grep -i "$3";
                            else
                                fc -l "$1" "$2";
                            fi;
                        else
                            fc -l "${1:-${first}}" | grep -i "$2";
                        fi;
                    fi;
                else
                    fc -l "${2:-${first}}" "$3" | grep -i "$1";
                fi;
            fi;
        fi;
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

ccmset () { 
    local TEMPFILE=${TMP:-/tmp}/ccmset_$$_$RANDOM;
    trap "\rm -f $TEMPFILE" EXIT KILL INT HUP;
    Perl e:/home/ecl/projs/ccm/ccm_setaddr/ccm_setaddr.pl --format=bourne $* $(cygpath -w $TEMPFILE) && . $TEMPFILE
}

mk () { 
    test -f make.bat || return 42;
    nice -n 20 ./make.bat "$@"
}


desktop () {
        cygstart "${USERPROFILE}/Desktop/$1"
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

if [[ -f ~/.bash.d/inputrc ]]; then
    export INPUTRC=~/.bash.d/inputrc
fi

if [[ -f ~/.bash.d/aliases ]]; then
    . ~/.bash.d/aliases
elif [[ -f ~/.bash_aliases ]]; then
    . ~/.bash_aliases
fi
