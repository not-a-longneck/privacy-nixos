{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should manage
  home.username = "user";
  home.homeDirectory = "/home/user";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "24.05";

  # ============================================================================
  # PRIVACY: DISABLE THUMBNAILS
  # ============================================================================

  # Disable thumbnail generation for file managers
  xdg.configFile."thumbnailers/disable.thumbnailer".text = "";

  # Redirect thumbnail cache to tmpfs (will be wiped on reboot)
  home.file.".cache/.keep".text = "";
  home.file.".thumbnails/.keep".text = "";

  # ============================================================================
  # PRIVACY: SHELL CONFIGURATION
  # ============================================================================

  programs.bash = {
    enable = true;
    historyFile = "/dev/null";
    historySize = 0;
    historyFileSize = 0;
    shellOptions = [
      "histappend"
    ];
    initExtra = ''
      # Ensure no history is saved
      unset HISTFILE
      export HISTSIZE=0
      export HISTFILESIZE=0
    '';
  };

  programs.zsh = {
    enable = false;  # Set to true if you prefer zsh
    history = {
      size = 0;
      path = "/dev/null";
      save = 0;
    };
  };

  # ============================================================================
  # XDG DIRECTORIES
  # ============================================================================

  xdg.enable = true;

  # These directories are on tmpfs root, so they're wiped on reboot
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    desktop = "${config.home.homeDirectory}/Desktop";
    documents = "${config.home.homeDirectory}/Documents";
    download = "${config.home.homeDirectory}/Downloads";
    music = "${config.home.homeDirectory}/Music";
    pictures = "${config.home.homeDirectory}/Pictures";
    videos = "${config.home.homeDirectory}/Videos";
  };

  # ============================================================================
  # GIT (if you use it)
  # ============================================================================

  programs.git = {
    enable = true;
    userName = "user";
    userEmail = "user@localhost";
    extraConfig = {
      init.defaultBranch = "main";
      # Git credentials are NOT saved (ephemeral)
    };
  };

  # ============================================================================
  # HOME MANAGER
  # ============================================================================

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;
}
