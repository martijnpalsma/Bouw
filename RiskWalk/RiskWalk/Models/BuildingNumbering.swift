import Foundation

enum BuildingNumbering {
    /// Allocates the next display code from the highest existing G-number (never reuse deleted codes).
    static func nextDisplayCode(existing: [Building], sequenceHint: Int) -> (code: String, nextSequence: Int) {
        let maxFromBuildings = existing.compactMap { codeNumber(from: $0.displayCode) }.max() ?? 0
        let next = max(maxFromBuildings, sequenceHint) + 1
        let code = String(format: "G%02d", next)
        return (code, next)
    }

    static func codeNumber(from displayCode: String) -> Int? {
        guard displayCode.hasPrefix("G") else { return nil }
        return Int(displayCode.dropFirst())
    }
}
