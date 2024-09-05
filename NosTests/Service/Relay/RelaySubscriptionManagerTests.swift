import XCTest
import Starscream

final class RelaySubscriptionManagerTests: XCTestCase {

    let relayOneURL = URL(string: "wss://relay.one")!
    let relayTwoURL = URL(string: "wss://relay.two")!
    let relayThreeURL = URL(string: "wss://relay.three")!
    
    var subject: RelaySubscriptionManagerActor!
    
    override func setUp() async throws {
        try await super.setUp()
        subject = RelaySubscriptionManagerActor()
    }
    
    func test_openSockets_givenDisconnectedSockets_startsConnectingAll() async throws {
        // Arrange
        _ = await subject.queueSubscription(with: Filter(), to: relayOneURL)
        _ = await subject.queueSubscription(with: Filter(), to: relayTwoURL)
        _ = await subject.queueSubscription(with: Filter(), to: relayThreeURL)
        
        // Act
        await subject.openSockets()
        
        // Assert
        var connections = await subject.socketConnections
        XCTAssertEqual(connections.count, 3)
        connections.values.forEach { XCTAssertEqual($0.state, .connecting) }
    }
    
    func test_openSockets_givenErroredSocket_startsConnectingAll() async throws {
        // Arrange
        _ = await subject.queueSubscription(with: Filter(), to: relayOneURL)
        _ = await subject.queueSubscription(with: Filter(), to: relayTwoURL)
        _ = await subject.queueSubscription(with: Filter(), to: relayThreeURL)
        await subject.openSockets()
        var request = URLRequest(url: relayTwoURL)
        request.timeoutInterval = 10
        let socket = WebSocket(request: request, useCustomEngine: false)
        
        // Act
        await subject.trackError(socket: socket)
        try await Task.sleep(for: .seconds(1))
        await subject.openSockets()
        
        // Assert
        var connections = await subject.socketConnections
        XCTAssertEqual(connections.count, 3)
        connections.values.forEach { 
            XCTAssertEqual($0.state, .connecting)
        }
    }
    
    func test_openSockets_givenOneDisconnectedSocket_startsConnectingAll() async throws {
        // Arrange
        _ = await subject.queueSubscription(with: Filter(), to: relayOneURL)
        _ = await subject.queueSubscription(with: Filter(), to: relayTwoURL)
        _ = await subject.queueSubscription(with: Filter(), to: relayThreeURL)
        await subject.openSockets()
        
        var connections = await subject.socketConnections
        let connection = connections[relayThreeURL]
        connection?.state = .disconnected
        
        // Act
        await subject.openSockets()
        
        // Assert
        XCTAssertEqual(connections.count, 3)
        connections.values.forEach { 
            XCTAssertEqual($0.state, .connecting)
        }
    }
}
