import Foundation

public struct ToggleNotchState: Codable, Equatable, Sendable {
    public var displayID: UInt32
    public var mode: DisplayModeInfo
    public var savedAt: Date

    public init(displayID: UInt32, mode: DisplayModeInfo, savedAt: Date = Date()) {
        self.displayID = displayID
        self.mode = mode
        self.savedAt = savedAt
    }
}

public struct StateStore: Sendable {
    public var fileURL: URL

    public init(fileURL: URL = StateStore.defaultFileURL()) {
        self.fileURL = fileURL
    }

    public static func defaultFileURL() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("togglenotch", isDirectory: true)
            .appendingPathComponent("state.json")
    }

    public func load() throws -> ToggleNotchState? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }

        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(ToggleNotchState.self, from: data)
    }

    public func save(_ state: ToggleNotchState) throws {
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(state)
        try data.write(to: fileURL, options: .atomic)
    }
}
