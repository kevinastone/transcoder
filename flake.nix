{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      treefmt-nix,
      ...
    }:
    utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        treefmtStack = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          # Nix formatters
          programs.nixfmt.enable = true;
          programs.statix.enable = true;
          programs.deadnix.enable = true;
          settings.formatter = {
            deadnix.priority = 1;
            statix.priority = 2;
            nixfmt.priority = 3;
          };
        };

        ffmpegPkg = pkgs.ffmpeg-headless;

        scripts = pkgs.callPackage ./nix/scripts { };
      in
      {
        packages = rec {
          ffmpeg =
            with pkgs;
            dockerTools.buildImage rec {
              name = "transcoder";
              tag = ffmpegPkg.version;
              copyToRoot = with dockerTools; [
                usrBinEnv
                binSh
                fakeNss
                bash
                coreutils
                ffmpegPkg
                jq
                scripts.argo-ffmpeg-progress
              ];
              config.Entrypoint = [ (lib.getExe ffmpegPkg) ];
              config.Labels = {
                "org.opencontainers.image.title" = name;
              };
            };

          default = ffmpeg;

          inherit (scripts) push-multiarch;
        };

        checks = {
          formatting = treefmtStack.config.build.check self;
        };

        formatter = treefmtStack.config.build.wrapper;
        devShells.default =
          with pkgs;
          mkShell {
            nativeBuildInputs = [ treefmtStack.config.build.wrapper ];
            packages = [
              dive
              skopeo
              scripts.dive-archive
            ];
          };
      }
    );
}
