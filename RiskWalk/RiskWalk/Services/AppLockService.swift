import Foundation
import LocalAuthentication
import SwiftUI

/// Optional biometric / passcode gate for opening the app with inspection data.
@MainActor
final class AppLockService: ObservableObject {
    @Published private(set) var isUnlocked: Bool
    @Published var isLockEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isLockEnabled, forKey: Keys.lockEnabled)
            if !isLockEnabled {
                isUnlocked = true
            }
        }
    }

    private enum Keys {
        static let lockEnabled = "security.appLockEnabled"
    }

    init() {
        let enabled = UserDefaults.standard.bool(forKey: Keys.lockEnabled)
        isLockEnabled = enabled
        // Require unlock when lock is enabled; otherwise start unlocked.
        isUnlocked = !enabled
    }

    func lockIfNeeded() {
        guard isLockEnabled else {
            isUnlocked = true
            return
        }
        isUnlocked = false
    }

    func authenticate() async {
        guard isLockEnabled else {
            isUnlocked = true
            return
        }

        let context = LAContext()
        var error: NSError?
        let policy: LAPolicy = .deviceOwnerAuthentication

        guard context.canEvaluatePolicy(policy, error: &error) else {
            // Device has no passcode/biometrics — do not brick the app; keep unlocked but log.
            AppLogger.authResult(success: false)
            isUnlocked = true
            return
        }

        do {
            let success = try await context.evaluatePolicy(
                policy,
                localizedReason: "Ontgrendel RiskWalk om inspectiedossiers te openen."
            )
            isUnlocked = success
            AppLogger.authResult(success: success)
        } catch {
            isUnlocked = false
            AppLogger.authResult(success: false)
        }
    }
}
