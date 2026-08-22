import Foundation

enum GameSaveRepositoryError: Error {
    case unsupportedSchemaVersion(Int)
}

protocol GameSaveRepository {
    func save(_ gameSave: GameSave) throws
    func load() throws -> GameSave?
    func hasSave() -> Bool
    func deleteSave() throws
}

final class FileGameSaveRepository: GameSaveRepository {
    private struct GameSaveHeader: Decodable {
        let schemaVersion: Int
    }

    private let fileManager: FileManager
    private let saveURL: URL

    init(
        fileManager: FileManager = .default,
        directoryURL: URL? = nil
    ) throws {
        self.fileManager = fileManager

        let saveDirectory: URL

        if let directoryURL {
            saveDirectory = directoryURL
        } else {
            saveDirectory = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }

        try fileManager.createDirectory(
            at: saveDirectory,
            withIntermediateDirectories: true
        )

        saveURL = saveDirectory.appendingPathComponent(
            "game-save.json",
            isDirectory: false
        )
    }

    func save(
        _ gameSave: GameSave
    ) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let data = try encoder.encode(gameSave)
        try data.write(to: saveURL, options: .atomic)
    }

    func load() throws -> GameSave? {
        guard hasSave() else {
            return nil
        }

        let data = try Data(contentsOf: saveURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let header = try decoder.decode(
            GameSaveHeader.self,
            from: data
        )

        switch header.schemaVersion {
        case GameSave.currentSchemaVersion:
            return try decoder.decode(GameSave.self, from: data)

        default:
            throw GameSaveRepositoryError.unsupportedSchemaVersion(
                header.schemaVersion
            )
        }
    }

    func hasSave() -> Bool {
        fileManager.fileExists(atPath: saveURL.path)
    }

    func deleteSave() throws {
        guard hasSave() else {
            return
        }

        try fileManager.removeItem(at: saveURL)
    }
}
