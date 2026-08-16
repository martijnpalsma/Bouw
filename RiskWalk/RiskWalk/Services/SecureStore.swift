import Foundation

/// Multi-dossier persistence with Data Protection.
enum SecureStore {
    private static let directoryName = "RiskWalkData"
    private static let indexFileName = "dossier-index.json"
    private static let legacyFileName = "current-dossier.json"
    private static let dossiersFolderName = "dossiers"

    static var applicationSupportDirectory: URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let base = urls[0].appendingPathComponent(directoryName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: base.path) {
            try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
            try? applyProtection(at: base)
        }
        return base
    }

    static var dossiersDirectory: URL {
        let dir = applicationSupportDirectory.appendingPathComponent(dossiersFolderName, isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            try? applyProtection(at: dir)
        }
        return dir
    }

    private static var indexURL: URL {
        applicationSupportDirectory.appendingPathComponent(indexFileName)
    }

    private static var legacyURL: URL {
        applicationSupportDirectory.appendingPathComponent(legacyFileName)
    }

    static func dossierURL(for id: UUID) -> URL {
        dossiersDirectory.appendingPathComponent("\(id.uuidString).json")
    }

    // MARK: - Index

    static func loadIndex() throws -> [DossierSummary] {
        try migrateLegacyIfNeeded()
        guard FileManager.default.fileExists(atPath: indexURL.path) else { return [] }
        let data = try Data(contentsOf: indexURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([DossierSummary].self, from: data)
    }

    static func saveIndex(_ summaries: [DossierSummary]) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(summaries)
        try atomicWrite(data, to: indexURL)
    }

    // MARK: - Dossier CRUD

    static func save(_ snapshot: InspectionSnapshot) throws {
        try migrateLegacyIfNeeded()
        var mutable = snapshot
        mutable.updatedAt = Date()

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        let data = try encoder.encode(mutable)
        try atomicWrite(data, to: dossierURL(for: mutable.id))

        var index = (try? loadIndex()) ?? []
        let summary = makeSummary(from: mutable)
        if let idx = index.firstIndex(where: { $0.id == mutable.id }) {
            index[idx] = summary
        } else {
            index.insert(summary, at: 0)
        }
        index.sort { $0.updatedAt > $1.updatedAt }
        try saveIndex(index)

        AppLogger.dossierSaved(
            id: mutable.id.uuidString,
            buildingCount: mutable.buildings.count,
            photoCount: mutable.photos.count
        )
    }

    static func load(id: UUID) throws -> InspectionSnapshot? {
        try migrateLegacyIfNeeded()
        let url = dossierURL(for: id)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(InspectionSnapshot.self, from: data)
    }

    /// Backward-compatible helper used by older single-dossier call sites/tests.
    static func load() throws -> InspectionSnapshot? {
        try migrateLegacyIfNeeded()
        let index = try loadIndex()
        if let firstActive = index.first(where: { !$0.isArchived }) ?? index.first {
            return try load(id: firstActive.id)
        }
        return nil
    }

    static func deleteDossier(id: UUID, photoIds: [UUID]) throws {
        let url = dossierURL(for: id)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        for photoId in photoIds {
            PhotoStore.deleteImage(photoId: photoId)
        }
        var index = try loadIndex()
        index.removeAll { $0.id == id }
        try saveIndex(index)
        AppLogger.dossierDeleted(id: id.uuidString)
    }

    static func clearAll() throws {
        if FileManager.default.fileExists(atPath: applicationSupportDirectory.path) {
            try FileManager.default.removeItem(at: applicationSupportDirectory)
        }
        _ = applicationSupportDirectory
    }

    static func makeSummary(from snapshot: InspectionSnapshot) -> DossierSummary {
        DossierSummary(
            id: snapshot.id,
            companyName: snapshot.companyName,
            place: DossierProgress.place(from: snapshot.address),
            inspectionDate: snapshot.inspectionDate,
            status: snapshot.status,
            progress: DossierProgress.calculate(from: snapshot),
            buildingCount: snapshot.buildings.count,
            photoCount: snapshot.photos.count,
            openIssueCount: snapshot.openIssues.filter { !$0.isResolved }.count,
            isArchived: snapshot.isArchived,
            updatedAt: snapshot.updatedAt
        )
    }

    // MARK: - Migration

    private static func migrateLegacyIfNeeded() throws {
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        let data = try Data(contentsOf: legacyURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let snapshot = try decoder.decode(InspectionSnapshot.self, from: data)
        try atomicWrite(data, to: dossierURL(for: snapshot.id))
        try saveIndex([makeSummary(from: snapshot)])
        try FileManager.default.removeItem(at: legacyURL)
        AppLogger.dossierOpened(id: snapshot.id.uuidString)
    }

    // MARK: - Helpers

    private static func atomicWrite(_ data: Data, to url: URL) throws {
        let tempURL = url.appendingPathExtension("tmp")
        try data.write(to: tempURL, options: [.atomic])
        try applyProtection(at: tempURL)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: tempURL, to: url)
        try applyProtection(at: url)
    }

    private static func applyProtection(at url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }
}
