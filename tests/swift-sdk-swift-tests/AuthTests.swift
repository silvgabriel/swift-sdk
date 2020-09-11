//
//  Created by Jay Kim on 7/6/20.
//  Copyright © 2020 Iterable. All rights reserved.
//

import XCTest

@testable import IterableSDK

class AuthTests: XCTestCase {
    private static let apiKey = "zeeApiKey"
    private static let email = "user@example.com"
    private static let userId = "testUserId"
    private static let authToken = "testAuthToken"
    
    override func setUp() {
        super.setUp()
    }
    
    func testEmailPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        internalAPI.email = AuthTests.email
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testUserIdPersistence() {
        let internalAPI = IterableAPIInternal.initializeForTesting()
        
        internalAPI.userId = AuthTests.userId
        
        XCTAssertNil(internalAPI.email)
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }
    
    func testEmailWithTokenPersistence() {
        let config = IterableConfig()
        
        let emailToken = "asdf"
        
        config.onAuthTokenRequestedCallback = { () in
            emailToken
        }
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        internalAPI.email = "previous.user@example.com"
        
        internalAPI.setEmail(AuthTests.email)
        
        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertEqual(internalAPI.auth.authToken, emailToken)
    }
    
    func testUserIdWithTokenPersistence() {
        let config = IterableConfig()
        
        let userIdToken = "qwer"
        
        config.onAuthTokenRequestedCallback = { () in
            userIdToken
        }
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config)

        internalAPI.userId = "previousUserId"
        
        internalAPI.setUserId(AuthTests.userId)

