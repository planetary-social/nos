//
//  CreateUsernameSheet.swift
//  Nos
//
//  Created by Martin Dutra on 31/1/24.
//

import Combine
import Dependencies
import Logger
import SwiftUI

struct CreateUsernameSheet: View {

    @Binding var isPresented: Bool

    var body: some View {
        NavigationStack {
            ClaimYourUniqueIdentityPage(isPresented: $isPresented)
        }
        .frame(idealWidth: 320, idealHeight: 480)
        .presentationDetents([.medium])
    }
}

fileprivate class UsernameObserver: ObservableObject {

    @Published
    var debouncedText = ""

    @Published
    var text = ""

    private var subscriptions = Set<AnyCancellable>()

    init() {
        $text
            .removeDuplicates()
            .filter { $0.count >= 3 }
            .debounce(for: .milliseconds(200), scheduler: RunLoop.main)
            .sink { [weak self] value in
                self?.debouncedText = value
            }
            .store(in: &subscriptions)
    }
}

fileprivate struct ClaimYourUniqueIdentityPage: View {

    @Binding var isPresented: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 40)
            PlainText(String(localized: LocalizedStringResource.localizable.new).uppercased())
                .padding(.horizontal, 6)
                .padding(.vertical, 5)
                .font(.clarity(.bold, textStyle: .footnote))
                .foregroundStyle(Color.white)
                .background {
                    Color.secondaryTxt
                        .cornerRadius(4, corners: .allCorners)
                }
            PlainText(.localizable.claimUniqueUsernameTitle).sheetTitle()
            PlainText(.localizable.claimUniqueUsernameDescription).sheetDescription()

            Spacer(minLength: 0)

            NavigationLink(String(localized: LocalizedStringResource.localizable.setUpMyUsername)) {
                PickYourUsernamePage(isPresented: $isPresented)
            }
            .buttonStyle(BigActionButtonStyle())

            Spacer(minLength: 40)
        }
        .padding(.horizontal, 40)
        .sheetPage()
    }
}

fileprivate struct PickYourUsernamePage: View {

    @Binding var isPresented: Bool
    @StateObject private var usernameObserver = UsernameObserver()
    @State private var verified: Bool?
    @State private var isVerifying = false
    @FocusState private var usernameFieldIsFocused: Bool
    @Dependency(\.namesAPI) var namesAPI

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Button {
                isPresented = false
            } label: {
                PlainText(.localizable.cancel)
                    .font(.clarity(.medium, textStyle: .body))
                    .foregroundStyle(Color.primaryTxt)
                    .padding()
            }
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    PlainText(.localizable.pickYourUsernameTitle).sheetTitle()
                    PlainText(.localizable.pickYourUsernameDescription).sheetDescription()
                    HStack {
                        SwiftUI.TextField(
                            text: $usernameObserver.text,
                            prompt: PlainText(.localizable.username).foregroundStyle(Color.primaryTxt)
                        ) {
                            PlainText(.localizable.username)
                                .foregroundStyle(Color.primaryTxt)
                        }
                        .focused($usernameFieldIsFocused)
                        .font(.clarity(.bold, textStyle: .title3))
                        .textInputAutocapitalization(.never)
                        .textCase(.lowercase)
                        .autocorrectionDisabled()
                        .foregroundStyle(Color.primaryTxt)
                        .lineLimit(1)
                        .padding(10)
                        .cornerRadius(10)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.secondaryTxt, lineWidth: 2)
                        }
                        .background {
                            Color.black.opacity(0.1).cornerRadius(10)
                        }
                        .onChange(of: usernameObserver.text) { oldValue, newValue in
                            let characterset = CharacterSet(
                                charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-."
                            )
                            if newValue.rangeOfCharacter(from: characterset.inverted) != nil {
                                usernameObserver.text = oldValue
                            } else if newValue.count > 30 {
                                usernameObserver.text = oldValue
                            } else {
                                usernameObserver.text = newValue.lowercased()
                            }
                        }
                        .onChange(of: usernameObserver.debouncedText) { _, newValue in
                            Task {
                                await verify(newValue)
                            }
                        }
                        .onSubmit {
                            Task {
                                await verify(usernameObserver.text)
                            }
                        }
                        PlainText(".nos.social")
                            .font(.clarityTitle3)
                            .foregroundStyle(Color.secondaryTxt)
                    }
                    if validationFailed {
                        usernameAlreadyClaimedText()
                    } else {
                        usernameAlreadyClaimedText()
                            .hidden()
                    }

                    Spacer(minLength: 0)
                }
                .padding(.horizontal, 40)

                NavigationLink {
                    ExcellentChoicePage(username: usernameObserver.text, isPresented: $isPresented)
                } label: {
                    if isVerifying {
                        ZStack {
                            ProgressView()
                                .frame(height: .zero)
                                .tint(Color.white)
                            PlainText(.localizable.next)
                                .hidden()
                        }
                    } else {
                        PlainText(.localizable.next)
                    }
                }
                .padding(.horizontal, 40)
                .buttonStyle(BigActionButtonStyle())
                .disabled(verified != true || isVerifying || invalidInput)
            }
        }
        .sheetPage()
    }

    private func usernameAlreadyClaimedText() -> some View {
        PlainText(.localizable.usernameAlreadyClaimed)
            .font(.clarity(.medium, textStyle: .subheadline))
            .foregroundStyle(Color.red)
            .lineSpacing(3)
    }

    private var invalidInput: Bool {
        usernameObserver.text.count < 3
    }

    private var validationFailed: Bool {
        verified == false
    }

    private func verify(_ username: String) async {
        verified = nil

        guard !username.isEmpty else {
            return
        }

        isVerifying = true

        defer {
            isVerifying = false
        }

        do {
            verified = try await namesAPI.verify(username: username)
        } catch {
            Log.error(error.localizedDescription)
        }
    }
}

