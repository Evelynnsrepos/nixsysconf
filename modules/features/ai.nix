{ inputs, ... }: {

  # Everything for local AI in one place:
  #   LM Studio (models, OpenAI-compatible server on 127.0.0.1:1234, started in the app)
  #   Open WebUI   http://localhost:6967   chat UI, first visit creates the admin account
  #   n8n          http://localhost:5678   workflows + assistant, first visit creates the owner account
  #   aider        CLI coding assistant against LM Studio
  #   MCP servers  web-search and aider, served twice:
  #                mcpo      127.0.0.1:8766/<name>               OpenAPI, for Open WebUI
  #                mcp-proxy 127.0.0.1:8767/servers/<name>/mcp   MCP over HTTP, for n8n (/sse for its assistant)
  # Only reachable from this machine (the firewall stays closed).
  flake.nixosModules.ai = { pkgs, lib, ... }:
    let
      lmStudio = "http://127.0.0.1:1234/v1";

      # Playwright from nixpkgs; web-search-mcp's package.json pins the same playwright version.
      browsers = pkgs.playwright-driver.browsers;

      # mrkrsl/web-search-mcp, built by Nix. ai/web-search-mcp/ holds its package.json and lock
      # with playwright pinned to nixpkgs' playwright-driver version. When nixpkgs bumps
      # playwright-driver, bump it there too and update npmDepsHash.
      web-search-mcp = pkgs.buildNpmPackage {
        pname = "web-search-mcp";
        version = "0-unstable-eeb03f8";
        src = pkgs.fetchFromGitHub {
          owner = "mrkrsl";
          repo = "web-search-mcp";
          rev = "eeb03f88525cbf74c4019e59a3fea45a537a760b";
          sha256 = "0l226nbhd2im766mfvhc0xsv57wr75nccgqg83c2nkx4d2y1shfi";
        };
        # Smaller searches for local models with small context windows (gpt-oss-20b, 8k):
        # full-web-search fetches 3 pages by default instead of 5, and its description tells
        # the model to try the cheap snippet search first.
        postPatch = ''
          cp ${./ai/web-search-mcp/package.json} package.json
          cp ${./ai/web-search-mcp/package-lock.json} package-lock.json
          sed -i -e "s/default(5).describe('Number of results to return with full content/default(3).describe('Number of results to return with full content/" \
            -e "s/^    let limit = 5; \/\/ default/    let limit = 3; \/\/ default/" \
            -e "s/This is the most comprehensive web search tool\./Uses many tokens: try get-web-search-summaries first and use this only when the snippets are not enough./" \
            src/index.ts
          grep -q "default(3).describe('Number of results to return with full" src/index.ts
          grep -q "^    let limit = 3;" src/index.ts
          grep -q "Uses many tokens" src/index.ts
        '';
        npmDepsHash = "sha256-c+6Z4YBYVmNUw0RNE3T4Z1JwL/GsaIY9m18L0MHGd4E=";
        env.PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
        installPhase = ''
          mkdir -p $out/lib/web-search-mcp
          cp -r dist node_modules package.json $out/lib/web-search-mcp/
        '';
      };

      # disler/aider-mcp-server, pinned source; uv installs the exact versions from its uv.lock
      # into ~/.cache on first start (the Nix store copy is read-only). It writes logs/ into
      # its working directory, so the services below run in ~/.cache/aider-mcp-server.
      aider-mcp-src = pkgs.fetchFromGitHub {
        owner = "disler";
        repo = "aider-mcp-server";
        rev = "b2516fa466d0d851932da92ee6d0e66946db9efc";
        sha256 = "124zhiqzzj07jvri6p2rn1q169y9rdkf67mjmcnzcb0axgqwzbkf";
      };

      mcpConfig = pkgs.writeText "mcp-servers.json" (builtins.toJSON {
        mcpServers = {
          web-search = {
            command = "${pkgs.nodejs}/bin/node";
            args = [ "${web-search-mcp}/lib/web-search-mcp/dist/index.js" ];
            env = {
              MAX_CONTENT_LENGTH = "2000";  # characters per fetched page, about 500 tokens
              BROWSER_HEADLESS = "true";
              MAX_BROWSERS = "1";
              PLAYWRIGHT_BROWSERS_PATH = "${browsers}";
            };
          };
          aider = {
            command = "${pkgs.uv}/bin/uv";
            args = [
              "run" "--frozen" "--python" "3.12" "--project" "${aider-mcp-src}"
              "aider-mcp-server"
              "--editor-model" "openai/openai/gpt-oss-20b"
              "--current-working-dir" "/home/evilynn/My-repos/aider-sandbox"
            ];
            env = {
              UV_PROJECT_ENVIRONMENT = "/home/evilynn/.cache/aider-mcp-server/venv";
              OPENAI_API_BASE = lmStudio;
              OPENAI_API_KEY = "lm-studio";
            };
          };
        };
      });

      # git: aider-mcp-server needs it
      mcpServicePath = [ pkgs.uv pkgs.nodejs pkgs.git ];
      mcpServiceDirs = {
        CacheDirectory = "aider-mcp-server";
        WorkingDirectory = "%C/aider-mcp-server";
      };

      # older nixpkgs on purpose, see nixpkgs-pinned in flake.nix
      pinned = import inputs.nixpkgs-pinned {
        system = pkgs.stdenv.hostPlatform.system;
        config.allowUnfree = true;  # Open WebUI's license counts as unfree
      };
    in {
      # aider from pinned: on unstable its posthog dependency is marked broken (mcp-proxy below, too: needs mcp<2)
      environment.systemPackages = [ pkgs.lmstudio pinned.aider-chat-with-browser ];

      services.open-webui.enable = true;
      services.open-webui.port = 6967;
      services.open-webui.package = pinned.open-webui;

      services.n8n.enable = true;
      # MCP servers for the n8n assistant (/assistant); it only speaks SSE to them.
      services.n8n.environment.N8N_INSTANCE_AI_MCP_SERVERS =
        "websuche=http://127.0.0.1:8767/servers/web-search/sse,aider=http://127.0.0.1:8767/servers/aider/sse";

      # So Playwright tools started from a shell use the nixpkgs browsers instead of downloading.
      environment.sessionVariables.PLAYWRIGHT_BROWSERS_PATH = "${browsers}";

      # Aider: set `model` to the model id LM Studio shows, with the `openai/` prefix.
      home-manager.users.evilynn.home.file.".aider.conf.yml".text = ''
        openai-api-base: ${lmStudio}
        openai-api-key: lm-studio
        model: openai/local-model
      '';

      # mcpo is not in nixpkgs and crashes with newer mcp/fastapi, so uvx runs exact versions;
      # --exclude-newer freezes the rest of the dependency resolution to that date.
      systemd.user.services.mcpo = {
        description = "mcpo (MCP to OpenAPI proxy for Open WebUI)";
        wantedBy = [ "default.target" ];
        path = mcpServicePath;
        serviceConfig = mcpServiceDirs // {
          ExecStart = "${pkgs.uv}/bin/uvx --python 3.12 --exclude-newer 2026-10-23T00:00:00Z --with mcp==1.30.0 --with fastapi==0.115.14 mcpo==0.0.20 --host 127.0.0.1 --port 8766 --config ${mcpConfig}";
          Restart = "on-failure";
        };
      };

      systemd.user.services.mcp-proxy = {
        description = "mcp-proxy (MCP servers over HTTP for n8n)";
        wantedBy = [ "default.target" ];
        path = mcpServicePath;
        serviceConfig = mcpServiceDirs // {
          ExecStart = "${lib.getExe pinned.mcp-proxy} --host 127.0.0.1 --port 8767 --named-server-config ${mcpConfig}";
          Restart = "on-failure";
        };
      };
    };

}
