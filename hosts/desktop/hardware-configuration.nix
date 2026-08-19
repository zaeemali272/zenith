# Placeholder. Replace this with YOUR machine's hardware configuration.
#
# A hardware-configuration.nix describes physical disks by UUID. Those UUIDs are
# true for exactly one computer, so shipping someone else's here is actively
# dangerous: the build succeeds, and the next boot cannot mount root and drops
# into emergency mode. This file therefore refuses to evaluate rather than hand
# you a system that fails at boot instead of at build time.
#
# Generate your own:
#
#   sudo nixos-generate-config --show-hardware-config \
#     > hosts/desktop/hardware-configuration.nix
#
# Then set your identity in vars.nix -- at minimum user, fullName, email,
# hostname and gpu -- and build:
#
#   sudo nixos-rebuild switch --flake .#desktop
throw ''

  hosts/desktop/hardware-configuration.nix is still the placeholder.

  This config cannot know your disks, so you have to generate that one file:

      sudo nixos-generate-config --show-hardware-config > hosts/desktop/hardware-configuration.nix

  Then set your identity in vars.nix (user, fullName, email, hostname, gpu)
  and build:

      sudo nixos-rebuild switch --flake .#desktop

  Building without doing this would leave your machine in emergency mode on
  the next boot, which is why it stops here instead.
''
