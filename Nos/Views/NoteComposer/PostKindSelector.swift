import SwiftUI

/// Enum representing different types of posts a user can create
enum PostKind: Int, CaseIterable, Identifiable {
    case textNote = 1      // Regular text note (Kind 1)
    case picturePost = 20  // NIP-68 picture post (Kind 20)
    case videoPost = 21    // NIP-71 video post (Kind 21)
    case shortVideo = 22   // NIP-71 short-form video (Kind 22)
    
    var id: Int { rawValue }
    
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
    
    var eventKind: EventKind {
        switch self {
        case .textNote:
            return .text
        case .picturePost:
            return .picturePost
        case .videoPost:
            return .video
        case .shortVideo:
            return .shortVideo
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
                    .foregroundColor(.secondaryTxt)
                Text(selectedKind.title)
                    .font(.clarity(.regular, textStyle: .caption))
                    .foregroundColor(.secondaryTxt)
                Image(systemName: "chevron.down")
                    .font(.clarity(.regular, textStyle: .caption))
                    .foregroundColor(.secondaryTxt)
                    .rotationEffect(.degrees(showSelector ? 180 : 0))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.secondaryBg)
            )
        }
        .overlay(
            showSelector ? selectorOverlay : nil
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
                                .foregroundColor(selectedKind == kind ? .accentColor : .primaryTxt)
                                .frame(width: 24)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(kind.title)
                                    .font(.clarity(.medium, textStyle: .subheadline))
                                    .foregroundColor(.primaryTxt)
                                Text(kind.description)
                                    .font(.clarity(.regular, textStyle: .caption))
                                    .foregroundColor(.secondaryTxt)
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
                            selectedKind == kind ? Color.secondaryBg.opacity(0.5) : Color.clear
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if kind != PostKind.allCases.last {
                        Divider()
                            .padding(.leading, 48)
                    }
                }
            }
            .background(Color.cardBgTop)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.cardDividerTop, lineWidth: 1)
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
    .background(Color.appBg)
}