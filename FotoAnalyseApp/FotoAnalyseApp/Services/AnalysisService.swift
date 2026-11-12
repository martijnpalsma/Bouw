//
//  AnalysisService.swift
//  FotoAnalyseApp
//
//  Service voor communicatie met Flask API
//

import Foundation
import UIKit
import Combine

@MainActor
class AnalysisService: ObservableObject {
    @Published var uploadState: UploadState = .idle
    @Published var currentAnalysis: AnalysisResponse?
    @Published var isHealthy: Bool = false
    @Published var apiConfigured: Bool = false
    
    // Configureerbare base URL
    var baseURL: String = "http://localhost:5000" {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "apiBaseURL")
        }
    }
    
    init() {
        // Laad opgeslagen URL
        if let savedURL = UserDefaults.standard.string(forKey: "apiBaseURL") {
            baseURL = savedURL
        }
    }
    
    // MARK: - Health Check
    func checkHealth() async {
        guard let url = URL(string: "\(baseURL)/api/health") else {
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isHealthy = false
                return
            }
            
            let healthResponse = try JSONDecoder().decode(HealthResponse.self, from: data)
            isHealthy = healthResponse.status == "healthy"
            apiConfigured = healthResponse.apiConfigured
            
        } catch {
            print("Health check failed: \(error.localizedDescription)")
            isHealthy = false
        }
    }
    
    // MARK: - Upload & Analyze Photo
    func uploadAndAnalyze(image: UIImage) async {
        uploadState = .uploading
        
        guard let url = URL(string: "\(baseURL)/api/upload") else {
            uploadState = .error("Ongeldige API URL")
            return
        }
        
        // Comprimeer en converteer image naar JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            uploadState = .error("Kan foto niet verwerken")
            return
        }
        
        // Check file size (max 10MB)
        let maxSize = 10 * 1024 * 1024 // 10MB
        if imageData.count > maxSize {
            uploadState = .error("Foto is te groot (max 10MB)")
            return
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"gebouw.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        uploadState = .analyzing
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                uploadState = .error("Ongeldig server response")
                return
            }
            
            if httpResponse.statusCode != 200 {
                // Try to decode error message
                if let errorDict = try? JSONDecoder().decode([String: String].self, from: data),
                   let errorMessage = errorDict["error"] {
                    uploadState = .error(errorMessage)
                } else {
                    uploadState = .error("Server fout: \(httpResponse.statusCode)")
                }
                return
            }
            
            let analysisResponse = try JSONDecoder().decode(AnalysisResponse.self, from: data)
            currentAnalysis = analysisResponse
            uploadState = .completed(analysisResponse)
            
        } catch {
            uploadState = .error("Netwerk fout: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Clarify Analysis
    func clarifyAnalysis(filename: String, answer: String) async {
        uploadState = .analyzing
        
        guard let url = URL(string: "\(baseURL)/api/clarify") else {
            uploadState = .error("Ongeldige API URL")
            return
        }
        
        let requestBody: [String: Any] = [
            "filename": filename,
            "answer": answer,
            "conversation_history": []
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            uploadState = .error("Kan request niet maken")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                uploadState = .error("Server fout")
                return
            }
            
            let analysisResponse = try JSONDecoder().decode(AnalysisResponse.self, from: data)
            currentAnalysis = analysisResponse
            uploadState = .completed(analysisResponse)
            
        } catch {
            uploadState = .error("Netwerk fout: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Reset
    func reset() {
        uploadState = .idle
        currentAnalysis = nil
    }
}
