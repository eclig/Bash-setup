alias update-cfg='Perl -I e:/home/ecl/perl/update-config e:/home/ecl/perl/update-config/update-config.pl'
alias xml_validate='e:/qx29999/tools/xml_validate/validate.pl'

repo='https://asc-repo.bmwgroup.net/svn/asc045'
projs="${repo}/Projects"

make () {
    if [[ -e ./make.bat ]]; then
        local LOG=",make.log"

        date >> "$LOG"
        echo "make.bat $*" >> "$LOG"
        nice -n 20 time ./make.bat $* 2>&1 | tee --append "$LOG"
        date >> "$LOG"
        echo -e '\f' >> "$LOG"
    else
        command make $*
    fi
}

alias mkx='make expert=1'
alias mkg='make debug=1 MAKE_DBG=ON'
mks () { make show x="$1"; }

alias asc='e:/tools/ascent/cli/asc.bat'

svn16 () { PATH=/cygdrive/e/tools/Subversion-1.6.11/bin:"$PATH" "$@"; }
svn17 () { PATH=/cygdrive/c/Progra~1/SlikSvn/bin:"$PATH" "$@"; }
tort17 () { PATH=/cygdrive/c/Progra~1/TortoiseSVN/bin:"$PATH" "$@"; }

if [[ -f f:/Apps/PortableGit-1.8.1.2/bin/git.exe ]]; then
    hash -p f:/Apps/PortableGit-1.8.1.2/bin/git.exe git > /dev/null 2>&1
elif [[ -f f:/apps/PortableGit-1.7.4/bin/git.exe ]]; then
    hash -p f:/apps/PortableGit-1.7.4/bin/git.exe git > /dev/null 2>&1
fi

perl510 () {
    local PERL510_DIR="/cygdrive/c/tools/Perl_5_10_0_1005"
    PATH="${PERL510_DIR}/bin":"$PATH" "$@";
}

perl516 () {
    local PERL516_DIR="/cygdrive/c/tools/Perl_5_16_1_1/perl"
    PATH="${PERL516_DIR}/bin":"$PATH" "$@";
}

proxy () {
    local pwd
    read -s -p "password: " pwd
    echo

    for p in http https; do
        export ${p}_proxy="${p}://${USER}${pwd:+:${pwd}}@proxy.muc:8080"
    done
}

for p in http{,s}; do
    export ${p}_proxy="${p}://proxy.muc:8080";
done

alias brotzeit='cygstart //europe.bmw.corp/winfs/EA-org/EA-4_Org/EA-41/EA-41/40_Allgemein/04_Austausch/Ern/Brotzeit/aktuelle_Brotzeit_Bestellliste.xls'

alias cfg='configure.cmd --walayout=absolute'
alias mkg='mk MAKE_DBG=ON debug=1'
alias mkx='mk expert=1'
