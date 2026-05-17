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
    .package(url: "https://github.com/huggingface/swift-huggingface.git", from: "0.9.0"),
    .package(url: "https://github.com/huggingface/swift-transformers.git", from: "1.3.0"),
    .package(url: "https://github.com/DePasqualeOrg/swift-tiktoken", branch: "main"),
  ],
  targets: [
    .target(
      name: "MLXAudio",
      dependencies: [
        .product(name: "MLXLMCommon", package: "mlx-swift-lm"),
        .product(name: "MLXLLM", package: "mlx-swift-lm"),
        .product(name: "MLX", package: "mlx-swift"),
        .product(name: "MLXNN", package: "mlx-swift"),
        .product(name: "MLXFFT", package: "mlx-swift"),
        .product(name: "HuggingFace", package: "swift-huggingface"),
        .product(name: "Tokenizers", package: "swift-transformers"),
        .product(name: "SwiftTiktoken", package: "swift-tiktoken"),
      ],
      path: "package",
      exclude: ["TTS", "Tests", "Codec"],
      resources: []
    ),
  ]
)
