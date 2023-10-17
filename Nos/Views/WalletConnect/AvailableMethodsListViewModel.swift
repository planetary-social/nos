//
//  AvailableMethodsListViewModel.swift
//  DAppExample
//
//  Created by Marcel Salej on 28/09/2023.
//

import Foundation
import Combine
import WalletConnectSign

class AvailableMethodsListViewModel: ObservableObject {
    private var disposeBag = Set<AnyCancellable>()
    private let walletConnectManager = WalletConnectManager.shared

    @Published var methods: [SupportedMethodsType] = []
    @Published var selectedMethod: SupportedMethodsType? = nil


    let session: Session
    let currencyItem: CurrencyItem

    init(session: Session, currencyItem: CurrencyItem) {
        self.session = session
        self.currencyItem = currencyItem
        self.methods = currencyItem.methods.compactMap {SupportedMethodsType(rawValue: $0)}
    }

    func setSelectedMethod(method: SupportedMethodsType) {
        self.selectedMethod = method
    }
}
