//
//  UNSWizard.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/20/23.
//

import SwiftUI
import Dependencies

struct UNSWizard: View {
        
    @ObservedObject var controller: UNSWizardController
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
            switch controller.state {
            case .intro:
                UNSWizardIntro(controller: controller)
            case .enterPhone:
                UNSWizardPhone(controller: controller)
               
            case .enterOTP:
                UNSWizardOTP(controller: controller)
                
            case .loading:
                FullscreenProgressView(isPresented: .constant(true))
            case .chooseName:
                UNSWizardChooseName(controller: controller)
                
            case .needsPayment:
                UNSWizardNeedsPayment(controller: controller)
            case .newName:
                Form {
                    Section {
                        TextField(text: $controller.textField) {
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
                    guard let authorKey = controller.authorKey else {
                        controller.state = .error
                        return
                    }
                    
                    do {
                        controller.state = .loading
                        analytics.choseUNSName()
                        try await api.createName(
                            controller.textField.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        let names = try await api.getNames()
                        controller.nameRecord = names.first!
                        let message = try await api.requestNostrVerification(npub: currentUser.keyPair!.npub, nameID: controller.nameRecord!.id)!
                        let nip05 = try await api.submitNostrVerification(
                            message: message,
                            keyPair: currentUser.keyPair!
                        )
                        let author = try Author.find(by: authorKey, context: viewContext)!
                        author.name = controller.nameRecord?.name
                        author.nip05 = nip05
                        await currentUser.publishMetaData()
                        controller.state = .success
                    } catch {
                        controller.state = .error
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
                    controller.state = .newName
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
                    Text("\(controller.nameRecord?.name ?? "") \(Localized.yourNewUNMessage.string)")
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
                    controller.state = .enterPhone
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
            switch controller.state {
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
    
    @State var controller = UNSWizardController(authorKey: KeyFixture.pubKeyHex)
    @State var isPresented = true
    @State var previewData = PreviewData()
    
    return UNSWizard(controller: controller, isPresented: $isPresented)
        .inject(previewData: previewData)
}
