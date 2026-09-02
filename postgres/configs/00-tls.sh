#!/bin/bash
# Postgres ships with ssl off and no certificate, so an instance published on a public
# address sends its rows — and the password exchange around them — in clear. This turns TLS
# on before the server first accepts a connection. Set POSTGRES_TLS=off for a database
# nothing outside the cluster reaches.
#
# Everything below is one if/else and there is no `exit` anywhere, deliberately. The
# entrypoint SOURCES this file rather than executing it, so an `exit` here ends the
# entrypoint and the database never starts — which is what turning TLS off used to do.
# `set -e` is left out for the same reason: it would outlive this script.

if [ "${POSTGRES_TLS:-on}" = "off" ]; then
  echo "tls: POSTGRES_TLS=off, leaving connections unencrypted"
else
  tls_crt="$PGDATA/server.crt"
  tls_key="$PGDATA/server.key"

  # Self-signed, and named for the service rather than a hostname: an instance answers on
  # whatever address its owner points at it, so no CN would be right for all of them.
  # Clients therefore encrypt without verifying the server (sslmode=require), which defeats
  # eavesdropping but not an active man in the middle. Replace these two files with your own
  # certificate to get sslmode=verify-full.
  if [ ! -f "$tls_key" ]; then
    openssl req -new -x509 -days 3650 -nodes -text \
      -out "$tls_crt" -keyout "$tls_key" -subj "/CN=postgres" >/dev/null 2>&1
    chmod 600 "$tls_key"
    chown postgres:postgres "$tls_crt" "$tls_key" 2>/dev/null || true
  fi

  # ALTER SYSTEM rather than server flags, because this runs against the temporary server the
  # entrypoint starts for initialisation and postgresql.auto.conf is read by the real one that
  # follows. A server told ssl=on before the certificate exists refuses to start.
  psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
	ALTER SYSTEM SET ssl = on;
	ALTER SYSTEM SET ssl_cert_file = 'server.crt';
	ALTER SYSTEM SET ssl_key_file = 'server.key';
	EOSQL

  echo "tls: enabled with a self-signed certificate"
fi
