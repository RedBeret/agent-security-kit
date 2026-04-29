# Changelog

All notable changes to this project will be documented here. This project follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and uses [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-04-25

### Added
- Initial public release. 9-phase maintenance lifecycle (health check, secrets, system updates, Ollama refresh, agent updates, security scan, cleanup, agent start, AV scan). Heavy phases gated by 7-day stamp file. Includes launchd/systemd templates.
