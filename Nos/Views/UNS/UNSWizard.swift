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
    @Environment(CurrentUser.self) private var currentUser
    @Dependency(\.analytics) var analytics
    
    @State private var flow: Flow?
    
    enum FocusedField {
        case textEditor
    }
    
    @FocusState private var focusedField: FocusedField?
    
    var body: some View {
        VStack {
            switch controller.state {
            case .intro:
                UNSWizardIntroView(controller: controller)
            case .enterPhone:
                UNSWizardPhoneView(controller: controller)
            case .verificationCode:
                UNSVerifyCodeView(controller: controller)
            case .loading:
                FullscreenProgressView(isPresented: .constant(true))
            case .chooseName:
                UNSWizardChooseNameView(controller: controller)
            case .needsPayment:
                UNSWizardNeedsPaymentView(controller: controller)
            case .newName:
                UNSNewNameView(controller: controller)
            case .nameTaken:
                UNSNameTakenView(controller: controller)
            case .success:
                UNSSuccessView(controller: controller, isPresented: $isPresented)
            case .error:
                UNSErrorView(controller: controller)
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
        .nosNavigationBar(title: .localizable.setUpUNS)
    }
}

#Preview {
    
    @State var controller = UNSWizardController(authorKey: KeyFixture.pubKeyHex)
    @State var isPresented = true
    @State var previewData = PreviewData()
    
    return UNSWizard(controller: controller, isPresented: $isPresented)
        .inject(previewData: previewData)
}
