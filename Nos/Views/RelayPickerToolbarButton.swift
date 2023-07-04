//
//  RelayPickerToolbarButton.swift
//  Nos
//
//  Created by Matthew Lorentz on 6/16/23.
//

import SwiftUI

struct RelayPickerToolbarButton: ToolbarContent {
    
    @Binding var selectedRelay: Relay?
    @Binding var isPresenting: Bool
    var defaultSelection: Localized
    var action: () -> Void
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    var title: String {
        if let selectedRelay {
            return selectedRelay.host ?? Localized.error.string
        } else {
            return defaultSelection.string
        }
    }
    
    var imageName: String {
        if isPresenting {
            return "chevron.up"
        } else {
            return "chevron.down"
        }
    }
    
    var disclosureIndicator: some View {
        Image(systemName: imageName)
            .font(.system(size: 10))
            .fontWeight(.black)
            .foregroundColor(.secondaryText)
            .background(
                Circle()
                    .foregroundColor(.appBg)
                    .frame(width: 25, height: 25)
            )
    }
    
    var maxWidth: CGFloat {
        horizontalSizeClass == .regular ? 400 : 190
    }
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            HStack {
                Button {
                    action()
                } label: {
                    HStack {
                        PlainText(title)
                            .font(.clarityTitle3)
                            .foregroundColor(.primaryTxt)
                            .bold()
                            .padding(.leading, 14)
                        disclosureIndicator
                    }
                    .frame(maxWidth: maxWidth)
                }
                .frame(height: 35)
                .padding(.bottom, 3)
            }
        }
    }
}

struct RelayPickerToolbarButton_Previews: PreviewProvider {
    
    static var previews: some View {
        StatefulPreviewContainer(false) { isPresented in
            StatefulPreviewContainer(nil as Relay?) { selectedRelay in
                NavigationStack {
                    VStack {
                        Spacer()
                    }
                    .background(Color.appBg)
                    .toolbar {
                        
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button {}
                            label: {
                                Localized.cancel.view
                                    .foregroundColor(.secondaryText)
                            }
                        }
                        RelayPickerToolbarButton(
                            selectedRelay: selectedRelay, 
                            isPresenting: isPresented, 
                            defaultSelection: .allMyRelays
                        ) {}
                        ToolbarItem(placement: .navigationBarTrailing) {
                            ActionButton(title: Localized.post, action: {})
                                .frame(height: 22)
                                .padding(.bottom, 3)
                        }
                    }
                    .navigationBarTitle(Localized.discover.string, displayMode: .inline)
                    .toolbarBackground(.visible, for: .navigationBar)
                    .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
                }
            }
        }
    }
}
