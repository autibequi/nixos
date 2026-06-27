{ pkgs, ... }:
{
  programs.ydotool = {
    enable = true;
  };

  # Garante que o usuário tem acesso ao socket do ydotoold
  users.users.pedrinho.extraGroups = [ "ydotool" ];
}
