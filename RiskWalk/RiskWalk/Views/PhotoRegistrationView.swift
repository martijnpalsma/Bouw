import PhotosUI
import SwiftUI
import UIKit

struct PhotoRegistrationView: View {
    @EnvironmentObject var data: InspectionData
    @EnvironmentObject var permissions: PermissionManager
    @State private var selectedPhotoId: UUID?
    @State private var filterOption: PhotoFilter = .all
    @State private var pickerItem: PhotosPickerItem?
    @State private var permissionAlert: String?

    enum PhotoFilter: String, CaseIterable {
        case all = "Alle foto's"
        case tekortkomingen = "Tekortkomingen"
        case electrical = "Elektrische installatie"
        case fire = "Brand"
        case accu = "Acculaden"
        case hazmat = "Gevaarlijke stoffen"
        case security = "Inbraak"
        case water = "Water/storm"
    }

    private var filteredPhotos: [InspectionPhoto] {
        switch filterOption {
        case .all:
            return data.photos
        case .tekortkomingen:
            return data.photos.filter { $0.status == .shortage || $0.status == .attention }
        case .electrical:
            return data.photos.filter { $0.topic?.contains("Elektrische") == true }
        case .fire:
            return data.photos.filter { $0.topic?.localizedCaseInsensitiveContains("brand") == true }
        case .accu:
            return data.photos.filter { $0.topic?.localizedCaseInsensitiveContains("accu") == true }
        case .hazmat:
            return data.photos.filter { $0.topic?.contains("Gevaarlijke") == true }
        case .security:
            return data.photos.filter { $0.topic?.contains("Inbraak") == true }
        case .water:
            return data.photos.filter {
                $0.topic?.contains("Water") == true || $0.topic?.contains("Storm") == true
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Menu {
                    ForEach(PhotoFilter.allCases, id: \.self) { filter in
                        Button {
                            filterOption = filter
                        } label: {
                            HStack {
                                Text(filter.rawValue)
                                if filterOption == filter { Image(systemName: "checkmark") }
                            }
                        }
                    }
                } label: {
                    HStack {
                        Text(filterOption.rawValue)
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .foregroundStyle(.primary)
                .padding()

                ScrollView {
                    if filteredPhotos.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "photo.on.rectangle")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            Text("Nog geen foto's gemaakt")
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                            ForEach(Array(filteredPhotos.enumerated()), id: \.element.id) { index, photo in
                                Button {
                                    selectedPhotoId = photo.id
                                } label: {
                                    photoCell(photo: photo, index: index)
                                }
                                .foregroundStyle(.primary)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Foto's (\(filteredPhotos.count))")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Image(systemName: "photo.badge.plus")
                    }
                }
            }
            .onChange(of: pickerItem) { _, item in
                guard let item else { return }
                Task {
                    let ok = await permissions.requestPhotoLibraryReadAccess()
                    guard ok else {
                        permissionAlert = "Toegang tot foto's is nodig om bestaande afbeeldingen te koppelen."
                        return
                    }
                    if let dataBytes = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: dataBytes) {
                        _ = data.addPhoto(
                            image: image,
                            building: nil,
                            topic: nil,
                            alsoSaveToPhotoLibrary: false
                        )
                    }
                    pickerItem = nil
                }
            }
            .sheet(isPresented: Binding(
                get: { selectedPhotoId != nil },
                set: { if !$0 { selectedPhotoId = nil } }
            )) {
                if let id = selectedPhotoId,
                   let index = data.photos.firstIndex(where: { $0.id == id }) {
                    PhotoDetailView(photo: $data.photos[index], photoNumber: index + 1)
                }
            }
            .alert("Toegang nodig", isPresented: Binding(
                get: { permissionAlert != nil },
                set: { if !$0 { permissionAlert = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(permissionAlert ?? "")
            }
        }
    }

    @ViewBuilder
    private func photoCell(photo: InspectionPhoto, index: Int) -> some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                if let image = photo.loadThumbnail() {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 150, height: 150)
                        .overlay {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.secondary)
                        }
                }

                if let status = photo.status {
                    Circle()
                        .fill(status.color)
                        .frame(width: 20, height: 20)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .padding(4)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Foto \(String(format: "%03d", photo.photoNumber > 0 ? photo.photoNumber : index + 1))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let code = photo.buildingDisplayCode {
                    Text(code).font(.caption.weight(.semibold))
                }
                if let topic = photo.topic {
                    Text(topic)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct PhotoDetailView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var data: InspectionData
    @Binding var photo: InspectionPhoto
    let photoNumber: Int

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let image = photo.loadFullImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView(
                            "Foto niet beschikbaar",
                            systemImage: "photo",
                            description: Text("Het bestand ontbreekt of is niet leesbaar.")
                        )
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Foto \(String(format: "%03d", photoNumber))")
                            .font(.headline)

                        if let code = photo.buildingDisplayCode {
                            InfoRow(label: "Gebouw", value: code)
                        }
                        if let topic = photo.topic {
                            InfoRow(label: "Onderwerp", value: topic)
                        }

                        Picker("Status", selection: Binding(
                            get: { photo.status },
                            set: {
                                photo.status = $0
                                data.scheduleAutosave()
                            }
                        )) {
                            Text("Geen").tag(Optional<InspectionStatus>.none)
                            ForEach(InspectionStatus.allCases, id: \.self) { status in
                                Text(status.rawValue).tag(Optional(status))
                            }
                        }

                        TextField("Omschrijving", text: $photo.note)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: photo.note) { _, _ in data.scheduleAutosave() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
            .navigationTitle("Foto details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sluit") { dismiss() }
                }
            }
        }
    }
}
