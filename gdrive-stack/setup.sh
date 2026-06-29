#!/usr/bin/env bash
# Configura e sobe o gdrive-stack do zero. Idempotente: pode rodar de novo.
# - gera .env (com SYNC_ROOT, BACKUP_HOST, TZ e uma senha forte de restic)
# - cria o remote do Google Drive (OAuth no navegador)
# - builda e sobe o container
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

say()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
die()  { printf '\033[31merro:\033[0m %s\n' "$*" >&2; exit 1; }

# ── Pré-requisitos ───────────────────────────────────────────────────────────
command -v docker >/dev/null || die "docker não encontrado. Instale com 'yay -S docker docker-compose'."
docker compose version >/dev/null 2>&1 || die "plugin 'docker compose' ausente. Instale 'docker-compose'."
docker info >/dev/null 2>&1 || die "daemon do docker indisponível. Rode:
  sudo systemctl enable --now docker
  sudo usermod -aG docker \"$USER\"   # depois relogue"

# ── .env ─────────────────────────────────────────────────────────────────────
generated_pass=""
if [ ! -f .env ]; then
  say "Gerando .env"
  pass="$(openssl rand -base64 24)"
  tz="$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo America/Sao_Paulo)"
  sed -e "s|^RESTIC_PASSWORD=.*|RESTIC_PASSWORD=${pass}|" \
      -e "s|^SYNC_ROOT=.*|SYNC_ROOT=${HOME}|" \
      -e "s|^BACKUP_HOST=.*|BACKUP_HOST=$(hostname)|" \
      -e "s|^TZ=.*|TZ=${tz}|" \
      .env.example > .env
  chmod 600 .env
  generated_pass="$pass"
else
  say ".env já existe — mantendo o atual"
fi

# carrega as vars do .env
set -a; . ./.env; set +a
remote="${RCLONE_REMOTE:-gdrive}"

# ── Remote do Google Drive (OAuth) ───────────────────────────────────────────
if [ -f config/rclone.conf ] && grep -q "^\[${remote}\]" config/rclone.conf; then
  say "Remote '${remote}' já configurado — pulando OAuth"
else
  say "Configurando o remote '${remote}' do Google Drive (vai abrir o navegador)"
  if command -v rclone >/dev/null; then
    RCLONE_CONFIG="$PWD/config/rclone.conf" rclone config create "${remote}" drive scope=drive \
      || die "rclone config falhou. Tente de novo ou rode 'rclone config' manualmente."
  else
    say "rclone não está no host — buildando a imagem pra rodar o config por ela"
    docker compose build backup
    docker compose run --rm -e RCLONE_CONFIG=/config/rclone.conf backup \
      rclone config create "${remote}" drive scope=drive \
      || die "rclone config (via container) falhou."
  fi
fi

# ── Jobs ─────────────────────────────────────────────────────────────────────
if ! grep -qE '^\s*-\s*\{?\s*mode:' config/jobs.yaml 2>/dev/null; then
  say "Lembrete: edite config/jobs.yaml pra escolher o que sincroniza/backupa"
fi

# ── Build + up ───────────────────────────────────────────────────────────────
say "Buildando e subindo o container"
docker compose up -d --build

say "Pronto. Status:"
docker compose ps

if [ -n "$generated_pass" ]; then
  cat <<EOF

############################################################
  SENHA DO RESTIC (salve no gerenciador de senhas AGORA):

      ${generated_pass}

  Perdeu a senha = backups irrecuperáveis.
  Já está em gdrive-stack/.env (fora do git); guarde uma cópia.
############################################################
EOF
fi
