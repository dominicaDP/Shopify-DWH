# Deploy — systemd unit installation

The ETL is a daily batch job: `shopify-dwh.timer` fires `shopify-dwh.service`, which
runs `python -m shopify_dwh.pipeline --check` once. These two files are templates —
edit the paths/user, then install.

This is the **scheduling** half of Phase E. It needs the ETL Linux VM (ACTIONS.md §A.2),
so it's a deploy-time activity, not something runnable from a dev box.

## One-time host setup

```bash
# 1. Dedicated least-privilege user (no login shell).
sudo useradd --system --home /opt/shopify-dwh --shell /usr/sbin/nologin shopify_etl

# 2. Code + venv (clone or copy the repo to /opt/shopify-dwh).
sudo -u shopify_etl python3 -m venv /opt/shopify-dwh/code/etl/venv
sudo -u shopify_etl /opt/shopify-dwh/code/etl/venv/bin/pip install -r /opt/shopify-dwh/code/etl/requirements.txt

# 3. Secrets OUTSIDE the repo, owned by the ETL user, perms 600.
sudo install -d -o shopify_etl -g shopify_etl -m 700 /etc/shopify-dwh
sudo -u shopify_etl install -m 600 /dev/null /etc/shopify-dwh/etl.env
sudo -u shopify_etl editor /etc/shopify-dwh/etl.env      # fill from .env.example

# 4. Mint the Shopify token (interactive, once per scope change) and confirm Gate A.
sudo -u shopify_etl /opt/shopify-dwh/code/etl/venv/bin/python -m shopify_dwh.oauth_install
sudo -u shopify_etl bash -c 'set -a; . /etc/shopify-dwh/etl.env; set +a; \
  /opt/shopify-dwh/code/etl/venv/bin/python -m shopify_dwh.healthcheck'
```

`etl.env` uses the same keys as [`.env.example`](../.env.example). systemd's
`EnvironmentFile` injects them as environment variables; `config.py` reads
`os.environ` (its `load_dotenv` no-ops because there's no in-repo `code/etl/.env`),
so no secret ever lands in the working tree.

## Install the units

```bash
sudo cp shopify-dwh.service shopify-dwh.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now shopify-dwh.timer     # enable the TIMER, not the service
```

## Operate

```bash
systemctl list-timers shopify-dwh.timer       # when it next runs / last ran
sudo systemctl start shopify-dwh.service      # run once now (ad hoc)
journalctl -u shopify-dwh.service -f          # follow a live run
journalctl -u shopify-dwh.service -e          # last run's output (the pipeline summary)
```

The pipeline prints a per-step summary (OK/FAIL + duration) and exits non-zero if any
step fails, so `systemctl status` / journald reflect run health. For what to do when a
run fails, see [`../RUNBOOK.md`](../RUNBOOK.md).
