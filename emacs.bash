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
        _eshell_emacsclient --eval "(find-dired \"${dir}\" \"$*\")" > /dev/null
    else
        find "$dir" "$@" -print0 | xargs -0 --no-run-if-empty ls -ldht
    fi
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
    _eshell_emacsclient --eval "(progn$evalstr)"
}

_eshell_emacsclient () {
    local _emacsclient="${EMACSCLIENT:-emacsclient}"
    type -t "${_emacsclient}" > /dev/null 2>&1 && "${_emacsclient}" "$@"
}
