fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### bump_major

```sh
[bundle exec] fastlane bump_major
```



### bump_minor

```sh
[bundle exec] fastlane bump_minor
```



### bump_patch

```sh
[bundle exec] fastlane bump_patch
```



### bump_version

```sh
[bundle exec] fastlane bump_version
```



----


## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Push a new beta build to TestFlight

### ios certs

```sh
[bundle exec] fastlane ios certs
```

Refresh certificates in the match repo

### ios nuke_certs

```sh
[bundle exec] fastlane ios nuke_certs
```

Clean App Store Connect of certificates

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
