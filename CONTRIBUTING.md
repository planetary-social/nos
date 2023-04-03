# Contributing

Nos is an open-source project, as such, we openly welcome contributions of any sort: code improvement, bug fixes, translations, new features, bug reports, etc.

We encourage you to read this guide first or contact any of us. We have a public [Discord server](https://discord.gg/aNgVthyHac) which is also bridged to this [Matrix room](https://matrix.to/#/#planetary:matrix.org). Feel free to also ask a question by opening a [Github issue](https://github.com/planetary-social/nos/issues).

## Translations

If you want to contribute by translating the app to another language, you can head in to our [project in Crowdin](https://crowdin.com/project/nossocial) and start translating there. It will automatically generate a Pull Request with your translations that we will happily take care of merging. If we haven't set up the langauge you would like to translate let us know by [opening an issue](https://github.com/planetary-social/nos/issues) or emailing support@planetary.social. Please do not edit the Generated.strings files in this repository directly.

## Building

Nos iOS is built using Xcode. To build it yourself you can follow the steps below. These steps assume you have installed Xcode, Homebrew, and have some familiarity with the Terminal app. You can see what version of Xcode our team is using in the .xcode-version file in this repository.

From the Terminal: 

1. `brew install swiftlint`

2. `git clone git@github.com:planetary-social/nos.git`

3. `cd planetary-ios`

4. Open the Nos project in Xcode:

```sh
open Nos.xcodeproj
```

In Xcode:

5. In the menu bar choose Product -> Build

## Running

The app is fully functional in the iOS simulator. To run the app in the simulator, select a simulator using the Product -> Destination menu in Xcode, and then click Product -> Run.  If you want to run it on a device you will need to change the Bundle Identifier and Code Signing settings to use your personal team.

## Contributing Code

If you'd like to contribute code to the main branch of Nos, it's best to check with us first. The best way to do this is to open or comment on an [issue](https://github.com/planetary-social/nos/issues) describing your proposed change. Feel free to @-mention some of the maintainers if we don't respond in a reasonable amount of time.

We use SwiftLint to enforce many of our style conventions. When it comes to naming conventions we follow the [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

### Opening a Pull Request

For now `main` is the main branch and code improvements are made in topic branches that get merged into it.

1. Fork the repo and create a branch named `initials-topic` or ticket tag like `esw-190`.
2. Make your proposed changes. Make sure to test them thoroughly and consider adding unit or integration tests.
3. Open a PR with a short description of what the PR accomplishes, and a link to the corresponding issue.
4. If possible add screenshots (use shift-command-4-space-click to capture the iOS simulator window).

A maintainer will review your code and merge it when it has the required number of approvals.

### Dependency Management

We prefer to install dependencies using the Swift Package Manager. 

### Releasing

We build and release using [Fastlane](https://docs.fastlane.tools). You can set up fastlane like this:

1. Install command line tools `xcode-select --install`
2. Install fastlane: `brew install fastlane` or `gem install fastlane`
3. Get the Apple Developer API Key from another team member and place it in `$HOME/.fastlane`.
