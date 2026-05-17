// swift-tools-version:6.2
import PackageDescription

let package = Package(
  name: "mlx-whisper-swift",
  platforms: [.macOS("14.0"), .iOS("17.0")],
  products: [
    .library(
      name: "MLXAudio",
      targets: ["MLXAudio"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/joelnishanth/mlx-swift-lm.git", branch: "feature/turboquant"),
    .package(url: "https://github.com/joelnishanth/mlx-swift.git", branch: "feature/turboquant"),
    .package(url: "https://github.com/DePasqualeOrg/swift-tokenizers-mlx", branch: "main"),
    .package(url: "https://github.com/DePasqualeOrg/swift-hf-api-mlx", branch: "main"),
    .package(url: "https://github.com/DePasqualeOrg/swift-tiktoken", branch: "main"),
  ],
  targets: [
    .target(
      name: "MLXAudio",
      dependencies: [
        .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
        .product(name: "MLXLLM", package: "mlx-swift-lm"),
        .product(name: "MLXFFT", package: "mlx-swift"),
        .product(name: "MLXLMTokenizers", package: "swift-tokenizers-mlx"),
        .product(name: "MLXLMHFAPI", package: "swift-hf-api-mlx"),
        .product(name: "SwiftTiktoken", package: "swift-tiktoken"),
      ],
      path: "package",
      exclude: ["TTS/Kokoro", "Tests"],
      resources: [
        .process("TTS/OuteTTS/default_speaker.json"),
      ]
    ),
    .testTarget(
      name: "MLXAudioTests",
      dependencies: ["MLXAudio"],
      path: "package/Tests"
    ),
  ]
)
