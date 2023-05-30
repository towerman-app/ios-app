//
//  CameraService+Enums.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-18.
//

import Foundation

//  MARK: CameraService Enums
extension CameraService {
    enum LivePhotoMode {
        case on
        case off
    }
    
    enum DepthDataDeliveryMode {
        case on
        case off
    }
    
    enum PortraitEffectsMatteDeliveryMode {
        case on
        case off
    }
    
    enum SessionSetupResult {
        case success
        case notAuthorized
        case configurationFailed
    }
    
    enum CaptureMode: Int {
        case photo = 0
        case movie = 1
    }
}
