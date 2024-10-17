import SwiftUI
import SwiftUINavigation

struct FullscreenProgressView: View {
    
    @Binding var isPresented: Bool 

    var text: String?
    var hideAfter: DispatchTime?
    
    var body: some View {
        VStack {
            Spacer()
            ProgressView()
                .foregroundColor(.primaryTxt)
            if let text {
                Text(text)
                    .font(.clarity(.regular))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 25)
                    .foregroundColor(.primaryTxt)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
        .onAppear {
            if let hideAfter {
                DispatchQueue.main.asyncAfter(deadline: hideAfter) {
                    isPresented = false
                }
            }
        }
    }
}

#Preview("No text") {
    FullscreenProgressView(isPresented: .constant(true))
}

#Preview("Short text") {
    FullscreenProgressView(isPresented: .constant(true), text: "Lorem ipsum...")
}

#Preview("Long text") {
    FullscreenProgressView(
        isPresented: .constant(true),
        text: String(localized: "notFindingResults")
    )
}
