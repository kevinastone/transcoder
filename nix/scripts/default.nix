{ pkgs, ... }:
{
  argo-ffmpeg-progress = pkgs.writeShellApplication {
    name = "argo-ffmpeg-progress";
    runtimeInputs = with pkgs; [
      gawk
    ];
    text = builtins.readFile ./argo-ffmpeg-progress.sh;
  };

  push-multiarch = pkgs.writeShellApplication {
    name = "push-multiarch";
    runtimeInputs = with pkgs; [
      regctl
      gzip
      coreutils
    ];
    text = builtins.readFile ./push-multiarch.sh;
  };
}
