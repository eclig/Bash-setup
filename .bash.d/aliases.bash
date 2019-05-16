## -*- shell-script -*-

alias aliases='source ~/.bash.d/aliases.bash'

alias  1='cd -1'
alias  2='cd -2'
alias  3='cd -3'
alias  4='cd -4'
alias  5='cd -5'
alias  6='cd -6'
alias  7='cd -7'
alias  8='cd -8'
alias  9='cd -9'
alias 10='cd -10'
alias 11='cd -11'
alias 12='cd -12'
alias 13='cd -13'
alias 14='cd -14'
alias 15='cd -15'
alias 16='cd -16'
alias 17='cd -17'
alias 18='cd -18'
alias 19='cd -19'
alias 20='cd -20'
alias 21='cd -21'
alias 22='cd -22'

alias b='cd -'

alias u='cd ..'
alias uu='cd ../..'
alias uuu='cd ../../..'
alias uuuu='cd ../../../..'
alias uuuuu='cd ../../../../..'

alias d='dirs -v'

alias cp='\cp -ivb'
alias mv='\mv -ivb'
alias mkdir='\mkdir -p'

if inside_emacs; then
    ls_color='always'
else
    ls_color='auto'
fi

alias ls="ls -xBFh -T0 --color=$ls_color"
alias lst='ls -tr'
alias la='ls -A'
alias ll='ls -l'
alias llt='ls -ltr'

lsnew () {
    if [[ $# -eq 0 ]]; then
        set "."
    fi
    ## find . -mindepth 1 -maxdepth 1 -printf '%T@ %p\0' | sort -nrz | head
    find "$@" -mindepth 1 -maxdepth 1 -mtime -1 -print0 | xargs --null --no-run-if-empty ls -ldht
}

alias j='jobs -l'

# start a program and immediately disown it
quiet() {
    "$@" < /dev/null &> /dev/null & disown $!
}


save () {
    local timeformat='%Y%m%dT%H%M%S'
    local time
    local OPTARG OPTIND opt
    while getopts ":nh" opt; do
        case "$opt" in
            n)
                time=$(date +"${timeformat}")
                ;;
            h)
                echo "Usage: $FUNCNAME [-n] <file> ...
Make a backup copy of <file> named <file>.~<timestample>~.
Here <timestample> is of the form \"<YYYY><MM><DD>T<hh><mm><ss>\",
corresponding to the modification time of <file>.
If the option \"-n\" (as in \"now\") is used, use the current time instead."
                return 0
                ;;
            \?)
                echo "$FUNCNAME: invalid option: -$OPTARG.  Try \`$FUNCNAME -h'" >&2
                return 1
                ;;
        esac
    done

    shift $((OPTIND - 1))

    local f
    for f in "${@%/}"; do
        \cp --archive --interactive -- "${f}" "${f}.~${time:-$(date --reference="${f}" +'%Y%m%dT%H%M%S')}~"
    done
}

alias dc='darcs changes --summary LL'
alias dr='darcs record'
alias dww='darcs whatsnew --unified --look-for-adds'

diff4ediff () {
    ## instead of showing the differences, this only prints the line
    ##     ediff <file1> <file2>
    ## if the files differ.
    ## In Emacs Shell-mode pressing <RET> on such a line cause it to
    ## be executed.
    ## Useful when used with the `--recursive' flag to selectively
    ## diff some of the files using `ediff'.
    diff --brief "$@" | perl -ne 'm|^Files (\S+) and (\S+) differ$| && print qq(ediff "$1" "$2" \n);'
}

path () {
    local action='display';

    local OPTARG OPTIND opt
    while getopts ":elh" opt; do
        case "$opt" in
            e)
                action='edit'
                ;;
            l)
                action='display'
                ;;
            h)
                echo "Usage: $FUNCNAME [-elh]
Display (-l) or edit (-e) the PATH environment variable, one entry per line.
Use the value of the variable EDITOR (alternatively VISUAL or \`vi' as a last
resort) to edit the entries.  The option -h causes this message to be displayed.
With no option show the value of PATH."

                return 0
                ;;
            \?)
                echo "$FUNCNAME: invalid option: -$OPTARG.  Try \`$FUNCNAME -h'" >&2
                return 1
                ;;
        esac
    done

    shift $((OPTIND - 1))

    if [[ -n "$1" ]]; then
        echo "$FUNCNAME: too many arguments: $@" >&2
        return 1
    fi

    if [[ "$action" == edit ]]; then
        if [[ -z "$EDITOR" ]]; then
            echo "$FUNCNAME: environment variable EDITOR is not set" >&2
            return 1
        fi

        local TMP=${TMP:-/tmp}

        if [[ "${OSTYPE}" == cygwin ]]; then
            TMP="$(cygpath -w "$TMP" | sed -e 's/\\/\//g')";
        elif [[ "${OSTYPE}" == msys ]]; then
            TMP="$(echo "$TMP" | sed -e 's|^/\\(.\\)/|\\1:/|')";
        else
            TMP="$TMP";
        fi;

        local TEMPFILE="${TMP}/path-$$-$SECONDS-$RANDOM"
        echo -e "${PATH//:/\\n}" > "${TEMPFILE}"
        ${EDITOR:-${VISUAL:-vi}} "${TEMPFILE}"
        PATH=$(sed -e :a -e '$!N; s/\n/:/; ta' "${TEMPFILE}")

        ## can't use `trap' *locally* for that, traps are global
        command rm -f "${TEMPFILE}"
    else
        echo -e "${PATH//:/\\n}"
    fi
}

