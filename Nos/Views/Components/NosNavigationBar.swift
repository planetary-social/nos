import SwiftUI

fileprivate struct NosNavigationBarModifier: ViewModifier {
    
    let titleKey: LocalizedStringKey
    
    init(_ titleKey: LocalizedStringKey) {
        self.titleKey = titleKey
    }

    func body(content: Content) -> some View {
        content
            .navigationBarTitle(titleKey, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(titleKey)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryTxt)
                        .tint(.primaryTxt)
                        .allowsHitTesting(false)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
    }
}

fileprivate struct AttributedNavigationBarModifier: ViewModifier {
    let title: AttributedString
    
    func body(content: Content) -> some View {
        content
            .navigationBarTitle(String(title.characters), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primaryTxt)
                        .tint(.primaryTxt)
                        .allowsHitTesting(false)
                }
            }
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.cardBgBottom, for: .navigationBar)
    }
}

extension View {
    func nosNavigationBar(_ title: LocalizedStringKey) -> some View {
        self.modifier(NosNavigationBarModifier(title))
    }
    func nosNavigationBar(title: AttributedString) -> some View {
        self.modifier(AttributedNavigationBarModifier(title: title))
    }
}

#Preview {
    NavigationStack {
        VStack {
            Spacer()
            Text("Content")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .nosNavigationBar("homeFeed")
    }
}

#Preview {
    NavigationStack {
        VStack {
            Spacer()
            Text("Content")
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .nosNavigationBar(LocalizedStringKey(stringLiteral: "me@nos.social"))
    }
}
