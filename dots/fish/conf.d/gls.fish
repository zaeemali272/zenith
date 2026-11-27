function gls -d "Gallery-dl through Tor proxy"
    if not systemctl is-active --quiet tor
        echo (set_color yellow)"Tor is not running. Starting it now..."(set_color normal)
        sudo systemctl start tor
    end

    gallery-dl --proxy "socks5h://127.0.0.1:9050" $argv
end