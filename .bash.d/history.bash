shopt -s histappend      # appends rather than overwriting the history
shopt -s cmdhist         # save multi-line entries as one command

if [[ -d ~/.bash.d ]]; then
    HISTFILE="$HOME/.bash.d/history"
fi

HISTSIZE=-1                     # no limits!
HISTFILESIZE=-1                 # no limits!
HISTCONTROL="erasedups:ignoreboth"
HISTIGNORE=" *:&:?:??:exit:ls:pwd:bg:fg:fc *:disown *:ee *:e *:history:h *:hh *:help *:type *"
HISTTIMEFORMAT='%FT%T '

# h () {
#     ## needs the extglob shell option set!
#     if ! shopt -q extglob; then
#         echo "sorry, need the option \`extglob' set!" >&2
#         return 2
#     fi

#     if [[ -z "$1" ]]; then
#         command history 20
#     elif [[ $# -eq 1 && "$1" == +([[:digit:]]) ]]; then
#         command history $1
#     else
#         command history | awk -v IGNORECASE=1 -v w="$*" 'BEGIN{split(w,q)} {m=1; for (i in q) {if (match($0,q[i]) == 0) {m=0; break}}; if (m != 0) print $0}'
#     fi
# }

__hh_raw () {
    \ag --nonumbers --invert-match "^#" "$HISTFILE" | \
        awk -v IGNORECASE=1 -v w="$*" 'BEGIN{split(w,q)} {m=1; for (i in q) {if (match($0,q[i]) == 0) {m=0; break}}; if (m != 0) print $0}'| \
        sort | uniq -c | sort -nr | \
        awk '{for (i=2; i<NF; i++) printf("%s ", $i); print $NF}'
}

## http://hcgatewood.me/003-navigating-the-terminal/
__hh_fzf () {
    __tmp=$(__hh_raw "$@"| fzf) && \
        history -s "$__tmp" && \
        eval "$__tmp"
}

h () {
    if [[ ${INSIDE_EMACS} == *comint* ]]; then
        __hh_raw "$@"
    elif [[ -t 1 ]]; then
        __hh_fzf "$@"
    else
        __hh_raw "$@";
    fi
}

history_compress () {
    ## http://mywiki.wooledge.org/BashFAQ/088
    awk 'NR==FNR && !/^#/{lines[$0]=FNR;next} lines[$0]==FNR' "$HISTFILE" "$HISTFILE" > "$HISTFILE.compressed$$" && mv "$HISTFILE.compressed$$" "$HISTFILE"
}
