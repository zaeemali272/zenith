function yts -d "yt-dlp through Tor proxy"
    # Check if tor is active
    if not systemctl is-active --quiet tor
        echo (set_color yellow)"Tor is not running. Starting it now..."(set_color normal)
        sudo systemctl start tor
    end

    # Run yt-dlp with the proxy
    yt-dlp --proxy "socks5h://127.0.0.1:9050" $argv
end