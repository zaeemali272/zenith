sudo pacman -Syu --needed qemu-full virt-manager dnsmasq vde2 bridge-utils openbsd-netcat
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER


