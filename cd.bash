## A smart `cd' function with extra features:
##
##  * maintains a directory stack, which you can examine using `cdhist';
##  * cd -<n>, where <n> is a number, changes to the nth entry in the stack;
##  * cd -<string> changes to the first directory in the stack matching <string>;
##  * cd <filename> changes to the directory where <filename> resides;
##  * cd <foo> <bar> changes to the directory obtained by changing all
##    instances of <foo> by <bar>;
##
## If the variable CDHISTFILE is set, the directory stack is read from
## and saved to the file named by it.  The CDHISTSIZE, if set,
## determines the size of the directory stack.  The default size is 22.

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
    elif [ $# -eq 1 ]; then
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
                for ((i=0 ; i < cdlen ; i=i+1)); do
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
    elif [ $# -eq 2 ]; then
        builtin cd "${PWD//$1/$2}" && pwd;
    else
        echo $FUNCNAME: too many arguments 1>&2;
        return 1;
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
        printf "%2d: %s\n" $i "${CDHIST[$i]//${HOME}/~}"
    done
}

