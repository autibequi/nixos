{
  description = "A very basic flake";

  inputs = {
    # Nix Channels
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # nixpkgs.url = "github:NixOS/nixpkgs/staging";
    nixpkgs.url = "github:NixOS/nixpkgs/staging-next";

    # Hardware URL
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  # Non Nixos Sources
  inputs = {
    # Others
    # nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    
    # Interactive SystemD
    isd.url = "github:isd-project/isd";

    # Home Manager
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11"; 
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Logitech Solaar
    solaar = {
      url = "https://flakehub.com/f/Svenum/Solaar-Flake/*.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Outputs
  # This is the default output, which is a set of attributes.
  outputs = { self, nixpkgs, solaar, nixos-hardware, home-manager, chaotic, ... }@inputs: {
    packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    packages.x86_64-linux.default = self.packages.x86_64-linux.hello;

    nixosConfigurations.nomad = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        # Currenct Laptop Flake
        nixos-hardware.nixosModules.asus-zephyrus-ga402x-nvidia

        # Logitech Solaar
        solaar.nixosModules.default
        
        # CachyOS Kernel
        chaotic.nixosModules.nyx-cache
        chaotic.nixosModules.nyx-overlay
        chaotic.nixosModules.nyx-registry
        
        # home-manager
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
        
        # Cosmic
        # nixos-cosmic.nixosModules.default
        # {
        #   nix.settings = {
        #     substituters = [ "https://cosmic.cachix.org/" ];
        #     trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
        #   };
        # }
        
        # Interactive SystemD
        {
          environment.systemPackages = [ inputs.isd.packages.x86_64-linux.default ];
        }
        
        # Mine
        ./configuration.nix
      ];
    };
  };
}
