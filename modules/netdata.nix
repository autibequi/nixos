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
        # Coleta a cada 10s (era 1s — maior vilão de CPU+I/O do sistema)
        "update every" = "10";
        # Usar dbengine para histórico em disco
        "memory mode" = "dbengine";
        # Espaço em disco para métricas (MB) — reduzido pra poupar I/O
        "page cache size" = "32";
        "dbengine multihost disk space" = "256";
      };
      web = {
        "default port" = "19999";
        # Só acesso local
        "bind to" = "127.0.0.1";
      };
    };
  };
}
