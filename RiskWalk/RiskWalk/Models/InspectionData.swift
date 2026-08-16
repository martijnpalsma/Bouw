import Foundation
import SwiftUI
import UIKit

@MainActor
final class InspectionData: ObservableObject {
    @Published var dossierId: UUID = UUID()
    @Published var companyName: String = ""
    @Published var address: String = ""
    @Published var contactPerson: String = ""
    @Published var inspectionDate: Date = Date()
    @Published var lifecycleStatus: InspectionLifecycleStatus = .preparation
    @Published var buildings: [Building] = []
    @Published var selectedBusinessTypes: [String] = []
    @Published var customBusinessType: String = ""

    @Published var inspectBuildings: Bool = true
    @Published var inspectInventory: Bool = true
    @Published var inspectGoods: Bool = true
    @Published var inspectDamage: Bool = true

    @Published var topics: [InspectionTopic] = QuestionDatabase.defaultTopicNames.map {
        InspectionTopic(name: $0, category: .general)
    }

    @Published var questions: [Question] = QuestionDatabase.allQuestions
    @Published var answers: [String: Answer] = [:]
    @Published var photos: [InspectionPhoto] = []
    @Published var openIssues: [OpenIssue] = []
    @Published var recommendations: [String] = []

    /// When true, newly captured photos are also written to the system photo library (opt-in).
    @Published var saveAlsoToPhotoLibrary: Bool = false
    @Published var isArchived: Bool = false

    private var nextBuildingSequence: Int = 0
    private var autosaveTask: Task<Void, Never>?
    private var hasLoaded = false

    init(loadFromDisk: Bool = true) {
        if loadFromDisk {
            // Start empty on dashboard; dossiers are opened explicitly.
            _ = try? SecureStore.loadIndex()
        }
        hasLoaded = true
    }

    var displayTitle: String {
        let name = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? "Nieuw dossier" : name
    }

    var placeLabel: String {
        DossierProgress.place(from: address)
    }

    var progressValue: Double {
        DossierProgress.calculate(from: makeSnapshot())
    }

    private var hasMeaningfulContent: Bool {
        !companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !buildings.isEmpty
            || !photos.isEmpty
            || !answers.isEmpty
            || !selectedBusinessTypes.isEmpty
    }

    private func saveIfMeaningful() {
        guard hasMeaningfulContent else { return }
        saveData()
    }

    // MARK: - Persistence

