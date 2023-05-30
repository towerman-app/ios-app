//
//  TestCam.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-18.
//

import SwiftUI
import AVFoundation
import Combine

final class CameraModel: ObservableObject {
    private let service = CameraService()
    
    @Published var photo: Photo!
    
    @Published var showAlertError = false
    
    @Published var isFlashOn = false
    
    @Published var willCapturePhoto = false
    
    var alertError: AlertError!
    
    var session: AVCaptureSession
    
    private var subscriptions = Set<AnyCancellable>()
    
    init() {
        self.session = service.session
        
        service.$photo.sink { [weak self] (photo) in
            guard let pic = photo else { return }
            self?.photo = pic
        }
        .store(in: &self.subscriptions)
        
        service.$shouldShowAlertView.sink { [weak self] (val) in
            self?.alertError = self?.service.alertError
            self?.showAlertError = val
        }
        .store(in: &self.subscriptions)
        
        service.$flashMode.sink { [weak self] (mode) in
            self?.isFlashOn = mode == .on
        }
        .store(in: &self.subscriptions)
        
        service.$willCapturePhoto.sink { [weak self] (val) in
            self?.willCapturePhoto = val
        }
        .store(in: &self.subscriptions)
    }
    
    func configure() {
        service.checkForPermissions()
        service.configure()
    }
    
    func capturePhoto() {
        service.capturePhoto()
    }
    
    func flipCamera() {
        service.changeCamera()
    }
    
    func zoom(with factor: CGFloat) {
        service.set(zoom: factor)
    }
    
    func switchFlash() {
        service.flashMode = service.flashMode == .on ? .off : .on
    }
}

struct CaptureView: View {
    @Binding var photos: [PlayData.PlayPhoto]
    @State private var initPhotos: [PlayData.PlayPhoto] = []
    let exit: () -> Void
    @StateObject var model = CameraModel()
    
    @State private var currentZoomFactor: CGFloat = 1.0
    
    // Increase responsiveness
    @State private var numberOfPhotos = 0
    @State private var isCapturing = false
    
    
    var captureButton: some View {
        Circle()
            .foregroundColor(.white)
            .frame(width: 80, height: 80, alignment: .center)
            .overlay(
                Circle()
                    .stroke(Color.black.opacity(0.8), lineWidth: isCapturing ? 5 : 2)
                    .frame(width: 65, height: 65, alignment: .center)
                    .scaleEffect(isCapturing ? 0.9 : 1)
            )
            .onTapGesture {
                model.capturePhoto()
                withAnimation(Animation.linear(duration: 0.1)) {
                    isCapturing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        isCapturing = false
                    }
                }
                
                withAnimation(Animation.linear(duration: numberOfPhotos == 0 ? 0.1 : 0)) {
                    numberOfPhotos += 1
                }
            }
    }
    
    var body: some View {
        GeometryReader { reader in
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                
                CameraPreview(session: model.session) {
                    exit()
                }
                .opacity(model.willCapturePhoto ? 0 : 1)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .onAppear {
                    model.configure()
                    initPhotos = photos
                    
                    withAnimation(Animation.easeInOut) {
                        numberOfPhotos = photos.count
                    }
                }
                .alert(isPresented: $model.showAlertError, content: {
                    Alert(title: Text(model.alertError.title), message: Text(model.alertError.message), dismissButton: .default(Text(model.alertError.primaryButtonTitle), action: {
                        model.alertError.primaryAction?()
                    }))
                })
                .overlay(
                    ZStack {
                        HStack {
                            Spacer()
                            VStack(alignment: .trailing) {
                                
                                if numberOfPhotos > 0 {
                                    Text(String(numberOfPhotos))
                                        .fontWeight(.bold)
                                        .padding(8)
                                        .background(AppColors.contrast)
                                        .cornerRadius(8)
                                        .padding(.trailing, 18)
                                        .transition(.scale)
                                    
                                    Button(action: {
                                        if model.willCapturePhoto {
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                                exit()
                                            }
                                        } else {
                                            exit()
                                        }
                                    }) {
                                        Text("Done")
                                            .foregroundColor(.white)
                                            .fontWeight(.bold)
                                            .padding(8)
                                            .background(AppColors.secondary)
                                            .cornerRadius(8)
                                    }
                                    .padding(.trailing, 12)
                                    .transition(.scale)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 16)
                        }
                        //                            Group {
                        //                                if model.willCapturePhoto {
                        //                                    Color.black
                        //                                }
                        //                            }
                    }
                )
                .onChange(of: model.photo) { newValue in
                    guard let pic = newValue else { return }
                    photos.append(PlayData.PlayPhoto(data: pic.originalData))
                }
            }
            .edgesIgnoringSafeArea(.horizontal)
            .overlay {
                HStack(alignment: .center) {
                    
                    // Zoom
                    ZoomSlider(zoom: $currentZoomFactor)
                        .padding(.leading, -100)
                        .onChange(of: currentZoomFactor) { zoom in
                            model.zoom(with: zoom)
                        }
//                    VStack(spacing: 16) {
//                        Button(action: {
//                            withAnimation(Animation.linear(duration: 0.1)) {
//                                currentZoomFactor = 2.0
//                                model.zoom(with: currentZoomFactor)
//                            }
//                        }) {
//                            ZoomText(zoom: 2.0, current: $currentZoomFactor)
//                        }
//
//                        Button(action: {
//                            withAnimation(Animation.linear(duration: 0.2)) {
//                                currentZoomFactor = 1.0
//                                model.zoom(with: currentZoomFactor)
//                            }
//                        }) {
//                            ZoomText(zoom: 1.0, current: $currentZoomFactor)
//                        }
//                    }
//                    .foregroundColor(.white)
                    
                    Spacer()
                    
                    ZoomPreview(zoom: $currentZoomFactor)
                    
                    Spacer()
                    
                    captureButton
                        .padding(.trailing, 12)
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { photos = initPhotos; exit() }) {
                            Text("Cancel")
                                .foregroundColor(.white)
                                .fontWeight(.bold)
                                .padding(8)
                                .background(AppColors.contrast)
                                .cornerRadius(8)
                        }
                        .padding(.trailing, 12)
                    }
                }
            }
            .edgesIgnoringSafeArea(.trailing)
            
        }
    }
}

