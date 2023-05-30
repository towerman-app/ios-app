//
//  CameraPreview.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-18.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
             AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
    }
    
    let session: AVCaptureSession
    let kill: () -> Void
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.cornerRadius = 0
        view.videoPreviewLayer.session = session
        DispatchQueue.main.async {
            if let connection = view.videoPreviewLayer.connection {
                connection.videoOrientation = .landscapeRight
            } else {
                kill()
            }
        }

        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
    }
}
