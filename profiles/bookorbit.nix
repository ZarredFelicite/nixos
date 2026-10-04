{ pkgs, ... }: {
  # A private app/DB network. The idempotent setup unit lets generated
  # oci-containers units depend on the network existing before container start.
  systemd.services.podman-network-bookorbit = {
    description = "Create the private BookOrbit Podman network";
    wantedBy = [ "multi-user.target" ];
    before = [ "podman-bookorbit-postgres.service" "podman-bookorbit-app.service" ];
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "+${pkgs.writeShellScript "bookorbit-network-create" ''
        if ! ${pkgs.podman}/bin/podman network exists bookorbit; then
          ${pkgs.podman}/bin/podman network create bookorbit
        fi
      ''}";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/bookorbit 0750 root root - -"
    "d /var/lib/bookorbit/app 0750 zarred users - -"
    "d /var/lib/bookorbit/import 0750 zarred users - -"
    "d /var/lib/bookorbit/postgres 0700 root root - -"
  ];

  virtualisation.oci-containers.containers = {
    bookorbit-postgres = {
      image = "docker.io/pgvector/pgvector:pg18@sha256:ad249f9fb9572979643a47694e59b9a8cdcdf6abc6accebf49bb80ad5f20ff9b";
      environment = {
        POSTGRES_DB = "bookorbit";
        POSTGRES_USER = "bookorbit";
        POSTGRES_PASSWORD_FILE = "/run/secrets/postgres-password";
        # PG18's image defaults to a versioned directory under
        # /var/lib/postgresql; explicitly place it in the persistent bind.
        PGDATA = "/var/lib/postgresql/data";
      };
      ports = [ ];
      networks = [ "bookorbit" ];
      volumes = [
        "/var/lib/bookorbit/postgres:/var/lib/postgresql/data"
        "/persist/etc/bookorbit/postgres-password:/run/secrets/postgres-password:ro"
      ];
      extraOptions = [
        "--network-alias=postgres"
        "--health-cmd=pg_isready -U bookorbit -d bookorbit"
        "--health-interval=10s"
        "--health-timeout=5s"
        "--health-retries=10"
      ];
    };

    bookorbit-app = {
      image = "ghcr.io/bookorbit/bookorbit:3.2.0@sha256:d2ad208924c3743078991ec8ee4819d84e435d3377c4ddf61a05f0cd033b3e08";
      dependsOn = [ "bookorbit-postgres" ];
      environment = {
        PORT = "3000";
        APP_URL = "http://192.168.8.200:8090";
        POSTGRES_HOST = "postgres";
        POSTGRES_PORT = "5432";
        POSTGRES_USER = "bookorbit";
        POSTGRES_DB = "bookorbit";
        POSTGRES_PASSWORD = "";
        POSTGRES_PASSWORD_FILE = "/run/secrets/postgres-password";
        JWT_SECRET = "";
        JWT_SECRET_FILE = "/run/secrets/jwt-secret";
        SETUP_BOOTSTRAP_TOKEN = "";
        SETUP_BOOTSTRAP_TOKEN_FILE = "/run/secrets/bootstrap-token";
        BOOK_REQUEST_ENCRYPTION_KEY = "";
        BOOK_REQUEST_ENCRYPTION_KEY_FILE = "/run/secrets/book-request-encryption-key";
        PUID = "1000";
        PGID = "100";
        BOOK_DOCK_PATH = "/import";
        LIBRARY_BROWSE_ROOT = "/source";
        NODE_MAX_OLD_SPACE_SIZE = "2048";
        TZ = "Australia/Melbourne";
      };
      ports = [ "192.168.8.200:8090:3000" ];
      networks = [ "bookorbit" ];
      volumes = [
        "/var/lib/bookorbit/app:/data"
        "/var/lib/bookorbit/import:/import"
        "/mnt/gargantua/media/books/cwa-library:/source/ebooks:ro"
        "/mnt/gargantua/media/books/audiobooks:/source/audiobooks:ro"
        "/persist/etc/bookorbit/postgres-password:/run/secrets/postgres-password:ro"
        "/persist/etc/bookorbit/jwt-secret:/run/secrets/jwt-secret:ro"
        "/persist/etc/bookorbit/bootstrap-token:/run/secrets/bootstrap-token:ro"
        "/persist/etc/bookorbit/book-request-encryption-key:/run/secrets/book-request-encryption-key:ro"
      ];
      extraOptions = [
        "--init"
        "--read-only"
        "--tmpfs=/tmp:rw,noexec,nosuid,size=256m"
        "--cap-drop=ALL"
        "--cap-add=CHOWN"
        "--cap-add=DAC_OVERRIDE"
        "--cap-add=FOWNER"
        "--cap-add=SETGID"
        "--cap-add=SETUID"
        "--security-opt=no-new-privileges:true"
      ];
    };
  };

  systemd.services.podman-bookorbit-postgres = {
    requires = [ "podman-network-bookorbit.service" ];
    after = [ "podman-network-bookorbit.service" ];
  };
  systemd.services.podman-bookorbit-app = {
    requires = [ "podman-network-bookorbit.service" ];
    after = [ "podman-network-bookorbit.service" ];
  };
}
