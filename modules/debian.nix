{ pkgs, config, lib, ... }:

let
  # Definição do pacote Antigravity baseado em .deb do repositório oficial
  antigravity = pkgs.stdenv.mkDerivation rec {
    pname = "antigravity";
    version = "1.0.0-1763466940";

    # URL extraída do repositório APT oficial:
    # https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/
    src = pkgs.fetchurl {
      url = "https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/pool/antigravity-debian/antigravity_${version}_amd64_f36c43ea9197552851df8c4000d2642d.deb";
      sha256 = "355cb727288e9b11d61a0f4fca07c96c78be367d38e0ed0942517e283d1558e0";
    };

    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.dpkg
      pkgs.makeWrapper
    ];

    # Dependências comuns para Apps GUI modernos (Electron/CEF/GTK)
    buildInputs = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libxkbcommon
      mesa
      nspr
      nss
      pango
      systemd
      xorg.libX11
      xorg.libXcomposite
      xorg.libXdamage
      xorg.libXext
      xorg.libXfixes
      xorg.libXrandr
      xorg.libxcb
      xorg.libxkbfile
    ];

    unpackPhase = ''
      # Extrai o pacote manualmente e ignora erros de permissão (suid bit)
      # O Nix build roda em sandbox sem root, então não pode setar suid.
      dpkg-deb -x $src . || true
    '';

    installPhase = ''
      mkdir -p $out
      cp -r usr/* $out/
      
      # O binário principal
      mkdir -p $out/bin
      ln -s $out/share/antigravity/antigravity $out/bin/antigravity
    '';

    meta = with lib; {
      description = "Google Antigravity (Custom Package)";
      homepage = "https://antigravity.google/";
      license = licenses.unfree;
      platforms = platforms.linux;
      mainProgram = "antigravity";
    };
  };

in
{
  environment.systemPackages = [
    antigravity
  ];
}

