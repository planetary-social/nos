//
//  UniversalNameWizard.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/20/23.
//

import SwiftUI

struct UniversalNameWizard: View {
        
    var author: Author

    var dismiss: (() -> Void)?
    
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
                            .foregroundColor(.primaryTxt)
                            .keyboardType(.phonePad)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .textEditor)
                            HighlightedText(
                                "The Universal Namespace gives you one name you can use everywhere. You can verify your identity and get your universal name here in Nos. This screen is for demo purposes only, all names will be reset in the future. Learn more.",
                                highlightedWord: "Learn more.",
                                highlight: .diagonalAccent,
                                link: URL(string: "https://universalname.space")
                            )
                        } header: {
                            Text("Verify your identity")
                                .foregroundColor(.primaryTxt)
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
                            
                            textField = ""
                            do {
                                flowState = .loading
                                try await api.requestOTPCode(phoneNumber: number)
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
                            .foregroundColor(.primaryTxt)
                            .keyboardType(.phonePad)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .textEditor)
                        } header: {
                            Text("Enter Code")
                                .foregroundColor(.primaryTxt)
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
                    BigActionButton(title: .submit) {
                        Task {
                            do {
                                flowState = .loading
                                try await api.verifyOTPCode(phoneNumber: phoneNumber!, code: textField.trimmingCharacters(in: .whitespacesAndNewlines))
                                textField = ""
                                let names = try await api.getNames()
                                if let name = names.first {
                                    self.name = name
                                    var nip05: String
                                    if let message = try await api.requestNostrVerification(npub: currentUser.keyPair!.npub) {
                                        nip05 = try await api.submitNostrVerification(message: message, keyPair: currentUser.keyPair!)
                                    } else {
                                        nip05 = try await api.getNIP05()
                                    }
                                    author.name = name
                                    author.nip05 = nip05
                                    CurrentUser.shared.publishMetaData()
                                    try viewContext.save()
                                    flowState = .success
                                } else {
                                    flowState = .chooseName
                                }
                            } catch {
                                textField = ""
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
                            .foregroundColor(.primaryTxt)
                            .autocorrectionDisabled()
                            .autocapitalization(.none)
                            .focused($focusedField, equals: .textEditor)
                        } header: {
                            Text("Choose Your Name")
                                .foregroundColor(.primaryTxt)
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
                    BigActionButton(title: .submit) {
                        Task {
                            flowState = .loading
                            guard try await api.createName(textField.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)) else {
                                flowState = .nameTaken
                                return
                            }
                            let names = try await api.getNames()
                            name = names.first!
                            let message = try await api.requestNostrVerification(npub: currentUser.keyPair!.npub)!
                            let nip05 = try await api.submitNostrVerification(message: message, keyPair: currentUser.keyPair!)
                            author.name = name
                            author.nip05 = nip05
                            CurrentUser.shared.publishMetaData()
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
                            .foregroundColor(.primaryTxt)
                        Text("\(name ?? "") is your new Nostr username.\n\nThis demo of the Universal Namespace is for testing purposes only. All names will be reset in the future.")
                            .padding()
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 500)
                            .foregroundColor(.primaryTxt)
                        Spacer()
                        BigActionButton(title: .dismiss) {
                            dismiss?()
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 50)
                    }
                    .frame(maxWidth: .infinity)
                case .error:
                    Spacer()
                    PlainText("Oops!")
                        .font(.title2)
                        .padding()
                        .foregroundColor(.primaryTxt)
                    PlainText("An error occured.")
                        .font(.body)
                        .padding()
                        .foregroundColor(.primaryTxt)
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
    
    static var persistenceController = PersistenceController.preview
    static var previewContext = persistenceController.container.viewContext

    static var author: Author {
        let author = Author(context: previewContext)
        author.hexadecimalPublicKey = KeyFixture.pubKeyHex
        return author
    }
    
    static var previews: some View {
        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(author: author, flowState: .enterPhone)
            }
        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(author: author, flowState: .enterOTP)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(author: author, flowState: .loading)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(author: author, flowState: .chooseName)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(author: author, flowState: .success)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(author: author, flowState: .error)
            }
                        VStack {}
            .sheet(isPresented: .constant(true)) {
                UniversalNameWizard(author: author, flowState: .nameTaken)
            }
    }
}