    func scheduleAutosave() {
        autosaveTask?.cancel()
        autosaveTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 400_000_000)
            guard let self, !Task.isCancelled else { return }
            self.saveData()
        }
    }

    func saveData() {
        guard hasLoaded else { return }
        do {
            try SecureStore.save(makeSnapshot())
        } catch {
            AppLogger.dossierSaveFailed(error)
        }
    }

    func loadData() {
        do {
            guard let snapshot = try SecureStore.load() else { return }
            apply(snapshot)
            AppLogger.dossierOpened(id: snapshot.id.uuidString)
        } catch {
            AppLogger.dossierSaveFailed(error)
        }
    }

    func openDossier(id: UUID) {
        saveIfMeaningful()
        do {
            guard let snapshot = try SecureStore.load(id: id) else { return }
            apply(snapshot)
            AppLogger.dossierOpened(id: id.uuidString)
        } catch {
            AppLogger.dossierSaveFailed(error)
        }
    }

    func createNewDossier() {
        saveIfMeaningful()
        resetEmpty()
        lifecycleStatus = .preparation
        saveData()
        AppLogger.dossierOpened(id: dossierId.uuidString)
    }

    @discardableResult
    func duplicateCurrentDossier() -> UUID {
        saveIfMeaningful()
        let originalPhotos = photos
        var copy = makeSnapshot()
        copy.id = UUID()
        copy.companyName = copy.companyName.isEmpty ? "Kopie" : "\(copy.companyName) (kopie)"
        copy.status = .preparation
        copy.isArchived = false
        copy.updatedAt = Date()

        // New photo IDs so originals are not deleted with the copy.
        var remapped: [InspectionPhoto] = []
        for photo in originalPhotos {
            let newId = UUID()
            if let image = PhotoStore.loadImage(photoId: photo.id, maxPixelSize: 4096) {
                try? PhotoStore.saveImage(image, photoId: newId)
            }
            var newPhoto = photo
            newPhoto.id = newId
            newPhoto.fileName = "\(newId.uuidString).jpg"
            remapped.append(newPhoto)
        }
        copy.photos = remapped

        do {
            try SecureStore.save(copy)
            apply(copy)
            AppLogger.dossierOpened(id: copy.id.uuidString)
        } catch {
            AppLogger.dossierSaveFailed(error)
        }
        return copy.id
    }

    func archiveCurrentDossier(archived: Bool = true) {
        isArchived = archived
        if archived, lifecycleStatus != .completed {
            lifecycleStatus = .completed
        }
        saveData()
    }

    func deleteDossier(id: UUID) {
        let photoIds: [UUID]
        if id == dossierId {
            photoIds = photos.map(\.id)
        } else if let snapshot = try? SecureStore.load(id: id) {
            photoIds = snapshot.photos.map(\.id)
        } else {
            photoIds = []
        }

        do {
            try SecureStore.deleteDossier(id: id, photoIds: photoIds)
            if id == dossierId {
                resetEmpty()
            }
        } catch {
            AppLogger.dossierSaveFailed(error)
        }
    }

    func exportText() -> String {
        // Shared lightweight export used from dashboard actions.
        var text = "INSPECTIE RAPPORT\n==================\n\n"
        text += "Bedrijfsnaam: \(companyName)\n"
        text += "Adres: \(address)\n"
        text += "Plaats: \(placeLabel)\n"
        text += "Contactpersoon: \(contactPerson)\n"
        text += "Inspectiedatum: \(inspectionDate.formatted(date: .long, time: .omitted))\n"
        text += "Status: \(lifecycleStatus.rawValue)\n"
        text += "Voortgang: \(Int((progressValue * 100).rounded()))%\n"
        text += "Gebouwen: \(buildings.count)\n"
        text += "Foto's: \(photos.count)\n"
        return text
    }

    private func resetEmpty() {
        dossierId = UUID()
        companyName = ""
        address = ""
        contactPerson = ""
        inspectionDate = Date()
        lifecycleStatus = .preparation
        buildings = []
        selectedBusinessTypes = []
        customBusinessType = ""
        inspectBuildings = true
        inspectInventory = true
        inspectGoods = true
        inspectDamage = true
        topics = QuestionDatabase.defaultTopicNames.map { InspectionTopic(name: $0, category: .general) }
        answers = [:]
        photos = []
        openIssues = []
        recommendations = []
        nextBuildingSequence = 0
        saveAlsoToPhotoLibrary = false
        isArchived = false
    }

    private func makeSnapshot() -> InspectionSnapshot {
        InspectionSnapshot(
            id: dossierId,
            companyName: companyName,
            address: address,
            contactPerson: contactPerson,
            inspectionDate: inspectionDate,
            status: lifecycleStatus,
            buildings: buildings,
            selectedBusinessTypes: selectedBusinessTypes,
            customBusinessType: customBusinessType,
            inspectBuildings: inspectBuildings,
            inspectInventory: inspectInventory,
            inspectGoods: inspectGoods,
            inspectDamage: inspectDamage,
            topics: topics,
            answers: answers,
            photos: photos,
            openIssues: openIssues,
            recommendations: recommendations,
            nextBuildingSequence: nextBuildingSequence,
            saveAlsoToPhotoLibrary: saveAlsoToPhotoLibrary,
            isArchived: isArchived,
            updatedAt: Date()
        )
    }

    private func apply(_ snapshot: InspectionSnapshot) {
        dossierId = snapshot.id
        companyName = snapshot.companyName
        address = snapshot.address
        contactPerson = snapshot.contactPerson
        inspectionDate = snapshot.inspectionDate
        lifecycleStatus = snapshot.status
        buildings = snapshot.buildings
        selectedBusinessTypes = snapshot.selectedBusinessTypes
        customBusinessType = snapshot.customBusinessType
        inspectBuildings = snapshot.inspectBuildings
        inspectInventory = snapshot.inspectInventory
        inspectGoods = snapshot.inspectGoods
        inspectDamage = snapshot.inspectDamage
        topics = snapshot.topics.isEmpty
            ? QuestionDatabase.defaultTopicNames.map { InspectionTopic(name: $0, category: .general) }
            : snapshot.topics
        answers = snapshot.answers
        photos = snapshot.photos
        openIssues = snapshot.openIssues
        recommendations = snapshot.recommendations
        nextBuildingSequence = snapshot.nextBuildingSequence
        saveAlsoToPhotoLibrary = snapshot.saveAlsoToPhotoLibrary
        isArchived = snapshot.isArchived
    }

    // MARK: - Buildings

    @discardableResult
    func addBuilding() -> Building {
        let allocated = BuildingNumbering.nextDisplayCode(existing: buildings, sequenceHint: nextBuildingSequence)
        nextBuildingSequence = allocated.nextSequence

        let building = Building(
            displayCode: allocated.code,
            name: "Gebouw \(allocated.code.dropFirst())"
        )
        buildings.append(building)
        AppLogger.buildingAdded(displayCode: building.displayCode, uuid: building.id)
        scheduleAutosave()
        return building
    }

    func removeBuilding(_ building: Building) {
        buildings.removeAll { $0.id == building.id }

        let keyPrefix = building.id.uuidString + "_"
        answers = answers.filter { !$0.key.hasPrefix(keyPrefix) }

        let photoIds = photos.filter { $0.buildingId == building.id }.map(\.id)
        photos.removeAll { $0.buildingId == building.id }
        for photoId in photoIds {
            PhotoStore.deleteImage(photoId: photoId)
        }

        for index in topics.indices {
            topics[index].buildingStatuses.removeValue(forKey: building.id.uuidString)
            topics[index].buildingNotes.removeValue(forKey: building.id.uuidString)
            topics[index].buildingVoiceNotes.removeValue(forKey: building.id.uuidString)
        }

        AppLogger.buildingRemoved(displayCode: building.displayCode, uuid: building.id)
        scheduleAutosave()
    }

    // MARK: - Questions

    func activeQuestions(for buildingId: UUID?) -> [Question] {
        var active: [Question] = []
        var seen = Set<String>()
        let categories = selectedBusinessTypes.isEmpty ? ["Algemeen"] : selectedBusinessTypes + ["Algemeen"]

        for question in questions {
            let matchesCategory = question.categories.contains(where: { categories.contains($0) })
                || question.categories.contains("Algemeen")
            guard matchesCategory, !seen.contains(question.id) else { continue }
            guard shouldShowQuestion(question, buildingId: buildingId) else { continue }
            if !inspectDamage && question.id.hasPrefix("bi_") { continue }
            active.append(question)
            seen.insert(question.id)
        }
        return active
    }

    func shouldShowQuestion(_ question: Question, buildingId: UUID?) -> Bool {
        guard let dependsOn = question.dependsOn else { return true }
        let key = answerKey(questionId: dependsOn, buildingId: buildingId)
        guard let answer = answers[key] else { return false }
        if let requiredValue = question.requiresValue {
            return answer.value == requiredValue
        }
        return true
    }

    func answerKey(questionId: String, buildingId: UUID?) -> String {
        if let buildingId {
            return "\(buildingId.uuidString)_\(questionId)"
        }
        return questionId
    }

    // MARK: - Photos

    @discardableResult
    func addPhoto(
        image: UIImage,
        building: Building?,
        topic: String?,
        alsoSaveToPhotoLibrary: Bool
    ) -> InspectionPhoto? {
        let photoId = UUID()
        do {
            try PhotoStore.saveImage(image, photoId: photoId)
            let photo = InspectionPhoto(
                id: photoId,
                buildingId: building?.id,
                buildingDisplayCode: building?.displayCode,
                topic: topic,
                photoNumber: photos.count + 1
            )
            photos.append(photo)
            AppLogger.photoSaved(id: photoId, buildingCode: building?.displayCode)
            scheduleAutosave()

            if alsoSaveToPhotoLibrary {
                Task {
                    let permissions = PermissionManager()
                    let ok = await permissions.requestPhotoLibraryAddAccess()
                    guard ok else { return }
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                }
            }
            return photo
        } catch {
            AppLogger.photoSaveFailed(error)
            return nil
        }
    }

    // MARK: - Status helpers

    struct TopicFinding: Identifiable, Hashable {
        var id: String { "\(buildingCode)-\(topicName)-\(status.rawValue)" }
        let buildingCode: String
        let topicName: String
        let status: InspectionStatus

        var label: String { "\(buildingCode) — \(topicName)" }
    }

    func getShortages() -> [TopicFinding] {
        findings(matching: .shortage)
    }

    func getAttentionPoints() -> [TopicFinding] {
        findings(matching: .attention)
    }

    private func findings(matching status: InspectionStatus) -> [TopicFinding] {
        var result: [TopicFinding] = []
        for topic in topics {
            for building in buildings {
                if topic.buildingStatuses[building.id.uuidString] == status {
                    result.append(TopicFinding(
                        buildingCode: building.displayCode,
                        topicName: topic.name,
                        status: status
                    ))
                }
            }
        }
        return result
    }

    func detectMissingInformation() {
        let previouslyResolved = Dictionary(
            openIssues.compactMap { issue -> (String, Bool)? in
                guard let key = issue.relatedQuestion else { return nil }
                return (key, issue.isResolved)
            },
            uniquingKeysWith: { _, new in new }
        )
        openIssues.removeAll()

        for (key, answer) in answers where answer.value == "Ja" && key.contains("sprinkler") {
            let detailsKey = key + "_details"
            if answers[detailsKey] == nil {
                openIssues.append(
                    OpenIssue(
                        title: "Sprinklerinstallatie details ontbreken",
                        description: "Type, onderhoud en certificering nog uitzoeken",
                        relatedQuestion: key,
                        isResolved: previouslyResolved[key] ?? false
                    )
                )
            }
        }
    }

    func addCategoryToBuilding(_ buildingId: UUID, category: String) {
        guard let index = buildings.firstIndex(where: { $0.id == buildingId }) else { return }
        if !buildings[index].categories.contains(category) {
            buildings[index].categories.append(category)
            scheduleAutosave()
        }
    }
}
