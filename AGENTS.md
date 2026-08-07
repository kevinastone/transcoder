# Developer & AI Agent Guidelines (AGENTS.md)

Welcome! If you are an AI coding assistant (like Antigravity) or a developer onboarding to this repository, please read these instructions to understand the code architecture, tooling, and coding standards of Transcoder.

---

## 🛠️ Tooling & Commands

### 1. Code Formatting
Transcoder is fully Nix-integrated. To format the entire codebase, always run:
```bash
nix fmt
```

### 2. Building & Validating
To verify the flake config, checks, and formatting:
```bash
nix flake check
```

To build the OCI container image locally (which produces the symlink `./result` pointing to the built tarball):
```bash
nix build .#ffmpeg
# or simply:
nix build
```

### 3. Debugging & Inspecting
Enter the Nix devShell to load development tools like `dive`, `skopeo`, and custom helper scripts:
```bash
nix develop
```

Once in the devShell, you can inspect the OCI container layers using the `dive-archive` helper:
```bash
dive-archive ./result
```

### 4. Git Commits
Do **not** commit any code changes using `git commit` without explicitly asking and obtaining confirmation from the user first.

---

## 📁 Repository Structure

- `flake.nix`: Nix package definitions, OCI image configuration, formatting rules, and devShell.
- `nix/scripts/`:
  - `argo-ffmpeg-progress.sh`: The progress tracker packaged directly into the OCI container.
  - `push-multiarch.sh`: CI/CD helper script to assemble and push multi-architecture OCI manifests.
  - `default.nix`: Nix packaging expressions for the shell scripts.
- `.github/workflows/`:
  - `ci.yaml`: CI/CD pipeline that validates the flake, builds images for amd64/arm64, and publishes them to GHCR.
- `AGENTS.md`: Onboarding guidelines for developers and AI agents (this file).
