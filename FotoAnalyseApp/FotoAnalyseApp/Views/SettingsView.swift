//
//  SettingsView.swift
//  FotoAnalyseApp
//
//  Instellingen voor API configuratie
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var analysisService: AnalysisService
    @Environment(\.dismiss) var dismiss
    @State private var apiURL: String = ""
    @State private var showSaveConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Circle()
                            .fill(analysisService.isHealthy ? Color.green : Color.red)
                            .frame(width: 12, height: 12)
                        
                        Text(analysisService.isHealthy ? "Verbonden" : "Niet verbonden")
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Button("Test") {
                            Task {
                                await analysisService.checkHealth()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                } header: {
                    Text("Status")
                }
                
                Section {
                    TextField("API URL", text: $apiURL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .keyboardType(.URL)
                    
                    Text("Bijvoorbeeld: http://localhost:5000")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("API Configuratie")
                } footer: {
                    Text("De Flask API moet draaien op dit adres. Voor lokaal testen gebruik http://localhost:5000")
                }
                
                Section {
                    if analysisService.apiConfigured {
                        Label("AI Analyse actief", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Demo Mode", systemImage: "info.circle.fill")
                            .foregroundColor(.orange)
                        
                        Text("Configureer OPENAI_API_KEY in de Flask backend voor echte AI analyse")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("API Key Status")
                }
                
                Section {
                    Button("Opslaan") {
                        saveSettings()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(apiURL.isEmpty)
                    
                    if showSaveConfirmation {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Instellingen opgeslagen")
                                .font(.subheadline)
                        }
                    }
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flask Backend Starten")
                            .font(.headline)
                        
                        Text("Terminal:")
                            .font(.caption.bold())
                        Text("python app.py")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                        
                        Text("Of gebruik:")
                            .font(.caption.bold())
                            .padding(.top, 4)
                        Text("./start.sh")
                            .font(.system(.caption, design: .monospaced))
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                    }
                } header: {
                    Text("Help")
                }
            }
            .navigationTitle("Instellingen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klaar") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                apiURL = analysisService.baseURL
            }
        }
    }
    
    private func saveSettings() {
        analysisService.baseURL = apiURL
        showSaveConfirmation = true
        
        Task {
            await analysisService.checkHealth()
            
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSaveConfirmation = false
        }
    }
}
