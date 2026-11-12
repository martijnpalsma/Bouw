//
//  ResultsView.swift
//  FotoAnalyseApp
//
//  View voor analyse resultaten
//

import SwiftUI

struct ResultsView: View {
    let response: AnalysisResponse
    @EnvironmentObject var analysisService: AnalysisService
    @State private var answerText = ""
    @State private var showingAnswerSheet = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Analyse Compleet")
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            
            // Demo warning
            if response.demoResponse == true {
                HStack {
                    Image(systemName: "info.circle.fill")
                    Text("Demo Mode - Configureer OPENAI_API_KEY voor echte analyse")
                        .font(.caption)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.orange.opacity(0.3))
                .cornerRadius(8)
            }
            
            if let analysis = response.analysis {
                // Constructie
                if let constructie = analysis.constructie {
                    AnalysisCard(
                        title: "🏗️ Constructie",
                        icon: "building.2",
                        color: Color(hex: "667eea")
                    ) {
                        InfoRow(label: "Type", value: constructie.type)
                        InfoRow(label: "Draagconstructie", value: constructie.draagconstructie)
                        if let verdiepingen = constructie.verdiepingen {
                            InfoRow(label: "Verdiepingen", value: "\(verdiepingen)")
                        }
                        InfoRow(label: "Details", value: constructie.details)
                    }
                }
                
                // Materialen
                if let materialen = analysis.materialen {
                    AnalysisCard(
                        title: "🧱 Materialen",
                        icon: "square.stack.3d.up",
                        color: Color(hex: "764ba2")
                    ) {
                        ListRow(label: "Gevel", items: materialen.gevel)
                        ListRow(label: "Dak", items: materialen.dak)
                        ListRow(label: "Kozijnen", items: materialen.kozijnen)
                        InfoRow(label: "Fundering", value: materialen.fundering)
                        ListRow(label: "Overig", items: materialen.overig)
                    }
                }
                
                // Isolatie
                if let isolatie = analysis.isolatie {
                    AnalysisCard(
                        title: "🌡️ Isolatie",
                        icon: "thermometer.medium",
                        color: Color.orange
                    ) {
                        ListRow(label: "Geschat", items: isolatie.geschat)
                        if let waarschijnlijkheid = isolatie.waarschijnlijkheid {
                            HStack {
                                Text("Waarschijnlijkheid:")
                                    .font(.subheadline.bold())
                                Spacer()
                                BetrouwbaarheidBadge(level: waarschijnlijkheid)
                            }
                        }
                        ListRow(label: "Aanbevelingen", items: isolatie.aanbevelingen)
                    }
                }
                
                // Staat
                if let staat = analysis.staat {
                    AnalysisCard(
                        title: "📋 Staat van het Gebouw",
                        icon: "checklist",
                        color: Color.blue
                    ) {
                        InfoRow(label: "Algemeen", value: staat.algemeen)
                        InfoRow(label: "Onderhoud", value: staat.onderhoud)
                        ListRow(label: "Aandachtspunten", items: staat.aandachtspunten)
                    }
                }
                
                // Bouwperiode
                if let bouwperiode = analysis.bouwperiode {
                    AnalysisCard(
                        title: "📅 Bouwperiode",
                        icon: "calendar",
                        color: Color.purple
                    ) {
                        InfoRow(label: "Geschat", value: bouwperiode.geschat)
                        ListRow(label: "Indicatoren", items: bouwperiode.indicatoren)
                    }
                }
                
                // Betrouwbaarheid & Conclusie
                if analysis.betrouwbaarheid != nil || analysis.conclusie != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        if let betrouwbaarheid = analysis.betrouwbaarheid {
                            HStack {
                                Text("🎯 Betrouwbaarheid:")
                                    .font(.headline)
                                Spacer()
                                BetrouwbaarheidBadge(level: betrouwbaarheid)
                            }
                        }
                        
                        if let conclusie = analysis.conclusie {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("✅ Conclusie")
                                    .font(.headline)
                                Text(conclusie)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
                
                // Verduidelijkingsvragen
                if let vragen = analysis.verduidelijkingsvragen, !vragen.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "questionmark.circle.fill")
                                .foregroundColor(.orange)
                            Text("Verduidelijkingsvragen")
                                .font(.headline)
                        }
                        
                        ForEach(vragen) { vraag in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(vraag.vraag)
                                    .font(.subheadline.bold())
                                Text("Reden: \(vraag.reden)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        Button {
                            showingAnswerSheet = true
                        } label: {
                            Label("Beantwoord Vragen", systemImage: "text.bubble")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.orange)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
        .sheet(isPresented: $showingAnswerSheet) {
            AnswerSheet(
                response: response,
                answerText: $answerText,
                onSubmit: {
                    if let filename = response.filename {
                        Task {
                            await analysisService.clarifyAnalysis(
                                filename: filename,
                                answer: answerText
                            )
                            showingAnswerSheet = false
                            answerText = ""
                        }
                    }
                }
            )
        }
    }
}

// MARK: - Analysis Card
struct AnalysisCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            content
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String?
    
    var body: some View {
        if let value = value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
            }
        }
    }
}

// MARK: - List Row
struct ListRow: View {
    let label: String
    let items: [String]?
    
    var body: some View {
        if let items = items, !items.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                ForEach(items, id: \.self) { item in
                    HStack(spacing: 8) {
                        Text("•")
                        Text(item)
                            .font(.subheadline)
                    }
                }
            }
        }
    }
}

// MARK: - Betrouwbaarheid Badge
struct BetrouwbaarheidBadge: View {
    let level: String
    
    var color: Color {
        switch level.lowercased() {
        case "hoog": return .green
        case "middel": return .orange
        case "laag": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        Text(level.uppercased())
            .font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
    }
}

// MARK: - Answer Sheet
struct AnswerSheet: View {
    let response: AnalysisResponse
    @Binding var answerText: String
    let onSubmit: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Beantwoord de vragen om de analyse te verfijnen")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                TextEditor(text: $answerText)
                    .frame(minHeight: 150)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                
                Button("Verstuur Antwoord") {
                    onSubmit()
                }
                .buttonStyle(.borderedProminent)
                .disabled(answerText.isEmpty)
                
                Spacer()
            }
            .navigationTitle("Verduidelijking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuleer") {
                        dismiss()
                    }
                }
            }
        }
    }
}
