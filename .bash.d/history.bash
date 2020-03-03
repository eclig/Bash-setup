shopt -s histappend      # appends rather than overwriting the history
shopt -s cmdhist         # save multi-line entries as one command

if [[ -d ~/.bash.d ]]; then
    HISTFILE="$HOME/.bash.d/history"
fi

HISTSIZE=40960
HISTFILESIZE=1000000
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE=" *:&:?:??:exit:ls:pwd:bg:fg:fc *:disown *:ee *:e *:history:help *:type *"
HISTTIMEFORMAT='%FT%T '

h () {
    ## needs the extglob shell option set!
    if ! shopt -q extglob; then
        echo "sorry, need the option \`extglob' set!" >&2
        return 2
    fi

    if [[ -z "$1" ]]; then
        command history 20
    elif [[ $# -eq 1 && "$1" == +([[:digit:]]) ]]; then
        command history $1
    else
        command history | awk -v IGNORECASE=1 -v w="$*" 'BEGIN{split(w,q)} {m=1; for (i in q) {if (match($0,q[i]) == 0) {m=0; break}}; if (m != 0) print $0}'
    fi
}

history_compress () {
    ## http://mywiki.wooledge.org/BashFAQ/088
    awk 'NR==FNR && !/^#/{lines[$0]=FNR;next} lines[$0]==FNR' "$HISTFILE" "$HISTFILE" > "$HISTFILE.compressed$$" && mv "$HISTFILE.compressed$$" "$HISTFILE"
}
