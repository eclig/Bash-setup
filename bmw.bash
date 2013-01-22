alias update-cfg='Perl -I e:/home/ecl/perl/update-config e:/home/ecl/perl/update-config/update-config.pl'
alias xml_validate='e:/qx29999/tools/xml_validate/validate.pl'

repo='https://asc-repo.bmwgroup.net/svn/asc045'
projs="${repo}/Projects"

svn16 () { PATH=/cygdrive/e/tools/Subversion-1.6.11/bin:"$PATH" "$@"; }
svn17 () { PATH=/cygdrive/c/Progra~1/SlikSvn/bin:"$PATH" "$@"; }
tort17 () { PATH=/cygdrive/c/Progra~1/TortoiseSVN/bin:"$PATH" "$@"; }

perl510 () {
    local PERL510_DIR="/cygdrive/c/tools/Perl_5_10_0_1005"
    PATH="${PERL510_DIR}/bin":"$PATH" "$@";
}

proxy () {
    local pwd
    read -s -p "password: " pwd
    echo

    for p in http https; do
        export ${p}_proxy="${p}://${USER}${pwd:+:${pwd}}@proxy.muc:8080"
    done
}

alias brotzeit='cygstart //europe.bmw.corp/winfs/EA-org/EA-4_Org/EA-41/EA-41/40_Allgemein/04_Austausch/Ern/Brotzeit/aktuelle_Brotzeit_Bestellliste.xls'

alias cfg='configure.cmd --walayout=absolute'
alias mkg='mk MAKE_DBG=ON debug=1'
alias mkx='mk expert=1'
