//
//  AvailableMethodsListView.swift
//  DAppExample
//
//  Created by Marcel Salej on 28/09/2023.
//

import SwiftUI

struct AvailableMethodsListView: View {
    @ObservedObject private var viewModel: AvailableMethodsListViewModel

    init(model: AvailableMethodsListViewModel) {
        self.viewModel = model
    }

    var body: some View {
        NavigationStack {
            VStack {
                Text("This are your confirmed actions for the manipulation with wallet")
                    .multilineTextAlignment(.center)
                    .font(Font.system(size: 14, weight: .bold))
                Spacer()
                    .frame(height: 10)
                List(viewModel.methods, id: \.self) { method in
                    NavigationLink(destination: {
                        MethodDetailView(viewModel: .init(session: viewModel.session,
                                                          currencyItem: viewModel.currencyItem,
                                                          selectedMethod: method))
                    }, label: {
                        Text(method.displayName)
                            .font(Font.system(size: 14, weight: .black) )
                            .monospaced()
                    })
                }
            }.background(Color.gray.opacity(0.2))
        }
    }
}
