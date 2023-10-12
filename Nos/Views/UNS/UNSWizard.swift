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
                UNSNewName(controller: controller)
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
