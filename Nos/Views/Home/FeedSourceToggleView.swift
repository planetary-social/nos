import SwiftUI

struct FeedSourceToggleView<Content: View, EmptyPlaceholder: View>: View {
    @Environment(FeedController.self) var feedController
    
    let author: Author
    let headerText: Text
    let items: [FeedToggleRow.Item]
    let footer: () -> Content
    let noContent: () -> EmptyPlaceholder
    
    init(
        author: Author,
        headerText: Text,
        items: [FeedToggleRow.Item],
        @ViewBuilder footer: @escaping () -> Content,
        @ViewBuilder noContent: @escaping () -> EmptyPlaceholder
    ) {
        self.author = author
        self.headerText = headerText
        self.items = items
        self.footer = footer
        self.noContent = noContent
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HorizontalLine(color: .buttonBevelBottom)
            
            HStack {
                Image(systemName: "lightbulb.max.fill")
                
                headerText
                    .font(.clarity(.medium))
                
                Spacer()
            }
            .foregroundStyle(Color.primaryTxt)
            .padding()
            
            if !items.isEmpty {
                let rows = Group {
                    ForEach(items) { item in
                        VStack(spacing: 0) {
                            BeveledSeparator()
                            
                            FeedToggleRow(item: item)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.vertical, 10)
                                .onChange(of: item.isOn) { _, _ in
                                    feedController.toggleSourceEnabled(item.source)
                                }
                        }
                    }
                    
                    BeveledSeparator()
                }
                    .padding(.horizontal, 16)
                
                ViewThatFits(in: .vertical) {
                    VStack(spacing: 0) {
                        rows
                        Spacer()
                    }
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            rows
                        }
                    }
                }
                .geometryGroup()
            } else {
                Spacer()
                noContent()
                Spacer()
            }
            
            footer()
        }
    }
}
