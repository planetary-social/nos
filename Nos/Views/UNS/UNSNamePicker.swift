//
//  UNSNamePicker.swift
//  Nos
//
//  Created by Matthew Lorentz on 10/12/23.
//

import SwiftUI

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
                    .stroke(Color.secondaryTxt)
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

struct UNSNamePicker: View {
    
    @Binding var selectedName: UNSNameRecord?
    @Binding var desiredName: UNSName
    @ObservedObject var controller: UNSWizardController
    @FocusState private var isTextFieldFocused: Bool
    
    var textFieldForegroundStyle: LinearGradient {
        if isTextFieldFocused {
            LinearGradient.verticalAccent
        } else {
            LinearGradient(colors: [Color.primaryTxt], startPoint: .top, endPoint: .bottom)
        } 
    }
    
    var body: some View {
        VStack {
            VStack {
                if let names = controller.names {
                    ForEach(names) { name in
                        Button { 
                            selectedName = name
                            isTextFieldFocused = false
                        } label: { 
                            let isSelected = Binding { 
                                selectedName == name && !isTextFieldFocused
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
            }
            .padding(.vertical, 15)
            
            Rectangle()
                .frame(height: 2)
                .foregroundColor(.secondaryTxt)

            HStack(spacing: 0) {
                if isTextFieldFocused {
                    Circle()
                        .foregroundStyle(LinearGradient.verticalAccent)
                        .frame(width: 16, height: 16)
                } else {
                    Circle()
                        .stroke(Color.secondaryTxt)
                        .frame(width: 16, height: 16)
                }
                
                PlainTextField(text: $desiredName) {
                    PlainText(.localizable.createNewName)
                        .foregroundColor(.secondaryTxt)
                }
                .focused($isTextFieldFocused)
                .font(.clarityTitle2)
                .foregroundStyle(textFieldForegroundStyle)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.none)
                .padding(15)
                .offset(x: -6)
                .onChange(of: desiredName) { _, newValue in
                    if newValue.isEmpty == false {
                        selectedName = nil
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 15)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.secondaryTxt, lineWidth: 2)
                .background(Color.textFieldBg)
        )    
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State var controller = UNSWizardController(names: [
            UNSNameRecord(name: "Sebastian", id: "1"),
            UNSNameRecord(name: "Chardot", id: "2"),
            UNSNameRecord(name: "Seb", id: "3"),
        ])
        @State var selectedName: UNSNameRecord?
        @State var desiredName: UNSName = ""
        
        var body: some View {
            VStack {
                Spacer()
                UNSNamePicker(selectedName: $selectedName, desiredName: $desiredName, controller: controller)
                    .padding(20)
                Spacer()
            }
            .background(Color.appBg)
        }
    }
    return PreviewWrapper().preferredColorScheme(.dark)
}
