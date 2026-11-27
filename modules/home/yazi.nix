{ pkgs, ... }: {
  programs.yazi = {
    enable = true;

    settings = {
      # 1. Define the executable/command as an opener entry
      opener = {
        antigravity = [
          {
            run = ''antigravity "$0"'';
            block = true;
            desc = "Antigravity";
          }
        ];
      };

      # 2. Assign default openers by file pattern or extension
      open = {
        rules = [
          # Directory default (Target folders)
          { name = "*/"; use = [ "antigravity" "open" ]; }

          # Text files / Code default
          { mime = "text/*"; use = [ "antigravity" "edit" ]; }

          # Catch-all default (Anything else)
          # { name = "*"; use = [ "antigravity" "open" ]; }
        ];
      };
    };
  };
}