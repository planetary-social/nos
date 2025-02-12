import SwiftUI

/// A button that lets the user select an `ExpirationTimeOption` to specify when an event should be deleted.
struct ExpirationTimeButton: View {
    
    let model: ExpirationTimeOption
    @State var showClearButton = false
    var minSize: Binding<CGSize?>?
    @Binding var isSelected: Bool
    
    var body: some View {
        ZStack {
            let textLayer = HStack(spacing: 3) {
                VStack {
                    Text(model.topText)
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.bold))
                    Text(model.unit)
                        .foregroundColor(.secondaryTxt)
                        .font(.clarity(.regular, textStyle: .caption2))
                }
                
                if showClearButton {
                    Image(systemName: "xmark")
                        .font(.callout)
                        .fontWeight(.heavy)
                        .foregroundColor(.primaryTxt)
                }
            }
            .padding(.horizontal, showClearButton ? 6 : 4)
            .padding(.vertical, 6)
            .frame(minWidth: minSize?.wrappedValue?.width, minHeight: minSize?.wrappedValue?.height)
            .cornerRadius(5)
            .background(Color.buttonBevelBg)
            
            if isSelected {
                textLayer
                    // highlighted border
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(Color.accent, lineWidth: 1.2)
                    )
            } else {
                textLayer
                    // bottom bevel
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(Color.buttonBevelBottom, lineWidth: 1)
                            .offset(x: 0, y: 0.8)
                            .padding(.horizontal, -0.8)
                            .clipped()
                    )
                    // top bevel
                    .overlay(
                        RoundedRectangle(cornerSize: CGSize(width: 5, height: 5))
                            .stroke(Color.buttonBevelTop, lineWidth: 1)
                            .offset(x: 0, y: -0.8)
                            .padding(.horizontal, -0.8)
                            .clipped()
                    )
            }
        }
        .accessibilityLabel(Text(model.accessibilityLabel))
        .cornerRadius(5)
        .onTapGesture {
            isSelected.toggle() 
        }
    }
}

struct ExpirationTimeButton_Previews: PreviewProvider {
    
    static var previews: some View {
        VStack {
            HStack {
                ExpirationTimeButton(model: ExpirationTimeOption.oneHour, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.oneDay, isSelected: .constant(false))
                ExpirationTimeButton(model: ExpirationTimeOption.sevenDays, isSelected: .constant(true))
                ExpirationTimeButton(
                    model: ExpirationTimeOption.oneHour, 
                    showClearButton: true, 
                    isSelected: .constant(true)
                )
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(Color.appBg)
    }
}
