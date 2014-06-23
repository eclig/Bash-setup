## http://blog.sanctum.geek.nz/bash-prompts/
prompt_git() {
    git branch &>/dev/null || return 1
    HEAD="$(git symbolic-ref HEAD 2>/dev/null)"
    BRANCH="${HEAD##*/}"
    [[ -n "$(git status 2>/dev/null | \
        grep -F 'working directory clean')" ]] || STATUS='!'
    printf '(git:%s)' "${BRANCH:-unknown}${STATUS}"
}

prompt_hg() {
    hg branch &>/dev/null || return 1
    BRANCH="$(hg branch 2>/dev/null)"
    [[ -n "$(hg status 2>/dev/null)" ]] && STATUS='!'
    printf '(hg:%s)' "${BRANCH:-unknown}${STATUS}"
}

prompt_svn() {
    svn info &>/dev/null || return 1
    URL="$(svn info 2>/dev/null | awk -F': ' '$1 == "URL" {print $2}')"
    ## https://asc-repo.bmwgroup.net/svn/asc045/Shared/medc17_LEAD/trunk
    case "$URL" in
        */trunk/*|*/trunk)
            BRANCH=trunk
            ;;
        *)
            BRANCH="${URL}"
            BRANCH="${BRANCH##*/branches/}"
            BRANCH="${BRANCH##*/pretags/}"
            BRANCH="${BRANCH##*/tags/}"
            BRANCH="${BRANCH%%/*}"
            ;;
    esac
    [[ -n "$(svn status 2>/dev/null)" ]] && STATUS='!'
    printf '(svn:%s)' "${BRANCH:-unknown}${STATUS}"
}

prompt_vcs() {
    prompt_svn || prompt_git || prompt_hg
}
