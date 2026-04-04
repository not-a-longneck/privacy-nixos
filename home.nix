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
  # INSTALL HOME MANAGER
  # ============================================================================

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;


  # ============================================================================
  # INSTALL APPS
  # ============================================================================

  home.packages = with pkgs; [
      tor-browser
      vlc
      spice-vdagent # for vm features
      cifs-utils # for mounting network drives
      veracrypt
      kdePackages.kate
      pyload-ng
    ];

  # Flatpaks
  services.flatpak = {
    enable = true;
    packages = [
      "org.jdownloader.JDownloader"
    ];
  };
  # ============================================================================
  # APP SETTINGS
  # ============================================================================

  # JDownloader Flatpak Permissions
  services.flatpak.overrides."org.jdownloader.JDownloader".Context = {
      filesystems = [
        "xdg-download:rw"
        "/tmp:rw"
        "/mnt:rw"
      ];
      sockets = [ "x11" "wayland" "fallback-x11" ];
      shared = [ "network" "ipc" ];
      bus-talk = [ "org.freedesktop.NetworkManager" ];
  };

  # VLC Config
  home.file.".config/vlc/vlcrc" = {
    text = ''
      [core]
      metadata-network-access=0
      show-hiddenfiles=1
      playlist-tree=0
      recursive=expand
      random=1
      [qt]
      qt-privacy-ask=0
      qt-notification=0
      qt-video-autoresize=0
  '';
  force = true;
  };


  # Tor browser
  home.file.".tor-project/TorBrowser/Data/Browser/profile.default/user.js" = {
    text = ''
      user_pref("javascript.enabled", false);
      user_pref("extensions.torlauncher.prompt_at_startup", false);
      user_pref("network.bootstrapped", true);
      user_pref("intl.accept_languages", "en-US, en");
      user_pref("intl.locale.requested", "en-US");
      user_pref("browser.toolbars.bookmarks.visibility", "never");
    '';
  };


  # ============================================================================
  # SET DEFAULT APPS
  # ============================================================================

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "video/mp4" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "video/quicktime" = [ "vlc.desktop" ];
      "video/x-msvideo" = [ "vlc.desktop" ]; # AVI
      "video/mpeg" = [ "vlc.desktop" ];
      "video/ogg" = [ "vlc.desktop" ];
      "video/x-flv" = [ "vlc.desktop" ];       # This covers Flash video
      "video/3gpp" = [ "vlc.desktop" ];        # This covers old phone videos
    };
  };


}