        XCTAssertNil(internalAPI.email)
        XCTAssertEqual(internalAPI.userId, AuthTests.userId)
        XCTAssertEqual(internalAPI.auth.authToken, userIdToken)
    }

    func testUserLoginAndLogout() {
        let internalAPI = IterableAPIInternal.initializeForTesting()

        internalAPI.setEmail(AuthTests.email)

        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)

        internalAPI.email = nil

        XCTAssertNil(internalAPI.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)
    }

    func testNewEmailWithTokenChange() {
        var internalAPI: IterableAPIInternal?
        
        let originalEmail = "first@example.com"
        let originalToken = "fdsa"
        
        let newEmail = "second@example.com"
        let newToken = "jay"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            if internalAPI?.email == originalEmail { return originalToken }
            if internalAPI?.email == newEmail { return newToken }
            return nil
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }

        API.setEmail(originalEmail)

        XCTAssertEqual(API.email, originalEmail)
        XCTAssertNil(API.userId)
        XCTAssertEqual(API.auth.authToken, originalToken)

        API.setEmail(newEmail)

        XCTAssertEqual(API.email, newEmail)
        XCTAssertNil(API.userId)
        XCTAssertEqual(API.auth.authToken, newToken)
    }
    
    func testNewUserIdWithTokenChange() {
        var internalAPI: IterableAPIInternal?

        let originalUserId = "firstUserId"
        let originalToken = "nen"

        let newUserId = "secondUserId"
        let newToken = "greedIsland"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            if internalAPI?.userId == originalUserId { return originalToken }
            if internalAPI?.userId == newUserId { return newToken }
            return nil
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setUserId(originalUserId)

        XCTAssertNil(API.email)
        XCTAssertEqual(API.userId, originalUserId)
        XCTAssertEqual(API.auth.authToken, originalToken)

        API.setUserId(newUserId)

        XCTAssertNil(API.email)
        XCTAssertEqual(API.userId, newUserId)
        XCTAssertEqual(API.auth.authToken, newToken)
    }
    
    func testUpdateEmailWithToken() {
        let condition1 = expectation(description: "update email with auth token")
        
        var internalAPI: IterableAPIInternal?
        
        let originalEmail = "first@example.com"
        let originalToken = "fdsa"
        
        let updatedEmail = "second@example.com"
        let updatedToken = "jay"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            if internalAPI?.email == originalEmail { return originalToken }
            if internalAPI?.email == updatedEmail { return updatedToken }
            return nil
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setEmail(originalEmail)
        
        XCTAssertEqual(API.email, originalEmail)
        XCTAssertNil(API.userId)
        XCTAssertEqual(API.auth.authToken, originalToken)
        
        API.updateEmail(updatedEmail,
                        onSuccess: { data in
                            XCTAssertEqual(API.email, updatedEmail)
                            XCTAssertNil(API.userId)
                            XCTAssertEqual(API.auth.authToken, updatedToken)
                            condition1.fulfill()
        },
                        onFailure: nil)
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
    
    func testLogoutUser() {
        let config = IterableConfig()
        
        config.onAuthTokenRequestedCallback = { () in
            AuthTests.authToken
        }
        
        let localStorage = MockLocalStorage()

        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   localStorage: localStorage)
        
        XCTAssertNil(localStorage.email)
        XCTAssertNil(localStorage.userId)
        XCTAssertNil(localStorage.authToken)

        internalAPI.setEmail(AuthTests.email)

        XCTAssertEqual(internalAPI.email, AuthTests.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertEqual(internalAPI.auth.authToken, AuthTests.authToken)

        XCTAssertEqual(localStorage.email, AuthTests.email)
        XCTAssertNil(localStorage.userId)
        XCTAssertEqual(localStorage.authToken, AuthTests.authToken)

        internalAPI.logoutUser()

        XCTAssertNil(internalAPI.email)
        XCTAssertNil(internalAPI.userId)
        XCTAssertNil(internalAPI.auth.authToken)

        XCTAssertNil(localStorage.email)
        XCTAssertNil(localStorage.userId)
        XCTAssertNil(localStorage.authToken)
    }
    
    func testAuthTokenChangeWithSameEmail() {
        var authTokenChanged = false
        
        var internalAPI: IterableAPIInternal?
        
        let newAuthToken = AuthTests.authToken + "3984ru398gj893"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            guard internalAPI?.email == AuthTests.email else { return nil }
            
            return authTokenChanged ? newAuthToken : AuthTests.authToken
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }

        API.setEmail(AuthTests.email)
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken()
        
        XCTAssertEqual(API.email, AuthTests.email)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testAuthTokenChangeWithSameUserId() {
        var authTokenChanged = false
        
        var internalAPI: IterableAPIInternal?
        
        let newAuthToken = AuthTests.authToken + "3984ru398gj893"
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = { () in
            guard internalAPI?.userId == AuthTests.userId else { return nil }
            
            return authTokenChanged ? newAuthToken : AuthTests.authToken
        }
        
        internalAPI = IterableAPIInternal.initializeForTesting(config: config)
        
        guard let API = internalAPI else {
            XCTFail()
            return
        }
        
        API.setUserId(AuthTests.userId)

        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, AuthTests.authToken)
        
        authTokenChanged = true
        API.authManager.requestNewAuthToken()
        
        XCTAssertEqual(API.userId, AuthTests.userId)
        XCTAssertEqual(API.auth.authToken, newAuthToken)
    }
    
    func testRetrieveNewAuthTokenCallbackCalled() {
        let condition1 = expectation(description: "\(#function) - auth failure callback didn't get called")
        
        var callbackCalled = false
        
        let config = IterableConfig()
        config.onAuthTokenRequestedCallback = {
            callbackCalled = true
            return nil
        }
        
        let mockNetworkSession = MockNetworkSession(statusCode: 401,
                                                    json: [JsonKey.Response.iterableCode: JsonValue.Code.invalidJwtPayload])
        
        let internalAPI = IterableAPIInternal.initializeForTesting(config: config,
                                                                   networkSession: mockNetworkSession)
        
        internalAPI.email = AuthTests.email
        
        internalAPI.track("event",
                          dataFields: nil,
                          onSuccess: { data in
                            XCTFail("track event shouldn't have succeeded")
        }, onFailure: { reason, data in
            XCTAssertTrue(callbackCalled)
            condition1.fulfill()
        })
        
        wait(for: [condition1], timeout: testExpectationTimeout)
    }
}
