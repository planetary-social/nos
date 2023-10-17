//
//  MethodDetailView.swift
//  DAppExample
//
//  Created by Marcel Salej on 28/09/2023.
//

import SwiftUI

struct MethodDetailView: View {

    @ObservedObject private var viewModel: MethodDetailViewModel

    init(viewModel: MethodDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(content: {

            switch viewModel.methodType {
            case .ethGetBalance:
                getBalanceView
            case .ethSendTransaction:
                sendTransactionView
            case .ethSignTypedData:
                signTypedDataView
            case .personalSign:
                personalSignView
            }
        })
        .navigationTitle(viewModel.methodType.displayName)
    }


    var getBalanceView: some View {
        VStack {
            Spacer().frame(height: 20)
            HStack {
                Text("Your balance is: ")
                Text("--.-- $")
            }
        }
        .onAppear() {
            viewModel.getAddressBalance()
        }
    }

    var sendTransactionView: some View {
        VStack(spacing: 15) {
            Spacer()
                .frame(height: 30)
            VStack {
                HStack {
                    Text("Enter sender address")
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                HStack {
                    TextField("Sender address", text: $viewModel.senderAddres)
                        .background(Color.gray.opacity(0.1))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
            VStack {
                HStack {
                    Text("Enter amount")
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                HStack {
                    TextField("Amount", text: $viewModel.sendAmount)
                        .background(Color.gray.opacity(0.1))
                        .textFieldStyle(RoundedBorderTextFieldStyle())

                }
            }
            Spacer()
                .frame(height: 20)
            Button(action: {
                viewModel.sendTransaction()
            }, label: {
                Spacer()
                Text("Send")
                    .foregroundStyle(.white)
                Spacer()
            }).buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            Spacer()
                .frame(height: 60)

            if let errorMessage = $viewModel.errorMessage.wrappedValue {
                Text(errorMessage)
                    .font(Font.system(size: 16, weight: .bold))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if $viewModel.transactionId.wrappedValue.count != 0 {
                Text("Congratulations! \n \n your transaction has been created! \n \n check your transaction on etherscan by tapping on link")
                    .font(Font.system(size: 16, weight: .bold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                Button {
                    let url = viewModel.supportedChainType
                    switch url {
                    case .ethereum:
                        guard let url = URL(string: String(format: "https://sepolia.etherscan.io/tx/%@", viewModel.transactionId)) else { return }
                        UIApplication.shared.open(url)
                    case .universalLedger:
                        guard let url = URL(string: String(format: "https://explorer.tst.uled.io/tx/%@", viewModel.transactionId)) else { return }
                        UIApplication.shared.open(url)

                    }
                } label: {
                    Text(viewModel.transactionId)
                        .foregroundStyle(Color.blue)
                }.buttonStyle(.borderless)
                    .background(Color.clear)
                    .controlSize(.large)
                Spacer()
                    .frame(height: 20)
                Text("If transaction is not found, try to refresh the browser after few seconds")
                    .font(Font.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center
                    )

            }
            Spacer()
        }.padding([.leading, .trailing], 40)
    }

    var signTypedDataView: some View {
        VStack {
            Text("")
        }.onAppear {
            viewModel.signTypedData()
        }
    }

    var personalSignView: some View {
        VStack {
            Text("Insert message")
            Spacer()
                .frame(height: 20)
            TextEditor(text: $viewModel.personalSignMessage)
                .frame(height: 100)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

            Spacer()
                .frame(height: 20)
            Button(action: {
                viewModel.personalSign()
            }, label: {
                Spacer()
                Text("Sign")
                Spacer()
            }).buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
            Spacer()
        }
        .padding()
        .onAppear {
        }
    }
}
