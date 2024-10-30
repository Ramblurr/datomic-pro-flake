# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [UNRELEASED]

## v0.2.0 (2024-10-30)

### Breaking

- `transactor` bin renamed to `datomic-transactor`
- `console` bin renamed to `datomic-console`

### Added

- oci image: Added Docker container image with lots of customizable features
   - Includes sqlite, postgresql, and mysql JDBC drivers by default
   - Ability to customize the CLASSPATH and LD_LIBRARY_PATH
   - `unstable` container image tag that follows the `main` branch
- nix pkg: Added ability to override the build and add extra native libs or java libs
- nix pkg: Exposed more packages: `datomic-shell`, `datomic-run`, `datomic-repl`, `datomic-peer-server`

### Changed

- nix pkg: Updated datomic-pro to version 1.0.7260
- nix pkg: Switched to Nix's JDK 21 headless package (now that it is sufficiently headless

### Fixed

- This changelog formatting

## v0.1.0 (2024-06-12)


### Added

- Created this flake with datomic-pro version 1.0.7075
