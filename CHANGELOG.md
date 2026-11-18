# Changelog

All notable changes to OctetPulse will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-11-18

### Added
- **Biometric Facial Liveness & Anti-Spoofing Verification (Sprint 6)**:
  - Interactive optical viewfinder HUD simulator with facial oval reticle and pulsing scan animation.
  - Randomized multi-step action sequence challenge (`blink`, `smile`, `nod`, `turnHead`) to prevent photo/screen replay spoofing.
  - Real-time ambient lux sensor simulation with automatic low-light detection (< 20 lux threshold).
  - Supervisor Authorization PIN fallback override (`1234`) for harsh low-light optical conditions.
  - Cryptographic SHA-256 attestation generation pairing challenge ID, employee ID, action sequence, timestamp, and salt.
  - SQLite database migration (v7) adding `livenessAttestationHash`, `isBiometricallyVerified`, and `livenessLuxLevel` to the `attendance` table.
  - Verified biometric shield badge and anti-spoofing status on shift operations cockpit.
  - Comprehensive unit and widget tests covering challenge sequences, cryptographic hashing, supervisor PIN fallback, and 800x360 landscape safety.

## [1.0.0] - 2026-11-18

### Added
- Initial enterprise workforce management release:
  - Geofenced attendance tracking with polygon campus boundaries.
  - Enterprise VoIP communication suite with encrypted recording vault.
  - Shift swap peer-to-peer exchange engine.
  - Automated payroll ledger and tax jurisdiction payslip breakdown.
  - Offline-first SQLite persistence and Material 3 adaptive UI.
