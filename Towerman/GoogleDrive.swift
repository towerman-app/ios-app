//
//  GoogleDrive.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-01-09.
//

import Foundation
//import GoogleAPIClientForREST_Drive
//import GoogleAPIClientForRESTCore
//import GoogleSignIn


//let rootFolderName = "Games"
//var rootFolderId: String? = nil
//
//func setRootFolder(
//    service: GTLRDriveService,
//    user: GIDGoogleUser,
//    completion: @escaping () -> Void
//) {
//    folderId(name: rootFolderName, service: service, user: user) { id in
//        rootFolderId = id
//        completion()
//    }
//}
//
//func folderId(
//    name: String,
//    service: GTLRDriveService,
//    user: GIDGoogleUser,
//    completion: @escaping (String) -> Void) {
//        getFolderID(
//            name: name,
//            service: service,
//            user: user) { id in
//                if let folderId = id {
//                    // Folder already exists
//                    completion(folderId)
//                } else {
//                    createFolder(
//                        name: name,
//                        service: service,
//                        parents: name == rootFolderName ? nil : [rootFolderId!]) {
//                            completion($0)
//                        }
//                }
//            }
//    }
//
//func getFolderID(
//    name: String,
//    service: GTLRDriveService,
//    user: GIDGoogleUser,
//    completion: @escaping (String?) -> Void) {
//
//    let query = GTLRDriveQuery_FilesList.query()
//
//    // Comma-separated list of areas the search applies to. E.g., appDataFolder, photos, drive.
//    query.spaces = "drive"
//
//    // Comma-separated list of access levels to search in. Some possible values are "user,allTeamDrives" or "user"
//    query.corpora = "user"
//
//    let withName = "name = '\(name)'" // Case insensitive!
//    let foldersOnly = "mimeType = 'application/vnd.google-apps.folder'"
//        let ownedByUser = "'\(user.profile!.email)' in owners"
//    query.q = "\(withName) and \(foldersOnly) and \(ownedByUser)"
//
//    service.executeQuery(query) { (_, result, error) in
//        guard error == nil else {
//            fatalError(error!.localizedDescription)
//        }
//
//        let folderList = result as! GTLRDrive_FileList
//
//        // For brevity, assumes only one folder is returned.
//        completion(folderList.files?.first?.identifier)
//    }
//}
//
//
//func createFolder(
//    name: String,
//    service: GTLRDriveService,
//    parents: [String]?,
//    completion: @escaping (String) -> Void) {
//
//        let folder = GTLRDrive_File()
//        folder.mimeType = "application/vnd.google-apps.folder"
//        folder.name = name
//        folder.parents = parents
//
//        // Google Drive folders are files with a special MIME-type.
//        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
//
//        service.executeQuery(query) { (_, file, error) in
//            guard error == nil else {
//                fatalError(error!.localizedDescription)
//            }
//
//            let folder = file as! GTLRDrive_File
//            completion(folder.identifier!)
//    }
//}
//
//func uploadFile(
//    name: String,
//    folderID: String,
//    data: Data,
//    mimeType: String,
//    service: GTLRDriveService,
//    onComplete: @escaping () -> Void
//) {
//
//    let file = GTLRDrive_File()
//    file.name = name
//    file.parents = [folderID]
//
//    let uploadParameters = GTLRUploadParameters(data: data, mimeType: mimeType)
//
//    let query = GTLRDriveQuery_FilesCreate.query(withObject: file, uploadParameters: uploadParameters)
//
//    service.uploadProgressBlock = { _, totalBytesUploaded, totalBytesExpectedToUpload in
//        // This block is called multiple times during upload and can
//        // be used to update a progress indicator visible to the user.
//    }
//
//    service.executeQuery(query) { (_, result, error) in
//        guard error == nil else {
//            fatalError(error!.localizedDescription)
//        }
//
//        // Successful upload if no error is returned.
//        onComplete()
//    }
//}
