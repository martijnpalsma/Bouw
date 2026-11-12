import SwiftUI

/// Workspace with fast switching between inspection frames.
struct InspectionWorkspaceView: View {
    @EnvironmentObject private var data: InspectionData
    @EnvironmentObject private var router: AppRouter
    @Environment(\.horizontalSizeClass) private var sizeClass

    var body: some View {
        Group {
            if sizeClass == .regular {
                splitWorkspace
            } else {
                compactWorkspace
            }
        }
    }

    private var splitWorkspace: some View {
        NavigationSplitView {
            frameSidebar
        } detail: {
            frameDetail
        }
    }

    private var compactWorkspace: some View {
        VStack(spacing: 0) {
            frameSwitcher
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(uiColor: .systemBackground))
            Divider()
            frameDetail
        }
    }

    private var frameSidebar: some View {
        List {
            Section {
                Button {
                    data.saveData()
                    router.refreshIndex()
                    router.openDashboard()
                } label: {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
            }

            Section("Dossier") {
                Text(data.displayTitle)
                    .font(.headline)
                Text(data.placeLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ProgressView(value: data.progressValue)
                Text("\(Int((data.progressValue * 100).rounded()))% · \(data.lifecycleStatus.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Frames") {
                ForEach(AppFrame.allCases) { frame in
                    Button {
                        router.selectedFrame = frame
                    } label: {
                        Label(frame.title, systemImage: frame.systemImage)
                            .foregroundStyle(router.selectedFrame == frame ? Color.accentColor : .primary)
                            .symbolVariant(router.selectedFrame == frame ? .fill : .none)
                    }
                }
            }

            Section("Snelkoppelingen") {
                if !data.buildings.isEmpty {
                    Text("\(data.buildings.count) gebouwen")
                }
                Text("\(data.photos.count) foto's")
                let openCount = data.openIssues.filter { !$0.isResolved }.count
                if openCount > 0 {
                    Text("\(openCount) uitzoeken")
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("RiskWalk")
        .listStyle(.sidebar)
    }

    private var frameSwitcher: some View {
        VStack(spacing: 8) {
            HStack {
                Button {
                    data.saveData()
                    router.refreshIndex()
                    router.openDashboard()
                } label: {
                    Label("Dashboard", systemImage: "chevron.left")
                }
                Spacer()
                Text(data.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }

            Picker("Frame", selection: $router.selectedFrame) {
                ForEach(AppFrame.allCases) { frame in
                    Text(frame.title).tag(frame)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    @ViewBuilder
    private var frameDetail: some View {
        switch router.selectedFrame {
        case .dossier:
            DossierView()
        case .inspection:
            InspectionRoundView()
        case .questionnaire:
            QuestionnaireView()
        case .photos:
            PhotoRegistrationView()
        case .summary:
            SummaryView()
        }
    }
}
