//
// Copyright 2018-2020 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
import SQLite
import Combine

@testable import Amplify
@testable import AmplifyTestCommon
@testable import AWSPluginsCore
@testable import AWSDataStoreCategoryPlugin

class ReadyEventEmitterTests: XCTestCase {
    var stateMachine: MockStateMachine<RemoteSyncEngine.State, RemoteSyncEngine.Action>!
    var readyEventEmitter: ReadyEventEmitter?
    var readyEventSink: AnyCancellable?

    override func setUp() {
        super.setUp()
    }

    func testReadyEventReceived() throws {
        let readyReceived = expectation(description: "ready received")
        readyReceived.assertForOverFulfill = false

        readyEventSink = Amplify.Hub.publisher(for: .dataStore).sink { payload in
            switch payload.eventName {
            case HubPayload.EventName.DataStore.ready:
                readyReceived.fulfill()
            default:
                break
            }
        }

        let remoteSyncTopicPublisher = PassthroughSubject<RemoteSyncEngineEvent, DataStoreError>()
        readyEventEmitter = ReadyEventEmitter(remoteSyncEnginePublisher: remoteSyncTopicPublisher.eraseToAnyPublisher())

        remoteSyncTopicPublisher.send(.syncStarted)
        let syncQueriesReadyEventPayload = HubPayload(eventName: HubPayload.EventName.DataStore.syncQueriesReady)
        Amplify.Hub.dispatch(to: .dataStore, payload: syncQueriesReadyEventPayload)
        
        wait(for: [readyReceived], timeout: 1)
        readyEventSink?.cancel()
    }

}
