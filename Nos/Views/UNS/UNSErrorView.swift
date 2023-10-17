//
//  UNSErrorView.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/13/23.
//

import SwiftUI
import Dependencies
import Logger

struct UNSErrorView: View {
    
    @ObservedObject var controller: UNSWizardController
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    
    var body: some View {
        NavigationView {
            VStack {
                ScrollView {
                    UNSStepImage { Image.unsOtp.offset(x: 7, y: 5) }
                        .padding(40)
                        .padding(.top, 50)
                    
                    PlainText(.oops)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                        .padding(.top, 20)
                        .padding(.bottom, 3)
                    
                    PlainText(.anErrorOccurred)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                        .padding(.bottom, 20)
                    
                    Text(.tryAgainOrContactSupport)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondaryText)
                        .padding(.vertical, 17)
                        .padding(.horizontal, 20)
                        .shadow(radius: 1, y: 1)
                        .padding(.bottom, 20)
                }
                
                Spacer()
                
                BigActionButton(title: .goBack) {
                    if api.accessToken != nil {
                        do { 
                            try await controller.navigateToChooseOrRegisterName()
                        } catch {
                            Log.optional(error)
                            controller.state = .enterPhone
                        }
                    } else {
                        controller.state = .enterPhone
                    }
                }
                .padding(.bottom, 41)
            }
            .padding(.horizontal, 38)
            .readabilityPadding()
            .background(Color.appBg)
            .onAppear {
                switch controller.state {
                case .error(let error):
                    Log.optional(error, "UNSWizard encountered an error.")
                    analytics.encounteredUNSError(error)
                default:
                    Log.error("UNSWizard encountered an error.")
                }
            }
        } 
    }
}

#Preview {
    @State var controller = UNSWizardController(state: .error(nil))
    
    return UNSErrorView(controller: controller)
}