struct ZoomSlider: View {
    @Binding var zoom: CGFloat
    
    @State private var offset: CGFloat = 0
    @State private var height: CGFloat = 0
    
    private let maxZoom: CGFloat = 3
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.gray, lineWidth: 2)
                .frame(width: 4)
                .frame(maxHeight: .infinity)
                .padding(.vertical, UIScreen.screenHeight * 0.2)
            
            Circle()
                .frame(width: 20, height: 20)
                .foregroundColor(.yellow)
                .offset(y: offset - height/2)
        }
        .frame(maxHeight: .infinity)
        .padding(.trailing, 100)
        .padding(.leading, 100)
        .contentShape(Rectangle())
        .gesture(DragGesture()
            .onChanged({ v in
                offset = min(height, max(0, v.location.y - UIScreen.screenHeight * 0.2))
                let percent = (height - offset) / height
                print(percent)
                zoom = 1 + percent * (maxZoom-1.0)
            }))
        .overlay {
            GeometryReader { geo in
                Color.clear.onAppear {
                    height = geo.size.height - UIScreen.screenHeight * 0.4
                    offset = height
                }
            }
        }
//        .padding(.vertical, UIScreen.screenHeight * 0.2)
    }
}

struct ZoomPreview: View {
    @Binding var zoom: CGFloat
    
    @State private var justChanged = false
    var body: some View {
        ZStack {
            if justChanged {
                Rectangle()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                    .opacity(0.8)
                Text("\(zoom, specifier: "%.1f")x")
                    .fontWeight(.semibold)
            }
        }
        .onChange(of: zoom) { current in
            withAnimation(Animation.linear(duration: 0.1)) {
                justChanged = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if current == zoom {
                    withAnimation(Animation.linear(duration: 0.1)) {
                        justChanged = false
                    }
                }
            }
        }
    }
}

//struct ZoomText: View {
//
//    let zoom: CGFloat
//    @Binding var current: CGFloat
//    @State private var radius: CGFloat = .zero
//    @State private var selected = false
//
//    var body: some View {
//
//        return ZStack {
//
//            Text("\(Int(zoom))x")
//                .padding(6)
//                .background(GeometryReader { proxy in Color.clear.onAppear() { radius = max(proxy.size.width, proxy.size.height) } }.hidden())
//                .onAppear {
//                    selected = zoom == current
//                }
//                .onChange(of: current) { newValue in
//                    selected = zoom == current
//                }
//
//            if (!radius.isZero) {
//
//                Circle().strokeBorder(selected ? .yellow : .white).frame(width: radius, height: radius)
//
//            }
//
//        }
//    }
//}
