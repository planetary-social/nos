//
//  OnboardingView.swift
//  Nos
//
//  Created by Shane Bielefeld on 2/14/23.
//

import SwiftUI
import Dependencies

struct OnboardingView: View {
    @Environment(\.managedObjectContext) private var viewContext

    enum OnboardingStep {
        case onboardingStart
        case addPrivateKey
        case ageVerification
        case notOldEnough
        case termsOfService
        case createAccount
    }
    
    enum OnboardingFlow {
        case createAccount
        case loginToExistingAccount
    }
    
    /// Completion to be called when all onboarding steps are complete
    let completion: () -> Void
    
    @State private var selectedTab: OnboardingStep = .onboardingStart
    
    @State private var keyPair: KeyPair? {
        didSet {
            if let pair = keyPair {
                let privateKey = Data(pair.privateKeyHex.utf8)
                let publicStatus = KeyChain.save(key: KeyChain.keychainPrivateKey, data: privateKey)
                print("Public key keychain storage status: \(publicStatus)")
            }
        }
    }
    
    @State var privateKeyString = ""
    
    @State var showError = false
    
    @State var flow: OnboardingFlow = .createAccount
    
    @State var path = NavigationPath()
    
    @Dependency(\.analytics) private var analytics
    
    var loginView: some View {
        VStack {
            Form {
                Section {
                    TextField("NSec1", text: $privateKeyString)
                        .foregroundColor(.textColor)
                } header: {
                    Localized.pasteYourSecretKey.view
                        .foregroundColor(.textColor)
                        .fontWeight(.heavy)
                }
                .listRowBackground(LinearGradient(
                    colors: [Color.cardBgTop, Color.cardBgBottom],
                    startPoint: .top,
                    endPoint: .bottom
                ))
            }
            if !privateKeyString.isEmpty {
                BigActionButton(title: .login) {
                    if let keyPair = KeyPair(nsec: privateKeyString) {
                        self.keyPair = keyPair
                        analytics.identify(with: keyPair)
                        analytics.importedKey()
                        completion()
                    } else {
                        self.keyPair = nil
                        self.showError = true
                    }
                }
                .padding(.horizontal, 24)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.appBg)
        .navigationTitle(Localized.loginToYourAccount.string)
        .alert(isPresented: $showError) {
            Alert(
                title: Localized.invalidKey.view,
                message: Localized.couldNotReadPrivateKeyMessage.view
            )
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                Image.nosLogo
                    .resizable()
                    .frame(width: 235.45, height: 67.1)
                    .padding(.top, 155)
                    .padding(.bottom, 10)
                PlainText(Localized.onboardingTitle.string)
                    .font(.custom("ClarityCity-Bold", size: 25.21))
                    .fontWeight(.heavy)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#F08508"),
                                Color(hex: "#F43F75")
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                        .blendMode(.normal)
                    )
                Spacer()
                BigActionButton(title: .createAccount) {
                    flow = .createAccount
                    selectedTab = .ageVerification
                }
                .padding()
                Button(Localized.loginToYourAccount.string) {
                    flow = .loginToExistingAccount
                    selectedTab = .ageVerification
                }
            }
            .background(Color.appBg)
            .tag(OnboardingStep.onboardingStart)
            
            // Age verification
            VStack {
                PlainText(Localized.ageVerificationTitle.string)
                    .multilineTextAlignment(.center)
                    .padding(.top, 92)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 77.5)
                    .font(.custom("ClarityCity-Bold", size: 34, relativeTo: .largeTitle))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#F08508"),
                                Color(hex: "#F43F75")
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                        .blendMode(.normal)
                    )
                Text(Localized.ageVerificationSubtitle.string)
                    .foregroundColor(.secondaryTxt)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44.5)
                Spacer()
                HStack {
                    BigActionButton(title: .no) {
                        selectedTab = .notOldEnough
                    }
                    BigActionButton(title: .yes) {
                        selectedTab = .termsOfService
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(Color.appBg)
            .tag(OnboardingStep.ageVerification)
            
            // Not old enough
            VStack {
                PlainText(Localized.notOldEnoughTitle.string)
                    .font(.custom("ClarityCity-Bold", size: 34, relativeTo: .largeTitle))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(hex: "#F08508"),
                                Color(hex: "#F43F75")
                            ],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        )
                        .blendMode(.normal)
                    )
                    .multilineTextAlignment(.center)
                    .padding(.top, 92)
                    .padding(.bottom, 20)
                    .padding(.horizontal, 45)
                Text(Localized.notOldEnoughSubtitle.string)
                    .foregroundColor(.secondaryTxt)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 45)
                Spacer()
                BigActionButton(title: .notOldEnoughButton) {
                    selectedTab = .onboardingStart
                }
                .padding(.horizontal, 24)
            }
            .background(Color.appBg)
            .tag(OnboardingStep.notOldEnough)
            
            // Terms of Service
            NavigationStack(path: $path) {
                VStack {
                    PlainText(Localized.termsOfServiceTitle.string)
                        .font(.custom("ClarityCity-Bold", size: 34, relativeTo: .largeTitle))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#F08508"),
                                    Color(hex: "#F43F75")
                                ],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                            .blendMode(.normal)
                        )
                        .padding(.top, 92)
                        .padding(.bottom, 60)
                    ScrollView {
                        Text(Localized.termsOfService.string)
                            .foregroundColor(.secondaryTxt)
                    }
                    .padding(.horizontal, 44.5)
                    HStack {
                        BigActionButton(title: Localized.reject) {
                            selectedTab = .onboardingStart
                        }
                        BigActionButton(title: Localized.accept) {
                            if flow == .createAccount {
                                let keyPair = KeyPair()!
                                self.keyPair = keyPair
                                analytics.identify(with: keyPair)
                                analytics.generatedKey()
                                
                                // Default Relays for new user
                                for address in Relay.defaults {
                                    Relay(context: viewContext, address: address, author: CurrentUser.author)
                                }
                                
                                CurrentUser.publishContactList(tags: [])
                            }
                            path.append(flow)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .navigationDestination(for: OnboardingFlow.self) { flow in
                    if flow == .loginToExistingAccount {
                        loginView
                    } else {
                        ProfileEditView(author: CurrentUser.author!, createAccountCompletion: completion)
                    }
                }
                .background(Color.appBg)
            }
            .tag(OnboardingStep.termsOfService)
        }
    }
    
    @State var finishOnboardingAction: Int? = 0
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {}
    }
}
