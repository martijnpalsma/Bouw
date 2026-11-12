import SwiftUI

struct SummaryView: View {
    @EnvironmentObject var data: InspectionData
    @EnvironmentObject var permissions: PermissionManager
    @State private var showingVoiceAnalysis = false
    @State private var showingExport = false
    @State private var exportText = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VoiceAnalysisButton(showingVoiceAnalysis: $showingVoiceAnalysis)

                    Button(action: generateExport) {
                        Label("Exporteer inspectie", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Bedrijfsgegevens").font(.headline)
                        if !data.companyName.isEmpty { InfoRow(label: "Bedrijf", value: data.companyName) }
                        if !data.address.isEmpty { InfoRow(label: "Adres", value: data.address) }
                        if !data.contactPerson.isEmpty { InfoRow(label: "Contactpersoon", value: data.contactPerson) }
                        InfoRow(
                            label: "Inspectiedatum",
                            value: data.inspectionDate.formatted(date: .long, time: .omitted)
                        )
                        InfoRow(label: "Status", value: data.lifecycleStatus.rawValue)
                    }

                    findingsSection(title: "Tekortkomingen", items: data.getShortages(), icon: "xmark.circle.fill", color: .red)
                    findingsSection(title: "Aandachtspunten", items: data.getAttentionPoints(), icon: "exclamationmark.triangle.fill", color: .orange)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Foto's").font(.headline)
                        Text("\(data.photos.count) foto's vastgelegd")
                            .foregroundStyle(.secondary)
                        ForEach(data.photos.prefix(20)) { photo in
                            Text(photoExportLine(photo))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gebouwen").font(.headline)
                        ForEach(data.buildings) { building in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(building.displayCode)
                                    .font(.subheadline.weight(.semibold))
                                let count = data.photos.filter { $0.buildingId == building.id }.count
                                Text("\(count) foto's")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Samenvatting")
            .sheet(isPresented: $showingVoiceAnalysis) {
                VoiceAnalysisView()
                    .environmentObject(data)
                    .environmentObject(permissions)
            }
            .sheet(isPresented: $showingExport) {
                ExportView(exportText: exportText)
            }
        }
    }

    @ViewBuilder
    private func findingsSection(
        title: String,
        items: [InspectionData.TopicFinding],
        icon: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title).font(.headline)
            if items.isEmpty {
                Text(title == "Tekortkomingen" ? "Geen tekortkomingen geconstateerd" : "Geen aandachtspunten")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) { item in
                    HStack {
                        Image(systemName: icon).foregroundStyle(color)
                        Text(item.label)
                    }
                }
            }
        }
    }

    private func photoExportLine(_ photo: InspectionPhoto) -> String {
        var parts: [String] = ["Foto \(String(format: "%03d", photo.photoNumber))"]
        if let code = photo.buildingDisplayCode { parts.append(code) }
        if let topic = photo.topic { parts.append(topic) }
        if !photo.note.isEmpty { parts.append(photo.note) }
        return parts.joined(separator: " – ")
    }

    private func generateExport() {
        var text = "INSPECTIE RAPPORT\n==================\n\n"
        text += "BEDRIJFSGEGEVENS\n"
        text += "Bedrijfsnaam: \(data.companyName)\n"
        text += "Adres: \(data.address)\n"
        text += "Contactpersoon: \(data.contactPerson)\n"
        text += "Inspectiedatum: \(data.inspectionDate.formatted(date: .long, time: .omitted))\n"
        text += "Status: \(data.lifecycleStatus.rawValue)\n\n"

        text += "TE INSPECTEREN ONDERDELEN\n"
        if data.inspectBuildings { text += "- Gebouwen\n" }
        if data.inspectInventory { text += "- Inventaris\n" }
        if data.inspectGoods { text += "- Goederen\n" }
        if data.inspectDamage { text += "- Bedrijfsschade\n" }
        text += "\n"

        text += "GEBOUWEN\n"
        for building in data.buildings {
            text += "\n\(building.displayCode) - \(building.name)\n"
            text += String(repeating: "-", count: 40) + "\n"
            let key = building.id.uuidString
            for topic in data.topics {
                if let status = topic.buildingStatuses[key] {
                    text += "\(topic.name): \(status.rawValue)\n"
                    if let note = topic.buildingNotes[key], !note.isEmpty {
                        text += "  Notitie: \(note)\n"
                    }
                    if let voiceNotes = topic.buildingVoiceNotes[key] {
                        for voiceNote in voiceNotes {
                            text += "  Dictaat: \(voiceNote.text)\n"
                        }
                    }
                }
            }
            let buildingPhotos = data.photos.filter { $0.buildingId == building.id }
            text += "Foto's: \(buildingPhotos.count)\n"
            for photo in buildingPhotos {
                text += "  - \(photoExportLine(photo))\n"
            }
        }

        text += "\nTEKORTKOMINGEN\n"
        let shortages = data.getShortages()
        if shortages.isEmpty {
            text += "Geen tekortkomingen geconstateerd\n"
        } else {
            for item in shortages { text += "❌ \(item.label)\n" }
        }

        text += "\nAANDACHTSPUNTEN\n"
        let attention = data.getAttentionPoints()
        if attention.isEmpty {
            text += "Geen aandachtspunten\n"
        } else {
            for item in attention { text += "⚠️ \(item.label)\n" }
        }

        text += "\nFOTOREGISTRATIE\n"
        text += "Totaal aantal foto's: \(data.photos.count)\n"
        for photo in data.photos {
            text += "- \(photoExportLine(photo))\n"
        }

        exportText = text
        showingExport = true
        AppLogger.reportGenerated(photoCount: data.photos.count)
    }
}

struct VoiceAnalysisButton: View {
    @Binding var showingVoiceAnalysis: Bool

    var body: some View {
        Button { showingVoiceAnalysis = true } label: {
            Label("VERTEL WAT U ZIET", systemImage: "mic.fill")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct ExportView: View {
    @Environment(\.dismiss) var dismiss
    let exportText: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("De export bevat inspectiegegevens. Deel alleen met bevoegde ontvangers.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    Text(exportText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)

                    Button {
                        UIPasteboard.general.string = exportText
                    } label: {
                        Label("Kopieer naar klembord", systemImage: "doc.on.doc")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)

                    ShareLink(item: exportText) {
                        Label("Deel rapport", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Exporteer inspectie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sluit") { dismiss() }
                }
            }
        }
    }
}
