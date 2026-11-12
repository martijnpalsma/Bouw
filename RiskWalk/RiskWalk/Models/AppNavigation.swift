import Foundation

/// Main workspace frames for quick switching during an inspection.
enum AppFrame: String, CaseIterable, Identifiable, Hashable {
    case dossier
    case inspection
    case questionnaire
    case photos
    case summary

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dossier: return "Dossier"
        case .inspection: return "Inspectie"
        case .questionnaire: return "Vragenlijst"
        case .photos: return "Foto's"
        case .summary: return "Samenvatting"
        }
    }

    var systemImage: String {
        switch self {
        case .dossier: return "building.2"
        case .inspection: return "checklist"
        case .questionnaire: return "list.bullet.clipboard"
        case .photos: return "photo.on.rectangle"
        case .summary: return "doc.text"
        }
    }
}

/// Lightweight row used on the dashboard list (no full payload).
struct DossierSummary: Identifiable, Codable, Hashable {
    var id: UUID
    var companyName: String
    var place: String
    var inspectionDate: Date
    var status: InspectionLifecycleStatus
    var progress: Double
    var buildingCount: Int
    var photoCount: Int
    var openIssueCount: Int
    var isArchived: Bool
    var updatedAt: Date

    var displayName: String {
        companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Naamloos dossier"
            : companyName
    }

    var progressPercent: Int {
        Int((min(max(progress, 0), 1) * 100).rounded())
    }
}

enum DossierProgress {
    static func calculate(from snapshot: InspectionSnapshot) -> Double {
        let buildings = snapshot.buildings
        guard !buildings.isEmpty else {
            let answered = snapshot.answers.values.filter { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
            let totalQuestions = max(snapshot.answers.count + 8, 8)
            return min(Double(answered) / Double(totalQuestions), 1)
        }

        var filled = 0
        var total = 0
        for topic in snapshot.topics {
            for building in buildings {
                total += 1
                if topic.buildingStatuses[building.id.uuidString] != nil {
                    filled += 1
                }
            }
        }

        let answerBonus = snapshot.answers.isEmpty ? 0.0 : min(Double(snapshot.answers.count) / 40.0, 0.15)
        let base = total == 0 ? 0 : Double(filled) / Double(total)
        return min(base + answerBonus * 0.2, 1)
    }

    static func place(from address: String) -> String {
        let parts = address
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        if let last = parts.last, parts.count > 1 {
            return last
        }
        // Dutch-style: "Straat 1, 1234 AB Plaats" or "Straat 1 1234 AB Plaats"
        let tokens = address.split(separator: " ").map(String.init)
        if tokens.count >= 2 {
            return tokens.suffix(2).joined(separator: " ")
        }
        return address.isEmpty ? "—" : address
    }
}
