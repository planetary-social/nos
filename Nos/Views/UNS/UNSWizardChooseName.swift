//
//  UNSWizardChooseName.swift
//  Nos
//
//  Created by Matthew Lorentz on 9/29/23.
//

import SwiftUI
import Dependencies
import Logger

fileprivate struct PickerRow<Label: View>: View {
    @Binding var isSelected: Bool
    var label: Label
    
    init(isSelected: Binding<Bool>, @ViewBuilder builder: () -> Label) {
        self._isSelected = isSelected
        self.label = builder()
    }
    
    var body: some View {
        HStack {
                if isSelected {
                    Circle()
                        .foregroundStyle(LinearGradient.verticalAccent)
                        .frame(width: 16, height: 16)
                } else {
                    Circle()
                        .stroke(Color.secondaryAction)
                        .frame(width: 16, height: 16)
                }
            
            if isSelected {
                label.foregroundStyle(LinearGradient.verticalAccent) 
            } else {
                label.foregroundStyle(Color.primaryTxt) 
            }
            
            Spacer()
        }
        .padding(.horizontal, 15)
        .padding(.top, 15)
    }
}

struct UNSWizardChooseName: View {
    
    @Environment(\.managedObjectContext) private var viewContext
    @Dependency(\.analytics) var analytics
    @Dependency(\.unsAPI) var api
    @Dependency(\.currentUser) var currentUser 
    @Binding var context: UNSWizardContext
    @State var selectedName: UNSName?
    @State var desiredName: UNSName = ""

    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    //                    UNSStepImage { Image.unsOTP.offset(x: 7, y: 5) }
                    //                        .padding(40)
                    //                        .padding(.top, 50)
                    //                    
                    //                    PlainText(.verification)
                    //                        .font(.clarityTitle)
                    //                        .multilineTextAlignment(.center)
                    //                        .foregroundColor(.primaryTxt)
                    //                        .shadow(radius: 1, y: 1)
                    
                    
                    VStack {
                        
                        if let names = context.names {
                            ForEach(names) { name in
                                Button { 
                                    selectedName = name
                                    desiredName = ""
                                } label: { 
                                    let isSelected = Binding { 
                                        selectedName == name && desiredName.isEmpty
                                    } set: { isSelected in
                                        if isSelected {
                                            selectedName = name
                                        } else {
                                            selectedName = nil
                                        }
                                    }

                                    PickerRow(isSelected: isSelected) {
                                        PlainText(name)
                                            .font(.clarityTitle2)
                                    }
                                }
                            }
                            .onAppear {
                                selectedName = names.first
                            }
                        }
                        
                        Rectangle()
                            .frame(height: 2)
                            .foregroundColor(.secondaryAction)

                        let isSelected = Binding { 
                            !desiredName.isEmpty
                        } set: { newValue in
                            
                        }

                        PickerRow(isSelected: isSelected) { 
                            PlainTextField(text: $desiredName) {
                                PlainText(.createNewName)
                                    .foregroundColor(.secondaryText)
                            }
                            .font(.clarityTitle2)
                            .foregroundStyle(LinearGradient.verticalAccent)
                            .foregroundColor(.primaryTxt)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.none)
                            .padding(19)
                            Spacer()
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondaryAction, lineWidth: 2)
                            .background(Color.textFieldBg)
                    )
                    
                    Spacer()
                    
                    BigActionButton(title: .next) {
                        await submit()
                    }
                    .padding(.bottom, 41)
                }
                .padding(.horizontal, 38)
                .readabilityPadding()
            }
            .background(Color.appBg)
        }    
    }
    
    @MainActor func submit() async {
        do {
            if !desiredName.isEmpty {
                try await register(desiredName: desiredName)
            } else if let selectedName {
                context.name = selectedName
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
                await saveDetails(name: selectedName, nip05: nip05)
            }
        } catch {
            Log.optional(error)
            context.state = .error
        }
    }
    
    func register(desiredName: UNSName) async throws {
        context.state = .loading
        analytics.choseUNSName()
        do {
            try await api.createName(
                // TODO: sanitize somewhere else
                desiredName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            ) 
        } catch {
            if case let UNSError.requiresPayment(paymentURL) = error {
                print("go to \(paymentURL) to complete payment")
            } else {
                context.state = .nameTaken
                return
            }
        }
        context.name = desiredName
        let message = try await api.requestNostrVerification(npub: currentUser.keyPair!.npub)!
        let nip05 = try await api.submitNostrVerification(
            message: message,
            keyPair: currentUser.keyPair!
        )
        await saveDetails(name: desiredName, nip05: nip05)
    }
    
    @MainActor func saveDetails(name: String, nip05: String) async {
        let author = currentUser.author
        author?.name = context.name
        author?.nip05 = nip05
        await currentUser.publishMetaData()
        context.state = .success
    }
}

#Preview {
    
    var previewData = PreviewData()
    @State var context = UNSWizardContext(
        state: .chooseName, 
        authorKey: previewData.alice.hexadecimalPublicKey!,
        names: ["Fred", "Sally", "Hubert Blaine Wolfeschlegelsteinhausenbergerdorff Sr."]
    )
    
    return UNSWizardChooseName(context: $context)
}
