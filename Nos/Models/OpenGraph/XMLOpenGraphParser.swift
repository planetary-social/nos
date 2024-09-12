import Foundation

class XMLOpenGraphParser: NSObject, OpenGraphParser, XMLParserDelegate {
    private var currentElement = ""
    private var videoWidth: String?

    func videoMetadata(html: String) -> OpenGraphMedia? {
        guard let data = html.data(using: .utf8) else { return nil }
        let width = videoWidth(data: data)
        return OpenGraphMedia(url: nil, type: .video, width: width, height: nil)
    }

    func videoWidth(data: Data) -> Double? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        guard let videoWidth else { return nil }
        return Double(videoWidth)
    }

    // XMLParserDelegate methods
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        if elementName == "meta", let property = attributeDict["property"], property == "og:video:width" {
            videoWidth = attributeDict["content"]
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        // No need to handle characters for meta tags
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = ""
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("Parse error: \(parseError.localizedDescription)")
    }
}
