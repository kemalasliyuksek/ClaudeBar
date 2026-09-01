import Foundation
import AppKit
import UserNotifications

/// Sistem bildirimlerini gönderir.
///
/// Uygulama bir .app paketi içinde çalışıyorsa UNUserNotificationCenter kullanılır:
/// izin yönetimi Sistem Ayarları'na düşer, bildirim ClaudeBar adı ve simgesiyle görünür.
/// `swift run` gibi paket dışı çalışmalarda bundle identifier olmadığı için merkez
/// kullanılamaz; o durumda eski AppleScript yolu devreye girer.
@MainActor
final class Notifier: NSObject, UNUserNotificationCenterDelegate {
    private let center: UNUserNotificationCenter?
    /// Merkez bir kez hata verirse sonraki bildirimler AppleScript ile gider
    private var centerUnavailable = false

    override init() {
        center = Bundle.main.bundleIdentifier != nil ? UNUserNotificationCenter.current() : nil
        super.init()
        center?.delegate = self
    }

    /// İzin ister. Merkez yoksa nil, kullanıcı reddettiyse false döner.
    func requestAuthorization() async -> Bool? {
        guard let center else { return nil }
        do {
            return try await center.requestAuthorization(options: [.alert, .sound])
        } catch {
            centerUnavailable = true
            return nil
        }
    }

    func send(title: String, body: String) {
        guard let center, !centerUnavailable else {
            sendViaAppleScript(title: title, body: body)
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        center.add(request) { error in
            guard error != nil else { return }
            Task { @MainActor in
                self.centerUnavailable = true
                self.sendViaAppleScript(title: title, body: body)
            }
        }
    }

    /// Menü çubuğu penceresi açıkken uygulama "ön planda" sayılır; bildirimi yine de göster
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    private func sendViaAppleScript(title: String, body: String) {
        let escapedTitle = Self.escape(title)
        let escapedBody = Self.escape(body)
        let script = "display notification \"\(escapedBody)\" with title \"\(escapedTitle)\" sound name \"default\""

        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
