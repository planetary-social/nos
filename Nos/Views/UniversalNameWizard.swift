//
//  UniversalNameWizard.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/20/23.
//

import SwiftUI

struct UniversalNameWizard: View {
    
    @Binding var isPresented: Bool
    
    enum Flow {
        case signUp
        case login
    }
    
    enum FlowState {
        case loading
        case chooseName
        case enterPhone
        case enterOTP
        case success
        case error
        case nameTaken
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var currentUser: CurrentUser
    
    @MainActor @State var flowState = FlowState.enterPhone
    @State private var flow: Flow?
    @MainActor @State private var textField: String = ""
    @MainActor @State private var phoneNumber: String?
    @MainActor @State private var name: String?
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?
    
    let api = UNSAPI()!
    
    var body: some View {
        NavigationView {
            VStack {
                switch flowState {
                case .enterPhone:
                    Form {
                        Section {
                            TextField(text: $textField) {
                                Text("+1-234-567-8910")
                                    .foregroundColor(.secondaryTxt)
                            }
                            .foregroundColor(.textColor)
                            .keyboardType(.phonePad)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .textEditor)
                        } header: {
                            Text("Verify your identity")
                                .foregroundColor(.textColor)
                                .fontWeight(.heavy)
                        }
                        .listRowBackground(LinearGradient(
                            colors: [Color.cardBgTop, Color.cardBgBottom],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                    }
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                    
                    BigActionButton(title: .sendCode) {
                        Task {
                            var number = textField
                            number = number.trimmingCharacters(in: .whitespacesAndNewlines)
                            number.replace("-", with: "")
                            number.replace("+", with: "")
                            number = "+\(number)"
                            phoneNumber = number
                            
                            do {
                                flowState = .loading
                                try await api.requestOTPCode(phoneNumber: number)
                                textField = ""
                                flowState = .enterOTP
                            } catch {
                                flowState = .error
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                case .enterOTP:
                    Form {
                        Section {
                            TextField(text: $textField) {
                                Text("123456")
                                    .foregroundColor(.secondaryTxt)
                            }
                            .foregroundColor(.textColor)
                            .keyboardType(.phonePad)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .textEditor)
                        } header: {
                            Text("Enter Code")
                                .foregroundColor(.textColor)
                                .fontWeight(.heavy)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    
                    Spacer()
                    BigActionButton(title: .submit) {
                        Task {
                            do {
                                flowState = .loading
                                try await api.verifyOTPCode(phoneNumber: phoneNumber!, code: textField.trimmingCharacters(in: .whitespacesAndNewlines))
                                textField = ""
                                let names = try await api.getNames()
                                if let name = names.first {
                                    self.name = name
                                    if let message = try await api.requestNostrVerification(npub: currentUser.keyPair!.npub) {
                                        let nip05 = try await api.submitNostrVerification(message: message, keyPair: currentUser.keyPair!)
                                        currentUser.author?.nip05 = nip05
                                    }
                                    currentUser.author?.name = name
                                    currentUser.publishMetaData()
                                    flowState = .success
                                } else {
                                    flowState = .chooseName
                                }
                            } catch {
                                flowState = .error
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)

                case .loading:
                    VStack {
                        Spacer()
                        ProgressView()
                            .foregroundColor(.primaryTxt)
                            .background(Color.appBg)
                            .scaleEffect(2)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                case .chooseName:
                    Form {
                        Section {
                            TextField(text: $textField) {
                                Text("name")
                                    .foregroundColor(.secondaryTxt)
                            }
                            .textInputAutocapitalization(.none)
                            .foregroundColor(.textColor)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .textEditor)
                        } header: {
                            Text("Choose Your Name")
                                .foregroundColor(.textColor)
                                .fontWeight(.heavy)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    Spacer()
                    BigActionButton(title: .submit) {
                        Task {
                            flowState = .loading
                            guard try await api.createName(textField.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) else {
                                flowState = .nameTaken
                                return
                            }
                            let names = try await api.getNames()
                            name = names.first!
                            let message = try await api.requestNostrVerification(npub: currentUser.publicKey!)!
                            let nip05 = try await api.submitNostrVerification(message: message, keyPair: currentUser.keyPair!)
                            currentUser.author?.name = name
                            currentUser.author?.nip05 = nip05
                            currentUser.publishMetaData()
                            flowState = .success
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                case .nameTaken:
                    Spacer()
                    PlainText("Oops!")
                        .font(.title2)
                        .padding()
                        .foregroundColor(.primaryTxt)
                    PlainText("That name is taken.")
                        .font(.body)
                        .padding()
                        .foregroundColor(.primaryTxt)
                    Spacer()
                    BigActionButton(title: .goBack) {
                        flowState = .chooseName
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                case .success:
                    VStack {
                        PlainText("Success!")
                            .font(.title)
                            .padding(.top, 50)
                            .foregroundColor(.textColor)
                        Text("\(String(describing: name)) is your new Nostr username.\n\nThis demo of the Universal Name Space is for testing purposes only. All names will be reset in teh future.")
                            .padding()
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 500)
                            .foregroundColor(.textColor)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                case .error:
                    Spacer()
                    PlainText("Oops!")
                        .font(.title2)
                        .padding()
                        .foregroundColor(.textColor)
                    PlainText("An error occured.")
                        .font(.body)
                        .padding()
                        .foregroundColor(.textColor)
                    Spacer()
                    BigActionButton(title: .startOver) {
                        flowState = .enterPhone
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
            }
            .onAppear {
                focusedField = .textEditor
            }
            .background(Color.appBg)
            .nosNavigationBar(title: .setUpUNS)
        }
    }
}

struct UniversalNameWizard_Previews: PreviewProvider {
    static var previews: some View {
        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(isPresented: .constant(true), flowState: .enterPhone)
            }
        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(isPresented: .constant(true), flowState: .enterOTP)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(isPresented: .constant(true), flowState: .loading)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(isPresented: .constant(true), flowState: .chooseName)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(isPresented: .constant(true), flowState: .success)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(isPresented: .constant(true), flowState: .error)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(isPresented: .constant(true), flowState: .nameTaken)
            }
    }
}
