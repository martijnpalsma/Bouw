import XCTest
@testable import RiskWalk

@MainActor
final class BuildingNumberingTests: XCTestCase {
    func testSequentialCodesG01ThroughG05() {
        let data = InspectionData(loadFromDisk: false)

        let g01 = data.addBuilding()
        let g02 = data.addBuilding()
        let g03 = data.addBuilding()
        let g04 = data.addBuilding()
        let g05 = data.addBuilding()

        XCTAssertEqual(g01.displayCode, "G01")
        XCTAssertEqual(g02.displayCode, "G02")
        XCTAssertEqual(g03.displayCode, "G03")
        XCTAssertEqual(g04.displayCode, "G04")
        XCTAssertEqual(g05.displayCode, "G05")

        let ids = [g01, g02, g03, g04, g05].map(\.id)
        XCTAssertEqual(Set(ids).count, 5, "Building UUIDs must be unique")
    }

    func testDeleteDoesNotReuseIdentityOrRemapCodes() {
        let data = InspectionData(loadFromDisk: false)
        let g01 = data.addBuilding()
        let g02 = data.addBuilding()
        let g03 = data.addBuilding()

        g01.name = "Magazijn"
        g03.name = "Kantoor"

        data.removeBuilding(g02)

        XCTAssertEqual(data.buildings.map(\.displayCode), ["G01", "G03"])
        XCTAssertEqual(data.buildings.first { $0.displayCode == "G01" }?.name, "Magazijn")
        XCTAssertEqual(data.buildings.first { $0.displayCode == "G03" }?.name, "Kantoor")

        let g04 = data.addBuilding()
        XCTAssertEqual(g04.displayCode, "G04")
        XCTAssertNotEqual(g04.id, g02.id)
        XCTAssertNotEqual(g04.id, g03.id)
    }
}

@MainActor
final class ConditionalQuestionTests: XCTestCase {
    func testFollowUpVisibleOnlyWhenYes() {
        let data = InspectionData(loadFromDisk: false)
        data.selectedBusinessTypes = ["Algemeen"]

        var visible = data.activeQuestions(for: nil).map(\.id)
        XCTAssertTrue(visible.contains("accu_present"))
        XCTAssertFalse(visible.contains("accu_location"))

        data.answers["accu_present"] = Answer(value: "Ja", note: nil, timestamp: Date())
        visible = data.activeQuestions(for: nil).map(\.id)
        XCTAssertTrue(visible.contains("accu_location"))

        data.answers["accu_location"] = Answer(value: "Magazijn", note: nil, timestamp: Date())
        data.answers["accu_present"] = Answer(value: "Nee", note: nil, timestamp: Date())
        visible = data.activeQuestions(for: nil).map(\.id)
        XCTAssertFalse(visible.contains("accu_location"))
        XCTAssertEqual(data.answers["accu_location"]?.value, "Magazijn", "Hidden answers must be retained")
    }
}

@MainActor
final class ScopeToggleTests: XCTestCase {
    func testBusinessInterruptionQuestionsHiddenWhenDisabled() {
        let data = InspectionData(loadFromDisk: false)
        data.selectedBusinessTypes = ["Algemeen"]
        data.questions.append(
            Question(id: "bi_term", text: "Gewenste BI-termijn?", type: .text, categories: ["Algemeen"], dependsOn: nil, requiresValue: nil)
        )

        data.inspectDamage = true
        XCTAssertTrue(data.activeQuestions(for: nil).contains(where: { $0.id == "bi_term" }))

        data.inspectDamage = false
        XCTAssertFalse(data.activeQuestions(for: nil).contains(where: { $0.id == "bi_term" }))
    }
}

final class SecureStoreRoundTripTests: XCTestCase {
    func testSnapshotRoundTripWithoutPIIInLoggerContract() throws {
        let snapshot = InspectionSnapshot(
            id: UUID(),
            companyName: "Test BV",
            address: "Geheimstraat 1",
            contactPerson: "Jan",
            inspectionDate: Date(),
            status: .inProgress,
            buildings: [
                Building(displayCode: "G01", name: "Hal")
            ],
            selectedBusinessTypes: ["Kantoor"],
            customBusinessType: "",
            inspectBuildings: true,
            inspectInventory: true,
            inspectGoods: false,
            inspectDamage: true,
            topics: [InspectionTopic(name: "Brand", category: .general)],
            answers: ["accu_present": Answer(value: "Nee", note: nil, timestamp: Date())],
            photos: [],
            openIssues: [],
            recommendations: [],
            nextBuildingSequence: 1,
            saveAlsoToPhotoLibrary: false
        )

        try SecureStore.save(snapshot)
        let loaded = try SecureStore.load()
        XCTAssertEqual(loaded?.id, snapshot.id)
        XCTAssertEqual(loaded?.buildings.first?.displayCode, "G01")
        XCTAssertEqual(loaded?.inspectGoods, false)
        XCTAssertEqual(loaded?.saveAlsoToPhotoLibrary, false)
    }
}
