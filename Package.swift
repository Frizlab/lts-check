// swift-tools-version: 5.7
import PackageDescription



let package = Package(
	name: "lts-check",
	platforms: [.macOS(.v13)],
	products: [.executable(name: "lts-check", targets: ["lts-check"])],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.3")
	],
	targets: [
		.executableTarget(name: "lts-check", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser")
		]),
		.testTarget(name: "lts-checkTests", dependencies: ["lts-check"])
	]
)
