import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var data: InspectionData
    @EnvironmentObject private var router: AppRouter
    @EnvironmentObject private var appLock: AppLockService

    @State private var searchText = ""
    @State private var dossierPendingDelete: DossierSummary?
    @State private var exportText = ""
    @State private var showingExport = false
    @State private var showingSecurity = false

    private var filtered: [DossierSummary] {
        let base = router.visibleSummaries
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return base }
        return base.filter {
            $0.displayName.localizedCaseInsensitiveContains(query)
                || $0.place.localizedCaseInsensitiveContains(query)
                || $0.status.rawValue.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerStats

                    HStack {
                        Text(router.showArchived ? "Archief" : "Actieve dossiers")
                            .font(.title2.bold())
                        Spacer()
                        Button {
                            data.createNewDossier()
                            router.refreshIndex()
                            router.openWorkspace(frame: .dossier)
                        } label: {
                            Label("Nieuwe inspectie", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if filtered.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filtered) { summary in
                                DossierCardView(
                                    summary: summary,
                                    onOpen: { open(summary, frame: .dossier) },
                                    onInspect: { open(summary, frame: .inspection) },
                                    onPhotos: { open(summary, frame: .photos) },
                                    onSummary: { open(summary, frame: .summary) },
                                    onDuplicate: { duplicate(summary) },
                                    onArchive: { archive(summary) },
                                    onExport: { export(summary) },
                                    onDelete: { dossierPendingDelete = summary }
                                )
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .searchable(text: $searchText, prompt: "Zoek dossier, plaats of status")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Toggle(isOn: $router.showArchived) {
                        Image(systemName: router.showArchived ? "archivebox.fill" : "archivebox")
                    }
                    .toggleStyle(.button)
                    .accessibilityLabel("Toon archief")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSecurity = true
                    } label: {
                        Image(systemName: "lock.shield")
                    }
                    .accessibilityLabel("Privacy en beveiliging")
                }
            }
            .onAppear { router.refreshIndex() }
            .sheet(isPresented: $showingSecurity) {
                SecuritySettingsView()
                    .environmentObject(data)
                    .environmentObject(appLock)
            }
            .sheet(isPresented: $showingExport) {
                ExportView(exportText: exportText)
            }
            .alert(
                "Dossier verwijderen?",
                isPresented: Binding(
                    get: { dossierPendingDelete != nil },
                    set: { if !$0 { dossierPendingDelete = nil } }
                ),
                presenting: dossierPendingDelete
            ) { summary in
                Button("Annuleer", role: .cancel) { dossierPendingDelete = nil }
                Button("Verwijder", role: .destructive) {
                    data.deleteDossier(id: summary.id)
                    router.refreshIndex()
                    dossierPendingDelete = nil
                }
            } message: { summary in
                Text("Weet u zeker dat u \"\(summary.displayName)\" wilt verwijderen? Dit kan niet ongedaan worden gemaakt.")
            }
        }
    }

    private var headerStats: some View {
        let active = router.dossierSummaries.filter { !$0.isArchived }
        let inProgress = active.filter { $0.status == .inProgress || $0.status == .followUp }.count
        let ready = active.filter { $0.status == .readyForReport }.count

        return HStack(spacing: 12) {
            DashboardStatChip(title: "Actief", value: "\(active.count)", symbol: "folder")
            DashboardStatChip(title: "Bezig", value: "\(inProgress)", symbol: "figure.walk")
            DashboardStatChip(title: "Rapport", value: "\(ready)", symbol: "doc.badge.clock")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(router.showArchived ? "Geen gearchiveerde dossiers" : "Nog geen inspecties")
                .font(.headline)
            Text(router.showArchived
                 ? "Archiveren bewaart dossiers buiten de actieve lijst."
                 : "Start een nieuwe inspectie om gebouwen, vragen en foto's vast te leggen.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func open(_ summary: DossierSummary, frame: AppFrame) {
        data.openDossier(id: summary.id)
        router.refreshIndex()
        router.openWorkspace(frame: frame)
    }

    private func duplicate(_ summary: DossierSummary) {
        data.openDossier(id: summary.id)
        _ = data.duplicateCurrentDossier()
        router.refreshIndex()
        router.openWorkspace(frame: .dossier)
    }

    private func archive(_ summary: DossierSummary) {
        data.openDossier(id: summary.id)
        data.archiveCurrentDossier(archived: !summary.isArchived)
        router.refreshIndex()
    }

    private func export(_ summary: DossierSummary) {
        data.openDossier(id: summary.id)
        exportText = data.exportText()
        showingExport = true
        AppLogger.reportGenerated(photoCount: data.photos.count)
    }
}

private struct DashboardStatChip: View {
    let title: String
    let value: String
    let symbol: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct DossierCardView: View {
    let summary: DossierSummary
    var onOpen: () -> Void
    var onInspect: () -> Void
    var onPhotos: () -> Void
    var onSummary: () -> Void
    var onDuplicate: () -> Void
    var onArchive: () -> Void
    var onExport: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(summary.displayName)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(summary.status.rawValue)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor.opacity(0.15))
                            .foregroundStyle(statusColor)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }

                    HStack(spacing: 16) {
                        Label(summary.place, systemImage: "mappin.and.ellipse")
                        Label(summary.inspectionDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    ProgressView(value: summary.progress)
                        .tint(.blue)
                    HStack {
                        Text("\(summary.progressPercent)% gereed")
                        Spacer()
                        Text("\(summary.buildingCount) gebouwen · \(summary.photoCount) foto's")
                        if summary.openIssueCount > 0 {
                            Text("· \(summary.openIssueCount) uitzoeken")
                                .foregroundStyle(.orange)
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            // Quick frame switches
            HStack(spacing: 8) {
                frameButton("Openen", symbol: "folder", action: onOpen)
                frameButton("Inspectie", symbol: "checklist", action: onInspect)
                frameButton("Foto's", symbol: "photo", action: onPhotos)
                frameButton("Rapport", symbol: "doc.text", action: onSummary)
            }

            HStack(spacing: 8) {
                Button("Dupliceren", action: onDuplicate)
                Button(summary.isArchived ? "Terugzetten" : "Archiveren", action: onArchive)
                Button("Exporteren", action: onExport)
                Spacer()
                Button("Verwijderen", role: .destructive, action: onDelete)
            }
            .font(.caption)
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var statusColor: Color {
        switch summary.status {
        case .preparation: return .gray
        case .inProgress: return .blue
        case .followUp: return .orange
        case .readyForReport: return .purple
        case .completed: return .green
        }
    }

    private func frameButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.blue.opacity(0.85))
    }
}
