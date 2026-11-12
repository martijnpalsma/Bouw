import CoreGraphics
import Foundation
import ImageIO
import UIKit

/// File-based photo storage with Data Protection. Images are never the sole source of truth in RAM.
enum PhotoStore {
    private static let folderName = "Photos"

    static var photosDirectory: URL {
        let base = SecureStore.applicationSupportDirectory
            .appendingPathComponent(folderName, isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }

    static func fileURL(for photoId: UUID) -> URL {
        photosDirectory.appendingPathComponent("\(photoId.uuidString).jpg")
    }

    @discardableResult
    static func saveImage(_ image: UIImage, photoId: UUID, compressionQuality: CGFloat = 0.82) throws -> URL {
        guard let data = image.jpegData(compressionQuality: compressionQuality) else {
            throw PhotoStoreError.encodingFailed
        }

        let url = fileURL(for: photoId)
        let temp = url.appendingPathExtension("tmp")

        try data.write(to: temp, options: [.atomic])
        try applyFileProtection(at: temp)

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try FileManager.default.moveItem(at: temp, to: url)
        try applyFileProtection(at: url)

        return url
    }

    static func loadImage(photoId: UUID, maxPixelSize: CGFloat? = 1600) -> UIImage? {
        let url = fileURL(for: photoId)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        if let maxPixelSize {
            return downsampledImage(at: url, maxPixelSize: maxPixelSize)
        }
        return UIImage(contentsOfFile: url.path)
    }

    static func deleteImage(photoId: UUID) {
        let url = fileURL(for: photoId)
        try? FileManager.default.removeItem(at: url)
    }

    static func applyFileProtection(at url: URL) throws {
        try FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.completeUntilFirstUserAuthentication],
            ofItemAtPath: url.path
        )
    }

    /// Avoid keeping full-resolution bitmaps for thumbnails/export previews.
    private static func downsampledImage(at url: URL, maxPixelSize: CGFloat) -> UIImage? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
            return UIImage(contentsOfFile: url.path)
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
            return UIImage(contentsOfFile: url.path)
        }
        return UIImage(cgImage: cgImage)
    }
}

enum PhotoStoreError: LocalizedError {
    case encodingFailed

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Foto kon niet worden gecodeerd."
        }
    }
}
