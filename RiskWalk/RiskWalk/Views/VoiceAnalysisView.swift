import AVFoundation
import Speech
import SwiftUI

#if canImport(FoundationModels)
import FoundationModels
#endif

struct VoiceAnalysisView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var data: InspectionData
    @EnvironmentObject var permissions: PermissionManager

    @State private var isRecording = false
    @State private var transcribedText = ""
    @State private var isAnalyzing = false
    @State private var analysisResult = ""
    @State private var permissionAlert: String?
    @State private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "nl-NL"))
    @State private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    @State private var recognitionTask: SFSpeechRecognitionTask?
    @State private var audioEngine = AVAudioEngine()
    @State private var onDeviceModelAvailable = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if isRecording {
                        recordingState
                    } else if !transcribedText.isEmpty {
                        reviewState
                    } else {
                        idleState
                    }
                }
            }
            .navigationTitle("Vertel wat u ziet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") {
                        if isRecording { stopRecording() }
                        dismiss()
                    }
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
            .onAppear {
                checkOnDeviceModel()
            }
        }
    }

    private var idleState: some View {
        VStack(spacing: 16) {
            Image(systemName: "mic.circle")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            Text("Spreek in wat u ziet tijdens de inspectie")
                .font(.headline)
                .multilineTextAlignment(.center)
            Text("Bijvoorbeeld: \"We staan nu in gebouw G02. Stalen draagconstructie…\"")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("Spraak wordt verwerkt via Apple-spraakherkenning. Er wordt geen RiskWalk-cloud gebruikt.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                Task { await beginRecording() }
            } label: {
                Label("Start opname", systemImage: "mic.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private var recordingState: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.red)
            Text("Aan het opnemen...").font(.headline)
            if !transcribedText.isEmpty {
                Text(transcribedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            Button(action: stopRecording) {
                Label("Stop opname", systemImage: "stop.circle.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private var reviewState: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Opname:").font(.headline)
            Text(transcribedText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            if onDeviceModelAvailable {
                Button {
                    Task { await analyzeOnDevice() }
                } label: {
                    HStack {
                        if isAnalyzing { ProgressView().tint(.white) }
                        else { Image(systemName: "brain") }
                        Text(isAnalyzing ? "Analyseren..." : "Analyseer op apparaat")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(isAnalyzing)

                Text("AI-analyse gebeurt lokaal op dit apparaat (Apple Foundation Models), niet via een externe RiskWalk-API.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text("On-device AI is op dit apparaat niet beschikbaar. De transcriptie blijft lokaal bewaard.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if !analysisResult.isEmpty {
                Text("Analyse:").font(.headline)
                Text(analysisResult)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            Button {
                transcribedText = ""
                analysisResult = ""
            } label: {
                Text("Nieuwe opname")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }

    private func beginRecording() async {
        let ok = await permissions.prepareDictationAccess()
        guard ok else {
            permissionAlert = "Microfoon- en spraakherkenningstoegang zijn nodig."
            return
        }
        transcribedText = ""
        analysisResult = ""
        startRecording()
    }

    private func startRecording() {
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
                if let result {
                    Task { @MainActor in
                        transcribedText = result.bestTranscription.formattedString
                    }
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

    private func checkOnDeviceModel() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            onDeviceModelAvailable = SystemLanguageModel.default.availability == .available
        }
        #else
        onDeviceModelAvailable = false
        #endif
    }

    private func analyzeOnDevice() async {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard SystemLanguageModel.default.availability == .available else { return }
            isAnalyzing = true
            do {
                let session = LanguageModelSession(instructions: """
                Je bent een assistent die inspectie-notities analyseert.
                Extraheer gebouwnummer, constructie, materialen, risico's en vervolgvragen.
                Geef een gestructureerde samenvatting in het Nederlands.
                Verzin geen feiten die niet in de tekst staan.
                """)
                let response = try await session.respond(to: transcribedText)
                analysisResult = response.content
            } catch {
                analysisResult = "Analyse mislukt. De transcriptie blijft lokaal beschikbaar."
            }
            isAnalyzing = false
            return
        }
        #endif
        analysisResult = "On-device AI is niet beschikbaar op dit systeem."
    }
}
