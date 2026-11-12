//
//  AnalysisModels.swift
//  FotoAnalyseApp
//
//  Data models voor gebouw analyse
//

import Foundation
import UIKit

// MARK: - Analysis Response
struct AnalysisResponse: Codable, Identifiable {
    let id = UUID()
    let success: Bool
    let filename: String?
    let model: String?
    let timestamp: String?
    let analysis: BuildingAnalysis?
    let error: String?
    let demoResponse: Bool?
    
    enum CodingKeys: String, CodingKey {
        case success, filename, model, timestamp, analysis, error
        case demoResponse = "demo_response"
    }
}

// MARK: - Building Analysis
struct BuildingAnalysis: Codable {
    let constructie: Constructie?
    let materialen: Materialen?
    let isolatie: Isolatie?
    let staat: Staat?
    let bouwperiode: Bouwperiode?
    let verduidelijkingsvragen: [Vraag]?
    let conclusie: String?
    let betrouwbaarheid: String?
    
    // Voor raw response fallback
    let rawResponse: String?
    let parsed: Bool?
    
    enum CodingKeys: String, CodingKey {
        case constructie, materialen, isolatie, staat, bouwperiode
        case verduidelijkingsvragen, conclusie, betrouwbaarheid
        case rawResponse = "raw_response"
        case parsed
    }
}

// MARK: - Constructie
struct Constructie: Codable {
    let type: String?
    let draagconstructie: String?
    let verdiepingen: Int?
    let details: String?
}

// MARK: - Materialen
struct Materialen: Codable {
    let gevel: [String]?
    let dak: [String]?
    let kozijnen: [String]?
    let fundering: String?
    let overig: [String]?
}

// MARK: - Isolatie
struct Isolatie: Codable {
    let geschat: [String]?
    let waarschijnlijkheid: String?
    let aanbevelingen: [String]?
}

// MARK: - Staat
struct Staat: Codable {
    let algemeen: String?
    let onderhoud: String?
    let aandachtspunten: [String]?
}

// MARK: - Bouwperiode
struct Bouwperiode: Codable {
    let geschat: String?
    let indicatoren: [String]?
}

// MARK: - Vraag
struct Vraag: Codable, Identifiable {
    let id = UUID()
    let vraag: String
    let reden: String
    
    enum CodingKeys: String, CodingKey {
        case vraag, reden
    }
}

// MARK: - Health Response
struct HealthResponse: Codable {
    let status: String
    let apiConfigured: Bool
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case apiConfigured = "api_configured"
        case timestamp
    }
}

// MARK: - Upload State
enum UploadState {
    case idle
    case uploading
    case analyzing
    case completed(AnalysisResponse)
    case error(String)
}

// MARK: - Photo Item
struct PhotoItem: Identifiable {
    let id = UUID()
    let image: UIImage
    let timestamp = Date()
}
