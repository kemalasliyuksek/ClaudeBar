import XCTest
@testable import ClaudeBar

final class CredentialStoreTests: XCTestCase {

    private let home = URL(fileURLWithPath: "/Users/test")

    func testDefaultLocationUsesPlainServiceName() {
        let store = CredentialStore(environment: ["USER": "kemal"], home: home)
        XCTAssertEqual(store.serviceName, "Claude Code-credentials")
        XCTAssertEqual(store.configDir.path, "/Users/test/.claude")
        XCTAssertEqual(store.accountName, "kemal")
        XCTAssertEqual(store.refreshLockPath.path, "/Users/test/.claude.lock")
        XCTAssertEqual(store.storageLockPath.path, "/Users/test/.claude/.storage-write.lock")
        XCTAssertEqual(store.plaintextPath.path, "/Users/test/.claude/.credentials.json")
    }

    func testCustomConfigDirAppendsHashSuffix() {
        let store = CredentialStore(environment: ["USER": "kemal", "CLAUDE_CONFIG_DIR": "/tmp/profile-b"], home: home)
        XCTAssertEqual(store.configDir.path, "/tmp/profile-b")
        XCTAssertTrue(store.serviceName.hasPrefix("Claude Code-credentials-"))
        XCTAssertEqual(store.serviceName.count, "Claude Code-credentials-".count + 8)

        // Aynı dizin her zaman aynı son eki üretmeli, Claude Code ile eşleşmenin şartı bu
        let again = CredentialStore(environment: ["USER": "kemal", "CLAUDE_CONFIG_DIR": "/tmp/profile-b"], home: home)
        XCTAssertEqual(store.serviceName, again.serviceName)
    }

    func testEmptySecureStorageDirMeansDefault() {
        let store = CredentialStore(environment: ["CLAUDE_SECURESTORAGE_CONFIG_DIR": "", "CLAUDE_CONFIG_DIR": "/tmp/x"], home: home)
        XCTAssertEqual(store.serviceName, "Claude Code-credentials")
        XCTAssertEqual(store.configDir.path, "/Users/test/.claude")
    }

    func testInvalidUserNameFallsBack() {
        let store = CredentialStore(environment: ["USER": "kemal aslı"], home: home)
        XCTAssertEqual(store.accountName, "claude-code-user")
    }

    func testDirectoryLockAcquireReleaseAndStale() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }

        let lock = DirectoryLock(path: base.appendingPathComponent("x.lock"), staleAfter: 15)
        XCTAssertTrue(lock.tryAcquire())
        XCTAssertFalse(lock.tryAcquire(), "aynı kilit ikinci kez alınamamalı")
        lock.release()
        XCTAssertTrue(lock.tryAcquire())
        lock.release()

        // Bayat kilit: mtime'ı geçmişe çekilmiş bir dizin kırılıp yeniden alınmalı
        let stalePath = base.appendingPathComponent("stale.lock")
        try FileManager.default.createDirectory(at: stalePath, withIntermediateDirectories: false)
        try FileManager.default.setAttributes([.modificationDate: Date().addingTimeInterval(-60)], ofItemAtPath: stalePath.path)
        let staleLock = DirectoryLock(path: stalePath, staleAfter: 15)
        XCTAssertTrue(staleLock.tryAcquire())
        staleLock.release()
    }

    func testMergedScopesKeepsOrderWithoutDuplicates() {
        let merged = OAuthClient.mergedScopes(stored: ["user:inference", "user:custom"])
        XCTAssertEqual(merged, ["user:profile", "user:inference", "user:sessions:claude_code", "user:mcp_servers", "user:custom"])
    }
}
