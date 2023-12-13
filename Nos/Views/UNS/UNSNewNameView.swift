//
//  UNSNewNameView.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/12/23.
//

import SwiftUI
import Dependencies
import Logger

struct UNSNewNameView: View {
    
    @Dependency(\.analytics) var analytics
    @ObservedObject var controller: UNSWizardController
    @Dependency(\.unsAPI) var api
    @State var name: UNSName = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    UNSStepImage { Image.unsName.offset(x: 7, y: 5) }
                        .padding(20)
                        .padding(.top, 50)
                    
                    PlainText(.localizable.chooseYourName)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                        .padding(20)
                    
                    Text(.localizable.chooseYourNameDescription)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondaryTxt)
                        .padding(.vertical, 17)
                        .padding(.horizontal, 20)
                        .shadow(radius: 1, y: 1)
                    
                    Spacer()
                    WizardTextField(text: $name)
                    Spacer()
                    
                    BigActionButton(title: .localizable.next) {
                        await submit()
                    }
                    .padding(.vertical, 31)
                }
                .padding(.horizontal, 38)
                .readabilityPadding()
            }
            .background(Color.appBg)
        }
    }
    
    func submit() async {
        do {
            try await controller.register(desiredName: name)
        } catch {
            controller.state = .error(error)
        }   
    }
}

#Preview {
    @State var controller = UNSWizardController()
    return UNSNewNameView(controller: controller)
}
