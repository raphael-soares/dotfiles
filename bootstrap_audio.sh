#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

# Modulo opcional, fora do bootstrap.sh principal de proposito: mexe em audio,
# que e especifico de hardware/desktop, nao agnostico como o resto dos dotfiles.
# Rode a mao, so na maquina onde faz sentido.
#
# O que faz: forca todo dispositivo Bluetooth a so usar A2DP (som estereo de alta
# fidelidade), removendo os papeis handsfree HSP/HFP do WirePlumber. Resolve
# caixa/soundbar BT que conecta como "headset" mono 16 kHz. Detalhes no
# comentario de audio/.config/wireplumber/wireplumber.conf.d/53-bluetooth-a2dp-only.conf

cat <<'EOF'
Deps:

  stow git wireplumber (PipeWire)

EOF

if ! command -v stow >/dev/null || ! command -v git >/dev/null; then
  echo "Precisa de stow e git para rodar este script." >&2
  exit 1
fi

if ! command -v wireplumber >/dev/null; then
  echo "WirePlumber nao encontrado. Este modulo e para PipeWire + WirePlumber." >&2
  exit 1
fi

# Sem isto, numa maquina onde ~/.config/wireplumber ainda nao existe, o stow
# dobra o diretorio inteiro num symlink pro repo e o estado do WirePlumber vira
# sujeira versionada. Mesmo motivo do mkdir no bootstrap.sh.
mkdir -p "$HOME/.config/wireplumber/wireplumber.conf.d"

echo "==> Stowing audio..."
# --adopt puxa pro repo qualquer arquivo real que ja exista no destino; o
# git restore em seguida joga fora essa adocao e reafirma a versao do repo,
# deixando so o symlink. O || true cobre a primeira vez, quando o pacote ainda
# nao foi commitado e nao ha o que restaurar.
stow --adopt -R audio
git restore -- audio 2>/dev/null || true

echo "==> Reiniciando WirePlumber..."
if command -v systemctl >/dev/null; then
  systemctl --user restart wireplumber || true
else
  echo "systemctl --user indisponivel; reinicie o WirePlumber a mao para aplicar."
fi

echo
echo "Done. Reconecte o dispositivo Bluetooth para ele renegociar em A2DP."
