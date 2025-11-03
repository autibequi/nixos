{ pkgs, ... }:

{
  # Suporte ao protocolo HID++ da Logitech (MX Master 3, etc)
  # Necessário para high-resolution scrolling e outras features avançadas
  services.ratbagd.enable = true;

  # Pacotes para configuração do mouse Logitech
  environment.systemPackages = with pkgs; [
    piper # GUI para configurar o mouse via ratbagd
    libratbag # Biblioteca de suporte (já incluída pelo ratbagd)
  ];

  # Configurações do libinput para scroll suave
  services.libinput = {
    enable = true;
    mouse = {
      # Habilita scroll de alta resolução (smooth scrolling)
      scrollMethod = "button";
      # Aceleração natural do mouse (ajuste conforme preferência)
      accelSpeed = "0";
      # Scroll natural (inverter direção, como no macOS/Windows - desabilite se não gostar)
      naturalScrolling = false;
    };
  };

  # Módulos do kernel para suporte Logitech HID++
  boot.kernelModules = [
    "hid_logitech_dj"
    "hid_logitech_hidpp"
  ];

  # Parâmetros do kernel para otimizar o HID++
  boot.kernelParams = [
    "usbhid.mousepoll=1" # Poll rate de 1ms (1000Hz)
  ];

  # Regras udev para garantir acesso ao dispositivo
  services.udev.extraRules = ''
    # Logitech MX Master 3 - Permite acesso ao ratbagd
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="046d", MODE="0660", TAG+="uaccess"
  '';
}

