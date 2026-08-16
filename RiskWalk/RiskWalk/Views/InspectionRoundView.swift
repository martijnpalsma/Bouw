import AVFoundation
import Speech
import SwiftUI

struct InspectionRoundView: View {
    @EnvironmentObject var data: InspectionData
    @EnvironmentObject var permissions: PermissionManager
    @State private var currentTopicIndex = 0
    @State private var selectedBuildingId: UUID?
    @State private var showingCamera = false
    @State private var showingNote = false
    @State private var noteText = ""
    @State private var isRecording = false
    @State private var permissionAlert: String?
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "nl-NL"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()

    private var selectedBuilding: Building? {
        data.buildings.first { $0.id == selectedBuildingId }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 12) {
                    Menu {
                        ForEach(data.topics.indices, id: \.self) { index in
                            Button {
                                currentTopicIndex = index
                            } label: {
                                HStack {
                                    Text(data.topics[index].name)
                                    if currentTopicIndex == index {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        menuLabel("Onderwerp: \(safeTopicName)")
                    }
                    .foregroundStyle(.primary)

                    if !data.buildings.isEmpty {
                        Menu {
                            ForEach(data.buildings) { building in
                                Button {
                                    selectedBuildingId = building.id
                                } label: {
                                    HStack {
                                        Text("\(building.displayCode) - \(building.name)")
                                        if selectedBuildingId == building.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            menuLabel(
                                selectedBuilding.map { "\($0.displayCode) - \($0.name)" } ?? "Selecteer gebouw"
                            )
                        }
                        .foregroundStyle(.primary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                ScrollView {
                    VStack(spacing: 20) {
                        if data.buildings.isEmpty {
                            Text("Voeg eerst gebouwen toe in Dossier")
                                .foregroundStyle(.secondary)
                                .padding()
                        } else if let building = selectedBuilding {
                            topicContent(for: building)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Inspectieronde")
            .sheet(isPresented: $showingCamera) {
                if let building = selectedBuilding {
                    CameraView(building: building, topic: safeTopicName)
                        .environmentObject(data)
                        .environmentObject(permissions)
                }
            }
            .sheet(isPresented: $showingNote) {
                noteSheet
            }
            .alert("Toegang nodig", isPresented: Binding(
                get: { permissionAlert != nil },
                set: { if !$0 { permissionAlert = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(permissionAlert ?? "")
            }
            .onAppear {
                if selectedBuildingId == nil {
                    selectedBuildingId = data.buildings.first?.id
                }
                if currentTopicIndex >= data.topics.count {
                    currentTopicIndex = 0
                }
            }
        }
    }

    private var safeTopicName: String {
        guard data.topics.indices.contains(currentTopicIndex) else { return "—" }
        return data.topics[currentTopicIndex].name
    }

    private func menuLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func topicContent(for building: Building) -> some View {
        let buildingKey = building.id.uuidString

        VStack(spacing: 16) {
            Text(safeTopicName)
                .font(.title2.bold())
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(spacing: 12) {
                ForEach(InspectionStatus.allCases, id: \.self) { status in
                    Button {
                        data.topics[currentTopicIndex].buildingStatuses[buildingKey] = status
                        data.scheduleAutosave()
                    } label: {
                        HStack {
                            Text(status.rawValue).fontWeight(.medium)
                            Spacer()
                            if data.topics[currentTopicIndex].buildingStatuses[buildingKey] == status {
                                Image(systemName: "checkmark.circle.fill")
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(
                            data.topics[currentTopicIndex].buildingStatuses[buildingKey] == status
                            ? status.color.opacity(0.2)
                            : Color(.systemGray6)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .foregroundStyle(.primary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    Task {
                        let ok = await permissions.requestCameraAccess()
                        if ok {
                            showingCamera = true
                        } else {
                            permissionAlert = "Camera-toegang is nodig om inspectiefoto's te maken. Schakel dit in via Instellingen."
                        }
                    }
                } label: {
                    actionButton(icon: "camera.fill", title: "Foto", color: .blue)
                }

                Button {
                    Task { await toggleRecording() }
                } label: {
                    actionButton(
                        icon: isRecording ? "stop.circle.fill" : "mic.fill",
                        title: isRecording ? "Stop" : "Dicteren",
                        color: isRecording ? .red : .blue
                    )
                }

                Button {
                    noteText = data.topics[currentTopicIndex].buildingNotes[buildingKey] ?? ""
                    showingNote = true
                } label: {
                    actionButton(icon: "note.text", title: "Notitie", color: .blue)
                }
            }

            if let notes = data.topics[currentTopicIndex].buildingVoiceNotes[buildingKey], !notes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dictaten:").font(.caption).foregroundStyle(.secondary)
                    ForEach(notes) { note in
                        Text(note.text)
                            .font(.body)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                }
            }

            if let note = data.topics[currentTopicIndex].buildingNotes[buildingKey], !note.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Notitie:").font(.caption).foregroundStyle(.secondary)
                    Text(note)
                        .font(.body)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            HStack {
                Button {
                    if currentTopicIndex > 0 { currentTopicIndex -= 1 }
                } label: {
                    Label("Vorige", systemImage: "chevron.left")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(currentTopicIndex == 0)
                .opacity(currentTopicIndex == 0 ? 0.5 : 1)

                Button {
                    if currentTopicIndex < data.topics.count - 1 { currentTopicIndex += 1 }
                } label: {
                    Label("Volgende", systemImage: "chevron.right")
                        .labelStyle(.trailingIcon)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .disabled(currentTopicIndex >= data.topics.count - 1)
                .opacity(currentTopicIndex >= data.topics.count - 1 ? 0.5 : 1)
            }
        }
        .padding(.horizontal)
    }

    private func actionButton(icon: String, title: String, color: Color) -> some View {
        VStack {
            Image(systemName: icon).font(.title2)
            Text(title).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var noteSheet: some View {
        NavigationStack {
            TextEditor(text: $noteText)
                .padding()
                .navigationTitle("Notitie")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuleer") { showingNote = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Bewaar") {
                            if let building = selectedBuilding {
                                data.topics[currentTopicIndex].buildingNotes[building.id.uuidString] = noteText
                                data.scheduleAutosave()
                            }
                            showingNote = false
                        }
                    }
                }
        }
    }

    private func toggleRecording() async {
        if isRecording {
            stopRecording()
            return
        }
        let ok = await permissions.prepareDictationAccess()
        guard ok else {
            permissionAlert = "Microfoon- en spraakherkenningstoegang zijn nodig om te dicteren."
            return
        }
        startRecording()
    }

    private func startRecording() {
        guard let building = selectedBuilding else { return }
        let buildingKey = building.id.uuidString

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            recognitionRequest.requiresOnDeviceRecognition = true
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            try audioEngine.start()
            isRecording = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, _ in
                guard let result, result.isFinal else { return }
                let voiceNote = VoiceNote(text: result.bestTranscription.formattedString, date: Date())
                Task { @MainActor in
                    var notes = data.topics[currentTopicIndex].buildingVoiceNotes[buildingKey] ?? []
                    notes.append(voiceNote)
                    data.topics[currentTopicIndex].buildingVoiceNotes[buildingKey] = notes
                    data.scheduleAutosave()
                }
            }
        } catch {
            isRecording = false
        }
    }

    private func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var data: InspectionData
    @EnvironmentObject var permissions: PermissionManager
    let building: Building
    let topic: String

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                _ = parent.data.addPhoto(
                    image: image,
                    building: parent.building,
                    topic: parent.topic,
                    alsoSaveToPhotoLibrary: parent.data.saveAlsoToPhotoLibrary
                )
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
