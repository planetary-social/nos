import SwiftUI

struct UNSWizardIntroView: View {
    
    @ObservedObject var controller: UNSWizardController
    
    var body: some View {
        VStack {
            Image.unsIntro
                .frame(width: 178, height: 178)
                .padding(40)
                .padding(.top, 50)
            
            Text("unsRegister")
                .font(.clarityBold(.title))
                .multilineTextAlignment(.center)
                .foregroundColor(.primaryTxt)
                .readabilityPadding()
                .shadow(radius: 1, y: 1)
            
            Text("unsRegisterDescription")
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondaryTxt)
                .readabilityPadding()
                .padding(.vertical, 17)
                .padding(.horizontal, 20)
                .shadow(radius: 1, y: 1)
            
            Button { 
                UIApplication.shared.open(URL(string: "https://universalname.space")!)
            } label: { 
                Text("unsLearnMore")
                    .foregroundStyle(LinearGradient.horizontalAccent)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .shadow(radius: 1, y: 1)
            }
            
            Spacer()
            
            BigActionButton("start") {
                controller.state = .enterPhone
            }
            .padding(.bottom, 41)
        }
        .padding(.horizontal, 38)
        .readabilityPadding()
        .background(Color.appBg)
    }
}

struct UNSWizardIntro_Previews: PreviewProvider {
    
    @State static var controller = UNSWizardController(
        state: .intro 
    )
    
    static var previews: some View {
        UNSWizardIntroView(controller: controller)
    }
}
