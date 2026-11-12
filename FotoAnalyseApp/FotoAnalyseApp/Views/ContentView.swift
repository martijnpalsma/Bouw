//
//  ContentView.swift
//  FotoAnalyseApp
//
//  Hoofd view voor foto upload en analyse
//

import SwiftUI
import PhotosUI

struct ContentView: View {
    @EnvironmentObject var analysisService: AnalysisService
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showCamera = false
    @State private var showSettings = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient achtergrond
                LinearGradient(
                    colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerView
                        
                        // Status indicator
                        statusView
                        
                        // Upload sectie
                        uploadSection
                        
                        // Resultaten
                        if case .completed(let response) = analysisService.uploadState {
                            ResultsView(response: response)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                        
                        // Error
                        if case .error(let message) = analysisService.uploadState {
                            errorView(message)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showCamera) {
                CameraView(selectedImage: $selectedImage)
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        await analysisService.uploadAndAnalyze(image: image)
                    }
                }
            }
            .task {
                await analysisService.checkHealth()
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "building.2")
                .font(.system(size: 60))
                .foregroundColor(.white)
            
            Text("Gebouw Foto Analyse")
                .font(.title.bold())
                .foregroundColor(.white)
            
            Text("AI-powered analyse van constructie en materialen")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Status View
    private var statusView: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(analysisService.isHealthy ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            
            Text(analysisService.isHealthy ? "API Verbonden" : "API Niet Bereikbaar")
                .font(.caption)
            
            if analysisService.isHealthy && !analysisService.apiConfigured {
                Text("• Demo Mode")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.2))
        .cornerRadius(20)
    }
    
    // MARK: - Upload Section
    private var uploadSection: some View {
        VStack(spacing: 16) {
            // Preview van geselecteerde foto
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 300)
                    .cornerRadius(12)
                    .shadow(radius: 8)
            } else {
                // Upload placeholder
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("Selecteer een gebouwfoto")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [8]))
                )
            }
            
            // Upload knoppen
            if case .idle = analysisService.uploadState {
                HStack(spacing: 12) {
                    // Foto bibliotheek
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Foto Bibliotheek", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(hex: "667eea"))
                            .cornerRadius(12)
                            .font(.headline)
                    }
                    
                    // Camera
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .foregroundColor(Color(hex: "667eea"))
                            .cornerRadius(12)
                            .font(.headline)
                    }
                }
            }
            
            // Loading indicator
            if case .uploading = analysisService.uploadState {
                loadingView("Uploaden...")
            } else if case .analyzing = analysisService.uploadState {
                loadingView("AI analyseert foto...")
            }
            
            // Nieuwe analyse knop
            if case .completed = analysisService.uploadState {
                Button {
                    selectedImage = nil
                    analysisService.reset()
                } label: {
                    Label("Nieuwe Analyse", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .foregroundColor(Color(hex: "667eea"))
                        .cornerRadius(12)
                        .font(.headline)
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
    
    // MARK: - Loading View
    private func loadingView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text(message)
                .font(.headline)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
    
    // MARK: - Error View
    private func errorView(_ message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Button("Opnieuw") {
                analysisService.reset()
                selectedImage = nil
            }
            .font(.subheadline.bold())
            .foregroundColor(.white)
        }
        .padding()
        .background(Color.red.opacity(0.3))
        .cornerRadius(12)
        .transition(.opacity)
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
