//
// Copyright 2018-2019 Amazon.com,
// Inc. or its affiliates. All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import AWSMobileClient
@testable import Amplify
import AWSS3StoragePlugin
import AWSS3
import AWSCognitoIdentityProvider

class AWSS3StoragePluginTestBase: XCTestCase {

    /*
     Set up
     `amplify init`
     `amplify add storage`
     ? Please select from one of the below mentioned services: `Content (Images, audio, video, etc.)`
     ? You need to add auth (Amazon Cognito) to your project in order to add storage for user files. Do you want to add auth now? `Yes`
      Do you want to use the default authentication and security configuration? `Default configuration`
      How do you want users to be able to sign in? `Username`
      Do you want to configure advanced settings? `No, I am done.`
     Successfully added auth resource
     ? Please provide a friendly name for your resource that will be used to label this category in the project: `s3f34a5918`
     ? Please provide bucket name: `storage6e54d3cf8ff042e18d59639bdb4f1664`
     ? Who should have access: `Auth and guest users`
     ? What kind of access do you want for Authenticated users? `create/update, read, delete`
     ? What kind of access do you want for Guest users? `create/update, read, delete`
     ? Do you want to add a Lambda Trigger for your S3 Bucket? `No`
     `amplify push`

     awsconfiguration.json
     {
         "UserAgent": "aws-amplify/cli",
         "Version": "0.1.0",
         "IdentityManager": {
             "Default": {}
         },
         "CredentialsProvider": {
             "CognitoIdentity": {
                 "Default": {
                     "PoolId": "us-west-2:5eed512d-00bd-4d4b-a398-40e0eee8d1d8",
                     "Region": "us-west-2"
                 }
             }
         },
         "CognitoUserPool": {
             "Default": {
                 "PoolId": "us-west-2_HjINbPLHp",
                 "AppClientId": "1hpov6246ng77bvfj1uhg2ulah",
                 "AppClientSecret": "bktd98c6qnjibvqeq81bm83bl45p7g2t0j0997o5j59iit06qru",
                 "Region": "us-west-2"
             }
         },
         "S3TransferUtility": {
             "Default": {
                 "Bucket": "storage6e54d3cf8ff042e18d59639bdb4f1664151034-devo",
                 "Region": "us-west-2"
             }
         }
     }

     amplifyconfiguration.json
     {
         "UserAgent": "aws-amplify-cli/2.0",
         "Version": "1.0",
         "storage": {
             "plugins": {
                 "awsS3StoragePlugin": {
                     "bucket": "storage6e54d3cf8ff042e18d59639bdb4f1664151034-devo",
                     "region": "us-west-2",
                     "defaultAccessLevel": "guest"
                 }
             }
         }
     }
     */
    let bucket: JSONValue = "amplifystoragesample376a67475b8e41af863024fee02fc443-devo"
    let region: JSONValue = "us-east-1"
    let networkTimeout = TimeInterval(180) // 180 seconds to wait before network timeouts
    static let largeDataObject = Data(repeating: 0xff, count: 1_024 * 1_024 * 6) // 6MB

    override func setUp() {
        let config = [
            "CredentialsProvider": [
                "CognitoIdentity": [
                    "Default": [
                        "PoolId": "us-east-1:e80d0cb9-84b1-4d34-84e1-04ee17d576f5",
                        "Region": "us-east-1"
                    ]
                ]
            ],
            "CognitoUserPool": [
                "Default": [
                    "PoolId": "us-east-1_W4yPiPDfC",
                    "AppClientId": "49gnirp7oej6oa7ghbbpr0tjdb",
                    "AppClientSecret": "3uhb11mgra4gfjlgvtjf3069ovak0n8ol2ss0alatnkjcajenbq",
                    "Region": "us-east-1"
                ]
            ]
        ]
        AWSInfo.configureDefaultAWSInfo(config)

        let mobileClientIsInitialized = expectation(description: "AWSMobileClient is initialized")
        AWSMobileClient.default().initialize { userState, error in
            guard error == nil else {
                XCTFail("Error initializing AWSMobileClient. Error: \(error!.localizedDescription)")
                return
            }
            guard let userState = userState else {
                XCTFail("userState is unexpectedly empty initializing AWSMobileClient")
                return
            }
            if userState != UserState.signedOut {
                AWSMobileClient.default().signOut()
            }
            mobileClientIsInitialized.fulfill()
        }
        wait(for: [mobileClientIsInitialized], timeout: networkTimeout)
        print("AWSMobileClient Initialized")

        // Set up Amplify storage configuration

        let storageConfig = StorageCategoryConfiguration(
            plugins: [
                "awsS3StoragePlugin": [
                    "bucket": bucket,
                    "region": region,
                    "defaultAccessLevel": "guest"
                ]
            ]
        )

        let amplifyConfig = AmplifyConfiguration(storage: storageConfig)

        // Set up Amplify
        do {
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure(amplifyConfig)
        } catch {
            XCTFail("Failed to initialize and configure Amplify")
        }
        print("Amplify initialized")
    }

    override func tearDown() {
        print("Amplify reset")
        Amplify.reset()
        sleep(5)
    }

    // MARK: Common Helper functions

    func putData(key: String, dataString: String) {
        putData(key: key, data: dataString.data(using: .utf8)!)
    }

    func putData(key: String, data: Data) {
        let completeInvoked = expectation(description: "Completed is invoked")

        let operation = Amplify.Storage.putData(key: key, data: data, options: nil) { event in
            switch event {
            case .completed:
                completeInvoked.fulfill()
            case .failed(let error):
                XCTFail("Failed with \(error)")
            default:
                break
            }
        }

        XCTAssertNotNil(operation)
        waitForExpectations(timeout: 60)
    }
}