type -t hostname > /dev/null 2>&1 ||
    return

[[ $(hostname -d) == toptica.com ]] ||
    return

export http_proxy=http://192.168.50.2:3128
export https_proxy=http://192.168.50.2:3128
