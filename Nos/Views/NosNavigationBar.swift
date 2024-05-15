import SwiftUI

struct NosNavigationBarModifier: ViewModifier {
    
    var title: LocalizedStringResource

    func body(content: Content) -> some View {
        content
            .navigationBarTitle(String(localized: title), displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.clarity(.bold, textStyle: .title3))
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
    func nosNavigationBar(title: LocalizedStringResource) -> some View {
        self.modifier(NosNavigationBarModifier(title: title))
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
        .nosNavigationBar(title: .localizable.homeFeed)
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
        .nosNavigationBar(title: LocalizedStringResource(stringLiteral: "me@nos.social"))
    }
}
