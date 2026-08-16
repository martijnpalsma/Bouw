import SwiftUI

@main
struct RiskWalkApp: App {
    @StateObject private var inspectionData = InspectionData()
    @StateObject private var permissions = PermissionManager()
    @StateObject private var appLock = AppLockService()
    @StateObject private var router = AppRouter()
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
                        .environmentObject(router)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .background, .inactive:
                    inspectionData.saveData()
                    router.refreshIndex()
                    if phase == .background {
                        appLock.lockIfNeeded()
                    }
                case .active:
                    router.refreshIndex()
                @unknown default:
                    break
                }
            }
            .onAppear {
                router.refreshIndex()
            }
        }
    }
}
