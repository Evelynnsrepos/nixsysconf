{self, inputs, ...}: {

  # Link router: the default handler for web links (kitty, Discord, ...).
  # Spotify links open in the Spotify app, Steam links in Steam, the rest in Zen.
  # Zen and Spotify are Flatpaks and get launched directly, without
  # --file-forwarding: that goes through the document portal, and when its mount
  # at /run/user/$UID/doc is gone, clicked links silently do nothing.
  flake.nixosModules.links = { config, pkgs, ... }: let

    flatpak = "${config.services.flatpak.package}/bin/flatpak";

    link-router = pkgs.writeShellApplication {
      name = "link-router";
      text = ''
        url="''${1:-}"

        zen() {
          exec ${flatpak} run --branch=stable --arch=x86_64 \
            --command=launch-script.sh app.zen_browser.zen "$@"
        }

        [ -n "$url" ] || zen

        # open.spotify.com/(intl-xx/)<type>/<id>?si=...  ->  spotify:<type>:<id>
        spotify_re='^https?://open\.spotify\.com/(intl-[a-zA-Z-]+/)?(track|album|playlist|artist|episode|show|user)/([A-Za-z0-9]+)'
        if [[ "$url" =~ $spotify_re ]]; then
          exec ${flatpak} run --branch=stable --arch=x86_64 --command=spotify \
            com.spotify.Client --uri="spotify:''${BASH_REMATCH[2]}:''${BASH_REMATCH[3]}"
        fi

        steam_re='^https?://(store\.steampowered\.com|steamcommunity\.com|help\.steampowered\.com)(/|$)'
        if [[ "$url" =~ $steam_re ]]; then
          exec steam "steam://openurl/$url"
        fi

        zen "$url"
      '';
    };

  in {

    environment.systemPackages = [
      link-router
      (pkgs.makeDesktopItem {
        name = "link-router";
        desktopName = "Link Router";
        comment = "Opens Spotify/Steam links in their apps, everything else in Zen";
        exec = "link-router %u";
        noDisplay = true;
        mimeTypes = [ "x-scheme-handler/http" "x-scheme-handler/https" "text/html" ];
      })
    ];

    xdg.mime.defaultApplications = {
      "x-scheme-handler/http" = "link-router.desktop";
      "x-scheme-handler/https" = "link-router.desktop";
      "text/html" = "link-router.desktop";
      "x-scheme-handler/spotify" = "com.spotify.Client.desktop";
      "x-scheme-handler/steam" = "steam.desktop";
    };

  };

}
