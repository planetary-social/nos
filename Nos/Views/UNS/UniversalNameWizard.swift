//
//  UniversalNameWizard.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/20/23.
//

import SwiftUI
import Dependencies

struct UNSWizardContext {
    
    enum FlowState {
        case loading
        case intro
        case enterPhone
        case enterOTP
        case chooseName
        case success
        case error
        case nameTaken
    }
    
    var state: FlowState
    var authorKey: HexadecimalString
    var completionHandler: (() -> Void)?
    var textField: String = ""
    var phoneNumber: String?
    var name: String?
    var api = UNSAPI()!
}

struct UniversalNameWizard: View {
        
    @State var context: UNSWizardContext
    
    var author: Author

    var dismiss: (() -> Void)?
    
    enum Flow {
        case signUp
        case login
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var currentUser: CurrentUser
    @Dependency(\.analytics) var analytics
    
    @State private var flow: Flow?
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?
    
    let api = UNSAPI()!
    
    init(author: Author, completion: @escaping () -> Void) {
        self.author = author
        self.context = UNSWizardContext(state: .intro, authorKey: author.hexadecimalPublicKey!, completionHandler: completion)
    }
    
    var body: some View {
        VStack {
            switch context.state {
            case .intro:
                UNSWizardIntro(context: $context)
            case .enterPhone:
                UNSWizardPhone(context: $context)
               
            case .enterOTP:
                Form {
                    Section {
                        TextField(text: $context.textField) {
                            Text("123456")
                                .foregroundColor(.secondaryText)
                        }
                        .foregroundColor(.primaryTxt)
                        .keyboardType(.phonePad)
                        .autocorrectionDisabled()
                        .focused($focusedField, equals: .textEditor)
                    } header: {
                        Localized.enterCode.view
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
                    do {
                        context.state = .loading
                        analytics.enteredUNSCode()
                        try await api.verifyOTPCode(
                            phoneNumber: context.phoneNumber!,
                            code: context.textField.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        context.textField = ""
                        let names = try await api.getNames()
                        if let name = names.first {
                            context.name = name
                            var nip05: String
                            if let message = try await api.requestNostrVerification(
                                npub: currentUser.keyPair!.npub
                            ) {
                                nip05 = try await api.submitNostrVerification(
                                    message: message,
                                    keyPair: currentUser.keyPair!
                                )
                            } else {
                                nip05 = try await api.getNIP05()
                            }
                            author.name = name
                            author.nip05 = nip05
                            await currentUser.publishMetaData()
                            try viewContext.save()
                            context.state = .success
                        } else {
                            context.state = .chooseName
                        }
                    } catch {
                        context.textField = ""
                        context.state = .error
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                
            case .loading:
                FullscreenProgressView(isPresented: .constant(true))
            case .chooseName:
                Form {
                    Section {
                        TextField(text: $context.textField) {
                            Localized.name.view
                                .foregroundColor(.secondaryText)
                        }
                        .textInputAutocapitalization(.none)
                        .foregroundColor(.primaryTxt)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .focused($focusedField, equals: .textEditor)
                    } header: {
                        Localized.chooseYourName.view
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
                    do {
                        context.state = .loading
                        analytics.choseUNSName()
                        guard try await api.createName(
                            context.textField.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        ) else {
                            context.state = .nameTaken
                            return
                        }
                        let names = try await api.getNames()
                        context.name = names.first!
                        let message = try await api.requestNostrVerification(npub: currentUser.keyPair!.npub)!
                        let nip05 = try await api.submitNostrVerification(
                            message: message,
                            keyPair: currentUser.keyPair!
                        )
                        let author = try Author.find(by: context.authorKey, context: viewContext)!
                        author.name = context.name
                        author.nip05 = nip05
                        await currentUser.publishMetaData()
                        context.state = .success
                    } catch {
                        context.state = .error
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
            case .nameTaken:
                Spacer()
                PlainText(Localized.oops.string)
                    .font(.title2)
                    .padding()
                    .foregroundColor(.primaryTxt)
                PlainText(Localized.thatNameIsTaken.string)
                    .font(.body)
                    .padding()
                    .foregroundColor(.primaryTxt)
                Spacer()
                BigActionButton(title: .goBack) {
                    context.state = .chooseName
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .onAppear {
                    analytics.choseInvalidUNSName()
                }
            case .success:
                VStack {
                    PlainText(Localized.success.string)
                        .font(.title)
                        .padding(.top, 50)
                        .foregroundColor(.primaryTxt)
                    Text("\(context.name ?? "") \(Localized.yourNewUNMessage.string)")
                        .padding()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 500)
                        .foregroundColor(.primaryTxt)
                    Spacer()
                    BigActionButton(title: .dismiss) {
                        analytics.completedUNSWizard()
                        dismiss?()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
                .frame(maxWidth: .infinity)
            case .error:
                Spacer()
                PlainText(Localized.oops.string)
                    .font(.title2)
                    .padding()
                    .foregroundColor(.primaryTxt)
                PlainText(Localized.anErrorOccurred.string)
                    .font(.body)
                    .padding()
                    .foregroundColor(.primaryTxt)
                Spacer()
                BigActionButton(title: .startOver) {
                    context.state = .enterPhone
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .onAppear {
                    analytics.encounteredUNSError()
                }
            }
        }
        .onAppear {
            focusedField = .textEditor
            analytics.showedUNSWizard()
        }
        .onDisappear {
            if context.state != .success {
                analytics.canceledUNSWizard()
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .setUpUNS)
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
        UniversalNameWizard(author: author) {}
    }
}
