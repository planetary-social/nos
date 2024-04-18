// swiftlint:disable:next file_header
// swift-tools-version:5.2

// this is here because it helps SourceKit-LSP parse your project i.e. when used with VSCode.
// see https://medium.com/swlh/ios-development-on-vscode-27be37293fe1
import PackageDescription
let packageName = "Nos" 
let package = Package(
    name: "",
    // platforms: [.iOS("9.0")],
    products: [
        .library(name: packageName, targets: [packageName])
    ],
    targets: [
        .target(
            name: packageName,
            path: packageName
        )
    ]
)
