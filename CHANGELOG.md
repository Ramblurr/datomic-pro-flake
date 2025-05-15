# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [UNRELEASED]

This release brings versioned packages! We recommend you pin your deployments to specific versions and upgrade intentionally  .

### Changed

Package versions:

`pkgs.datomic-pro` will always be the latest release, but the following specific versions are also available:

-  `pkgs.datomic-pro_1_0_7364` (latest)
-  `pkgs.datomic-pro_1_0_7277`

And for peer:

-  `pkgs.datomic-pro-peer_1_0_7364` (latest)
-  `pkgs.datomic-pro-peer_1_0_7277`

## v0.5.0 (2025-05-15)

This release brings a Datomic version bump to [version 1.0.7364](https://docs.datomic.com/changes/pro.html#1.0.7364).

Also notably the container image size is now 433M, down from over 750M, thanks to Datomic's efforts to slim down the release jar!

### Changed

- nix pkg: Updated `datomic-pro` and `datomic-pro-peer` to [version 1.0.7364](https://docs.datomic.com/changes/pro.html#1.0.7364)
- docs: Improved SQLite example with rails 8 inspired tuning

## v0.4.0 (2025-03-14)

### Changed

- nix pkg: Updated `datomic-pro` and `datomic-pro-peer` to version 1.0.7277

## v0.3.0 (2024-11-01)

Nothing changed in 0.3.0, I just am struggling with [flakehub's](https://flakehub.com/flake/ramblurr/datomic-pro?view=releases) release process.

## v0.2.0 (2024-11-01)

### Breaking

- nix pkg: `transactor` bin renamed to `datomic-transactor`
- nix pkg: `console` bin renamed to `datomic-console`
- nixos module: removed the default settings that leaned towards dev/h2 storage by default

### Added

- oci image: Added Docker container image with lots of customizable features
   - Includes sqlite, postgresql, and mysql JDBC drivers by default
   - Ability to customize the CLASSPATH and LD_LIBRARY_PATH
   - `unstable` container image tag that follows the `main` branch
- nix pkg: Added ability to override the build and add extra native libs or java libs
- nix pkg: Exposed more packages: `datomic-shell`, `datomic-run`, `datomic-repl`, `datomic-peer-server`
- nixos module: You can now configure: logging, extra classpath entries, and extra java options.
- nix pkg: Added datomic-pro-peer package which is the datomic peer library with all of its dependencies
- nix pkg: Added option to build slimmed down JRE for datomic-pro

### Changed

- nix pkg: Updated datomic-pro to version 1.0.7260
- nix pkg: Switched to Nix's JDK 21 headless package (which is supported by Datomic)
- oci image: Use the slimmed down JRE and a custom babashka build to reduce size of the image

### Fixed

- This changelog formatting

## v0.1.0 (2024-06-12)


### Added

- Created this flake with datomic-pro version 1.0.7075
