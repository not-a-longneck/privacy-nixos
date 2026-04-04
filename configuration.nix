{ config, pkgs, lib, ... }:

{

imports = [
    ./hardware-configuration.nix
    ./scripts
  ];


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
  # PACKAGES & SERVICES
  # ============================================================================

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    htop
  ];

  # ============================================================================
  # DESKTOP ENVIRONMENT
  # ============================================================================

  # Enable the X11 windowing system
  # services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment
  # services.displayManager.sddm.enable = true;
  # services.desktopManager.plasma6.enable = true;

  # ============================================================================
  # MOUNTS
  # ============================================================================

    fileSystems."/mnt/tower/backups" = {
      device = "//192.168.1.53/backups";
      fsType = "cifs";
      # Force read-write and give you (uid=1000) full control
      options = [
        "guest"          # No password needed
        "uid=1000"       # Tells Linux the 'admin' user owns everything here
        "gid=100"        # The 'users' group
        "forceuid"       # <--- FORCES recursive ownership for 'admin'
        "forcegid"       # <--- FORCES recursive ownership for 'users'
        "noperm"         # CRITICAL: Tells the client to stop local permission checks
        "nobrl"          # <--- THIS IS THE MAGIC KEY
        "cache=none"     # Prevents Linux from "holding onto" the file in RAM
        "iocharset=utf8"
        "vers=3.0"       # Ensures you're using a modern SMB version
        "soft"           # Prevents the VM from freezing if Unraid goes offline
      ];
    };

  # ============================================================================
  # HARDWARE
  # ============================================================================

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    # Add extra configuration to stabilize the clock
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 1024; # Increasing this helps with choppiness
        "default.clock.min-quantum" = 512;
        "default.clock.max-quantum" = 2048;
      };
    };
  };

  # ============================================================================
  # LOCALE OPTIONS
  # ============================================================================

  time.timeZone = "Europe/Copenhagen";   # Set your time zone.
  i18n.defaultLocale = "en_DK.UTF-8";   # Select internationalisation properties.

  # Configure keymap in X11
  console.keyMap = "dk";
  services.xserver.xkb = {
    layout = "dk";
    variant = "";
  };


  # ============================================================================
  # SYSTEM VERSION
  # ============================================================================

  system.stateVersion = "24.05";
}
