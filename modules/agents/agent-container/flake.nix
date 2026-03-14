{
  description = "ClaudeOS — ambiente declarativo do container (agent-container)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    claude-code.url = "github:sadjow/claude-code-nix";
    claude-code.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, claude-code }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ claude-code.overlays.default ];
      };
      packages = import ./packages.nix { inherit pkgs; };
    in
    {
      packages.${system}.default = pkgs.buildEnv {
        name = "claudeos-env";
        paths = packages ++ [ pkgs.claude-code ];
        pathsToLink = [ "/bin" "/lib" "/share" "/etc" ];
      };
    };
}
