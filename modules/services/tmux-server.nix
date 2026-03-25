{ pkgs, ... }:
let
  user   = "pedrinho";
  uid    = "1000";
  socket = "/run/user/${uid}/zion-tmux.sock";

  serve = pkgs.writeShellScript "zion-tmux-serve" ''
    SOCK="${socket}"
    # Cria sessão persistente (ignora se já existe)
    ${pkgs.tmux}/bin/tmux -S "$SOCK" new-session -d -s main -x 220 -y 50 2>/dev/null || true
    # Servidor não morre quando todos os clientes desconectam
    ${pkgs.tmux}/bin/tmux -S "$SOCK" set-option -g exit-empty off 2>/dev/null || true
    # Mantém o processo vivo enquanto o servidor estiver rodando
    while ${pkgs.tmux}/bin/tmux -S "$SOCK" info >/dev/null 2>&1; do
      sleep 5
    done
  '';
in
{
  systemd.user.services.zion-tmux-serve = {
    description = "Zion tmux server — socket compartilhado host ↔ container";
    wantedBy    = [ "default.target" ];
    after       = [ "graphical-session.target" ];
    serviceConfig = {
      Type       = "simple";
      ExecStart  = "${serve}";
      ExecStop   = "${pkgs.tmux}/bin/tmux -S ${socket} kill-server";
      Restart    = "on-failure";
      RestartSec = "3s";
    };
  };
}
