# Load Wallust 16-color palette into the terminal on each shell start
if test -f ~/.cache/wallust/sequences
    cat ~/.cache/wallust/sequences
else if test -f ~/.cache/wal/sequences
    cat ~/.cache/wal/sequences
end