fileprivate struct ExcellentChoicePage: View {

    var username: String
    @Binding var isPresented: Bool
    @State private var isClaiming = false
    @State private var claimError: ClaimError?
    @Dependency(\.currentUser) var currentUser
    @Dependency(\.namesAPI) var namesAPI

    private var attributedUsername: AttributedString {
        AttributedString(
            username,
            attributes: AttributeContainer([NSAttributedString.Key.foregroundColor: UIColor(Color.primaryTxt)])
        ) + AttributedString(".nos.social")
    }

    private var showAlert: Binding<Bool> {
        Binding {
            claimError != nil
        } set: { _ in
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Spacer(minLength: 40)
            if isClaiming {
                ProgressView()
                    .tint(Color.accentColor)
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = claimError {
                SwiftUI.Text(error.localizedDescription)
                    .font(.clarity(.regular, textStyle: .callout))
                    .foregroundStyle(Color.primaryTxt)
            } else {
                PlainText(.localizable.excellentChoice).sheetTitle()
                SwiftUI.Text(attributedUsername)
                    .font(.clarity(.bold, textStyle: .title3))
                    .foregroundStyle(Color.secondaryTxt)
                SwiftUI.Text(
                    LocalizedStringKey(
                        String(localized: LocalizedStringResource.localizable.usernameClaimedNotice(username))
                    )
                )
                .sheetDescription()

                Spacer(minLength: 0)

                Button(String(localized: LocalizedStringResource.localizable.done)) {
                    isPresented = false
                }
                .buttonStyle(BigActionButtonStyle())
            }

            Spacer(minLength: 40)
        }
        .frame(maxWidth: .infinity)
        .alert(isPresented: showAlert, error: claimError) {
            Button {
                isPresented = false
            } label: {
                SwiftUI.Text(.localizable.ok)
            }
        }
        .task {
            guard !isClaiming, let keyPair = currentUser.keyPair else {
                claimError = .notLoggedIn
                return
            }

            isClaiming = true

            defer {
                isClaiming = false
            }

            do {
                try await namesAPI.register(username: username, keyPair: keyPair)
                currentUser.author?.nip05 = "\(username)@nos.social"
                try currentUser.viewContext.saveIfNeeded()
            } catch {
                Log.error(error.localizedDescription)
                claimError = .unableToClaim(error)
            }
        }
        .padding(.horizontal, 40)
        .sheetPage()
    }

    enum ClaimError: LocalizedError {
        case notLoggedIn
        case unableToClaim(Error)

        var errorDescription: String? {
            switch self {
            case .notLoggedIn:
                return "Not logged in"
            case .unableToClaim(let error):
                return error.localizedDescription
            }
        }
    }
}

fileprivate struct SheetPageModifier: ViewModifier {

    private let borderWidth: CGFloat = 6
    private let cornerRadius: CGFloat = 8
    private let inDrawer = true

    func body(content: Content) -> some View {
        ZStack {
            // Gradient border
            LinearGradient.diagonalAccent
            
            // Background color
            LinearGradient.nip05
                .cornerRadius(cornerRadius, corners: inDrawer ? [.topLeft, .topRight] : [.allCorners])
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)

            content
                .background {
                    VStack {
                        HStack(alignment: .top) {
                            Spacer()
                            Image.atSymbol
                                .aspectRatio(2, contentMode: .fit)
                                .blendMode(.softLight)
                                .scaleEffect(2)
                        }
                        .offset(x: 28, y: 20)
                        Spacer()
                    }
                }
                .padding(.top, borderWidth)
                .padding(.horizontal, borderWidth)
                .padding(.bottom, inDrawer ? 0 : borderWidth)
                .clipShape(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                )
        }
        .edgesIgnoringSafeArea(.bottom)
        .navigationBarBackButtonHidden()
    }
}

fileprivate struct SheetTitleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.clarity(.bold, textStyle: .title1))
            .foregroundStyle(Color.primaryTxt)
    }
}

fileprivate struct SheetDescriptionModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.clarity(.medium, textStyle: .subheadline))
            .lineSpacing(5)
            .foregroundStyle(Color.secondaryTxt)
    }
}

fileprivate extension View {
    func sheetPage() -> some View {
        self.modifier(SheetPageModifier())
    }
    func sheetTitle() -> some View {
        self.modifier(SheetTitleModifier())
    }
    func sheetDescription() -> some View {
        self.modifier(SheetDescriptionModifier())
    }
}

#Preview {
    var previewData = PreviewData()
    return Color.clear.sheet(isPresented: .constant(true)) {
        ExcellentChoicePage(username: "sebastian", isPresented: .constant(true)).presentationDetents([.medium])
    }
}