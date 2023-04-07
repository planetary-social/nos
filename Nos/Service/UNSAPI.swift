//
//  UNSAPI.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/20/23.
//

import Foundation
import Logger

class UNSAPI {
    
    enum UNSError: Error {
        case generic
    }
    
    private var authConnectionURL: URL
    private var connectionURL: URL
    private var clientID: String
    private var clientSecret: String
    private var orgCode: String
    private var apiKey: String
    
    // State
    private var accessToken: String?
    private var personaID: String?
    private var nameID: String?
    private var verificationID: String?
    
    init?() {
        guard let authConnectionURLString = Self.getEnvironmentVariable(named: "UNS_AUTH_CONNECTION_URL"),
            let authConnectionURL = URL(string: "https://\(authConnectionURLString)"),
            let connectionURLString = Self.getEnvironmentVariable(named: "UNS_CONNECTION_URL"),
            let connectionURL = URL(string: "https://\(connectionURLString)"),
            let clientID = Self.getEnvironmentVariable(named: "UNS_CLIENT_ID"),
            let clientSecret = Self.getEnvironmentVariable(named: "UNS_CLIENT_SECRET"),
            let apiKey = Self.getEnvironmentVariable(named: "UNS_API_KEY"),
            let orgCode = Self.getEnvironmentVariable(named: "UNS_ORG_CODE") else {
            return nil
        }
              
        self.authConnectionURL = authConnectionURL
        self.connectionURL = connectionURL
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.orgCode = orgCode
        self.apiKey = apiKey
    }
    
    func requestOTPCode(phoneNumber: String) async throws {
        var request = URLRequest(url: authConnectionURL.appending(path: "v1/phone_verification/request_otp"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "phone_number": phoneNumber,
        ]
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        Log.info(request.description)
        let response = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response.1 as? HTTPURLResponse,
            httpResponse.statusCode == 204 else {
            logError(response: response)
            throw UNSError.generic
        }
    }
    
    func verifyOTPCode(phoneNumber: String, code: String) async throws {
        var request = URLRequest(url: authConnectionURL.appending(path: "v1/phone_verification/validate_otp"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "phone_number": phoneNumber,
            "verification_code": code.description,
        ]
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        let response = try await URLSession.shared.data(for: request)
        let data = response.0
        
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let dataDict = responseDict["data"] as? [String: Any],
            let accessTokenDict = dataDict["access_token"] as? [String: Any],
            let personaDict = dataDict["persona"] as? [String: Any],
            let personaID = personaDict["persona_id"] as? String,
            let accessToken = accessTokenDict["access_token"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        
        self.personaID = personaID
        self.accessToken = accessToken
    }
    
    func getNames() async throws -> [String] {
        var request = URLRequest(url: connectionURL.appending(path: "v1/personas/\(personaID!)/names"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let response = try await URLSession.shared.data(for: request)
        let data = response.0
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let dataDict = responseDict["data"] as? [[String: Any]] else {
            logError(response: response)
            throw UNSError.generic
        }
        var names = [String]()
        for nameDict in dataDict {
            if let name = nameDict["name"] as? String {
                names.append(name)
            }
        }
        
        nameID = dataDict.first?["name_id"] as? String
        return names
    }
    
    func createName(_ name: String) async throws -> Bool {
        var request = URLRequest(url: connectionURL.appending(path: "v1/names"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = [
            "name": name,
            "persona_id": personaID,
        ]
        let jsonBody = try! JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        let response = try await URLSession.shared.data(for: request)
        guard let httpResponse = response.1 as? HTTPURLResponse,
            httpResponse.statusCode == 201 else {
            logError(response: response)
            return false
        }
        
        return true
    }
    
    func requestNostrVerification(npub: String) async throws -> String? {
        var request = URLRequest(url: connectionURL.appending(path: "/v1/resolver/social_connections"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = [
            "name_id": nameID ?? "null",
            "connection_type": "NOSTR_SIGNATURE",
            "scope": "PUBLIC",
            "arguments": [
                "nostr_pub_key": npub
            ]
        ] as [String: Any]
        let jsonBody = try! JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        
        let response = try await URLSession.shared.data(for: request)
        let responseData = response.0
        let responseString = String(data: responseData, encoding: .utf8)
        if responseString?.ranges(of: "DUPLICATED_SOCIAL_CONNECTION").isEmpty == false {
            return nil
        }
            
        guard let responseDict = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
            let dataDict = responseDict["data"] as? [String: Any],
            let verificationID = dataDict["verification_id"] as? String,
            let message = dataDict["message"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        self.verificationID = verificationID
        return message
    }
    
    func submitNostrVerification(message: String, keyPair: KeyPair) async throws -> String {
        var request = URLRequest(url: connectionURL.appending(path: "/v1/resolver/social_connections/nostr/signature"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        var bytesToSign = try message.data(using: .utf8)!.sha256.bytes
        let body = [
            "verification_id": verificationID ?? "null",
            "public_key": keyPair.npub,
            "signature": try keyPair.sign(bytes: &bytesToSign)
        ] as [String: Any]
        let jsonBody = try! JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"

        let response = try await URLSession.shared.data(for: request)
        let responseData = response.0
        guard let responseDict = try JSONSerialization.jsonObject(with: responseData) as? [String: Any],
            let dataDict = responseDict["data"] as? [String: Any],
            let verificationDict = dataDict["verification"] as? [String: Any],
            let externalID = verificationDict["external_id"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        return externalID
    }
    
    func getNIP05() async throws -> String {
        var url = connectionURL.appending(path: "/v1/resolver/admin")
        url = url.appending(queryItems: [
            URLQueryItem(name: "name_id", value: nameID!),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "1"),
            URLQueryItem(name: "key", value: "NOSTR"),
        ])
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let response = try await URLSession.shared.data(for: request)
        let data = response.0
        
        let responseDict = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        guard let dataDict = responseDict["data"] as? [[String: Any]],
            let nostrConnection = dataDict.first,
            let nip05 = nostrConnection["value"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        return nip05
    }
    
    func logError(from functionName: String = #function, response: (Data, URLResponse)) {
        Log.error("\(functionName) failed with \(String(data: response.0, encoding: .utf8) ?? "null")")
    }
    
    class func getEnvironmentVariable(named name: String) -> String? {
        Bundle.main.infoDictionary?[name] as? String
    }
}
