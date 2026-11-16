#!/usr/bin/env bash
# Configura solo la interfaz explicitamente indicada. El host debe usar VMnet1.
set -euo pipefail
if [[ $# != 1 || ! $1 =~ ^[a-zA-Z0-9_.:-]+$ ]]; then
  echo 'Uso en consola Kali: bash Configurar-red-lab.sh INTERFAZ' >&2
  exit 2
fi
iface=$1
[[ -d /sys/class/net/$iface ]] || { echo 'Interfaz inexistente' >&2; exit 2; }
[[ $iface != lo ]] || { echo 'No se puede usar loopback' >&2; exit 2; }
command -v nmcli >/dev/null
name="lab-plc-${iface}"
if nmcli -t -f NAME connection show | grep -Fxq "$name"; then
  bound=$(nmcli -g connection.interface-name connection show "$name")
  [[ $bound == "$iface" ]] || { echo 'El perfil existente pertenece a otra interfaz' >&2; exit 1; }
else
  sudo nmcli connection add type ethernet ifname "$iface" con-name "$name"
fi
sudo nmcli connection modify "$name" ipv4.method manual ipv4.addresses 192.168.212.10/24 ipv4.gateway '' ipv4.dns '' ipv4.never-default yes ipv4.ignore-auto-dns yes ipv6.method disabled
sudo nmcli connection up "$name" ifname "$iface"
ip -brief address show dev "$iface"
ip route show
ip -6 route show
if ip route show default | grep -q . || ip -6 route show default | grep -q .; then
  echo 'BLOQUEADO: hay ruta por defecto. Desconectar otros adaptadores antes de auditar.' >&2
  exit 1
fi
[[ $(sysctl -n net.ipv4.ip_forward) == 0 ]] || { echo 'BLOQUEADO: reenvio IPv4 habilitado' >&2; exit 1; }
echo 'Configuracion local comprobada; verificar tambien VMX host-only, rutas del host e inexistencia de ICS/puentes.'
