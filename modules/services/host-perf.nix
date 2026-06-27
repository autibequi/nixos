{ pkgs, ... }:
{
  # host-perf — sampler de performance em background (PSI cpu/mem/io + load + top
  # processo, a cada 5s) pra diagnosticar travas/lentidão intermitentes do host.
  # Grava em ~/nixos/.ephemeral/perf.log; o `! host-perf` no container do agente
  # apenas LÊ esse arquivo (montado em /workspace/host). "gerado no build, comando só lê".
  # Script: utils/host-perf/host-perf.sh (modo __loop = sampler infinito).
  systemd.user.services.host-perf = {
    description = "host-perf — performance sampler (PSI/load/top) p/ diagnosticar travas";
    wantedBy = [ "default.target" ];
    # PATH mínimo do systemd → declarar os bins que o sampler usa.
    path = [ pkgs.bash pkgs.coreutils pkgs.procps pkgs.gawk ];
    serviceConfig = {
      ExecStart = "${pkgs.bash}/bin/bash /home/pedrinho/nixos/utils/host-perf/host-perf.sh __loop";
      Restart = "always";
      RestartSec = 10;
    };
  };
}
