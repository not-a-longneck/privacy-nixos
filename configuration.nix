{ config, pkgs, lib, ... }:

imports = [
    ./hardware-configuration.nix
    ./scripts
  ];

{
  # ============================================================================
  # BOOT
  # ============================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ============================================================================
  # PRIVACY: DISABLE ALL LOGGING
  # ============================================================================

  # No systemd journal
  services.journald.extraConfig = ''
    Storage=none
    ForwardToSyslog=no
    ForwardToKMsg=no
    ForwardToConsole=no
    ForwardToWall=no
  '';

  # No audit
  security.audit.enable = false;
  security.auditd.enable = false;

  # Clear any residual logs
  systemd.services.clear-log-dirs = {
    description = "Clear log directories";
    wantedBy = [ "multi-user.target" ];
    before = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/rm -rf /var/log";
    };
  };

  # ============================================================================
  # PRIVACY: NO CRASH DUMPS OR CORE FILES
  # ============================================================================

  systemd.coredump.enable = false;
  systemd.coredump.extraConfig = ''
    Storage=none
    ProcessSizeMax=0
  '';

  # Disable crash dumps at kernel level
  boot.kernel.sysctl = {
    "kernel.core_pattern" = "|/bin/false";
  };

  # ============================================================================
  # PRIVACY: SHELL HISTORY DISABLED
  # ============================================================================

  environment.variables = {
    HISTFILE = "/dev/null";
    HISTSIZE = "0";
    HISTFILESIZE = "0";
  };

  programs.bash.shellInit = ''
    unset HISTFILE
    export HISTSIZE=0
  '';

  # ============================================================================
  # SYSTEM SETTINGS
  # ============================================================================

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # No swap (everything in RAM)
  swapDevices = [ ];

  # Clean /tmp on boot (redundant with tmpfs but explicit)
  boot.tmp.cleanOnBoot = true;

  # Networking
  networking.hostName = "privacy-vm";
  networking.networkmanager.enable = true;

  # VM guest tools
  services.qemuGuest.enable = true;
  services.spice-vdagentd.enable = true;

  # Time zone
  time.timeZone = "UTC";

  # Locale
  i18n.defaultLocale = "en_US.UTF-8";

  # ============================================================================
  # USER CONFIGURATION
  # ============================================================================

  users.mutableUsers = false;
  
  users.users.user = {
    isNormalUser = true;
    hashedPassword = "$6$CHANGEME";  # Will be replaced during install
    extraGroups = [ "wheel" "networkmanager" ];
    home = "/home/user";
  };

  # Enable sudo
  security.sudo.wheelNeedsPassword = true;

  # ============================================================================
  # PACKAGES
  # ============================================================================

  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
  ];

  # ============================================================================
  # DESKTOP ENVIRONMENT
  # ============================================================================

  # Enable the X11 windowing system
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;


  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================

  system.stateVersion = "24.05";
}
