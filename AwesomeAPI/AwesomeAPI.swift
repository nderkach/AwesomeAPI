//
//  AwesomeAPI.swift
//  AwesomeAPI
//
//  Created by Nikolay Derkach on 12/6/17.
//  Copyright © 2017 Nikolay Derkach. All rights reserved.
//

import Siesta
import JWTDecode

let baseURL = "https://jwt-api-siesta.herokuapp.com"

let AwesomeAPI = _AwesomeAPI()

class _AwesomeAPI {
    
    // MARK: - Configuration
    
    private let service = Service(
        baseURL: baseURL,
        standardTransformers: [.text, .image]
    )

    private var refreshTimer: Timer?

    private var authToken: String? {
        didSet {
            service.invalidateConfiguration()

            guard let token = authToken else { return }

            let jwt = try? JWTDecode.decode(jwt: token)
            tokenExpiryDate = jwt?.expiresAt
        }
    }

    public private(set) var tokenExpiryDate: Date? {
        didSet {
            guard let tokenExpiryDate = tokenExpiryDate else { return }

            let timeToExpire = tokenExpiryDate.timeIntervalSinceNow

            // try to refresh JWT token before the expiration time
            let timeToRefresh = Date(timeIntervalSinceNow: timeToExpire * 0.9)

            refreshTimer = Timer.scheduledTimer(withTimeInterval: timeToRefresh.timeIntervalSinceNow, repeats: false) { _ in

                AwesomeAPI.login("test", "test", onSuccess: {}, onFailure: { _ in })
            }
        }
    }
    
    fileprivate init() {
        // –––––– Global configuration ––––––
        
        #if DEBUG
            LogCategory.enabled = [.network]
        #endif

        service.configure("**") {
            if let authToken = self.authToken {
                $0.headers["Authorization"] = "Bearer \(authToken)"
            }
        }

        let jsonDecoder = JSONDecoder()
        let jsonDateFormatter = DateFormatter()
        jsonDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.A"
        jsonDecoder.dateDecodingStrategy = .formatted(jsonDateFormatter)

        // –––––– Mapping from specific paths to models ––––––

        service.configureTransformer("/status") {
            try jsonDecoder.decode([String: String].self, from: $0.content)
        }

        service.configureTransformer("/login", requestMethods: [.post]) {
            try jsonDecoder.decode([String: String].self, from: $0.content)
        }

        service.configureTransformer("/expenses") {
            try jsonDecoder.decode([Expense].self, from: $0.content)
        }
    }

    // MARK: - Resource Accessors

    func ping() -> Resource {
        return service.resource("/ping")
    }

    func expenses() -> Resource {
        return service.resource("/expenses")
    }

    func status() -> Resource {
        return service.resource("/status")
    }

    // MARK: - Authentication

    @discardableResult func login(_ username: String, _ password: String, onSuccess: @escaping () -> Void, onFailure: @escaping (String) -> Void) -> Request {
        let request = service.resource("/login")
            .request(.post, json: ["username": username, "password": password])
            .onSuccess { entity in
                guard let json: [String: String] = entity.typedContent() else {
                    onFailure("JSON parsing error")
                    return
                }

                guard let token = json["jwt"] else {
                    onFailure("JWT token missing")
                    return
                }

                self.authToken = token

                onSuccess()
            }
            .onFailure { (error) in
                onFailure(error.userMessage)
        }

        return request
    }

    func refreshAuth(_ username: String, _ password: String) -> Request {
        return self.login(username, password, onSuccess: {
            }, onFailure: { error in
        })
    }

    func refreshTokenOnAuthFailure(request: Siesta.Request) -> Request {
        return request.chained {
            guard case .failure(let error) = $0.response,  // Did request fail…
                error.httpStatusCode == 401 else {           // …because of expired token?
                    return .useThisResponse                    // If not, use the response we got.
            }

            return .passTo(
                self.refreshAuth("test", "test").chained {             // If so, first request a new token, then:
                    if case .failure = $0.response {           // If token request failed…
                        return .useThisResponse                  // …report that error.
                    } else {
                        return .passTo(request.repeated())       // We have a new token! Repeat the original request.
                    }
                }
            )
        }
    }
}
