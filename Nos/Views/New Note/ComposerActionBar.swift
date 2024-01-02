//
//  ComposerActionBar.swift
//  Nos
//
//  Created by Matthew Lorentz on 5/3/23.
//

import Foundation
import SwiftUI
import SwiftUINavigation

/// A horizontal bar that gives the user options to customize their message in the message composer.
struct ComposerActionBar: View {
    
    @Binding var expirationTime: TimeInterval?
    @Binding var text: EditableNoteText
    @State var fileStorageAPI: FileStorageAPI = NostrBuildFileStorageAPI()
    
    enum SubMenu {
        case expirationDate
    }
    
    @State private var subMenu: SubMenu?
    @State private var uploadingImage = false
    @State private var alert: AlertState<AlertAction>?
    
    fileprivate enum AlertAction {
    }
    
    var backArrow: some View {
        Button {
            subMenu = .none
        } label: {
            Image.backChevron
                .frame(minWidth: 44, minHeight: 44)
        }
        .transition(.opacity)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            switch subMenu {
            case .none:
                // Attach Media
                ImagePickerButton { image in
                    Task {
                        do {
                            startUploadingImage()
                            let attachedFile = AttachedFile(image: image)
                            let url = try await fileStorageAPI.upload(file: attachedFile)
                            text.append(url)
                            endUploadingImage()
                        } catch {
                            endUploadingImage()
                            print("error uploading: \(error)")
                            
                            alert = AlertState(title: {
                                TextState(String(localized: .imagePicker.errorUploadingFile))
                            }, message: {
                                TextState(String(localized: .imagePicker.errorUploadingFileMessage))
                            })
                        }
                    }
                } label: {
                    Image.attachMediaButton
                        .foregroundColor(.secondaryTxt)
                        .frame(minWidth: 44, minHeight: 44)
                }
                .padding(.leading, 8)
                .accessibilityLabel(Text(.localizable.attachMedia))
                
                // Expiration Time
                if let expirationTime, let option = ExpirationTimeOption(rawValue: expirationTime) {
                    ExpirationTimeButton(
                        model: option,
                        showClearButton: true,
                        isSelected: Binding(get: {
                            self.expirationTime == option.timeInterval
                        }, set: {
                            self.expirationTime = $0 ? option.timeInterval : nil
                        })
                    )
                    .accessibilityLabel(Text(.localizable.expirationDate))
                    .padding(12)
                } else {
                    Button {
                        subMenu = .expirationDate
                    } label: {
                        Image.disappearingMessages
                            .foregroundColor(.secondaryTxt)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                }
            case .expirationDate:
                backArrow
                ScrollView(.horizontal) {
                    HStack {
                        PlainText(.localizable.noteDisappearsIn)
                            .font(.clarityCaption)
                            .foregroundColor(.secondaryTxt)
                            .transition(.move(edge: .trailing))
                            .padding(10)
                        
                        ExpirationTimePicker(expirationTime: $expirationTime)
                            .padding(.vertical, 12)
                    }
                }
            }
            Spacer()
        }
        .sheet(isPresented: $uploadingImage) {
            FullscreenProgressView(
                isPresented: .constant(true), 
                text: String(localized: .imagePicker.uploading)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: subMenu)
        .transition(.move(edge: .leading))
        .onChange(of: expirationTime) { _, _ in
            subMenu = .none
        }
        .alert(unwrapping: $alert) { (_: AlertAction?) in
        }
        .background(
            LinearGradient(
                colors: [Color.actionBarGradientTop, Color.actionBarGradientBottom],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .overlay(
            Rectangle()
                .frame(width: nil, height: 1, alignment: .top)
                .foregroundColor(Color.actionBarBorderTop),
            alignment: .top
        )
    }
    
    private func startUploadingImage() {
        self.uploadingImage = true
    }
    
    private func endUploadingImage() {
        self.uploadingImage = false
        self.subMenu = .none
    }
}

struct ComposerActionBar_Previews: PreviewProvider {
    
    @State static var emptyExpirationTime: TimeInterval?
    @State static var setExpirationTime: TimeInterval? = 60 * 60
    @State static var postText = EditableNoteText()
    
    static var previews: some View {
        VStack {
            Spacer()
            ComposerActionBar(expirationTime: $emptyExpirationTime, text: $postText)
            Spacer()
            ComposerActionBar(expirationTime: $setExpirationTime, text: $postText)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .environment(\.sizeCategory, .extraExtraLarge)
    }
}
