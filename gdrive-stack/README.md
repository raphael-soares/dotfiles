# gdrive-stack

Stack Docker que faz duas coisas, declarativamente, contra o Google Drive:

- **sync** — espelho uma-via de pastas pro Drive, via `rclone sync`.
- **backup** — backup incremental versionado e encriptado, via `restic`
  usando o rclone como backend.

Container único (Alpine + rclone + restic). Agendamento por cron do busybox
**dentro** do container, sem systemd, sem cron no host. Portável: copia a pasta
pra qualquer máquina, preenche dois arquivos e sobe.

## Como funciona

- `config/jobs.yaml` — lista de jobs (campos `mode`, `src`, `dest`). Única
  superfície pra escolher o que sincroniza/backupa e o destino. Parseado com
  `yq` no container, então formate/lint com qualquer ferramenta YAML.
- `.env` — segredos e config da máquina (gitignored).
- `config/rclone.conf` — credenciais OAuth do Drive (gitignored).
- A pasta-raiz dos teus arquivos (`SYNC_ROOT`) é montada **read-only**. O stack
  nunca escreve nos teus arquivos.
- `restic`: um repositório só, separado por **tag** (dedup entre pastas, uma
  senha só). Retenção: 7 diários, 4 semanais, 6 mensais, com `--prune`.

Agendamento padrão (`config/crontab`): `sync` de hora em hora, `backup` às 03:30.

## Setup (um comando)

```bash
cd ~/.dotfiles/gdrive-stack
./setup.sh
```

`setup.sh` é idempotente e faz tudo: checa o docker, gera o `.env` (com
`SYNC_ROOT`, `BACKUP_HOST`, `TZ` e uma senha forte de restic), abre o OAuth do
Google Drive no navegador, builda e sobe o container. No fim mostra a senha do
restic pra você salvar. Rodar de novo não refaz o que já está pronto.

Depois, edite `config/jobs.yaml` com o que quer sincronizar/backupar (veja a
seção abaixo) e rode `./setup.sh` de novo (ou `docker compose up -d`).

### Setup manual (se preferir passo a passo)

1. Copie os templates:

   ```bash
   cd gdrive-stack
   cp .env.example .env
   cp config/rclone.conf.example config/rclone.conf   # será sobrescrito no passo 3
   ```

2. Edite o `.env`:
   - `SYNC_ROOT` — pasta-raiz dos teus arquivos (ex.: `/home/raphael`). Tudo em
     `jobs.yaml` precisa estar sob ela.
   - `RESTIC_PASSWORD` — senha forte. **Perdeu a senha = backups irrecuperáveis.**
   - `BACKUP_HOST`, `TZ` — conforme a máquina.

3. Crie o remote do rclone (passo interativo, abre o navegador):

   ```bash
   rclone config        # crie um remote chamado igual a RCLONE_REMOTE (ex.: gdrive), type=drive
   ```

   Copie a seção gerada pra `config/rclone.conf` (o `[gdrive]` tem que bater com
   `RCLONE_REMOTE`). Se o `rclone` não estiver instalado no host, gere dentro do
   container depois do `up`:

   ```bash
   docker compose run --rm backup rclone config
   ```

4. Defina teus jobs em `config/jobs.yaml`. Exemplo:

   ```yaml
   jobs:
     - mode: sync
       src: /home/raphael/Notes
       dest: notes
     - mode: backup
       src: /home/raphael/Workspace
       dest: workspace
   ```

5. Suba:

   ```bash
   docker compose up -d --build
   docker compose logs --tail=30 backup
   ```

## Comandos úteis

```bash
docker compose ps                                  # status do container
docker compose logs -f backup                      # acompanhar logs do cron
docker compose exec backup /scripts/dispatch.sh sync     # rodar sync agora
docker compose exec backup /scripts/dispatch.sh backup   # rodar backup agora

# inspecionar / restaurar backups (restic):
docker compose exec backup sh -c \
  'RESTIC_REPOSITORY=rclone:$RCLONE_REMOTE:$RESTIC_REPO_PATH restic snapshots'
docker compose exec backup sh -c \
  'RESTIC_REPOSITORY=rclone:$RCLONE_REMOTE:$RESTIC_REPO_PATH restic restore latest --target /tmp/restore --tag notes'
```

## Notas

- `sync` é uma via (local → Drive) e **espelha**: arquivos removidos na origem
  somem do destino. Use `backup` pro que precisa de histórico.
- Tratamento de erros: um job que falha não derruba os outros — cada um roda
  isolado e no fim sai um resumo (`N ok, M com erro`). O `dispatch.sh` retorna
  código != 0 se algum job falhou. Casos cobertos com mensagem clara: YAML
  inválido, remote do rclone inexistente (OAuth não feito), `mode` desconhecido,
  `src`/`dest` faltando, e `src` fora de `SYNC_ROOT` (não montado).
- Pastas listadas que não existem são puladas com aviso, não quebram o job.
- `.env` e `config/rclone.conf` estão no `.gitignore` — nunca commite segredo.
