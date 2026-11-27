function psm -d "Toggle private mode: Enter fish private mode, kill clipboard tracking and KDE Connect"
    switch $argv[1]
        case 'on'
            echo (set_color red)"Entering Private Mode..."(set_color normal)
            
            # 1. Kill the clipboard watchers and KDE Connect
            killall wl-paste 2>/dev/null
            killall kdeconnectd 2>/dev/null
            
            # 2. Enter Fish Private Mode
            # Note: This will start a new shell. 
            # When you 'exit', the function will resume to the 'off' logic if you prefer,
            # or you can just run 'ps off' manually after exiting.
            fish --private
            
        case 'off'
            echo (set_color green)"Exiting Private Mode. Restoring services..."(set_color normal)
            
            # 1. Restart wl-paste watchers for cliphist
            # We use nohup and & to ensure they keep running in the background
            nohup wl-paste --type text --watch cliphist store >/dev/null 2>&1 &
            nohup wl-paste --type image --watch cliphist store >/dev/null 2>&1 &
            
            # 2. Restart KDE Connect
            if command -v kdeconnect-cli >/dev/null
                nohup /usr/lib/kdeconnectd >/dev/null 2>&1 &
            end
            
            echo "Services restored."
            
        case '*'
            echo "Usage: ps [on|off]"
    end
end