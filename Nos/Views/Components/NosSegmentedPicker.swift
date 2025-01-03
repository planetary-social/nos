import SwiftUI

protocol NosSegmentedPickerItem: Equatable, Identifiable {
    var titleKey: LocalizedStringKey { get }
    var image: Image { get }
}

/// A custom styled segmented picker.
///
/// Pass in an array of items that conform to ``NosSegmentedPickerItem`` as
/// well as a binding to a selected item of the same type.
struct NosSegmentedPicker<Item: NosSegmentedPickerItem>: View {
    
    let items: [Item]
    @Binding var selectedItem: Item
    
    var body: some View {
        HStack {
            ForEach(items) { item in
                Button {
                    selectedItem = item
                } label: {
                    HStack {
                        Spacer()
                        let color = selectedItem == item ? Color.primaryTxt : .secondaryTxt
                        item.image
                            .renderingMode(.template)
                            .foregroundColor(color)
                        Text(item.titleKey)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(color)
                        Spacer()
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 12)
        .padding(.bottom, 15)
    }
}
