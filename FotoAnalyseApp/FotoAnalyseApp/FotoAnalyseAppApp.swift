//
//  FotoAnalyseAppApp.swift
//  FotoAnalyseApp
//
//  AI-powered Gebouw Foto Analyse
//

import SwiftUI

@main
struct FotoAnalyseAppApp: App {
    @StateObject private var analysisService = AnalysisService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(analysisService)
        }
    }
}
