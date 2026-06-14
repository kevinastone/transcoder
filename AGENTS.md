# Developer & AI Agent Guidelines (AGENTS.md)

Welcome! If you are an AI coding assistant (like Antigravity) or a developer onboarding to this repository, please read these instructions to understand the code architecture, tooling, and coding standards of Lynceus.

---

## 🛠️ Tooling & Commands

### 1. Code Formatting
Transcoder is fully Nix-integrated. To format the entire codebase, always run the following command:
```bash
nix fmt
```

### 2. Building & Testing
To verify code correctness:
- Run all checks: `cargo check`
- Run the test suite: `cargo test`
- Build the binary in development: `cargo build`
- Build the binary in release: `cargo build --release`

### 3. Container Images (Nix)
This project builds highly-reproducible, minimal Docker/OCI images using Nix:
- Build the OCI container tarball: `nix build .#image`
- Push the build artifact via Skopeo (integrated into Nix):
  ```bash
  nix run .#skopeo -- --insecure-policy copy --all docker-archive:./result docker://<destination>
  ```

### 4. Git Commits
Do **not** commit any code changes using `git commit` without explicitly asking and obtaining confirmation from the user first.

---

## 📁 Repository Structure

- `flake.nix`: Nix package definitions, OCI image configuration, formatting, and devShell.
- `.github/workflows/`:
  - `ci.yaml`: CD pipeline building OCI images with Nix and delivering to GHCR upon test success.
