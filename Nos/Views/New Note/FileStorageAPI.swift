import Foundation
import SwiftUI

struct AttachedFile {
    var image: UIImage
}

protocol FileStorageAPI {
    func upload(file: AttachedFile) async throws -> URL
}

class NostrBuildFileStorageAPI: FileStorageAPI {
    var uploadURL = URL(string: "https://nostr.build/api/upload/ios.php")!
    
    func upload(file: AttachedFile) async throws -> URL {
        let boundary = UUID().uuidString
        let fileName = "file.jpg"
        let paramName = "fileToUpload"
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var data = Data()
        data.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(paramName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: image/jpg\r\n\r\n".data(using: .utf8)!)
        data.append(file.image.jpegData(compressionQuality: 85)!)
        data.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        return try await withCheckedThrowingContinuation { continuation in
            URLSession.shared
                .uploadTask(with: request, from: data, completionHandler: { responseData, _, error in
                    do {
                        if error != nil {
                            continuation.resume(throwing: error!)
                            return
                        }
                        
                        let url = try JSONSerialization.jsonObject(with: responseData!, options: .allowFragments) as? String
                        continuation.resume(returning: URL(string: url!)!)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                })
                .resume()
        }
    }
}
