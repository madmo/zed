{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, flake-utils, nixpkgs, rust-overlay }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = (import nixpkgs) {
          overlays = [ (import rust-overlay) ];
          inherit system;
        };
      in {
        defaultPackage = self.packages.${system}.zed;
        packages.zed = pkgs.rustPlatform.buildRustPackage rec {
          pname = "zed";
          version = "main";

          src = pkgs.lib.cleanSource ./.;

          cargoLock = {
            lockFile = ./Cargo.lock;
            outputHashes = {
              "alacritty_terminal-0.24.1-dev" = "sha256-aVB1CNOLjNh6AtvdbomODNrk00Md8yz8QzldzvDo1LI=";
              "async-pipe-0.1.3" = "sha256-g120X88HGT8P6GNCrzpS5SutALx5H+45Sf4iSSxzctE=";
              "blade-graphics-0.4.0" = "sha256-khJke3tIO8V7tT3MBk9vQhBKTiJEWTY6Qr4vzeuKnOk=";
              "cosmic-text-0.11.2" = "sha256-TLPDnqixuW+aPAhiBhSvuZIa69vgV3xLcw32OlkdCcM=";
              "font-kit-0.11.0" = "sha256-+4zMzjFyMS60HfLMEXGfXqKn6P+pOngLA45udV09DM8=";
              "lsp-types-0.95.1" = "sha256-N4MKoU9j1p/Xeowki/+XiNQPwIcTm9DgmfM/Eieq4js=";
              "nvim-rs-0.6.0-pre" = "sha256-bdWWuCsBv01mnPA5e5zRpq48BgOqaqIcAu+b7y1NnM8=";
              "pathfinder_simd-0.5.3" = "sha256-bakBcAQZJdHQPXybe0zoMzE49aOHENQY7/ZWZUMt+pM=";
              "tree-sitter-0.20.100" = "sha256-xZDWAjNIhWC2n39H7jJdKDgyE/J6+MAVSa8dHtZ6CLE=";
              "tree-sitter-go-0.20.0" = "sha256-/mE21JSa3LWEiOgYPJcq0FYzTbBuNwp9JdZTZqmDIUU=";
              "tree-sitter-gowork-0.0.1" = "sha256-lM4L4Ap/c8uCr4xUw9+l/vaGb3FxxnuZI0+xKYFDPVg=";
              "tree-sitter-heex-0.0.1" = "sha256-6LREyZhdTDt3YHVRPDyqCaDXqcsPlHOoMFDb2B3+3xM=";
              "tree-sitter-jsdoc-0.20.0" = "sha256-fKscFhgZ/BQnYnE5EwurFZgiE//O0WagRIHVtDyes/Y=";
              "tree-sitter-markdown-0.0.1" = "sha256-F8VVd7yYa4nCrj/HEC13BTC7lkV3XSb2Z3BNi/VfSbs=";
              "tree-sitter-proto-0.0.2" = "sha256-W0diP2ByAXYrc7Mu/sbqST6lgVIyHeSBmH7/y/X3NhU=";
              "xim-0.4.0" = "sha256-vxu3tjkzGeoRUj7vyP0vDGI7fweX8Drgy9hwOUOEQIA=";
            };
          };

          nativeBuildInputs = with pkgs;
            [
              copyDesktopItems
              curl
              mold-wrapped
              perl
              pkg-config
              protobuf
              rustPlatform.bindgenHook
            ] ++ lib.optionals stdenv.isDarwin [ xcbuild.xcrun ];

          buildInputs = with pkgs;
            [ curl fontconfig freetype libgit2 openssl sqlite zlib zstd ]
            ++ lib.optionals stdenv.isLinux [
              alsa-lib
              libxkbcommon
              wayland
              xorg.libxcb
            ] ++ lib.optionals stdenv.isDarwin
            (with darwin.apple_sdk.frameworks; [
              AppKit
              CoreAudio
              CoreFoundation
              CoreGraphics
              CoreMedia
              CoreServices
              CoreText
              Foundation
              IOKit
              Metal
              Security
              SystemConfiguration
              VideoToolbox
            ]);

          buildFeatures = [ "gpui/runtime_shaders" ];

          env = {
            ZSTD_SYS_USE_PKG_CONFIG = true;
            FONTCONFIG_FILE = pkgs.makeFontsConf {
              fontDirectories = [
                "${src}/assets/fonts/zed-mono"
                "${src}/assets/fonts/zed-sans"
              ];
            };
          };

          postFixup = pkgs.lib.optionalString pkgs.stdenv.isLinux ''
            patchelf --add-rpath ${pkgs.vulkan-loader}/lib $out/bin/*
            patchelf --add-rpath ${pkgs.wayland}/lib $out/bin/*
          '';

          doCheck = false;

          meta = with pkgs.lib; {
            description =
              "High-performance, multiplayer code editor from the creators of Atom and Tree-sitter";
            homepage = "https://zed.dev";
            changelog =
              "https://github.com/zed-industries/zed/releases/tag/v${version}";
            license = licenses.gpl3Only;
            maintainers = with maintainers; [ GaetanLepage niklaskorz ];
            mainProgram = "zed";
            platforms = platforms.all;
            # Currently broken on darwin: https://github.com/NixOS/nixpkgs/pull/303233#issuecomment-2048650618
            broken = pkgs.stdenv.isDarwin;
          };
        };

        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.packages.${system};
        };
      });
}
