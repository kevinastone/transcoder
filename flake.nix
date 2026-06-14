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

        push-multiarch = pkgs.writeShellApplication {
          name = "push-multiarch";
          runtimeInputs = with pkgs; [
            regctl
            gzip
            coreutils
          ];
          text = ''
            if [ "$#" -lt 3 ]; then
              echo "Usage: push-multiarch <registry-repo> <amd64-image-tar> <arm64-image-tar>"
              exit 1
            fi

            REPO=$(echo "$1" | tr '[:upper:]' '[:lower:]')
            AMD64_IMAGE="$2"
            ARM64_IMAGE="$3"

            if [ -z "''${TAGS:-}" ]; then
              echo "Error: TAGS environment variable is not set"
              exit 1
            fi


            # Import images into local OCI layout directories directly from Nix build outputs
            regctl image import ocidir://./local-oci-amd64 "$AMD64_IMAGE"
            regctl image import ocidir://./local-oci-arm64 "$ARM64_IMAGE"

            # Get the digests of the imported OCI layouts
            AMD64_DIGEST=$(regctl image digest ocidir://./local-oci-amd64)
            ARM64_DIGEST=$(regctl image digest ocidir://./local-oci-arm64)

            # Push single-architecture layers and manifests by digest
            echo "Pushing AMD64 digest: $AMD64_DIGEST to $REPO..."
            regctl image copy ocidir://./local-oci-amd64 "$REPO@$AMD64_DIGEST"

            echo "Pushing ARM64 digest: $ARM64_DIGEST to $REPO..."
            regctl image copy ocidir://./local-oci-arm64 "$REPO@$ARM64_DIGEST"

            # Create and push the multi-architecture manifest index for each tag
            # Since TAGS is multiline, we read it line by line
            echo "$TAGS" | while read -r tag || [ -n "$tag" ]; do
              if [ -n "$tag" ]; then
                echo "Creating and pushing multi-arch index for $tag..."
                regctl index create "$tag" \
                  --ref "$REPO@$AMD64_DIGEST" \
                  --platform linux/amd64 \
                  --ref "$REPO@$ARM64_DIGEST" \
                  --platform linux/arm64
              fi
            done

            # Cleanup local OCI layouts
            rm -rf ./local-oci-amd64 ./local-oci-arm64
          '';
        };

        ffmpeg = pkgs.ffmpeg-headless;

        scripts = map (
          name:
          pkgs.writeShellApplication {
            inherit name;
            text = builtins.readFile (./scripts + "/${name}");
            # SC2155 warns on export VAR=$(cmd) which we use
            excludeShellChecks = [ "SC2155" ];
          }
        ) (builtins.attrNames (builtins.readDir ./scripts));
      in
      {
        packages = rec {
          image =
            with pkgs;
            dockerTools.buildImage rec {
              name = "transcoder";
              tag = ffmpeg.version;
              copyToRoot =
                with dockerTools;
                [
                  usrBinEnv
                  binSh
                  fakeNss
                  bash
                  coreutils
                  ffmpeg
                ]
                ++ scripts;
              config.Entrypoint = [ (lib.getExe ffmpeg) ];
              config.Labels = {
                "org.opencontainers.image.title" = name;
              };
            };

          default = image;

          inherit push-multiarch;
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
            ];
          };
      }
    );
}
