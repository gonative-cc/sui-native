<!-- markdownlint-disable MD013 -->
<!-- markdownlint-disable MD024 -->

<!--
Changelogs are for humans, not machines.
There should be an entry for every single version.
The same types of changes should be grouped.
The latest version comes first.
The release date of each version is displayed.

Usage:

Change log entries are to be added to the Unreleased section and in one of the following subsections: Features, Breaking Changes, Bug Fixes. Example entry:

* [#<PR-number>](https://github.com/gonative-cc/relayer/pull/<PR-number>) <description>
-->

# CHANGELOG

## Unreleased

### Features

- Move bitcoin_parser and bitcoin_spv packages to sui-native

### Breaking Changes

- Refactored the `nBTC` `verify_payment` function logic to be script based. It no longer parses transaction outputs to extract a Public Key Hash. Instead, it performs comparison of the full `scriptPubKey` against the `scriptPubKey` from the provided transaction.

- Renamed: `bitcoin_script_pubkey` to `bitcoin_spend_key` in the nBTC package.

### Bug Fixes

## v0.0.1 (YYYY-MM-DD)

### Features

### Breaking Changes

### Bug Fixes
