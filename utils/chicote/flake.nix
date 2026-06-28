{
  description = "chicote — overlay modal de chicote com física pro Hyprland";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      # raylib feature "wayland" usa GLFW do sistema (USE_EXTERNAL_GLFW).
      libs = with pkgs; [
        wayland libxkbcommon libGL glfw
        xorg.libX11 xorg.libXrandr xorg.libXi xorg.libXcursor xorg.libXinerama
      ];
    in {
      devShells.${system}.default = pkgs.mkShell {
        nativeBuildInputs = with pkgs; [ cargo rustc cmake pkg-config wayland-scanner clang ];
        buildInputs = libs ++ (with pkgs; [ wayland-protocols ]);
        # raylib carrega .so de GL/Wayland em runtime.
        LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath libs;
        # bindgen (raylib-sys) precisa do libclang.
        LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";
      };
    };
}
