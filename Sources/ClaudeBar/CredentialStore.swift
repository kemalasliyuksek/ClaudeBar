import Foundation
import CryptoKit

/// Claude Code'un sakladığı OAuth kimlik bilgilerine erişim katmanı.
///
/// Claude Code 2.1.x ile birebir aynı yolu izler:
/// - Birincil depo macOS Keychain, servis adı "Claude Code-credentials", hesap adı $USER.
///   CLAUDE_CONFIG_DIR özelleştirilmişse servis adına dizin hash'inin ilk 8 karakteri eklenir.
/// - Keychain okunamazsa ~/.claude/.credentials.json düz metin dosyasına düşülür.
/// - Yazma `security -i` ile stdin üzerinden yapılır; token süreç argümanlarında görünmez
///   ve `-U` sayesinde kayıt silinip yeniden eklenmek yerine yerinde güncellenir.
struct CredentialStore: Sendable {
    enum Source: Sendable, Equatable {
        case keychain
        case plaintextFile
    }

    /// Okunan ham JSON ve içinden çözümlenen OAuth alanları birlikte taşınır;
    /// yazarken ham JSON temel alınır ki bilinmeyen alanlar korunsun.
    struct Snapshot: Sendable, Equatable {
        let raw: Data
        let oauth: KeychainCredentials.OAuthCredentials?
        let source: Source
    }

    enum StoreError: Error, Equatable {
        case securityFailed(Int32)
        case fileWriteFailed(String)
    }

    static let defaultServiceName = "Claude Code-credentials"
    /// Claude Code'un `security -i` için kullandığı üst sınır; daha uzun komut satırı kesilir
    static let stdinCommandLimit = 4032

    let configDir: URL
    let serviceName: String
    let accountName: String
    private let securityPath = "/usr/bin/security"

    init(environment: [String: String] = ProcessInfo.processInfo.environment,
         home: URL = FileManager.default.homeDirectoryForCurrentUser) {
        let resolved = Self.resolveLocation(environment: environment, home: home)
        configDir = resolved.configDir
        serviceName = resolved.serviceName
        accountName = Self.resolveAccountName(environment: environment)
    }

    /// Testlerin gerçek Keychain kaydına dokunmadan ayrı bir servis adıyla çalışabilmesi için
    init(configDir: URL, serviceName: String, accountName: String) {
        self.configDir = configDir
        self.serviceName = serviceName
        self.accountName = accountName
    }

    // MARK: - Konum çözümleme

    /// Claude Code'un Ix() fonksiyonunun karşılığı: özel bir config dizini kullanılıyorsa
    /// servis adına sha256(dizin) hash'inin ilk 8 karakteri eklenir, böylece profiller karışmaz.
    static func resolveLocation(environment: [String: String], home: URL) -> (configDir: URL, serviceName: String) {
        let secureDir = environment["CLAUDE_SECURESTORAGE_CONFIG_DIR"]
        let configDirEnv = environment["CLAUDE_CONFIG_DIR"]
        let defaultDir = home.appendingPathComponent(".claude").path

        let isDefault: Bool
        let dirPath: String
        if let secureDir {
            isDefault = secureDir.isEmpty
            dirPath = secureDir.isEmpty ? defaultDir : secureDir
        } else {
            isDefault = configDirEnv == nil || configDirEnv?.isEmpty == true
            dirPath = configDirEnv.flatMap { $0.isEmpty ? nil : $0 } ?? defaultDir
        }

        let normalized = dirPath.precomposedStringWithCanonicalMapping
        var service = defaultServiceName
        if !isDefault {
            let digest = SHA256.hash(data: Data(normalized.utf8))
            let hex = digest.map { String(format: "%02x", $0) }.joined()
            service += "-" + hex.prefix(8)
        }
        return (URL(fileURLWithPath: normalized), service)
    }

