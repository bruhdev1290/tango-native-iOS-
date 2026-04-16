import XCTest
@testable import TaigaCore

final class TaigaCoreTests: XCTestCase {
    func testAuthTokenDecoding() throws {
        let json = """
        {"auth_token":"abc123","token_type":"Bearer"}
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let token = try decoder.decode(AuthToken.self, from: json)
        XCTAssertEqual(token.authToken, "abc123")
        XCTAssertEqual(token.tokenType, "Bearer")
    }

    // MARK: - SecurityLockService Tests

    func testSecurityLockServicePasscode() async throws {
        let service = SecurityLockService()
        XCTAssertFalse(await service.isPasscodeSet())

        try await service.setPasscode("1234")
        XCTAssertTrue(await service.isPasscodeSet())
        XCTAssertTrue(await service.validatePasscode("1234"))
        XCTAssertFalse(await service.validatePasscode("0000"))

        await service.removePasscode()
        XCTAssertFalse(await service.isPasscodeSet())
    }

    func testSecurityLockServiceBiometric() async throws {
        let service = SecurityLockService()
        try await service.setPasscode("1234")
        XCTAssertFalse(await service.isBiometricEnabled())

        try await service.setBiometricEnabled(true)
        XCTAssertTrue(await service.isBiometricEnabled())

        try await service.setBiometricEnabled(false)
        XCTAssertFalse(await service.isBiometricEnabled())

        await service.removePasscode()
        XCTAssertFalse(await service.isBiometricEnabled())
    }
}
