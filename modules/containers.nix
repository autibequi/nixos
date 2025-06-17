{
  pkgs,
  ...
}:

{
  # Enable containers with podman
  virtualisation = {
    containers = {
      enable = true;
      registries.search = [
        "docker.io"
        "quay.io"
        "registry.fedoraproject.org"
      ];
      policy = {
        default = [
          {
            type = "insecureAcceptAnything";
          }
        ];
      };
    };

    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Container Tools
  environment.systemPackages = with pkgs; [
    dive # look into docker image layers
    podman-tui # status of containers in the terminal
    podman-compose # start group of containers for dev
  ];

  # TODO: Manually add docker.io to the registries.conf
  # the setup in `virtualisation.containers.registries.search` does not work for some reasong
  home-manager.users.pedrinho = {
    home.file.".config/containers/registries.conf".text = ''
      [registries.search]
      registries = ['docker.io']
    '';

    home.file.".config/containers/policy.json".text = ''
      {
        "default": [
          {
            "type": "insecureAcceptAnything"
          }
        ]
      }
    '';
  };
}
