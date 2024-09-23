import Foundation

enum LoadingContent<Content: Equatable>: Equatable {
    case loading, loaded(Content)
}
