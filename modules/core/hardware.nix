{ pkgs, vars, lib, config, ... }:

let
  isIntel = vars.gpu == "intel";
  isAmd = vars.gpu == "amd";
  isNvidia = vars.gpu == "nvidia";
  isVm = vars.gpu == "vm";
in
{
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      mesa
      libva-utils
    ]
    ++ lib.optionals isIntel [
      intel-media-driver
      intel-vaapi-driver
      vpl-gpu-rt
    ]
    ++ lib.optionals isNvidia [
      nvidia-vaapi-driver
    ];
  };

  # Intel-specific hardware acceleration and power management
  boot.kernelParams = lib.optionals isIntel [
    "i915.enable_guc=3" # GuC/HuC hardware scheduling and power-efficient video decode
    "i915.enable_fbc=1" # Framebuffer compression for display power savings
  ];

  # AMD-specific kernel modules
  boot.initrd.kernelModules = lib.optionals isAmd [ "amdgpu" ];

  # NVIDIA-specific configuration
  services.xserver.videoDrivers = lib.optionals isNvidia [ "nvidia" ];
  hardware.nvidia = lib.mkIf isNvidia {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # VM-specific guest additions
  services.qemuGuest.enable = lib.mkIf isVm true;
  services.spice-vdagentd.enable = lib.mkIf isVm true;

  # Display backlight permissions for direct brightness control without logind session constraints
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod a+w /sys/class/backlight/%k/brightness"
  '';

  systemd.services.backlight-permissions = {
    description = "Allow users to adjust display backlight brightness directly";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "grant-backlight-perms" ''
        for f in /sys/class/backlight/*/brightness; do
          [ -e "$f" ] && ${pkgs.coreutils}/bin/chmod a+w "$f" || true
        done
      '';
    };
  };

  # Session variables tuned per GPU vendor
  environment.sessionVariables = lib.mkMerge [
    (lib.mkIf isIntel {
      LIBVA_DRIVER_NAME = "iHD";
      VDPAU_DRIVER = "va_gl";
      MESA_LOADER_DRIVER_OVERRIDE = "iris";
    })
    (lib.mkIf isAmd {
      LIBVA_DRIVER_NAME = "radeonsi";
      VDPAU_DRIVER = "radeonsi";
    })
    (lib.mkIf isNvidia {
      LIBVA_DRIVER_NAME = "nvidia";
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      NVD_BACKEND = "direct";
      ELECTRON_OZONE_PLATFORM_HINT = "auto";
    })
  ];
}
