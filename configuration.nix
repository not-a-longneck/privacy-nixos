{ config, pkgs, lib, ... }:

{
  # ============================================================================
  # BOOT & FILESYSTEM
  # ============================================================================

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Root on tmpfs - wiped every boot
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };

  # Boot partition (EFI)
  fileSystems."/boot" = {
    device = "/dev/disk/by-label/BOOT";
    fsType = "vfat";
  };

  # Persistent storage for nix store and config
  fileSystems."/nix" = {
    device = "/dev/disk/by-label/NIX";
    fsType = "ext4";
    neededForBoot = true;
  };

  fileSystems."/etc/nixos" = {
    device = "/nix/persist/etc/nixos";
    options = [ "bind" ];
    depends = [ "/nix" ];
  };

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
    hashedPassword = "$6$rounds=100000$CHANGEME";  # Generate with: mkpasswd -m sha-512
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
  # SYSTEM VERSION
  # ============================================================================

  system.stateVersion = "24.05";
}
