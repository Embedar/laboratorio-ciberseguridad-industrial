#!/usr/bin/env bash
# Provisionar antes de conectar victimas. No ejecutar durante auditoria aislada.
set -euo pipefail
if [[ ${1:-} != --aprovisionamiento || $# -gt 2 || ( $# == 2 && $2 != --capturas ) ]]; then
  echo 'Uso: bash bootstrap-kali.sh --aprovisionamiento [--capturas]' >&2
  exit 2
fi
sudo apt-get update
sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y nmap wireshark tshark curl python3 python3-pexpect telnet openssh-server open-vm-tools
# Dar captura al grupo wireshark sin ejecutar toda la practica como root.
printf 'wireshark-common wireshark-common/install-setuid boolean true\n' | sudo debconf-set-selections
sudo DEBIAN_FRONTEND=noninteractive dpkg-reconfigure wireshark-common
sudo usermod -aG wireshark "$(id -un)"
if [[ ${2:-} == --capturas ]]; then
  sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y xvfb qterminal xdotool xfwm4 x11-xserver-utils xfce4-screenshooter
fi
sudo systemctl enable --now ssh
sudo systemctl enable --now open-vm-tools
mkdir -p "$HOME/lab-plc/evidencias" "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
printf '%s\n' 'Cerrar y abrir sesion para activar grupo wireshark; comprobar id y dumpcap -D.'
printf '%s\n' 'Instalar SOLO la clave publica dedicada en ~/.ssh/authorized_keys (600), nunca copiar privada.'
printf '%s\n' 'Huella de consola: sudo ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub -E sha256'
systemctl is-active ssh open-vm-tools
