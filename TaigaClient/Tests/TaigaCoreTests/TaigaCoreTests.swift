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
}
