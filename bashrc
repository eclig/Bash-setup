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

if [[ -f ~/.bash.d/cd.bash ]]; then
    . ~/.bash.d/cd.bash
fi
CDPATH=.:..:~
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
