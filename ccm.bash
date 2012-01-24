#!/bin/bash

_CCM_PASSWORD_FILE="$HOME/.ccm_password"

_ccm_read_password () {
    local pwd

    read -s -e -p 'Enter Continuus password: ' pwd
    echo "$pwd"
}

_ccm_start_ccm () {
    local pwd="$1"

    local CCM_PROGRAM="e:/tools/ccm/64-synergy3/bin/ccm.exe"
    local CCM_INIT_FILE="e:/tools/ccm/64-synergy3/etc/ccm_bms08.ini"

    ${CCM_PROGRAM} start -q -m -nogui        \
                         -d /ccmdb/tbd/bms08 \
                         -pw "${pwd}"        \
                         -f "${CCM_INIT_FILE}"
}

_ccm_fetch_saved_password () {
    local pwd

    if [[ -e "${_CCM_PASSWORD_FILE}" ]]; then
        pwd=$(< "${_CCM_PASSWORD_FILE}")
        echo $pwd
    else
        false
    fi
}

_ccm_save_password () {
    local pwd="$1"
    echo "${pwd}" >| "${_CCM_PASSWORD_FILE}"
}

ccm_server () {
    local pwd=${1:-$(_ccm_fetch_saved_password)}
    test -z "${pwd}" && pwd=$(_ccm_read_password)

    local out

    if out=$(_ccm_start_ccm "${pwd}" 2>&1); then
        _ccm_save_password "${pwd}"
        echo -E "${out}"
        export CCM_ADDR="${out}"
    elif [[ ${out} == *unable\ to\ validate\ the\ password* ||
            ${out} == *Engine\ startup\ failed* ]]; then
        echo 'Engine startup failed.  Wrong password?  Try again!'
        main $(_ccm_read_password)
    else
        echo -E "${out}"
        exit 1
    fi
}

ccmset () { 
    local TEMPFILE=${TMP:-/tmp}/ccmset_$$_$RANDOM;
    trap "\rm -f $TEMPFILE" EXIT KILL INT HUP;
    Perl e:/qx29999/projs/ccm/ccm_setaddr/ccm_setaddr.pl --format=bourne $* $(cygpath -w $TEMPFILE) && . $TEMPFILE
}

reqtasks () {
    ccm query -f "%name %owner %status [%task_synopsis]" "type='task' and req_id='$(echo $1 | tr a-z A-Z)'" | \
        awk '$2=gensub(/task([0-9])/, "\\1", "g", $2)'
}

findtask () {
    ccm finduse -all_folder -task $*
}

taskinfo () {
    ccm task -show info $1
}

tasks () {
    ccm query -f "%name %owner %status [%task_synopsis]" "type='task' and owner='${1:-${USERNAME:-${USER:-${LOGNAME}}}}' and status='task_assigned'" | \
        sed -e 's/task\([0-9]\)+/\1/' | \
        awk '$2=gensub(/task([0-9])/, "\\1", "g", $2)'
}

working () {
    ccm query -f "%cvid %objectname %status %task %project" -u "owner='${1:-${USERNAME:-${USER:-${LOGNAME}}}}' and (status='working' or status='visible') and not type match 'project*' and not is_product=TRUE"
}

prep () {
    ccm query "name='$1' and type='project' and status='prep'"
}

taskobjs () {
    ccm task -show objs -format "%displayname    %release   %status   %owner" $1
}

alias cr='ccm_check_release'
alias ct='task_commit'
alias fd='e:/batch/ccm_folderdiff.exe -v'
alias fl='e:/batch/ccm_folderlist.exe'
alias ft='findtask'
alias q='ccm query -no_sort'
alias task='ccm task'
alias task_check='e:/home/ecl/projs/ccm/check-task/check-task.cmd -v'
alias task_commit='e:/batch/ccm_commit_task.exe --inttest'
alias task_init='e:/batch/ccm_task_init.exe'
alias tc='task_check'
alias ti='taskinfo'
alias to='taskobjs'

alias ccm-kill-all='{ for p in ccm ccm_seng ccm_ci ccm_gui; do PSKILL $p; done; } | grep -Fi "killed."'

