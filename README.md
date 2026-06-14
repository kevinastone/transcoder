# Transcoder

A minimal, reproducible container image for `ffmpeg` built with Nix, designed specifically for use in automated workflows like Argo Workflows.

## Overview

This repository uses Nix flakes to build a lightweight container image containing `ffmpeg` and some custom utility scripts. The primary goal is to provide a reliable, multi-architecture image (AMD64 & ARM64) that integrates seamlessly into cloud-native transcoding pipelines.

## Features

- **Nix-built Container**: Deterministic, minimal OCI images built using `dockerTools`.
- **Multi-Architecture**: Automatically built and published for `linux/amd64` and `linux/arm64` via GitHub Actions.
- **Argo Workflows Integration**: Includes `argo-ffmpeg-progress`, a helper script to translate `ffmpeg`'s `-progress` stream into an Argo-compatible progress format (`<percent>/100`).

## Included Tools

### `argo-ffmpeg-progress`

Reads ffmpeg's progress stream from `stdin` and writes the completion percentage to a specified progress file, making it easy to track transcoding jobs in Argo Workflows UI.

**Usage:**
```bash
ffmpeg [...] -progress >(argo-ffmpeg-progress <total_duration_in_seconds> <progress_file_path>) [...]
```

## Development

The project is fully integrated with Nix. To format the codebase, run:

```bash
nix fmt
```

To build the OCI container tarball locally:

```bash
nix build .#image
```

## CI/CD

This repository includes a GitHub Actions workflow (`ci.yaml`) that:
1. Runs Nix checks and formatting validation.
2. Builds AMD64 and ARM64 images.
3. Tags the images dynamically based on the upstream Nixpkgs `ffmpeg` version.
4. Pushes the multi-architecture manifest to GitHub Container Registry (GHCR).
