{ pkgs, ... }:

{
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber = {
      enable = true;
      extraConfig.wireplumber = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };

    extraConfig.pipewire."91-null-sinks" = {
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "stream-sink";
            "node.description" = "Stream Sink";
            "media.class" = "Audio/Sink";
            "object.linger" = true;
            "audio.position" = "[ FL FR ]";
          };
        }
      ];
    };
  };
}