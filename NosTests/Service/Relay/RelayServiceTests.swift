import XCTest

class RelayServiceTests: XCTestCase {
    func test_removeRelayableRelays_removes_relays_when_relayable_is_in_array() {
        // Arrange
        let relays = Relay.recommended.compactMap { URL(string: $0) }
        let expected = [
            "wss://relay.nostr.band",
            "wss://e.nos.lol",
            "wss://relay.current.fyi",
            "wss://relay.nos.social",
            "wss://relayable.org",
            "wss://relay.causes.com",
        ].compactMap { URL(string: $0) }

        // Act
        let result = RelayService.removeRelayableRelays(relayAddresses: relays)

        // Assert
        XCTAssertEqual(result, expected)
    }

    func test_removeRelayableRelays_does_not_remove_relays_when_relayable_is_not_in_array() {
        // Arrange
        let relays = Relay.streamedByRelayable.compactMap { URL(string: $0) }

        // Act
        let result = RelayService.removeRelayableRelays(relayAddresses: relays)

        // Assert
        XCTAssertEqual(result, relays)
    }
}