    /// Keychain hesap adı: $USER, geçersiz karakter varsa Claude Code'un kullandığı sabit
    static func resolveAccountName(environment: [String: String]) -> String {
        let candidate = environment["USER"].flatMap { $0.isEmpty ? nil : $0 } ?? NSUserName()
        let valid = candidate.range(of: #"^[a-zA-Z0-9._-]+$"#, options: .regularExpression) != nil
        return valid ? candidate : "claude-code-user"
    }

    var plaintextPath: URL {
        configDir.appendingPathComponent(".credentials.json")
    }

    /// Token yenilemesini Claude Code ile sıraya sokan kilit: ~/.claude.lock dizini
    var refreshLockPath: URL {
        let parent = configDir.deletingLastPathComponent()
        return parent.appendingPathComponent(configDir.lastPathComponent + ".lock")
    }

    /// Keychain yazmalarını sıraya sokan kilit: ~/.claude/.storage-write.lock dizini
    var storageLockPath: URL {
        configDir.appendingPathComponent(".storage-write.lock")
    }

    // MARK: - Okuma

    func read() -> Snapshot? {
        if let data = readKeychain() {
            return makeSnapshot(data, source: .keychain)
        }
        if let data = readPlaintext() {
            return makeSnapshot(data, source: .plaintextFile)
        }
        return nil
    }

    private func makeSnapshot(_ data: Data, source: Source) -> Snapshot {
        let decoded = try? JSONDecoder().decode(KeychainCredentials.self, from: data)
        return Snapshot(raw: data, oauth: decoded?.claudeAiOauth, source: source)
    }

    private func readKeychain() -> Data? {
        // Claude Code hesap adıyla yazıyor; eski kayıtlar için hesapsız aramayı da dene
        let attempts: [[String]] = [
            ["find-generic-password", "-a", accountName, "-w", "-s", serviceName],
            ["find-generic-password", "-w", "-s", serviceName],
        ]
        for arguments in attempts {
            let result = runSecurity(arguments)
            guard result.status == 0 else { continue }
            let trimmed = String(decoding: result.stdout, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                return Data(trimmed.utf8)
            }
        }
        return nil
    }

    private func readPlaintext() -> Data? {
        guard let data = try? Data(contentsOf: plaintextPath), !data.isEmpty else { return nil }
        return data
    }

    // MARK: - Yazma

    func write(_ raw: Data, to source: Source) throws {
        switch source {
        case .keychain:
            try writeKeychain(raw)
        case .plaintextFile:
            try writePlaintext(raw)
        }
    }

    private func writeKeychain(_ raw: Data) throws {
        // Parola hex olarak verilir (-X); tırnak ve kaçış sorunları böyle ortadan kalkar
        let hex = raw.map { String(format: "%02x", $0) }.joined()
        let command = "add-generic-password -U -a \"\(accountName)\" -s \"\(serviceName)\" -X \"\(hex)\" "

        let status: Int32
        if command.count <= Self.stdinCommandLimit {
            status = runSecurity(["-i"], stdin: command + "\n").status
        } else {
            // Claude Code da bu durumda argv'ye düşüyor; büyük kayıt için tek çalışan yol bu
            status = runSecurity(["add-generic-password", "-U", "-a", accountName, "-s", serviceName, "-X", hex]).status
        }
        guard status == 0 else { throw StoreError.securityFailed(status) }
    }

    private func writePlaintext(_ raw: Data) throws {
        do {
            try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
            try raw.write(to: plaintextPath, options: .atomic)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: plaintextPath.path)
        } catch {
            throw StoreError.fileWriteFailed(error.localizedDescription)
        }
    }

    // MARK: - security süreci

    private func runSecurity(_ arguments: [String], stdin: String? = nil) -> (status: Int32, stdout: Data) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: securityPath)
        process.arguments = arguments

        let output = Pipe()
        process.standardOutput = output
        process.standardError = Pipe()

        let input = Pipe()
        if stdin != nil {
            process.standardInput = input
        }

        do {
            try process.run()
        } catch {
            return (-1, Data())
        }

        if let stdin {
            input.fileHandleForWriting.write(Data(stdin.utf8))
            try? input.fileHandleForWriting.close()
        }

        // Önce çıktı tüketilir, sonra beklenir; aksi halde dolu pipe süreci kilitleyebilir
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return (process.terminationStatus, data)
    }
}

/// proper-lockfile ile uyumlu dizin kilidi. Claude Code aynı kütüphaneyi kullanır:
/// mkdir atomik olduğu için kilit anlamına gelir, dizinin mtime'ı bayatlık ölçüsüdür.
struct DirectoryLock: Sendable {
    let path: URL
    /// Bu süreden eski kilit sahibinin öldüğü varsayılır ve kilit kırılır
    let staleAfter: TimeInterval

    init(path: URL, staleAfter: TimeInterval = 15) {
        self.path = path
        self.staleAfter = staleAfter
    }

    /// Kilidi almayı dener; her başarısız denemede min ile max arasında rastgele bekler
    func acquire(retries: Int, minDelay: TimeInterval, maxDelay: TimeInterval) async -> Bool {
        for attempt in 0...retries {
            if tryAcquire() { return true }
            guard attempt < retries else { break }
            let delay = Double.random(in: minDelay...maxDelay)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }
        return false
    }

    /// Tek deneme, bekleme yok
    func tryAcquire() -> Bool {
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: path, withIntermediateDirectories: false)
            return true
        } catch let error as CocoaError where error.code == .fileWriteFileExists {
            guard isStale() else { return false }
            // Bayat kilidi temizle ve hemen yeniden dene; ikinci deneme de dolu ise başka süreç kaptı demektir
            try? manager.removeItem(at: path)
            return (try? manager.createDirectory(at: path, withIntermediateDirectories: false)) != nil
        } catch {
            return false
        }
    }

    func release() {
        try? FileManager.default.removeItem(at: path)
    }

    private func isStale() -> Bool {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path.path),
              let modified = attributes[.modificationDate] as? Date else { return false }
        return Date().timeIntervalSince(modified) > staleAfter
    }
}
