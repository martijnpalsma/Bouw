import Foundation
import SwiftUI

@MainActor
final class AppRouter: ObservableObject {
    @Published var selectedFrame: AppFrame = .dossier
    @Published var isShowingDashboard: Bool = true
    @Published var dossierSummaries: [DossierSummary] = []
    @Published var showArchived: Bool = false

    var visibleSummaries: [DossierSummary] {
        dossierSummaries
            .filter { showArchived ? $0.isArchived : !$0.isArchived }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func refreshIndex() {
        do {
            dossierSummaries = try SecureStore.loadIndex()
        } catch {
            AppLogger.dossierSaveFailed(error)
        }
    }

    func openDashboard() {
        isShowingDashboard = true
    }

    func openWorkspace(frame: AppFrame = .dossier) {
        selectedFrame = frame
        isShowingDashboard = false
    }
}
