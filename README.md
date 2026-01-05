# Safe OpenSig

The Verifiable Truth for Safe Treasury Execution.

## Table of Contents
- [About](#about)
- [Tech Stack](#tech-stack)
  - [Flutter Version](#flutter-version)
  - [State Management](#state-management)
  - [Storage](#storage)
  - [Navigation](#navigation)
- [Folder Structure](#folder-structure)
- [Getting Started](#getting-started)
  - [Installation](#installation)
- [Contributing](#contributing)
  - [Code Style](#code-style)
  - [Branching Strategy](#branching-strategy)

## About

Safe OpenSig is a mobile app designed for enterprise Safe signers. It eliminates the "Blind Signing" trap by reconstructing the truth of a transaction locally before it reaches a hardware signing device.

By decoupling verification from the execution interface, Safe OpenSig provides a secure, isolated environment to audit transaction logic, simulate state changes, and verify cryptographic integrity.

### The Objective

Most signing flows rely on centralized APIs and "black box" logic. Safe OpenSig replaces trust with absolute certainty.

1. Mitigate Blind Signing: Eliminate the risk of browser-based phishing, UI-injection attacks, and malicious payloads.
2. Data Sovereignty: Transaction intent remains on-device. The architecture is local-first with zero telemetry and no third-party tracking.
3. Deterministic Results: Shift from interface reliance to state verification.

### Core Architecture

Safe OpenSig operates on a three-pillar verification model:

1. Local REVM Simulation: The app runs a private instance of Rust Ethereum Virtual Machin directly on the device to decode transaction logic and preview balance or permission changes.

2. Cryptographic Integrity: Blockchain state is verified using Merkle Patricia Trie proofs (eth_getProof) fetched from independent nodes, ensuring the data is cryptographically sound.

3. Hardware Emulation: The app provides a 1:1 digital mirror of Ledger Nano S, X, and Pro screens. This allows for the verification of physical prompts and hex-decoding character-for-character prior to device commitment.

## Tech Stack

### Flutter Version

This project uses Flutter version `3.32.4` managed by FVM (Flutter Version Management). FVM ensures that all developers are using the same Flutter version, preventing compatibility issues.

To install and use FVM please refer to their [docs](https://fvm.app/documentation/getting-started)

### State Management

We use [Riverpod](https://pub.dev/packages/flutter_riverpod) for state management
Riverpod provides a robust and scalable way to manage state with compile-time safety and easy testing.

### Storage

[Hive](https://pub.dev/packages/hive_ce_flutter) is used for local storage
Hive is a lightweight and fast key-value database written in Dart, perfect for storing user preferences and account data locally.

### Navigation

[GoRouter](https://pub.dev/packages/go_router) handles navigation:
GoRouter provides a declarative approach to routing and navigation with deep linking support.

## Folder Structure
```
lib/
├── core/              
│   ├── router/        # Application routing
│   ├── storage/       # Storage related classes
│   └── theme/         # App themes and styling
├── features/          
│   ├── account_management/
│   └── onboarding/
├── hive/              # Hive related models and adapters
├── shared/            # Shared utilities and widgets
└── main.dart          
```

## Getting Started

### Installation
1. Install dependencies:
   ```bash
   fvm flutter pub get
   ```

2. Run the app:
   ```bash
   fvm flutter run
   ```

## Contributing

We welcome contributions to the Safe Verify App! Please follow these guidelines when contributing.

### Code Style

- Follow the official [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `dart format` to format your code before committing
- Run `flutter analyze` to check for any analysis issues

### Branching Strategy

- `main` - Production-ready code
- `develop` - Development branch, all pull requests should be made to this branch
- `feature/*` - Feature branches, branched from `develop`
- `fix/*`
- `refactor/*`
- `hotfix/*` - Hotfix branches for critical production issues