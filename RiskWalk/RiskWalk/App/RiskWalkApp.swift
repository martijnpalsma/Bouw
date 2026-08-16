import SwiftUI

@main
struct RiskWalkApp: App {
    @StateObject private var inspectionData = InspectionData()
    @StateObject private var permissions = PermissionManager()
    @StateObject private var appLock = AppLockService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if appLock.isLockEnabled && !appLock.isUnlocked {
                    AppLockView(appLock: appLock)
                } else {
                    ContentView()
                        .environmentObject(inspectionData)
                        .environmentObject(permissions)
                        .environmentObject(appLock)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background, .inactive:
                    inspectionData.saveData()
                    if phase == .background {
                        appLock.lockIfNeeded()
                    }
                case .active:
                    break
                @unknown default:
                    break
                }
            }
        }
    }
}
