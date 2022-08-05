// swift-tools-version: 5.7
import PackageDescription



let package = Package(
	name: "lts-check",
	platforms: [.macOS(.v11)],
	products: [.executable(name: "lts-check", targets: ["lts-check"])],
	dependencies: [
		.package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.3"),
		.package(url: "https://github.com/apple/swift-log.git", from: "1.4.2"),
		.package(url: "https://github.com/xcode-actions/clt-logger.git", from: "0.3.6")
	],
	targets: [
		.executableTarget(name: "lts-check", dependencies: [
			.product(name: "ArgumentParser", package: "swift-argument-parser"),
			.product(name: "CLTLogger",      package: "clt-logger"),
			.product(name: "Logging",        package: "swift-log")
		]),
		.testTarget(name: "lts-checkTests", dependencies: ["lts-check"])
	]
)
