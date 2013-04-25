eshell_find_dired () {
    if [[ $# -eq 0 ]]; then
        echo "Usage: $FUNCNAME [directory] <pattern>" >&2
        return 1
    elif [[ $# -eq 1 ]]; then
        set "." "-iname" "$@"
    fi

    local dir="$1"
    shift
    _eshell_emacsclient --eval "(find-dired \"${dir}\" \"$*\")" > /dev/null
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
