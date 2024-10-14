import Foundation

enum LoadingContent<Content: Equatable>: Equatable {
    case loading
    case loaded(Content)
}
