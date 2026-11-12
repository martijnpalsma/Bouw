import Foundation
import os

/// Central logging without customer PII in production logs.
enum AppLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "nl.riskwalk.app"

    private static let dossier = Logger(subsystem: subsystem, category: "dossier")
    private static let persistence = Logger(subsystem: subsystem, category: "persistence")
    private static let building = Logger(subsystem: subsystem, category: "building")
    private static let photo = Logger(subsystem: subsystem, category: "photo")
    private static let report = Logger(subsystem: subsystem, category: "report")
    private static let security = Logger(subsystem: subsystem, category: "security")

    static func dossierOpened(id: String) {
        dossier.info("Opened dossier id=\(redacted(id), privacy: .public)")
    }

    static func dossierDeleted(id: String) {
        dossier.info("Deleted dossier id=\(redacted(id), privacy: .public)")
    }

    static func dossierSaved(id: String, buildingCount: Int, photoCount: Int) {
        persistence.info("Saved dossier id=\(redacted(id), privacy: .public) buildings=\(buildingCount, privacy: .public) photos=\(photoCount, privacy: .public)")
    }

    static func dossierSaveFailed(_ error: Error) {
        persistence.error("Save failed: \(error.localizedDescription, privacy: .public)")
    }

    static func buildingAdded(displayCode: String, uuid: UUID) {
        building.info("Added building code=\(displayCode, privacy: .public) uuid=\(uuid.uuidString, privacy: .public)")
    }

    static func buildingRemoved(displayCode: String, uuid: UUID) {
        building.info("Removed building code=\(displayCode, privacy: .public) uuid=\(uuid.uuidString, privacy: .public)")
    }

    static func photoSaved(id: UUID, buildingCode: String?) {
        photo.info("Saved photo id=\(id.uuidString, privacy: .public) building=\(buildingCode ?? "-", privacy: .public)")
    }

    static func photoSaveFailed(_ error: Error) {
        photo.error("Photo save failed: \(error.localizedDescription, privacy: .public)")
    }

    static func reportGenerated(photoCount: Int) {
        report.info("Generated report photos=\(photoCount, privacy: .public)")
    }

    static func permissionDenied(_ permission: String) {
        security.warning("Permission denied: \(permission, privacy: .public)")
    }

    static func authResult(success: Bool) {
        security.info("Local auth success=\(success, privacy: .public)")
    }

    /// Never log raw customer identifiers; keep a short stable fingerprint for correlation.
    private static func redacted(_ value: String) -> String {
        guard !value.isEmpty else { return "-" }
        let prefix = value.prefix(8)
        return "\(prefix)…"
    }
}
