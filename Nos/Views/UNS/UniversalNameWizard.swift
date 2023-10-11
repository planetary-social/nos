//
//  UniversalNameWizard.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/20/23.
//

import SwiftUI
import Dependencies

typealias UNSName = String

extension UNSName: Identifiable {
    public var id: String {
        self
    }
}

struct UNSWizardContext {
    
    enum FlowState {
        case loading
        case intro
        case enterPhone
        case enterOTP
        case newName
        case chooseName
        case success
        case error
        case nameTaken
        case needsPayment(URL)
    }
    
    var state: FlowState = .intro
    var authorKey: HexadecimalString?
    var textField: String = ""
    var phoneNumber: String?
    var nameRecord: UNSNameRecord?
    
    /// All names the user has already registered
    var names: [UNSNameRecord]?
}

struct UniversalNameWizard: View {
        
    @Binding var context: UNSWizardContext
    @Binding var isPresented: Bool
    
    enum Flow {
        case signUp
        case login
    }
    
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var currentUser: CurrentUser
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    
    @State private var flow: Flow?
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        VStack {
            switch context.state {
            case .intro:
                UNSWizardIntro(context: $context)
            case .enterPhone:
                UNSWizardPhone(context: $context)
               
            case .enterOTP:
                UNSWizardOTP(context: $context)
                
            case .loading:
                FullscreenProgressView(isPresented: .constant(true))
            case .chooseName:
                UNSWizardChooseName(context: $context)
                
            case .needsPayment:
                UNSWizardNeedsPayment(context: $context)
            case .newName:
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
                    guard let authorKey = context.authorKey else {
                        context.state = .error
                        return
                    }
                    
                    do {
                        context.state = .loading
                        analytics.choseUNSName()
                        try await api.createName(
                            context.textField.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        let names = try await api.getNames()
                        context.nameRecord = names.first!
                        let message = try await api.requestNostrVerification(npub: currentUser.keyPair!.npub, nameID: context.nameRecord!.id)!
                        let nip05 = try await api.submitNostrVerification(
                            message: message,
                            keyPair: currentUser.keyPair!
                        )
                        let author = try Author.find(by: authorKey, context: viewContext)!
                        author.name = context.nameRecord?.name
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
                    context.state = .newName
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
                    Text("\(context.nameRecord?.name ?? "") \(Localized.yourNewUNMessage.string)")
                        .padding()
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 500)
                        .foregroundColor(.primaryTxt)
                    Spacer()
                    BigActionButton(title: .dismiss) {
                        isPresented = false
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 50)
                }
                .frame(maxWidth: .infinity)
                .onAppear {
                    analytics.completedUNSWizard()
                }
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
            switch context.state {
            case .success:
                return
            default:
                analytics.canceledUNSWizard()
            }
        }
        .background(Color.appBg)
        .nosNavigationBar(title: .setUpUNS)
    }
}

#Preview {
    
    @State var context = UNSWizardContext(authorKey: KeyFixture.pubKeyHex)
    @State var isPresented = true
    @State var previewData = PreviewData()
    
    return UniversalNameWizard(context: $context, isPresented: $isPresented)
        .inject(previewData: previewData)
}
