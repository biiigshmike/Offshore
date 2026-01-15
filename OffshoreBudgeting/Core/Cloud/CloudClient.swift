//
//  CloudClient.swift
//  Offshore
//

import CloudKit
import Foundation

// MARK: - CloudClient
/// Thin wrapper around the app's CloudKit container and its databases.
struct CloudClient {
    // MARK: Stored
    let container: CKContainer
    let privateDatabase: CKDatabase
    let publicDatabase: CKDatabase
    let sharedDatabase: CKDatabase

    // MARK: Init
    init(containerIdentifier: String = CloudKitConfig.containerIdentifier) {
        let container = CKContainer(identifier: containerIdentifier)
        self.container = container
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        self.sharedDatabase = container.sharedCloudDatabase
    }
}
