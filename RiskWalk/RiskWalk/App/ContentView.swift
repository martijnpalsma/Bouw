import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @EnvironmentObject private var inspectionData: InspectionData

    var body: some View {
        TabView(selection: $selectedTab) {
            DossierView()
                .tabItem { Label("Dossier", systemImage: "building.2") }
                .tag(0)

            InspectionRoundView()
                .tabItem { Label("Inspectie", systemImage: "checklist") }
                .tag(1)

            QuestionnaireView()
                .tabItem { Label("Vragenlijst", systemImage: "list.bullet.clipboard") }
                .tag(2)

            PhotoRegistrationView()
                .tabItem { Label("Foto's", systemImage: "photo.on.rectangle") }
                .tag(3)

            SummaryView()
                .tabItem { Label("Samenvatting", systemImage: "doc.text") }
                .tag(4)
        }
    }
}

struct AppLockView: View {
    @ObservedObject var appLock: AppLockService

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("RiskWalk is vergrendeld")
                .font(.title2.bold())

            Text("Inspectiegegevens zijn lokaal beschermd. Ontgrendel met Face ID, Touch ID of toegangscode.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Ontgrendelen") {
                Task { await appLock.authenticate() }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .task {
            await appLock.authenticate()
        }
    }
}
