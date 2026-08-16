import Foundation
import SwiftUI
import UIKit

struct Building: Identifiable, Hashable, Codable {
    /// Stable internal primary key — never reuse after delete.
    var id: UUID
    /// Visible sequence code (G01, G02, …). Independent of array index.
    var displayCode: String
    var name: String
    var description: String
    var function: String
    var constructionYear: Int?
    var area: Double?
    var floors: Int?
    var categories: [String]

    init(
        id: UUID = UUID(),
        displayCode: String,
        name: String,
        description: String = "",
        function: String = "",
        constructionYear: Int? = nil,
        area: Double? = nil,
        floors: Int? = nil,
        categories: [String] = []
    ) {
        self.id = id
        self.displayCode = displayCode
        self.name = name
        self.description = description
        self.function = function
        self.constructionYear = constructionYear
        self.area = area
        self.floors = floors
        self.categories = categories
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Building, rhs: Building) -> Bool {
        lhs.id == rhs.id
    }
}

enum TopicCategory: String, Codable {
    case general = "Algemeen"
    case categorySpecific = "Categorie-specifiek"
}

enum InspectionStatus: String, CaseIterable, Codable {
    case ok = "✅ In orde"
    case attention = "⚠️ Aandachtspunt"
    case shortage = "❌ Tekortkoming"
    case notApplicable = "N.v.t."

    var color: Color {
        switch self {
        case .ok: return .green
        case .attention: return .orange
        case .shortage: return .red
        case .notApplicable: return .gray
        }
    }
}

struct VoiceNote: Identifiable, Codable, Hashable {
    var id: UUID
    var text: String
    var date: Date

    init(id: UUID = UUID(), text: String, date: Date = Date()) {
        self.id = id
        self.text = text
        self.date = date
    }
}

struct InspectionTopic: Identifiable, Codable {
    var id: UUID
    var name: String
    var category: TopicCategory
    /// Keyed by building UUID string.
    var buildingStatuses: [String: InspectionStatus]
    var buildingNotes: [String: String]
    var buildingVoiceNotes: [String: [VoiceNote]]

    init(
        id: UUID = UUID(),
        name: String,
        category: TopicCategory,
        buildingStatuses: [String: InspectionStatus] = [:],
        buildingNotes: [String: String] = [:],
        buildingVoiceNotes: [String: [VoiceNote]] = [:]
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.buildingStatuses = buildingStatuses
        self.buildingNotes = buildingNotes
        self.buildingVoiceNotes = buildingVoiceNotes
    }
}

struct InspectionPhoto: Identifiable, Codable {
    var id: UUID
    var buildingId: UUID?
    var buildingDisplayCode: String?
    var topic: String?
    var subtopic: String?
    var status: InspectionStatus?
    var note: String
    var timestamp: Date
    var photoNumber: Int
    /// Relative file name under PhotoStore directory.
    var fileName: String

    init(
        id: UUID = UUID(),
        buildingId: UUID? = nil,
        buildingDisplayCode: String? = nil,
        topic: String? = nil,
        subtopic: String? = nil,
        status: InspectionStatus? = nil,
        note: String = "",
        timestamp: Date = Date(),
        photoNumber: Int = 0,
        fileName: String? = nil
    ) {
        self.id = id
        self.buildingId = buildingId
        self.buildingDisplayCode = buildingDisplayCode
        self.topic = topic
        self.subtopic = subtopic
        self.status = status
        self.note = note
        self.timestamp = timestamp
        self.photoNumber = photoNumber
        self.fileName = fileName ?? "\(id.uuidString).jpg"
    }

    func loadThumbnail(maxPixelSize: CGFloat = 400) -> UIImage? {
        PhotoStore.loadImage(photoId: id, maxPixelSize: maxPixelSize)
    }

    func loadFullImage(maxPixelSize: CGFloat = 2048) -> UIImage? {
        PhotoStore.loadImage(photoId: id, maxPixelSize: maxPixelSize)
    }
}

struct Question: Identifiable, Codable, Hashable {
    let id: String
    let text: String
    let type: QuestionType
    let categories: [String]
    let dependsOn: String?
    let requiresValue: String?

    enum QuestionType: String, Codable {
        case yesNo
        case text
        case number
        case multipleChoice
    }
}

struct Answer: Codable, Hashable {
    var value: String
    var note: String?
    var timestamp: Date
}

struct OpenIssue: Identifiable, Codable, Hashable {
    var id: UUID
    var title: String
    var description: String
    var relatedQuestion: String?
    var isResolved: Bool

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        relatedQuestion: String? = nil,
        isResolved: Bool = false
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.relatedQuestion = relatedQuestion
        self.isResolved = isResolved
    }
}

enum InspectionLifecycleStatus: String, Codable, CaseIterable {
    case preparation = "Voorbereiding"
    case inProgress = "In uitvoering"
    case followUp = "Uitzoeken"
    case readyForReport = "Gereed voor rapportage"
    case completed = "Afgerond"
}

/// Codable snapshot persisted by SecureStore.
struct InspectionSnapshot: Codable {
    var id: UUID
    var companyName: String
    var address: String
    var contactPerson: String
    var inspectionDate: Date
    var status: InspectionLifecycleStatus
    var buildings: [Building]
    var selectedBusinessTypes: [String]
    var customBusinessType: String
    var inspectBuildings: Bool
    var inspectInventory: Bool
    var inspectGoods: Bool
    var inspectDamage: Bool
    var topics: [InspectionTopic]
    var answers: [String: Answer]
    var photos: [InspectionPhoto]
    var openIssues: [OpenIssue]
    var recommendations: [String]
    var nextBuildingSequence: Int
    var saveAlsoToPhotoLibrary: Bool
}
