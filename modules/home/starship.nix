{ pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    
    settings = {
      add_newline = true;
      scan_timeout = 10;
      palette = "zenith";

      palettes.zenith = {
        primary = "#ffb4a7";
        secondary = "#e7bdb5";
        tertiary = "#ddc48c";
        accent = "#ffdad4";
        subtext = "#d8c2be";
        surface = "#271d1c";
        background = "#1a1110";
        red = "#ffb4ab";
        green = "#a6d189";
        yellow = "#fae0a6";
        blue = "#89b4fa";
        purple = "#cba6f7";
      };

      # Minimalist Poweruser Layout
      format = lib.concatStrings [
        "$os"
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$git_state"
        "$nix_shell"
        "$c"
        "$rust"
        "$golang"
        "$nodejs"
        "$python"
        "$java"
        "$lua"
        "$docker_context"
        "$cmd_duration"
        "$status"
        "$line_break"
        "$character"
      ];

      # Prompt Character
      character = {
        success_symbol = "[❯](bold primary)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold tertiary)";
      };

      # OS Icon - Subtle & sleek
      os = {
        disabled = false;
        style = "bold primary";
        symbols = {
          NixOS = "󱄅 ";
          Arch = "󰣇 ";
          Debian = "󰣚 ";
          Ubuntu = "󰕈 ";
          Linux = "󰌽 ";
        };
        format = "[$symbol]($style)";
      };

      # Username - Only show when SSH or root
      username = {
        style_user = "bold tertiary";
        style_root = "bold red";
        format = "[$user]($style)@";
        disabled = false;
        show_always = false;
      };

      # Hostname - Only show when SSH
      hostname = {
        ssh_only = true;
        style = "bold tertiary";
        format = "[$hostname]($style) ";
        disabled = false;
      };

      # Directory - Clean path with truncation and subtle colors
      directory = {
        home_symbol = "~";
        read_only = " 󰌾";
        read_only_style = "bold red";
        style = "bold primary";
        truncation_length = 3;
        truncation_symbol = "…/";
        format = "[$path]($style)[$read_only]($read_only_style) ";
        substitutions = {
          "Documents" = "󰈙 Documents";
          "Downloads" = "󰇚 Downloads";
          "Music" = "󰎈 Music";
          "Pictures" = "󰋩 Pictures";
          "Videos" = "󰕧 Videos";
          "GitHub" = "󰊤 GitHub";
        };
      };

      # Git Branch & Status
      git_branch = {
        style = "bold secondary";
        symbol = "󰘬 ";
        format = "on [$symbol$branch]($style) ";
      };

      git_commit = {
        commit_hash_length = 7;
        tag_symbol = "🏷 ";
      };

      git_state = {
        style = "bold yellow";
        format = "[\($state( $progress_current/$progress_total)\)]($style) ";
      };

      git_status = {
        style = "bold red";
        format = "([$all_status$ahead_behind]($style) )";
        conflicted = "=";
        ahead = "⇡\${count}";
        behind = "⇣\${count}";
        diverged = "⇡\${ahead_count}⇣\${behind_count}";
        untracked = "?";
        stashed = "$";
        modified = "!";
        staged = "+";
        renamed = "»";
        deleted = "✘";
      };

      # Command Duration - Only show if > 2 seconds
      cmd_duration = {
        min_time = 2000;
        style = "bold yellow";
        format = "took [⏱ $duration]($style) ";
      };

      # Nix Shell - Minimal indicator
      nix_shell = {
        symbol = "󱄅 ";
        style = "bold tertiary";
        format = "via [$symbol$state]($style) ";
        impure_msg = "nix";
        pure_msg = "nix (pure)";
      };

      # Language & Runtime Indicators (Minimal text + version)
      c = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$version]($style) ";
      };

      rust = {
        symbol = " ";
        style = "bold bright-red";
        format = "[$symbol$version]($style) ";
      };

      golang = {
        symbol = " ";
        style = "bold bright-cyan";
        format = "[$symbol$version]($style) ";
      };

      nodejs = {
        symbol = " ";
        style = "bold bright-green";
        format = "[$symbol$version]($style) ";
      };

      python = {
        symbol = " ";
        style = "bold yellow";
        format = "[$symbol$version]($style) ";
      };

      java = {
        symbol = " ";
        style = "bold red";
        format = "[$symbol$version]($style) ";
      };

      lua = {
        symbol = " ";
        style = "bold blue";
        format = "[$symbol$version]($style) ";
      };

      docker_context = {
        symbol = "󰡨 ";
        style = "bold blue";
        format = "[$symbol$context]($style) ";
      };

      memory_usage = {
        disabled = true;
      };

      time = {
        disabled = true;
      };

      battery = {
        disabled = true;
      };

      status = {
        disabled = false;
        symbol = "✘ ";
        style = "bold red";
        format = "[$symbol$status]($style) ";
      };

      package.disabled = true;
      line_break.disabled = false;
    };
  };
}
