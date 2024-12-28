import SwiftUI

struct FeedToggleRow: View {
    
    @Observable final class Item: Identifiable {
        let id = UUID()
        let source: FeedSource
        var isOn: Bool
        
        init(source: FeedSource, isOn: Bool) {
            self.source = source
            self.isOn = isOn
        }
    }
    
    let item: Item
    
    var body: some View {
        HStack {
            VStack(spacing: 2) {
                HStack {
                    Text(item.source.displayName)
                        .foregroundColor(.primaryTxt)
                        .font(.clarity(.bold))
                        .lineLimit(1)
                        .shadow(radius: 4, y: 4)
                    Spacer()
                }
                
                if let description = item.source.description {
                    HStack {
                        Text(description)
                            .font(.clarity(.medium, textStyle: .callout))
                            .multilineTextAlignment(.leading)
                            .foregroundColor(.secondaryTxt)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Spacer()
                    }
                }
            }
            
            Toggle("", isOn: Binding(get: { item.isOn }, set: { item.isOn = $0 }))
                .labelsHidden()
                .tint(.green)
        }
    }
}
