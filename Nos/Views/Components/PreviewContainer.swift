import SwiftUI

/// Allows you to use @State in SwiftUI Previews (see example in preview below)
/// https://peterfriese.dev/posts/swiftui-previews-interactive/
struct StatefulPreviewContainer<Value, Content: View>: View {
    @State var value: Value
    let content: (Binding<Value>) -> Content
    
    var body: some View {
        content($value)
    }
    
    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}

struct PreviewContainer_Previews: PreviewProvider {
    static var previews: some View {
        StatefulPreviewContainer(false) { binding in
            VStack {
                Toggle(isOn: binding) { Text("Toggle me") }
            }
            .padding()
        }
    }
}
