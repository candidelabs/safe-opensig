# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Flutter Version Management
This project uses Flutter version 3.32.4 managed by FVM (Flutter Version Management).
**IMPORTANT**: Always invoke Flutter/Dart via the `.fvm/` relative path (e.g., `.fvm/flutter_sdk/bin/flutter`) instead of `fvm flutter`. This avoids issues with the `fvm` wrapper.
```bash
# Install dependencies
.fvm/flutter_sdk/bin/flutter pub get

# Run the app (requires .env file with RPC endpoints)
.fvm/flutter_sdk/bin/flutter run

# Code generation (for Hive adapters and Riverpod providers)
.fvm/flutter_sdk/bin/flutter packages pub run build_runner build

# Run code analysis
.fvm/flutter_sdk/bin/flutter analyze

# Format code
.fvm/flutter_sdk/bin/dart format .

# Run tests
.fvm/flutter_sdk/bin/flutter test
```

### Code Generation
The project uses code generation for Hive adapters and Riverpod providers. When modifying models or providers, run:
```bash
.fvm/flutter_sdk/bin/flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Environment Variables
Create a `.env` file with RPC node URLs for multi-chain support. The app uses `flutter_dotenv` to load these at runtime.

## Architecture Overview

### Core Architecture
- **State Management**: Riverpod with provider notation and code generation
- **Storage**: Hive (lightweight NoSQL database) with migration system for schema versioning
- **Navigation**: GoRouter with declarative routing and deep linking support
- **UI**: Material Design with custom theming and cross-platform support
- **Simulation**: REVM-based EVM tracing with multi-node state verification

### Directory Structure
```
lib/
├── core/               # Core infrastructure
│   ├── router/        # GoRouter-based navigation
│   ├── storage/       # Hive persistence with migrations
│   └── theme/         # Material Design theming
├── features/          # Feature modules
│   ├── account_management/      # Safe account CRUD operations
│   ├── migration/               # Data migration screens
│   ├── onboarding/              # First-run user onboarding
│   └── verify_safe_transaction/ # Main verification flows
├── shared/            # Reusable components
│   ├── models/        # Domain models
│   ├── widgets/       # Reusable UI components
│   ├── services/      # Business logic (Safe Transaction Service API)
│   ├── constants/     # Network constants, safe hashes
│   └── utils/         # Platform helpers and utilities
└── main.dart          # App initialization
```

### Key Components

#### Storage System (`lib/core/storage/`)
- `accounts_box.dart`: Manages Safe account data persistence
- `misc_box.dart`: Stores app-wide settings, state, and schema version tracking
- `theme_box.dart`: Handles theme preferences
- `migrations/`: Schema migration system with `MigrationRegistry` for version upgrades

#### Models (`lib/shared/models/`)
- `SafeAccount`: Represents Safe multisig accounts with network, version, and address info
- `SafeTransaction`: Handles Safe transaction data with hash calculations and EVM operations
- `SafeAPITransaction`: Extends SafeTransaction with Safe Transaction Service API fields (confirmations, submission date)
- `NetworkModel`: Defines blockchain network configurations
- `hw_wallets/`: Hardware wallet emulation (Ledger Nano S, S Plus)
- `simulation/`: State verification and trace decoding models

#### State Providers
- `accountsProvider`: Manages Safe accounts list with CRUD operations
- Located in `lib/features/account_management/account_state_provider.dart`

### Transaction Verification Flow
The app implements a multi-step Safe transaction verification process:

1. **Input Phase** (`SafeTransactionFormScreen`): Users input transaction data via JSON or manual form
2. **Verification Phase** (`SafeTransactionVerifyScreen`): Validates transaction hashes and displays details
3. **Simulation**: EVM execution with state verification and trace decoding
4. **Hardware Wallet Verification**: Displays content as it appears on Ledger devices

### Simulation Architecture (`lib/shared/models/simulation/`)

#### State Verification (`state_verifier/`)
- **EVMStateVerifier**: Multi-node consensus verification
  - Fetches state roots from multiple RPC providers
  - Requires majority consensus (>50%) for trust minimization
  - Verifies Merkle Patricia Trie proofs via `eth_getProof`
  - Validates account and storage proofs

#### Trace Decoding (`trace_decoder.dart`)
Decodes EVM execution traces into human-readable actions:
- Token transfers and allowances (ERC-20, ERC-721, ERC-1155)
- Safe setting changes (owner add/remove, threshold, modules, guards)
- Singleton/implementation changes (dangerous transaction detection)
- Maintains trusted contract mappings for Safe versions 1.0.0-1.5.0

#### EVM Tracer (`evm_tracer.dart`)
- Bridges REVM Rust library via FFI (`revm_tracer`)
- Fetches prestate using `debug_traceCall` with prestateTracer
- Executes local REVM trace with verified state

### Hardware Wallet Emulation (`lib/shared/models/hw_wallets/`)

#### Ledger Support
- **Ledger Nano S**: Original hardware wallet emulation
- **Ledger Nano S Plus**: Extended support with NBGL font width calculations
  - Character-level pixel widths matching Open Sans Regular 11px
  - Screen config: 4 lines, 132px width, 18 chars/line
  - Generates multi-page verification content sequences

#### HWContentGenerator Base
Abstract base for hardware wallet page generation with:
- `HWScreenConfiguration`: Screen dimensions and line limits
- `HWPageContent`: Lead/trail icons with text lines
- Extensible for future wallet support (Nano X, Trezor)

### Cross-Platform Support

#### Platform Helper (`lib/shared/utils/platform_helper*.dart`)
Conditional imports for platform detection:
- `platform_helper.dart`: Abstract interface
- `platform_helper_io.dart`: iOS/Android/Windows implementation
- `platform_helper_stub.dart`: Web stub
- Provides: `isAndroid`, `isIOS`, `isWindows`, `isWeb`, `isMobile`

#### Window Manager Helper (`lib/shared/utils/window_manager_helper*.dart`)
Desktop window management:
- Fixed 360x800 dimensions for Windows/Linux to simulate mobile experience
- Centered window positioning
- Custom scroll behavior for mouse/trackpad support

### Network Support (`lib/shared/constants/network_constants.dart`)
Supports 13+ EVM chains:
- **L1s**: Ethereum, Polygon, Gnosis, BSC, Avalanche
- **L2s**: Optimism, Base, Worldchain, Unichain, Arbitrum, Celo

Each network includes:
- Multiple RPC provider fallbacks
- Chain prefix (EIP-3770 format)
- Native currency symbol
- Block explorer URLs

### Shared Widgets (`lib/shared/widgets/`)

#### Address Widget Suite
- **AddressWidget**: Displays EVM addresses with Blockies avatar, tap-to-expand, long-press copy
- **AddressDetailSheet**: Bottom sheet with full address, copy button, block explorer link
- Network-aware with chainId support for explorer links

### Code Generation Files
- `lib/hive/hive_adapters.g.dart`: Generated Hive type adapters
- `lib/hive/hive_registrar.g.dart`: Hive adapter registration

### Dependencies of Note
- `web3dart`: Ethereum blockchain interactions
- `wallet`: Cryptographic operations and key management
- `revm_tracer`: Rust-based EVM execution (FFI)
- `mobile_scanner`: QR code scanning for address input
- `wolt_modal_sheet`: Modal bottom sheets for UI interactions
- `flutter_dotenv`: Environment variable management
- `window_manager`: Desktop window control

### Safe Transaction Hash Calculation
The app implements Safe's EIP-712 transaction hash calculation, supporting both current and legacy versions (≤1.2.0) with different type hashes. Hash calculation involves domain hash, message hash, and final transaction hash generation.

### Navigation Structure
- `/onboarding` → `/accounts` → `/verify-transaction` → `/verify-transaction/verify`
- Automatic redirection based on onboarding completion state
- State passed between routes using GoRouter's `extra` parameter

### Linting and Code Quality
- Uses `package:flutter_lints/flutter.yaml` for standard Flutter linting rules
- Custom lint rules via `custom_lint` and `riverpod_lint`
- Analysis options configured in `analysis_options.yaml`

### Build Targets
- **Android/iOS**: Standard Flutter mobile builds
- **Web**: Custom scroll behavior, platform stubs
- **Windows/Linux**: Fixed window dimensions, native plugins via CMake
