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
        on_primary = "#561e15";
        secondary = "#e7bdb5";
        on_secondary = "#442a25";
        tertiary = "#ddc48c";
        on_tertiary = "#3d2e04";
        surface = "#271d1c";
        surface_high = "#3d3230";
        text = "#f1dfdb";
        subtext = "#d8c2be";
        red = "#ffb4ab";
        on_red = "#690005";
        yellow = "#fae0a6";
        green = "#a6d189";
        blue = "#89b4fa";
        purple = "#cba6f7";
        accent = "#ffdad4";
        background = "#1a1110";
      };

      # Powerlevel10k Style Rounded Pill Layout
      format = lib.concatStrings [
        "╭─$os$username$hostname$directory$git_branch$git_status$git_state$nix_shell$direnv$rust$nodejs$bun$deno$python$golang$c$java$kotlin$lua$docker_context$package$jobs$cmd_duration$status$time\n"
        "╰─$character"
      ];

      # Prompt Character
      character = {
        success_symbol = "[❯](bold primary)";
        error_symbol = "[❯](bold red)";
        vimcmd_symbol = "[❮](bold tertiary)";
      };

      # OS Icon Capsule
      os = {
        disabled = false;
        style = "bg:primary fg:on_primary";
        format = "[](fg:primary)[$symbol]($style)[](fg:primary) ";
        symbols = {
          NixOS = "󱄅 NixOS";
          Arch = "󰣇 Arch";
          Debian = "󰣚 Debian";
          Ubuntu = "󰕈 Ubuntu";
          Linux = "󰌽 Linux";
        };
      };

      # Username - Only show when SSH or root
      username = {
        show_always = false;
        style_user = "bg:tertiary fg:on_tertiary";
        style_root = "bg:red fg:on_red";
        format = "[](fg:tertiary)[ $user]($style)[](fg:tertiary) ";
      };

      # Hostname - Only show when SSH
      hostname = {
        ssh_only = true;
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[󰒍 $hostname]($style)[](fg:tertiary) ";
      };

      # Directory Capsule
      directory = {
        style = "bg:surface_high fg:text";
        format = "[](fg:surface_high)[ $path]($style)[$read_only]($read_only_style)[](fg:surface_high) ";
        read_only = " 󰌾";
        read_only_style = "bg:surface_high fg:red";
        truncation_length = 3;
        truncation_symbol = "…/";
        substitutions = {
          "Documents" = "󰈙 Documents";
          "Downloads" = " Downloads";
          "Music" = "󰝚 Music";
          "Pictures" = " Pictures";
          "GitHub" = "󰊤 GitHub";
        };
      };

      # Git Branch & Status
      git_branch = {
        symbol = " ";
        style = "bg:secondary fg:on_secondary";
        format = "[](fg:secondary)[$symbol$branch]($style)";
      };

      git_status = {
        style = "bg:secondary fg:on_secondary";
        format = "[$all_status$ahead_behind]($style)[](fg:secondary) ";
        conflicted = " =";
        ahead = " ⇡\${count}";
        behind = " ⇣\${count}";
        diverged = " ⇡\${ahead_count}⇣\${behind_count}";
        untracked = " ?";
        modified = " !";
        staged = " +";
        renamed = " »";
        deleted = " ✘";
      };

      git_state = {
        style = "bg:secondary fg:on_secondary";
        format = "([$state $progress_current/$progress_total]($style) )";
      };

      # Nix Shell Indicator
      nix_shell = {
        symbol = "󱄅 ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$state]($style)[](fg:tertiary) ";
        impure_msg = "nix";
        pure_msg = "nix (pure)";
      };

      direnv = {
        disabled = false;
        style = "bg:surface_high fg:tertiary";
        format = "[](fg:surface_high)[▼ direnv]($style)[](fg:surface_high) ";
      };

      # Language & Runtime Indicators
      rust = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      nodejs = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      bun = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      deno = {
        symbol = "🦕 ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      python = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      golang = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      c = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      java = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      kotlin = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      lua = {
        symbol = " ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$version]($style)[](fg:tertiary) ";
      };

      docker_context = {
        symbol = "󰡨 ";
        style = "bg:tertiary fg:on_tertiary";
        format = "[](fg:tertiary)[$symbol$context]($style)[](fg:tertiary) ";
      };

      jobs = {
        style = "bg:surface_high fg:yellow";
        format = "[](fg:surface_high)[✦ $number]($style)[](fg:surface_high) ";
      };

      cmd_duration = {
        min_time = 2000;
        style = "bg:surface_high fg:yellow";
        format = "[](fg:surface_high)[ $duration]($style)[](fg:surface_high) ";
      };

      status = {
        disabled = false;
        symbol = "✘ ";
        style = "bg:red fg:on_red";
        format = "[](fg:red)[$symbol$status]($style)[](fg:red) ";
      };

      time = {
        disabled = false;
        time_format = "%R";
        style = "bg:surface_high fg:subtext";
        format = "[](fg:surface_high)[ $time]($style)[](fg:surface_high) ";
      };

      package.disabled = true;
      line_break.disabled = false;
    };
  };

  # Disable Home Manager's immutable store symlink for starship.toml so zenith-theme.sh
  # can dynamically manage starship palettes without triggering activation collisions on boot.
  xdg.configFile."starship.toml".enable = lib.mkForce false;
}
