import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject var data: InspectionData
    @State private var selectedBuildingId: UUID?

    private var selectedBuilding: Building? {
        data.buildings.first { $0.id == selectedBuildingId }
    }

    private var activeQuestions: [Question] {
        data.activeQuestions(for: selectedBuildingId)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !data.buildings.isEmpty {
                    Menu {
                        Button {
                            selectedBuildingId = nil
                        } label: {
                            HStack {
                                Text("Algemeen (locatie)")
                                if selectedBuildingId == nil { Image(systemName: "checkmark") }
                            }
                        }
                        ForEach(data.buildings) { building in
                            Button {
                                selectedBuildingId = building.id
                            } label: {
                                HStack {
                                    Text("\(building.displayCode) - \(building.name)")
                                    if selectedBuildingId == building.id { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedBuilding.map { "\($0.displayCode) - \($0.name)" } ?? "Algemeen (locatie)")
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Image(systemName: "chevron.up.chevron.down").font(.caption)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .foregroundStyle(.primary)
                    .padding()
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        if data.selectedBusinessTypes.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 50))
                                    .foregroundStyle(.secondary)
                                Text("Selecteer eerst het soort bedrijf in Dossier")
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 100)
                        } else {
                            ForEach(activeQuestions) { question in
                                QuestionRowView(question: question, buildingId: selectedBuildingId)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Vragenlijst")
        }
    }
}

struct QuestionRowView: View {
    @EnvironmentObject var data: InspectionData
    let question: Question
    let buildingId: UUID?

    private var answerKey: String {
        data.answerKey(questionId: question.id, buildingId: buildingId)
    }

    private var currentAnswer: Answer? {
        data.answers[answerKey]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question.text)
                .font(.subheadline.weight(.medium))

            switch question.type {
            case .yesNo:
                HStack(spacing: 12) {
                    ForEach(["Ja", "Nee", "Onbekend", "N.v.t."], id: \.self) { option in
                        Button {
                            data.answers[answerKey] = Answer(
                                value: option,
                                note: currentAnswer?.note,
                                timestamp: Date()
                            )
                            data.scheduleAutosave()
                            data.detectMissingInformation()
                        } label: {
                            Text(option)
                                .font(.subheadline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(currentAnswer?.value == option ? optionColor(option) : Color(.systemGray6))
                                .foregroundStyle(currentAnswer?.value == option ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

            case .text:
                TextField("Antwoord", text: answerBinding)
                    .textFieldStyle(.roundedBorder)

            case .number:
                TextField("Aantal", text: answerBinding)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)

            case .multipleChoice:
                EmptyView()
            }

            if currentAnswer != nil {
                TextField("Notitie (optioneel)", text: noteBinding)
                    .font(.caption)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var answerBinding: Binding<String> {
        Binding(
            get: { currentAnswer?.value ?? "" },
            set: { newValue in
                data.answers[answerKey] = Answer(value: newValue, note: currentAnswer?.note, timestamp: Date())
                data.scheduleAutosave()
            }
        )
    }

    private var noteBinding: Binding<String> {
        Binding(
            get: { currentAnswer?.note ?? "" },
            set: { newValue in
                var answer = currentAnswer ?? Answer(value: "", note: nil, timestamp: Date())
                answer.note = newValue
                data.answers[answerKey] = answer
                data.scheduleAutosave()
            }
        )
    }

    private func optionColor(_ option: String) -> Color {
        switch option {
        case "Ja": return .green
        case "Nee": return .red
        case "Onbekend": return .orange
        case "N.v.t.": return .gray
        default: return .blue
        }
    }
}
