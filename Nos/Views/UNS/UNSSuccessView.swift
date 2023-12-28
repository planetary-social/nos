//
//  UNSSuccessView.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/12/23.
//

import SwiftUI
import Dependencies

struct UNSSuccessView: View {
    
    @ObservedObject var controller: UNSWizardController
    @Binding var isPresented: Bool
    @Dependency(\.analytics) var analytics
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    ZStack {
                        Circle()
                            .foregroundColor(.init(.unsLogoBackground))
                        Image.unsCircle.opacity(colorScheme == .dark ? 0.15 : 1)
                        VStack(spacing: 0) {
                            Image.unsCheck
                            PlainText(controller.nameRecord?.name ?? "")
                                .font(.clarityTitle)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primaryTxt)
                                .shadow(radius: 1, y: 1)
                        }
                    }
                    .frame(width: 178, height: 178)
                    .padding(20)
                    .padding(.top, 50)
                    
                    PlainText(.localizable.success)
                        .font(.clarityTitle)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primaryTxt)
                        .shadow(radius: 1, y: 1)
                        .padding(20)
                    
                    Text(.localizable.unsSuccessDescription)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondaryTxt)
                        .padding(.vertical, 17)
                        .padding(.horizontal, 20)
                        .shadow(radius: 1, y: 1)
                        .padding(20)
                }
                
                Spacer()
                
                BigActionButton(title: .localizable.done) {
                    isPresented = false
                }
                .padding(.bottom, 41)
            }
            .padding(.horizontal, 38)
            .readabilityPadding()
            .background(Color.appBg)
            .onAppear {
                analytics.completedUNSWizard()
            }
        }
    }
}

#Preview {
    @State var isPresented = true
    @State var controller = UNSWizardController(nameRecord: UNSNameRecord(name: "Chardot", id: "1"))
    
    return VStack {}
        .sheet(isPresented: $isPresented, content: {
            UNSSuccessView(controller: controller, isPresented: $isPresented)
        })
}