edit-executable () {
    if [[ -z "$1" ]]; then
        echo "usage: $FUNCNAME <executable>" >&2
        return 1
    fi

    local executable=$(type -p "$1")

    if [[ -z "$executable" ]]; then
        echo "$FUNCNAME: could not find executable '$executable' in path" >&2
        return 1
    fi

    ${EDITOR:-${VISUAL:-vi}} "$executable"
}

alias ver='echo Bash \($BASH\), version $BASH_VERSION $MACHTYPE'

alias tv='tar -tvf' # let `tar' automatically guess the compression format.
alias tx='tar -xf' # dito.
alias txj='tar -xjf'
alias txJ='tar -xJf'
alias txz='tar -xzf'

x () {
    if [[ $# -ne 1 ]]; then
        echo "ERROR: expecting exactly one argument, got $#"
    elif [[ -f "$1" ]]; then
        case "$1" in
            *.tar.bz2)
                tar xvjf "$1" ;;
            *.tar.gz)
                tar xvzf "$1" ;;
            *.bz2)
                bunzip2 "$1" ;;
            *.rar)
                unrar x "$1" ;;
            *.gz)
                gunzip "$1" ;;
            *.tar)
                tar xvf "$1" ;;
            *.tbz2)
                tar xvjf "$1" ;;
            *.tgz)
                tar xvzf "$1" ;;
            *.zip)
                unzip "$1" ;;
            *.Z)
                uncompress "$1" ;;
            *.7z)
                7z x "$1" ;;
            *)
                echo "ERROR: unknown archive format: '$1'"
                return 1 ;;
        esac
    else
        echo "File '$1' does not exist"
    fi
}

map () {
    if [ $# -le 1 ]; then
        return
    else
        local f="$1"
        local x="$2"
        shift 2

        $f "$x"

        map "$f" "$@"
    fi
}

hr () {
    history -n
    if [[ ${INSIDE_EMACS} == *comint* ]] && type -t eshell_read_history > /dev/null 2>&1; then
        eshell_read_history
    fi
}
alias hs='history -a'

history_stats () {
  history | awk '{a[$2]++}END{for(i in a){print a[i] " " i}}' | sort -rn | head
}

help! () {
    cat <<EOF
!!                 # Last command and all arguments
!-3                # Third-to-last command and all arguments
!^                 # First argument of last command
!42^               # First argument of the 42nd command in history
!:2                # Second argument of last command
!42:2              # Second argument of the 42nd command in history
!$                 # Last argument of last command
!*                 # All arguments of the last command
!42                # Expands to the 42nd command in history
!42*               # All arguments of the 42nd command in history
!42:1:t            # Basename ("tail") of the first argument of the 42nd command in history
!42:1:h            # Dirname ("head") of the first argument of the 42nd command in history
!42:1:t:r          # Basename of the first argument of the 42nd command in history, sans trailing suffix
!foo               # Last command beginning with 'foo'
!?foo              # Last command containing 'foo'
^foo^bar           # Last command with first instance of 'foo' replaced with 'bar'
!!:gs/foo/bar      # Last command with all instances of 'foo' replaced with 'bar
<command>:p        # Don't execute, just print command
EOF
}

alias po='popd'
alias pu='pushd'

alias r='fc -s'
alias rm='\rm -v'
alias rs='eval $(resize)'

alias op='cygstart'

md () {
    mkdir --parents "$@" || return $?
    shift $(( $# - 1 ))
    cd "$1"
}

alias asdf='[ -f "$HOME/.Xmodmap.$(uname -n)" ] && xmodmap "$HOME/.Xmodmap.$(uname -n)"'

alias escape='ssh -N -f escape'

alias l=less

alias svnu='svn update --ignore-externals'
alias svns='svn status --ignore-externals'
svn-delete-missing () { svn rm $( svn status "$@" | sed -e '/^!/!d' -e 's/^!//' ) ; }
svnsx () { svn status "$@" | grep -v '^\( *X\|Perform\|$\)' ; }
alias svnd='svn diff'
## http://www.commandlinefu.com/commands/view/9474/one-line-log-format-for-svn
svnl () { svn log --use-merge-history --limit 10 "$@" | perl -l40pe 's/^-+/\n/' ; }
alias svn.news='svn log -v -rBASE:HEAD'
alias svn.ext='svn pg svn:externals'
function svn.url { svn info "$@" 2>/dev/null | awk -F': ' '$1 == "URL" {print $2}' ; }

alias gits='git status --short --branch --ignore-submodules=none'
alias gitl="git log --name-status --pretty=format:'%h %s (%an, %ar)' -n 10"
alias gitd='git difftool -d'

alias ipaddr="curl -s http://checkip.dyndns.com/ | sed 's/[^0-9\.]//g'"
alias ipsearch="dig +short"

alias ag="ag --nogroup --column"

repobrowser () {
    ## http://tortoisesvn.net/docs/release/TortoiseSVN_en/tsvn-automation.html#tsvn-automation-basics
    TortoiseProc /command:repobrowser /path:"$1" &
    disown $!
}

cmd-here () {
    cmd /c start cmd
}

xterm-here () {
    env --unset=EMACS --unset=INSIDE_EMACS PAGER=pager xterm
}

alias w10='VBoxManage startvm "Lopes VM"'
alias w7=w10
