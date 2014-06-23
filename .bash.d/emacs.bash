quick_find () {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $FUNCNAME [directory] <pattern>" >&2
        return 1
    elif [[ $# -eq 1 ]]; then
        set "." "-iname" "$1"
    elif [[ $# -eq 2 ]]; then
        set "$1" "-iname" "$2"
    fi

    local dir="$1"
    shift

    if [[ ${INSIDE_EMACS} == *comint* ]]; then
        ## In the command substitution bellow we take advantage of the
        ## fact that `printf' reuses the format as necessary to
        ## consume all of the arguments.
        _eshell_emacsclient --eval "(find-dired \"${dir}\" (mapconcat 'shell-quote-argument '($(printf '"%s" ' "$@")) \" \"))" > /dev/null
    else
        find "$dir" "$@" -print0 | xargs -0 --no-run-if-empty ls -ldht
    fi
}

quick_grep () {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $FUNCNAME <pattern> [directory|file] ..." >&2
        return 1
    elif [[ $# -eq 1 ]]; then
        set -- "-r" "$1" "."
    elif [[ $# -eq 2 ]]; then
        set -- "-r" "$@"
    fi

    local grep_cmd
    if type -t ack > /dev/null 2>&1; then
        grep_cmd='ack --nofilter --nogroup --with-filename'
    else
        grep_cmd='grep --no-messages --line-number'
    fi

    if [[ ${INSIDE_EMACS} == *comint* ]]; then
        _eshell_emacsclient --eval "(grep \"${grep_cmd} $*\")" > /dev/null
    else
        grep "$@"
    fi
}

## for use with Emacs' "pwdsync" library:
## https://groups.google.com/group/gnu.emacs.sources/msg/5a771f9f7c5983a1?dmode=source&output=gplain&noredirect
emacs_sync_pwd () {
    local cwd;
    if [[ ${OSTYPE} == cygwin ]]; then
        cwd="$(cygpath --windows "$PWD" | sed -e 's|\\|/|g')";
    elif [[ ${OSTYPE} == msys ]]; then
        cwd="$(echo "$PWD" | sed -e 's@^/\(.\)\(/\|$\)@\1:/@')";
    else
        cwd="$PWD";
    fi;

    echo -en "\e[|pwdsync:$cwd|";
}

eshell_set_buffer_name () {
    _eshell_emacsclient --eval "(and (fboundp 'with-buffer-hosting-pid) (with-buffer-hosting-pid $$ (rename-buffer (format \"*shell: %s*\" \"$1\") t)))" > /dev/null
}

eshell_read_history () {
    _eshell_emacsclient --eval "(and (fboundp 'with-buffer-hosting-pid) (with-buffer-hosting-pid $$ (let ((comint-input-ring-file-name \"${HISTFILE}\")) (comint-read-input-ring))))" > /dev/null
}

esetenv () {
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
    _eshell_emacsclient --quiet --eval "(progn$evalstr)"
}

_eshell_emacsclient () {
    local _emacsclient="${EMACSCLIENT:-emacsclient}"
    type -t "${_emacsclient}" > /dev/null 2>&1 && "${_emacsclient}" --quiet "$@"
}
