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
    
    @Dependency(\.analytics) private var analytics
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
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
//                        let keyPair = KeyPair()!
//                        self.keyPair = keyPair
//                        analytics.identify(with: keyPair)
//                        analytics.generatedKey()
//
//                        // Default Relays for new user
//                        for address in Relay.defaults {
//                            Relay(context: viewContext, address: address, author: CurrentUser.author)
//                        }
//
//                        CurrentUser.publishContactList(tags: [])
//
//                        completion()
                        selectedTab = .ageVerification
                    }
                    .padding()
                    NavigationLink(Localized.logInWithYourKeys.string) {
                        VStack {
                            Form {
                                Section {
                                    TextField("NSec1", text: $privateKeyString)
                                } header: {
                                    Localized.pasteYourSecretKey.view
                                }
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
                            }
                        }
                        .navigationTitle(Localized.loginToYourAccount.string)
                        .alert(isPresented: $showError) {
                            Alert(
                                title: Localized.invalidKey.view,
                                message: Localized.couldNotReadPrivateKeyMessage.view
                            )
                        }
                    }
                    .padding()
                }
                .background(Color.appBg)
            }
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
                        // TODO: create account
                    }
                }
                .padding(.horizontal, 24)
            }
            .background(Color.appBg)
            .tag(OnboardingStep.termsOfService)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView {}
    }
}
