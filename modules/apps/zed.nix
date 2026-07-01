# Zed Editor — binário OFICIAL pré-compilado (zero compilação).
#
# Por que não o flake/nixpkgs:
#  - flake github:zed-industries/zed COMPILA o binário final em qualquer ref:
#    o cachix do Zed exclui o binário via pushFilter e o garnix só cacheia as
#    deps (o link final estoura o timeout) — testado empiricamente em tag e main.
#  - nixpkgs.zed-editor tem cache, mas fica ~1 mês atrás do stable.
#  Então baixamos o tar.gz oficial pronto e só fazemos autoPatchelf.
#
# Padrão reutilizável: para outro app distribuído só como binário Linux, copiar
# este módulo (fetchurl + autoPatchelfHook + wrapProgram pras libs dlopen).
# Atualizar a versão: `make zed-update` na raiz do repo.
{ pkgs, lib, ... }:
let
  zed-editor-bin = pkgs.stdenv.mkDerivation rec {
    pname = "zed-editor-bin";
    version = "1.9.0";
    src = pkgs.fetchurl {
      url = "https://github.com/zed-industries/zed/releases/download/v${version}/zed-linux-x86_64.tar.gz";
      hash = "sha256-OeVTzjoA/ut46rY6XLcjfLRg88lZaxsZBSzre56OxN0=";
    };
    nativeBuildInputs = with pkgs; [ autoPatchelfHook makeWrapper ];
    buildInputs = with pkgs; [
      stdenv.cc.cc.lib zlib zstd alsa-lib glib libgit2 openssl sqlite curl
      fontconfig freetype wayland libxkbcommon vulkan-loader libglvnd libGL
      libva libdrm libgbm
      libx11 libxcb libxcomposite libxdamage libxext
      libxfixes libxrandr libxi libxcursor
    ];
    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r . $out/
      # tarball oficial só traz bin/zed; recria o alias `zeditor` (como o flake/nixpkgs)
      ln -s zed $out/bin/zeditor
      runHook postInstall
    '';
    # libs carregadas via dlopen em runtime (autoPatchelf não vê via DT_NEEDED)
    postFixup = ''
      wrapProgram $out/libexec/zed-editor \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath (with pkgs; [ vulkan-loader wayland libva libGL libglvnd libxkbcommon ])}" \
        --suffix PATH : "${lib.makeBinPath (with pkgs; [ nodejs_22 ])}" \
        --set ZED_UPDATE_EXPLANATION "Instalado via Nix (modules/apps/zed.nix). Auto-update desligado — use 'make zed-update'."
    '';
    meta.mainProgram = "zed";
  };
in
{
  environment.systemPackages = [ zed-editor-bin ];
}
