#!/usr/bin/env bash

# Define the target file
BOOKMARKS_FILE="$HOME/.config/gtk-3.0/bookmarks"

# Create the directory if it doesn't exist
mkdir -p "$(dirname "$BOOKMARKS_FILE")"

# Define bookmarks (format: file:///path Label)
cat <<EOF > "$BOOKMARKS_FILE"
file://$HOME/Documents Documents
file://$HOME/Downloads Downloads
file://$HOME/Pictures Pictures
file://$HOME/Videos Videos
EOF

echo "Bookmarks updated at $BOOKMARKS_FILE"
