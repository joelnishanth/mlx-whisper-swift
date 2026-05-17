import Foundation
import HuggingFace
import MLXLMCommon
import Tokenizers

/// Bridge that makes `HuggingFace.HubClient` conform to `MLXLMCommon.Downloader`.
/// Replaces `MLXLMHFAPI` / `swift-hf-api-mlx` to avoid dependency conflicts.
public struct HubBridge: Downloader, Sendable {
    private let upstream: HubClient

    public init(_ upstream: HubClient = HubClient()) {
        self.upstream = upstream
    }

    public func download(
        id: String,
        revision: String?,
        matching patterns: [String],
        useLatest: Bool,
        progressHandler: @Sendable @escaping (Foundation.Progress) -> Void
    ) async throws -> URL {
        guard let repoID = Repo.ID(rawValue: id) else {
            throw HubBridgeError.invalidRepositoryID(id)
        }
        let revision = revision ?? "main"

        return try await upstream.downloadSnapshot(
            of: repoID,
            revision: revision,
            matching: patterns,
            progressHandler: { @MainActor progress in
                progressHandler(progress)
            }
        )
    }

    /// Default shared downloader for convenience
    public static let `default`: any Downloader = HubBridge()
}

public enum HubBridgeError: LocalizedError {
    case invalidRepositoryID(String)

    public var errorDescription: String? {
        switch self {
        case .invalidRepositoryID(let id):
            return "Invalid Hugging Face repository ID: '\(id)'. Expected format 'namespace/name'."
        }
    }
}

/// Bridge that wraps `Tokenizers.Tokenizer` into `MLXLMCommon.Tokenizer`.
/// Replaces `MLXLMTokenizers` / `swift-tokenizers-mlx` to avoid dependency conflicts.
struct TokenizerBridge: MLXLMCommon.Tokenizer {
    private let upstream: any Tokenizers.Tokenizer

    init(_ upstream: any Tokenizers.Tokenizer) {
        self.upstream = upstream
    }

    func encode(text: String, addSpecialTokens: Bool) -> [Int] {
        upstream.encode(text: text, addSpecialTokens: addSpecialTokens)
    }

    func decode(tokenIds: [Int], skipSpecialTokens: Bool) -> String {
        upstream.decode(tokens: tokenIds, skipSpecialTokens: skipSpecialTokens)
    }

    func convertTokenToId(_ token: String) -> Int? {
        upstream.convertTokenToId(token)
    }

    func convertIdToToken(_ id: Int) -> String? {
        upstream.convertIdToToken(id)
    }

    var bosToken: String? { upstream.bosToken }
    var eosToken: String? { upstream.eosToken }
    var unknownToken: String? { upstream.unknownToken }

    func applyChatTemplate(
        messages: [[String: any Sendable]],
        tools: [[String: any Sendable]]?,
        additionalContext: [String: any Sendable]?
    ) throws -> [Int] {
        try upstream.applyChatTemplate(
            messages: messages, tools: tools, additionalContext: additionalContext)
    }
}

/// Loader that creates `MLXLMCommon.Tokenizer` from `Tokenizers.AutoTokenizer`.
/// Replaces `TokenizersLoader` from `MLXLMTokenizers`.
public struct HFTokenizerLoader: TokenizerLoader, Sendable {
    public init() {}

    public func load(from directory: URL) async throws -> any MLXLMCommon.Tokenizer {
        let upstream = try await AutoTokenizer.from(modelFolder: directory)
        return TokenizerBridge(upstream)
    }
}
