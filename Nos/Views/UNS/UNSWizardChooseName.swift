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
    @ObservedObject var controller: UNSWizardController
    @State var selectedName: UNSNameRecord?
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
                        
                        if let names = controller.names {
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
                                        PlainText(name.name)
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
                try await controller.register(desiredName: desiredName)
            } else if let selectedName {
                try await controller.link(existingName: selectedName)
            }
        } catch {
            Log.optional(error)
            controller.state = .error
        }
    }
}

#Preview {
    
    var previewData = PreviewData()
    @State var controller = UNSWizardController(
        state: .chooseName, 
        authorKey: previewData.alice.hexadecimalPublicKey!,
        names: [
            UNSNameRecord(name: "Fred", id: "1"),
            UNSNameRecord(name: "Sally", id: "2"),
            UNSNameRecord(name: "Hubert Blaine Wolfeschlegelsteinhausenbergerdorff Sr.", id: "3"),
        ]
    )
    
    return UNSWizardChooseName(controller: controller)
}
