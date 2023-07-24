import Foundation

struct AttachedFile {
    var data: Data
}

protocol FileStorageAPI {
    func upload(file: AttachedFile) async throws -> URL
}

class NoopFileStorageAPI: FileStorageAPI {
    func upload(file: AttachedFile) async throws -> URL {
        return URL(string: "https://example.com/abcd.jpg")!
    }
}
