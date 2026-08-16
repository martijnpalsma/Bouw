import Foundation

/// Atomic, Data Protection–backed persistence for inspection dossiers.
enum SecureStore {
    private static let dossierFileName = "current-dossier.json"
    private static let directoryName = "RiskWalkData"

    static var applicationSupportDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let base = urls[0].appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            try? FileManager.default.setAttributes(
                [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
                ofItemAtPath: base.path
            )
        }
        return base
    }

    static var dossierURL: URL {
        applicationSupportDirectory.appendingPathComponent(dossierFileName)
    }

    static func save(_ snapshot: InspectionSnapshot) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        let data = try encoder.encode(snapshot)
        let tempURL = dossierURL.appendingPathExtension("tmp")

        try data.write(to: tempURL, options: [.atomic])
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: tempURL.path
        )

        if FileManager.default.fileExists(atPath: dossierURL.path) {
            try FileManager.default.removeItem(at: dossierURL)
        }
        try FileManager.default.moveItem(at: tempURL, to: dossierURL)
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: dossierURL.path
        )

        AppLogger.dossierSaved(
            id: snapshot.id.uuidString,
            buildingCount: snapshot.buildings.count,
            photoCount: snapshot.photos.count
        )
    }

    static func load() throws -> InspectionSnapshot? {
        guard FileManager.default.fileExists(atPath: dossierURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: dossierURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(InspectionSnapshot.self, from: data)
    }

    static func clearAll() throws {
        if FileManager.default.fileExists(atPath: applicationSupportDirectory.path) {
            try FileManager.default.removeItem(at: applicationSupportDirectory)
        }
        _ = applicationSupportDirectory
    }
}
