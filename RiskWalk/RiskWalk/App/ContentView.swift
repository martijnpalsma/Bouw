import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var router: AppRouter

    var body: some View {
        Group {
            if router.isShowingDashboard {
                DashboardView()
            } else {
                InspectionWorkspaceView()
            }
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
