# Yaak API client — AppImage oficial wrappado via appimageTools.
#
# Por que AppImage e não nixpkgs:
#  - Não existe pacote nixpkgs.yaak; AppImage é a distribuição oficial Linux.
#  - appimageTools.wrapType2 faz autoPatchelf + sandbox automáticos.
#
# Padrão idêntico ao zed.nix (fetchurl + wrap + desktop + ícone).
# Atualizar versão: make yaak-update na raiz do repo.
{ pkgs, lib, ... }:
let
  pname = "yaak";
  version = "2026.4.0";

  src = pkgs.fetchurl {
    url = "https://github.com/mountain-loop/yaak/releases/download/v${version}/${pname}_${version}_amd64.AppImage";
    hash = "sha256-vI3MXveQKPnlYAJhVxhWGk03CQpkX5yc3o9lQBeAykg="; # atualizar com: make yaak-update
  };

  desktopItem = pkgs.makeDesktopItem {
    name = pname;
    desktopName = "Yaak";
    exec = "${pname} %U";
    icon = pname;
    categories = [ "Development" "Network" ];
    startupWMClass = pname;
    startupNotify = true;
  };

  yaak = pkgs.appimageTools.wrapType2 {
    name = "${pname}-${version}";
    inherit src;
    extraInstallCommands = ''
      install -Dm644 ${desktopItem}/share/applications/${pname}.desktop \
        $out/share/applications/${pname}.desktop
      install -Dm644 ${./yaak.png} \
        $out/share/icons/hicolor/256x256/apps/${pname}.png
    '';
  };
in
{
  environment.systemPackages = [ yaak ];
}
