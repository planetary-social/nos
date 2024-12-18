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

### ios dev

```sh
[bundle exec] fastlane ios dev
```

Push a new Nos Dev build to TestFlight

### ios staging

```sh
[bundle exec] fastlane ios staging
```

Push a new Nos Staging build to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Push a new Nos Release build to TestFlight

### ios stamp_release

```sh
[bundle exec] fastlane ios stamp_release
```

Mark a deployed commit as having been deployed to our public beta testers

### ios recreate_certs

```sh
[bundle exec] fastlane ios recreate_certs
```

Revoke and delete old certificates in the match repo and request new ones

### ios nuke_certs

```sh
[bundle exec] fastlane ios nuke_certs
```

Clean App Store Connect of certificates

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
