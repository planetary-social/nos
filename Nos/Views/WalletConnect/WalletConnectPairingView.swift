//
//  AuthorizationView.swift
//  DAppExample
//
//  Created by Marcel Salej on 27/09/2023.
//

import SwiftUI

struct WalletConnectPairingView: View {
    @ObservedObject private var viewModel = WalletConnectPairingController()
    @State var sessionListOpened: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16.0) {
                if let qrImage = viewModel.qrImage {
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .frame(width: 300, height: 300)
                } else {
                    ProgressView()
                        .frame(width: 300, height: 300)
                        .progressViewStyle(.circular)
                        .foregroundColor(.white)
                        .controlSize(.large)
                }
                Spacer().frame(height: 20)
                HStack {
                    Spacer()
                    Button(action: { viewModel.copyDidPressed() }, label: {
                        Text("Copy link")
                    })
                    Spacer()
                    Button(action: { viewModel.deeplinkPressed() }, label: {
                        Text("Open link")
                    })
                    Spacer()
                    Button(action: { viewModel.payPressed() }, label: {
                        Text("Pay")
                    })
                    Spacer()
                }
                Spacer()
                    .frame(height: 20)
                if let session = viewModel.session {
                    Text("Connected to wallet \(session.peer.name)")
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .font(Font.system(size: 16, weight: .bold))
                } else {
                    Text("Please scan qr code to start pairing procedure")
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .font(Font.system(size: 16, weight: .bold))
                }
                if let namespaces = viewModel.session?.namespaces {
                    Text("Please select wallet address you want to manipulate")
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .font(Font.system(size: 14, weight: .semibold))
                    
                    
                    List(viewModel.currencyItems, id: \.self) { item  in
                        NavigationLink(destination: {
                            viewModel.session.map {
                                AvailableMethodsListView(model: .init(session: $0, currencyItem: item))
                            }
                        }) {
                            VStack(spacing: 10) {
                                if let chainType = SupportedChainType.allCases.first(where: { $0.blockChainValue == item.blockchain}) {
                                    HStack {
                                        Text("\(item.blockchain.absoluteString)   (\(chainType.displayValue))")
                                            .font(Font.system(size: 12, weight: .semibold))
                                        Spacer()
                                    }
                                    
                                }
                                HStack {
                                    Text("Address:")
                                        .font(Font.system(size: 12, weight: .semibold))
                                    Text("\(item.address)")
                                        .font(.system(size: 10, design: .monospaced))
                                    Spacer()
                                }
                            }
                        }
                        
                    }.frame(maxHeight: .infinity)
                    
                }
            }
            .task {
                Task {
                    try await viewModel.initiateConnectionToWC()
                }
            }.toolbar(content: {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        sessionListOpened = true
                    } label: {
                        Image(systemName: "list.bullet.indent")
                    }
                }
            })
            .navigationDestination(isPresented: $sessionListOpened) {
                SessionListView()
            }
        }
    }
}
