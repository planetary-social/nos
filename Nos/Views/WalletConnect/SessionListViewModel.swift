//
//  SessionListViewModel.swift
//  DAppExample
//
//  Created by Marcel Salej on 02/10/2023.
//

import Foundation
import WalletConnectSign

class SessionListViewModel: ObservableObject {
    private let walletConnectManager = WalletConnectManager.shared

    @Published var sessionListItems: [SessionCellItem] = []

    private var sessionsList: [Session] = []

    init() {
    }

    func generateList() {
        let sessions = walletConnectManager.getAllSessions()
        var cellItems: [SessionCellItem] = []
        sessions.forEach { session in
            let namespaces = session.namespaces.keys.joined(separator: ", ")
            cellItems.append(.init(topic: session.topic, peer: session.peer.name, namespaces: namespaces))
        }
        sessionListItems = cellItems
        sessionsList = sessions
    }

    func deleteAllSessions() async throws {
        await withTaskGroup(of: Void.self) { [self] group in
            for session in sessionsList {
                group.addTask { try? await self.walletConnectManager.deleteSession(topic: session.topic) }
            }

            return
        }
        await MainActor.run {
            generateList()
        }
    }

    func deleteSession(topic: String) async throws {
        try await self.walletConnectManager.deleteSession(topic: topic)
        await MainActor.run {
            generateList()
        }
    }

}


struct SessionCellItem: Hashable {

    var topic: String
    var peer: String
    var namespaces: String
}

