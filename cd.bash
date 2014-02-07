## A smart `cd' function with extra features:
##
##  * uses Bash's directory stack, which you can examine using the`dirs' builtin;
##  * cd -<n>, where <n> is a number, changes to the nth entry in the stack;
##  * Directories entries from the stack can be referenced using ~+<n>;
##  * cd -<string> changes to the first directory in the stack matching <string>;
##  * cd <filename> changes to the directory where <filename> resides;
##  * cd <foo> <bar> changes to the directory obtained by changing all
##    instances of <foo> by <bar>;
##
## If the variable CDHISTFILE is set, the directory stack is read from
## and saved to the file named by it.  The variable DIRSTACKSIZE, if set,
## determines the size of the directory stack.  The default size is 25.
##
## Based on "examples/scripts.v2/cdhist.bash" from the Bash distribution.

cd () {
    typeset -i cdlen i
    typeset t

    if [[ -n "$CDHISTFILE" && -r "$CDHISTFILE" ]]; then
        while read t; do
            pushd -n "$t"
        done <$CDHISTFILE
    fi

    cdlen=${#DIRSTACK[*]}

    if [ $# -eq 0 ]; then
        newdir=~
    elif [ $# -eq 1 ]; then
        case "$1" in
            -)
                if [[ "$OLDPWD" = "" && -n $((cdlen > 1)) ]]; then
                    newdir=${DIRSTACK[1]}
                else
                    newdir=-
                fi
                ;;
            -[[:digit:]]|-[[:digit:]][[:digit:]])
                if (((i=${1#-}) < cdlen)); then
                    newdir=${DIRSTACK[i]}
                else
                    echo $FUNCNAME: not enough elements in stack 1>&2
                    return 1
                fi
                ;;
            -*)
                for ((i=0 ; i < cdlen ; i=i+1)); do
                    if [[ ${DIRSTACK[i]} == *${1#-}* ]]; then
                        newdir=${DIRSTACK[i]}
                        break
                    fi
                done
                if ((i >= cdlen)); then
                    echo $FUNCNAME: no directory found matching \'${1#-}\' 1>&2
                    return 1
                fi
                ;;
            *)
                if [ -f "$1" ]; then
                    ${FUNCNAME} "${1%/*}" && pwd
                    return 0
                else
                    newdir=$1
                fi
                ;;
        esac
    elif [ $# -eq 2 ]; then
        newdir="${PWD//$1/$2}"
    else
        echo $FUNCNAME: too many arguments 1>&2
        return 1
    fi

    builtin cd -- "${newdir/#~\//$HOME/}"
    _autopushd_cdins "$OLDPWD"

    if [ -n "$CDHISTFILE" ]; then
        for ((i=0 ; i < ${#DIRSTACK[*]} ; i=i+1))
        do
            printf "%q\n" "${DIRSTACK[i]}"
        done >$CDHISTFILE
    fi
}

_autopushd_cdins () {
    typeset -i i

    for ((i=1 ; i < ${#DIRSTACK[*]} ; i=i+1)); do
        if [[ ${DIRSTACK[$i]} == ${PWD/#$HOME/~} ]]; then
            popd -n +$i > /dev/null
        fi
    done

    if [[ ${DIRSTACK[0]} != ${1/#$HOME/~} ]]; then
        pushd -n "$1" > /dev/null
    fi

    while (( ${#DIRSTACK[*]} >= ${DIRSTACKSIZE:-25})); do
        popd -n -${DIRSTACKSIZE:-25}
    done
}
