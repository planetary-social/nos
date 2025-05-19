import SwiftUI
import Foundation

/// Simplified version of PostKind for UI purposes
enum PostKind: String, CaseIterable, Identifiable {
    case textNote      // Kind 1
    case picturePost   // Kind 20
    case videoPost     // Kind 21
    case shortVideo    // Kind 22
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .textNote:
            return String(localized: "Text Note")
        case .picturePost:
            return String(localized: "Picture Post")
        case .videoPost:
            return String(localized: "Video Post")
        case .shortVideo:
            return String(localized: "Short Video")
        }
    }
    
    var icon: String {
        switch self {
        case .textNote:
            return "text.bubble"
        case .picturePost:
            return "photo"
        case .videoPost:
            return "video"
        case .shortVideo:
            return "video.badge.plus"
        }
    }
    
    var description: String {
        switch self {
        case .textNote:
            return String(localized: "Standard text note")
        case .picturePost:
            return String(localized: "Image-first post with title")
        case .videoPost:
            return String(localized: "Video post with title")
        case .shortVideo:
            return String(localized: "Short-form video")
        }
    }
    
    var nostrKind: Int {
        switch self {
        case .textNote:
            return 1
        case .picturePost:
            return 20
        case .videoPost:
            return 21
        case .shortVideo:
            return 22
        }
    }
    
    var requiresTitle: Bool {
        switch self {
        case .textNote:
            return false
        case .picturePost, .videoPost, .shortVideo:
            return true
        }
    }
}

/// A component that allows users to select the type of post they want to create
struct PostKindSelector: View {
    @Binding var selectedKind: PostKind
    @State private var showSelector = false
    
    var body: some View {
        Button {
            withAnimation {
                showSelector.toggle()
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: selectedKind.icon)
                    .foregroundColor(.gray)
                Text(selectedKind.title)
                    .font(.system(.caption))
                    .foregroundColor(.gray)
                Image(systemName: "chevron.down")
                    .font(.system(.caption))
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(showSelector ? 180 : 0))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.2))
            )
        }
        .overlay(
            Group {
                if showSelector {
                    selectorOverlay
                }
            }
        )
        .padding(.vertical, 8)
    }
    
    private var selectorOverlay: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 40)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(PostKind.allCases) { kind in
                    Button {
                        selectedKind = kind
                        withAnimation {
                            showSelector = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: kind.icon)
                                .foregroundColor(selectedKind == kind ? .accentColor : .primary)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.title)
                                    .font(.system(.subheadline, weight: .medium))
                                    .foregroundColor(.primary)
                                Text(kind.description)
                                    .font(.system(.caption))
                                    .foregroundColor(.gray)
                            }
                            Spacer()
                            if selectedKind == kind {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedKind == kind ? 
                                Color.gray.opacity(0.1) : 
                                Color.clear
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if kind != PostKind.allCases.last {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 10)
        .transition(.opacity)
        .onTapGesture {
            withAnimation {
                showSelector = false
            }
        }
    }
}

#Preview {
    VStack {
        PostKindSelector(selectedKind: .constant(.textNote))
        Spacer()
    }
    .padding()
    .background(Color(.systemBackground))
}