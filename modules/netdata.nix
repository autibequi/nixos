{
  pkgs,
  ...
}:

{
  services.netdata = {
    enable = true;
    package = pkgs.netdata;
    config = {
      global = {
        # Histórico de 7 dias (em segundos)
        "history" = "604800";
        # Coleta a cada 1 segundo
        "update every" = "1";
        # Usar dbengine para histórico em disco
        "memory mode" = "dbengine";
        # Espaço em disco para métricas (MB)
        "page cache size" = "64";
        "dbengine multihost disk space" = "512";
      };
      web = {
        "default port" = "19999";
        # Só acesso local
        "bind to" = "127.0.0.1";
      };
    };
  };
}
