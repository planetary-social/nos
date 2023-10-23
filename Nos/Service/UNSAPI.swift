//
//  UNSAPI.swift
//  Nos
//
//  Created by Matthew Lorentz on 3/20/23.
//

import Foundation
import Logger
import Dependencies

typealias JSONObject = [String: Any]
typealias UNSNameID = String

struct UNSNameRecord: Identifiable, Equatable {
    var name: UNSName
    var id: UNSNameID
    var nostrPubKey: HexadecimalString?
}

enum UNSError: Error {
    case generic
    case noAccessToken
    case requiresPayment(URL)
    case nameTaken
    case notAuthenticated
    case developer
    case badResponse
}

// swiftlint:disable type_body_length

class UNSAPI {
    private var authConnectionURL: URL
    private var connectionURL: URL
    private var clientID: String
    private var clientSecret: String
    private var orgCode: String
    private var apiKey: String
    
    // State
    private(set) var accessToken: String?
    private var refreshToken: String?
    private var personaID: String?
    private var verificationID: String?
    
    private let refreshTokenKey = "com.nos.uns.refreshToken"
    
    @Dependency(\.userDefaults) private var userDefaults
    
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
        loadRefreshToken()
    }
    
    func requestVerificationCode(phoneNumber: String) async throws {
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
    
    func verifyPhone(phoneNumber: String, code: String) async throws {
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
        
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? JSONObject,
            let dataDict = responseDict["data"] as? JSONObject,
            let accessTokenDict = dataDict["access_token"] as? JSONObject,
            let personaDict = dataDict["persona"] as? JSONObject,
            let personaID = personaDict["persona_id"] as? String,
            let accessToken = accessTokenDict["access_token"] as? String,
            let refreshToken = accessTokenDict["refresh_token"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        
        self.personaID = personaID
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        saveRefreshToken()
    }
    
    func refreshAccessToken() async throws {
        guard let refreshToken else {
            throw UNSError.notAuthenticated
        }
        
        var request = URLRequest(url: authConnectionURL.appending(path: "v1/oauth"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": clientID,
            "client_secret": clientSecret,
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
        ]
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        let response = try await URLSession.shared.data(for: request)
        let data = response.0
        
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? JSONObject,
            let dataDict = responseDict["data"] as? JSONObject,
            let accessToken = dataDict["access_token"] as? String,
            let refreshToken = dataDict["refresh_token"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        saveRefreshToken()
    }
    
    func getNames() async throws -> [UNSNameRecord] {
        guard let personaID, let accessToken else {
            throw UNSError.generic
        }
        var request = URLRequest(url: connectionURL.appending(path: "v1/personas/\(personaID)/names"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"
        let response = try await URLSession.shared.data(for: request)
        let data = response.0
        
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw UNSError.generic
        }
        guard let dataDict = responseDict["data"] as? [JSONObject] else {
            logError(response: response)
            throw UNSError.generic
        }
        var names = [UNSNameRecord]()
        for nameDict in dataDict {
            if let name = nameDict["name"] as? String,
                let nameID = nameDict["name_id"] as? String {
                names.append(UNSNameRecord(name: name, id: nameID))
            }
        }
        
        return names
    }
    
    func createName(_ name: String) async throws -> UNSNameID {
        guard let accessToken else {
            throw UNSError.noAccessToken
        }
        var request = URLRequest(url: connectionURL.appending(path: "v1/names"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = [
            "name": name,
            "persona_id": personaID,
        ]
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        let response = try await URLSession.shared.data(for: request)
        if let httpResponse = response.1 as? HTTPURLResponse,
            httpResponse.statusCode == 201 {
            
            guard let responseDict = try? jsonDictionary(from: response.0),
                let dataDict = responseDict["data"] as? JSONObject,
                let nameDict = dataDict["name"] as? JSONObject,
                let nameID = nameDict["name_id"] as? String else {
                throw UNSError.generic
            }
            
            return nameID
        } else if isNeedPaymentError(response.0) {
            throw UNSError.requiresPayment(URL(string: "https://www.universalname.space/name/\(name)")!)
            // Waiting for API to support mobile
            // return .right(try await requestPaymentURL(for: name))
        } else if isNameTakenError(response.0) {
            throw UNSError.nameTaken
        } else {
            logError(response: response)
            throw UNSError.generic
        }
    }
    
    @available(*, deprecated, message: "This doesn't work yet because the API doesn't support non-http redirect URLs")
    func requestPaymentURL(for name: UNSName) async throws -> URL {
        guard let accessToken else {
            throw UNSError.noAccessToken
        }
        var request = URLRequest(url: connectionURL.appending(path: "/v1/names/\(name)/payments"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = [
            "persona_id": personaID ?? "null",
            "cancel_url": "nos://uns/payment/canceled",
            "success_url": "nos://uns/payment/success",
        ] as JSONObject
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        
        let response = try await URLSession.shared.data(for: request)
        let responseData = response.0
        _ = String(data: responseData, encoding: .utf8)
        
        // This is just a stub response for now.
        return URL(string: "https://www.universalname.space/name/\(name)")!
    }
    
    func requestNostrVerification(npub: String, nameID: String) async throws -> String? {
        guard let accessToken else {
            throw UNSError.noAccessToken
        }
        var request = URLRequest(url: connectionURL.appending(path: "/v1/resolver/social_connections"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = [
            "name_id": nameID,
            "connection_type": "NOSTR_SIGNATURE",
            "scope": "PUBLIC",
            "arguments": [
                "nostr_pub_key": npub
            ]
        ] as JSONObject
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"
        
        let response = try await URLSession.shared.data(for: request)
        let responseData = response.0
        let responseString = String(data: responseData, encoding: .utf8)
        if responseString?.ranges(of: "DUPLICATED_SOCIAL_CONNECTION").isEmpty == false {
            return nil
        }
            
        let responseJSON = try jsonDictionary(from: response.0)
        guard let dataDict = responseJSON["data"] as? JSONObject,
            let verificationID = dataDict["verification_id"] as? String,
            let message = dataDict["message"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        self.verificationID = verificationID
        return message
    }
    
    func submitNostrVerification(message: String, keyPair: KeyPair) async throws -> String {
        guard let accessToken else {
            throw UNSError.noAccessToken
        }
        var request = URLRequest(url: connectionURL.appending(path: "/v1/resolver/social_connections/nostr/signature"))
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        guard var bytesToSign = try message.data(using: .utf8)?.sha256.bytes else {
            throw UNSError.generic
        }
        let body = [
            "verification_id": verificationID ?? "null",
            "public_key": keyPair.npub,
            "signature": try keyPair.sign(bytes: &bytesToSign)
        ] as JSONObject
        let jsonBody = try JSONSerialization.data(withJSONObject: body)
        request.httpBody = jsonBody
        request.httpMethod = "POST"

        let response = try await URLSession.shared.data(for: request)
        let responseJSON = try jsonDictionary(from: response.0)
        guard let dataDict = responseJSON["data"] as? JSONObject,
            let verificationDict = dataDict["verification"] as? JSONObject,
            let externalID = verificationDict["external_id"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        return externalID
    }
    
    func getNIP05(for nameID: UNSNameID) async throws -> String {
        guard let accessToken else {
            throw UNSError.noAccessToken
        }
        var url = connectionURL.appending(path: "/v1/resolver/admin")
        url = url.appending(queryItems: [
            URLQueryItem(name: "name_id", value: nameID),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "1"),
            URLQueryItem(name: "key", value: "NOSTR"),
        ])
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        let response = try await URLSession.shared.data(for: request)
        let responseJSON = try jsonDictionary(from: response.0)
        
        guard let dataDict = responseJSON["data"] as? [JSONObject],
            let nostrConnection = dataDict.first,
            let nip05 = nostrConnection["value"] as? String else {
            logError(response: response)
            throw UNSError.generic
        }
        return nip05
    }
    
    func names(matching query: String) async throws -> [HexadecimalString] {
        if accessToken == nil {
            try await refreshAccessToken()
        }
        guard let accessToken else {
            throw UNSError.noAccessToken
        }
        
        var url = connectionURL.appending(path: "/v1/names")
        url = url.appending(queryItems: [
            URLQueryItem(name: "name", value: query.lowercased()),
        ])
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let response = try await URLSession.shared.data(for: request)
        let responseJSON = try jsonDictionary(from: response.0)
        
        guard let dataDict = responseJSON["data"] as? JSONObject,
            let available = dataDict["available"] as? Int else {
            throw UNSError.badResponse
        }
        
        if available == 0 { 
            guard let nameID = dataDict["name_id"] as? String else {
                throw UNSError.badResponse
            }
            let nameRecord = UNSNameRecord(name: query, id: nameID)
            let nostrPubKeys = try await nostrKeys(for: nameRecord)
            return nostrPubKeys
        } else {
            return []
        }
    }
    
    private func nostrKeys(for nameRecord: UNSNameRecord) async throws -> [HexadecimalString] {
        // Assumes we have an access token already
        guard let accessToken else {
            throw UNSError.noAccessToken
        }
        var url = connectionURL.appending(path: "/v1/resolver")
        url = url.appending(queryItems: [
            URLQueryItem(name: "name_id", value: nameRecord.id),
            URLQueryItem(name: "key", value: "NOSTR"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "page_size", value: "250"),
        ])
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue(orgCode, forHTTPHeaderField: "x-org-code")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let response = try await URLSession.shared.data(for: request)
        let responseJSON = try jsonDictionary(from: response.0)
        print(responseJSON)
        
        guard let dataArray = responseJSON["data"] as? [JSONObject] else {
            throw UNSError.badResponse
        }
       
        var nostrPubKeys = [HexadecimalString]()
        for connection in dataArray {
            if let npub = connection["display_value"] as? String,
                let pubKey = PublicKey(npub: npub) {
                nostrPubKeys.append(pubKey.hex)
            }
        }
        return nostrPubKeys
    }
    
    func logout() {
        refreshToken = nil
        accessToken = nil
        personaID = nil
        saveRefreshToken()
    }
    
    // MARK: - Helpers
    
    func isNeedPaymentError(_ data: Data) -> Bool {
        guard let responseDict = try? jsonDictionary(from: data) else {
            return false
        }
        if let errorDict = responseDict["error"] as? JSONObject,
            let codeDict = errorDict["code"] as? JSONObject,
            let numCode = codeDict["num_code"] as? Int {
            return numCode == 60_404 
        }
        
        return false
    }
    
    func isNameTakenError(_ data: Data) -> Bool {
        guard let responseDict = try? jsonDictionary(from: data) else {
            return false
        }
        if let errorDict = responseDict["error"] as? JSONObject,
            let codeDict = errorDict["code"] as? JSONObject,
            let numCode = codeDict["num_code"] as? Int {
            return numCode == 60_105 || numCode == 60_103
        }
        
        return false
    }
    
    func jsonDictionary(from data: Data) throws -> JSONObject {
        guard let responseDict = try JSONSerialization.jsonObject(with: data) as? JSONObject else {
            throw UNSError.generic
        }
        
        return responseDict
    }
    
    func logError(from functionName: String = #function, response: (Data, URLResponse)) {
        Log.error("\(functionName) failed with \(String(data: response.0, encoding: .utf8) ?? "null")")
    }
    
    class func getEnvironmentVariable(named name: String) -> String? {
        Bundle.main.infoDictionary?[name] as? String
    }
    
    func saveRefreshToken() {
        userDefaults.set(self.refreshToken, forKey: refreshTokenKey)
    }
    
    func loadRefreshToken() {
        self.refreshToken = userDefaults.string(forKey: refreshTokenKey)
    }
}

// swiftlint:enable type_body_length
