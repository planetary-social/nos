import SwiftUI

struct WalletConnectPairingView: View {
    
    @ObservedObject var viewModel: SendUSBCController 
    
    var body: some View {
        VStack {
            HStack {
                Text(.localizable.connectGlobalIDTitle)
                    .font(.clarity(.bold, textStyle: .title1))
                    .foregroundColor(.primaryTxt)
                    .multilineTextAlignment(.leading)
                    .padding(0)
                Spacer()
            }
            
            HStack {
                Text(.localizable.scanTheWalletConnectQR)
                    .font(.callout)
                    .foregroundColor(.secondaryTxt)
                    .padding(.vertical, 8)
                Spacer()
            }
            
            if let qrImage = viewModel.qrImage {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .foregroundColor(.white)
                        .aspectRatio(contentMode: .fit)
                    qrImage
                        .interpolation(.none)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(4)
                }
            } else {
                ProgressView()
                    .frame(width: 300, height: 300)
                    .progressViewStyle(.circular)
                    .foregroundColor(.white)
                    .controlSize(.large)
            }
            HStack {
                Spacer()
                Button(action: { viewModel.copyLinkPressed() }, label: {
                    HighlightedText(
                        text: .localizable.copyQRLink,
                        highlightedWord: String(localized: .localizable.copyQRLink), 
                        highlight: .verticalAccent, 
                        link: nil
                    )
                })
                Spacer()
            }
            .padding(13)
            
            BigActionButton(title: .localizable.connectGlobalID) { 
                viewModel.connectPressed()
            }
        }
        .padding(38)
        .background(Color.appBg)
    }
}

#Preview {
    var previewData = PreviewData()
    let controller = SendUSBCController(
        state: .pair, 
        destinationAddress: "0x12389749827", 
        destinationAuthor: previewData.unsAuthor,
        dismiss: {}
    ) 
    
    return WalletConnectPairingView(viewModel: controller)
}
