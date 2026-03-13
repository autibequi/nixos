# Usa o <nixpkgs> do canal já presente na imagem base (sem fetch)
# Uso: nix-build claudeOS/ -A env
# Claude Code é instalado via npm no Dockerfile (flake-only, sem legacy support)
let
  pkgs = import <nixpkgs> {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  packages = import ./packages.nix { inherit pkgs; };
in
{
  env = pkgs.buildEnv {
    name = "claudeos-env";
    paths = packages;
    pathsToLink = [ "/bin" "/lib" "/share" "/etc" ];
  };
}
