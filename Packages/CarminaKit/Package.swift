// swift-tools-version: 6.2
// SPDX-License-Identifier: GPL-3.0-or-later

import PackageDescription

let package = Package(
	name: "CarminaKit",
	platforms: [.iOS("27.0"), .macOS("27.0")],
	products: [
		.library(name: "CarminaDomain", targets: ["CarminaDomain"]),
		.library(name: "CarminaSources", targets: ["CarminaSources"]),
		.library(name: "CarminaSourcesTesting", targets: ["CarminaSourcesTesting"]),
	],
	targets: [
		.target(name: "CarminaDomain"),
		.target(name: "CarminaSources", dependencies: ["CarminaDomain"]),
		.target(name: "CarminaSourcesTesting", dependencies: ["CarminaDomain", "CarminaSources"]),
		.testTarget(
			name: "CarminaSourcesTests",
			dependencies: ["CarminaDomain", "CarminaSources", "CarminaSourcesTesting"]
		),
	]
)
