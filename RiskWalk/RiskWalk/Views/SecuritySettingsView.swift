import SwiftUI

struct SecuritySettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var data: InspectionData
    @EnvironmentObject var appLock: AppLockService

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("App-vergrendeling (Face ID / toegangscode)", isOn: $appLock.isLockEnabled)
                    Text("Bij vergrendeling blijven inspectiegegevens lokaal op dit apparaat. Ontgrendelen is vereist na achtergrond.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Toegang")
                }

                Section {
                    Toggle("Foto's ook in Fotobibliotheek bewaren", isOn: $data.saveAlsoToPhotoLibrary)
                        .onChange(of: data.saveAlsoToPhotoLibrary) { _, _ in data.scheduleAutosave() }
                    Text("Standaard worden foto's alleen veilig in het inspectiedossier opgeslagen (niet in Fotos). Schakel dit alleen in wanneer u een kopie in de systeem-fotobibliotheek wilt.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Foto's")
                }

                Section {
                    LabeledContent("Opslaglocatie", value: "Lokaal (Application Support)")
                    LabeledContent("Bestandsbescherming", value: "completeUntilFirstUserAuthentication")
                    LabeledContent("Tracking", value: "Uit")
                    LabeledContent("Externe cloud-sync", value: "Niet actief")
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Dossiergegevens en foto's worden niet naar RiskWalk-servers gestuurd. Spraakherkenning gebruikt Apple-voorzieningen volgens uw iOS-instellingen. Optionele AI-analyse (indien beschikbaar) gebeurt op het apparaat.")
                }
            }
            .navigationTitle("Privacy & beveiliging")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sluit") { dismiss() }
                }
            }
        }
    }
}
