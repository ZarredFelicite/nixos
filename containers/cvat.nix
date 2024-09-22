# Auto-generated using compose2nix v0.2.3-pre.
{ pkgs, lib, ... }:

{
  # Runtime
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    dockerCompat = true;
    defaultNetwork.settings = {
      # Required for container networking to be able to use names.
      dns_enabled = true;
    };
  };
  virtualisation.oci-containers.backend = "podman";

  # Containers
  virtualisation.oci-containers.containers."cvat_clickhouse" = {
    image = "clickhouse/clickhouse-server:23.11-alpine";
    environment = {
      "CLICKHOUSE_DB" = "cvat";
      "CLICKHOUSE_HOST" = "clickhouse";
      "CLICKHOUSE_PASSWORD" = "user";
      "CLICKHOUSE_PORT" = "8123";
      "CLICKHOUSE_USER" = "user";
    };
    volumes = [
      "/home/zarred/dev/cvat/components/analytics/clickhouse/init.sh:/docker-entrypoint-initdb.d/init.sh:ro"
      "cvat_cvat_events_db:/var/lib/clickhouse:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_clickhouse"
      "--network=cvat_cvat:alias=clickhouse"
    ];
  };
  systemd.services."podman-cvat_clickhouse" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_events_db.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_events_db.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_db" = {
    image = "postgres:15-alpine";
    environment = {
      "POSTGRES_DB" = "cvat";
      "POSTGRES_HOST_AUTH_METHOD" = "trust";
      "POSTGRES_USER" = "root";
    };
    volumes = [
      "cvat_cvat_db:/var/lib/postgresql/data:rw"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_db"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_db" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_db.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_db.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_grafana" = {
    image = "grafana/grafana-oss:10.1.2";
    environment = {
      "CLICKHOUSE_DB" = "cvat";
      "CLICKHOUSE_HOST" = "clickhouse";
      "CLICKHOUSE_PASSWORD" = "user";
      "CLICKHOUSE_PORT" = "8123";
      "CLICKHOUSE_USER" = "user";
      "GF_AUTH_ANONYMOUS_ENABLED" = "true";
      "GF_AUTH_ANONYMOUS_ORG_ROLE" = "Admin";
      "GF_AUTH_BASIC_ENABLED" = "false";
      "GF_AUTH_DISABLE_LOGIN_FORM" = "true";
      "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH" = "/var/lib/grafana/dashboards/all_events.json";
      "GF_INSTALL_PLUGINS" = "https://github.com/grafana/clickhouse-datasource/releases/download/v4.0.8/grafana-clickhouse-datasource-4.0.8.linux_amd64.zip;grafana-clickhouse-datasource";
      "GF_PATHS_PROVISIONING" = "/etc/grafana/provisioning";
      "GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS" = "grafana-clickhouse-datasource";
      "GF_SERVER_ROOT_URL" = "http://localhost/analytics";
    };
    volumes = [
      "/home/zarred/dev/cvat/components/analytics/grafana/dashboards:/var/lib/grafana/dashboards:ro"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_grafana"
      "--network=cvat_cvat:alias=grafana"
    ];
  };
  systemd.services."podman-cvat_grafana" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "no";
    };
    after = [
      "podman-network-cvat_cvat.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_opa" = {
    image = "openpolicyagent/opa:0.63.0";
    cmd = [ "run" "--server" "--log-level=error" "--set=services.cvat.url=http://cvat-server:8082" "--set=bundles.cvat.service=cvat" "--set=bundles.cvat.resource=/api/auth/rules" "--set=bundles.cvat.polling.min_delay_seconds=5" "--set=bundles.cvat.polling.max_delay_seconds=15" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_opa"
      "--network=cvat_cvat:alias=opa"
    ];
  };
  systemd.services."podman-cvat_opa" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_redis_inmem" = {
    image = "redis:7.2.3-alpine";
    volumes = [
      "cvat_cvat_inmem_db:/data:rw"
    ];
    cmd = [ "redis-server" "--save" "60" "100" "--appendonly" "yes" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_redis_inmem"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_redis_inmem" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_inmem_db.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_inmem_db.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_redis_ondisk" = {
    image = "apache/kvrocks:2.7.0";
    volumes = [
      "cvat_cvat_cache_db:/var/lib/kvrocks/data:rw"
    ];
    cmd = [ "--dir" "/var/lib/kvrocks/data" ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_redis_ondisk"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_redis_ondisk" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_cache_db.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_cache_db.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_server" = {
    image = "cvat/server:dev";
    environment = {
      "ADAPTIVE_AUTO_ANNOTATION" = "false";
      "ALLOWED_HOSTS" = "*";
      "CLICKHOUSE_DB" = "cvat";
      "CLICKHOUSE_HOST" = "clickhouse";
      "CLICKHOUSE_PASSWORD" = "user";
      "CLICKHOUSE_PORT" = "8123";
      "CLICKHOUSE_USER" = "user";
      "CVAT_ANALYTICS" = "1";
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "DJANGO_MODWSGI_EXTRA_ARGS" = "";
      "NUMPROCS" = "2";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "init" "run" "server" ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.cvat.entrypoints" = "web";
      "traefik.http.routers.cvat.rule" = "Host(`localhost`) && PathPrefix(`/api/`, `/static/`, `/admin`, `/documentation/`, `/django-rq`)";
      "traefik.http.services.cvat.loadbalancer.server.port" = "8082";
    };
    dependsOn = [
      "cvat_db"
      "cvat_opa"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_server"
      "--network=cvat_cvat:alias=cvat-server"
    ];
  };
  systemd.services."podman-cvat_server" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_ui" = {
    image = "cvat/ui:dev";
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.cvat-ui.entrypoints" = "localhost";
      "traefik.http.routers.cvat-ui.rule" = "Host(`localhost`)";
      "traefik.http.services.cvat-ui.loadbalancer.server.port" = "80";
    };
    dependsOn = [
      "cvat_server"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_ui"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_ui" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_utils" = {
    image = "cvat/server:dev";
    environment = {
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PASSWORD" = "";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "NUMPROCS" = "1";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "run" "utils" ];
    dependsOn = [
      "cvat_db"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_utils"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_utils" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_vector" = {
    image = "timberio/vector:0.26.0-alpine";
    environment = {
      "CLICKHOUSE_DB" = "cvat";
      "CLICKHOUSE_HOST" = "clickhouse";
      "CLICKHOUSE_PASSWORD" = "user";
      "CLICKHOUSE_PORT" = "8123";
      "CLICKHOUSE_USER" = "user";
    };
    volumes = [
      "/home/zarred/dev/cvat/components/analytics/vector/vector.toml:/etc/vector/vector.toml:ro"
    ];
    dependsOn = [
      "cvat_clickhouse"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_vector"
      "--network=cvat_cvat:alias=vector"
    ];
  };
  systemd.services."podman-cvat_vector" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_worker_analytics_reports" = {
    image = "cvat/server:dev";
    environment = {
      "CLICKHOUSE_DB" = "cvat";
      "CLICKHOUSE_HOST" = "clickhouse";
      "CLICKHOUSE_PASSWORD" = "user";
      "CLICKHOUSE_PORT" = "8123";
      "CLICKHOUSE_USER" = "user";
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "NUMPROCS" = "2";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "run" "worker.analytics_reports" ];
    dependsOn = [
      "cvat_db"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_worker_analytics_reports"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_worker_analytics_reports" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_worker_annotation" = {
    image = "cvat/server:dev";
    environment = {
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "NUMPROCS" = "1";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "run" "worker.annotation" ];
    dependsOn = [
      "cvat_db"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_worker_annotation"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_worker_annotation" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_worker_export" = {
    image = "cvat/server:dev";
    environment = {
      "CLICKHOUSE_DB" = "cvat";
      "CLICKHOUSE_HOST" = "clickhouse";
      "CLICKHOUSE_PASSWORD" = "user";
      "CLICKHOUSE_PORT" = "8123";
      "CLICKHOUSE_USER" = "user";
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "NUMPROCS" = "2";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "run" "worker.export" ];
    dependsOn = [
      "cvat_db"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_worker_export"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_worker_export" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_worker_import" = {
    image = "cvat/server:dev";
    environment = {
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "NUMPROCS" = "2";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "run" "worker.import" ];
    dependsOn = [
      "cvat_db"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_worker_import"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_worker_import" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_worker_quality_reports" = {
    image = "cvat/server:dev";
    environment = {
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "NUMPROCS" = "1";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "run" "worker.quality_reports" ];
    dependsOn = [
      "cvat_db"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_worker_quality_reports"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_worker_quality_reports" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."cvat_worker_webhooks" = {
    image = "cvat/server:dev";
    environment = {
      "CVAT_LOG_IMPORT_ERRORS" = "true";
      "CVAT_POSTGRES_HOST" = "cvat_db";
      "CVAT_REDIS_INMEM_HOST" = "cvat_redis_inmem";
      "CVAT_REDIS_INMEM_PORT" = "6379";
      "CVAT_REDIS_ONDISK_HOST" = "cvat_redis_ondisk";
      "CVAT_REDIS_ONDISK_PORT" = "6666";
      "DJANGO_LOG_SERVER_HOST" = "vector";
      "DJANGO_LOG_SERVER_PORT" = "80";
      "NUMPROCS" = "1";
      "SMOKESCREEN_OPTS" = "";
      "no_proxy" = "clickhouse,grafana,vector,nuclio,opa,";
    };
    volumes = [
      "cvat_cvat_data:/home/django/data:rw"
      "cvat_cvat_keys:/home/django/keys:rw"
      "cvat_cvat_logs:/home/django/logs:rw"
    ];
    cmd = [ "run" "worker.webhooks" ];
    dependsOn = [
      "cvat_db"
      "cvat_redis_inmem"
      "cvat_redis_ondisk"
    ];
    log-driver = "journald";
    extraOptions = [
      "--network-alias=cvat_worker_webhooks"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-cvat_worker_webhooks" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
      "podman-volume-cvat_cvat_data.service"
      "podman-volume-cvat_cvat_keys.service"
      "podman-volume-cvat_cvat_logs.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };
  virtualisation.oci-containers.containers."traefik" = {
    image = "traefik:v2.10";
    environment = {
      "CVAT_HOST" = "localhost";
      "DJANGO_LOG_VIEWER_HOST" = "grafana";
      "DJANGO_LOG_VIEWER_PORT" = "3000";
      "TRAEFIK_ACCESSLOG_FORMAT" = "json";
      "TRAEFIK_ENTRYPOINTS_web_ADDRESS" = ":8082";
      "TRAEFIK_LOG_FORMAT" = "json";
      "TRAEFIK_PROVIDERS_DOCKER_EXPOSEDBYDEFAULT" = "false";
      "TRAEFIK_PROVIDERS_DOCKER_NETWORK" = "cvat";
      "TRAEFIK_PROVIDERS_FILE_DIRECTORY" = "/etc/traefik/rules";
    };
    volumes = [
      "/home/zarred/dev/cvat/components/analytics/grafana_conf.yml:/etc/traefik/rules/grafana_conf.yml:ro"
      "/var/run/docker.sock:/var/run/docker.sock:ro"
    ];
    ports = [
      "8082:8082/tcp"
      "8092:8090/tcp"
    ];
    log-driver = "journald";
    extraOptions = [
      "--log-opt=max-file=10"
      "--log-opt=max-size=100m"
      "--network-alias=traefik"
      "--network=cvat_cvat"
    ];
  };
  systemd.services."podman-traefik" = {
    serviceConfig = {
      Restart = lib.mkOverride 500 "always";
    };
    after = [
      "podman-network-cvat_cvat.service"
    ];
    requires = [
      "podman-network-cvat_cvat.service"
    ];
    partOf = [
      "podman-compose-cvat-root.target"
    ];
    wantedBy = [
      "podman-compose-cvat-root.target"
    ];
  };

  # Networks
  systemd.services."podman-network-cvat_cvat" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "podman network rm -f cvat_cvat";
    };
    script = ''
      podman network inspect cvat_cvat || podman network create cvat_cvat
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };

  # Volumes
  systemd.services."podman-volume-cvat_cvat_cache_db" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect cvat_cvat_cache_db || podman volume create cvat_cvat_cache_db
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };
  systemd.services."podman-volume-cvat_cvat_data" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect cvat_cvat_data || podman volume create cvat_cvat_data
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };
  systemd.services."podman-volume-cvat_cvat_db" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect cvat_cvat_db || podman volume create cvat_cvat_db
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };
  systemd.services."podman-volume-cvat_cvat_events_db" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect cvat_cvat_events_db || podman volume create cvat_cvat_events_db
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };
  systemd.services."podman-volume-cvat_cvat_inmem_db" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect cvat_cvat_inmem_db || podman volume create cvat_cvat_inmem_db
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };
  systemd.services."podman-volume-cvat_cvat_keys" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect cvat_cvat_keys || podman volume create cvat_cvat_keys
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };
  systemd.services."podman-volume-cvat_cvat_logs" = {
    path = [ pkgs.podman ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      podman volume inspect cvat_cvat_logs || podman volume create cvat_cvat_logs
    '';
    partOf = [ "podman-compose-cvat-root.target" ];
    wantedBy = [ "podman-compose-cvat-root.target" ];
  };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-compose-cvat-root" = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
