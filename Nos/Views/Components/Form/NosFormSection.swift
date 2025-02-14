import SwiftUI
import SwiftUINavigation

struct NosFormSection<Content: View>: View {
    
    let label: LocalizedStringKey?
    let content: Content
    
    init(_ label: LocalizedStringKey? = nil, @ViewBuilder builder: () -> Content) {
        self.label = label
        self.content = builder()
    }
    
    var body: some View {
        VStack {
            if let label {
                HStack {
                    Text(label)
                        .font(.clarity(.semibold, textStyle: .headline))
                        .foregroundColor(.primaryTxt)
                        .padding(EdgeInsets(top: 16, leading: 8, bottom: 2, trailing: 0))
                    
                    Spacer()
                }
            }
            
            ZStack {
                // 3d card effect
                ZStack {
                    Color.card3d
                }
                .cornerRadius(21)
                .offset(y: 4.5)
                .shadow(
                    color: Color.lightShadow, 
                    radius: 2, 
                    x: 0, 
                    y: 0
                )
                
                VStack {
                    content
                }
                .background(LinearGradient.cardGradient)
                .cornerRadius(20)
            }
        }
        .padding(.horizontal, 13)
    }
}

struct NosFormSection_Previews: PreviewProvider {
    static var previews: some View {
        NosForm {
            NosFormSection("profilePicture") {
                WithState(initialValue: "Alice") { text in
                    NosTextField("url", text: text)
                }
            }    
        }
    }
}
