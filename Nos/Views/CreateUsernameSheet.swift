//
//  CreateUsernameSheet.swift
//  Nos
//
//  Created by Martin Dutra on 31/1/24.
//

import SwiftUI
import Combine

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
            Text("New".uppercased())
                .padding(5)
                .font(.clarityCaption)
                .foregroundStyle(Color.white)
                .background {
                    Color.secondaryTxt
                        .cornerRadius(4, corners: .allCorners)
                }
            Text(.localizable.claimUniqueUsernameTitle)
                .font(.clarityTitle)
                .foregroundStyle(Color.primaryTxt)
            Text(
                .localizable.claimUniqueUsernameDescription
            )
            .font(.clarity)
            .foregroundStyle(Color.secondaryTxt)

            Spacer(minLength: 0)

            NavigationLink {
                PickYourUsernamePage(isPresented: $isPresented)
            } label: {
                PlainText(.localizable.getMyHandle)
                    .font(.clarityBold)
                    .transition(.opacity)
                    .font(.headline)
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
    @State private var dataTask: URLSessionDataTask?
    @FocusState private var usernameFieldIsFocused: Bool

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
                    PlainText(.localizable.pickYourUsernameTitle)
                        .font(.clarity(.bold, textStyle: .title1))
                        .foregroundStyle(Color.primaryTxt)
                    PlainText(.localizable.pickYourUsernameDescription)
                        .font(.clarity(.medium, textStyle: .subheadline))
                        .lineSpacing(5)
                        .foregroundStyle(Color.secondaryTxt)
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
                            verify(newValue)
                        }
                        .onSubmit {
                            verify(usernameObserver.text)
                        }
                        PlainText(".nos.social")
                            .font(.clarityTitle3)
                            .foregroundStyle(Color.secondaryTxt)
                    }
                    if  validationFailed {
                        usernameAlreadyClaimedText()
                    } else {
                        usernameAlreadyClaimedText()
                            .hidden()
                    }

                    Spacer(minLength: 0)


                }
                .padding(.horizontal, 40)

                Button {

                } label: {
                    if isValidating {
                        ZStack {
                            ProgressView()
                                .frame(height: .zero)
                                .tint(Color.white)
                            PlainText(.localizable.next)
                                .font(.clarityBold)
                                .transition(.opacity)
                                .font(.headline)
                                .hidden()
                        }
                    } else {
                        PlainText(.localizable.next)
                            .font(.clarityBold)
                            .transition(.opacity)
                            .font(.headline)
                    }
                }
                .padding(.horizontal, 40)
                .buttonStyle(BigActionButtonStyle())
                .disabled(verified != true || dataTask != nil || invalidInput)
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

    private var isValidating: Bool {
        dataTask != nil
    }

    private var validationFailed: Bool {
        verified == false
    }

    private func verify(_ username: String) {
        dataTask?.cancel()
        dataTask = nil
        verified = nil

        guard !username.isEmpty else {
            return
        }

        guard let url = URL(string: "https://nos.social/.well-known/nostr.json?name=\(username.lowercased())") else { fatalError("Missing URL")
        }

        let urlRequest = URLRequest(url: url)

        dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                dataTask = nil
                return
            }

            guard let response = response as? HTTPURLResponse else {
                dataTask = nil
                return
            }

            if response.statusCode == 404 {
                verified = true
            } else {
                verified = false
            }

            dataTask = nil
        }
        dataTask?.resume()
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

fileprivate extension View {
    func sheetPage() -> some View {
        self.modifier(SheetPageModifier())
    }
}

#Preview {
    var previewData = PreviewData()
    return Color.clear.sheet(isPresented: .constant(true)) { CreateUsernameSheet(isPresented: .constant(true)).presentationDetents([.medium]) }
}
