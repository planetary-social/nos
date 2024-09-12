import Foundation
import Logger

class XMLOpenGraphParser: NSObject, OpenGraphParser, XMLParserDelegate {
    private var videoWidth: Double?
    private var videoHeight: Double?

    func videoMetadata(html: Data) -> OpenGraphMedia? {
        parse(data: html)
        return OpenGraphMedia(url: nil, type: .video, width: videoWidth, height: videoHeight)
    }

    private func parse(data: Data) {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if elementName == "meta", let property = attributeDict["property"], let content = attributeDict["content"] {
            if property == "og:video:width" {
                videoWidth = Double(content)
            } else if property == "og:video:height" {
                videoHeight = Double(content)
            }
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // No need to handle characters for meta tags
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        Log.error("Parse error: \(parseError.localizedDescription)")
    }
}
