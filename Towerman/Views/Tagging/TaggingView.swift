//
//  TaggingView.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-01-11.
//

import SwiftUI


struct TaggingView: View {
    @Binding var screen: AppScreen
    
    @ObservedObject var taggingManager: TaggingManager
    @ObservedObject var uploadManager: UploadManager
    @EnvironmentObject var server: ServerModel
    
    // State
    @State private var numberPadFor: NumberPadView.For = .none
    @State private var expandedPhotoIdx: Int? = nil
    @State private var inCaptureView = false
    
    // Upload
    @State private var uploadAnimation: CGFloat = 1
    
    
    // Number select (retains value in case user cancels)
    @State private var distance: Int = 1  // 1-99
    @State private var startLine: Int = 1  // (-49)-50
    @State private var endLine: Int = 1  // (-49)-50
    @State private var series: Int = 1  // 1+
    
//    @State private var lastOdk = "K"
//    @State private var wasKick = true
    
    @State private var photos: [PlayData.PlayPhoto] = []
    
    var body: some View {
        
        HStack(alignment: .top, spacing: 16) {
            // Quarter
            TapSelectView<Int>(title: "Q", options: [1, 2, 3, 4], selected: $taggingManager.play.quarter, nulled: nil)
            
            // ODK
            TapSelectView<String>(title: "ODK", options: ["O", "D", "K"], selected: $taggingManager.play.odk, nulled: nil)
                .onChange(of: taggingManager.play.odk) { odk in
//                    if wasKick {
//
//                    }
//                    if lastOdk == "K" {
//                        taggingManager.modify(down: 1, distance: 10, series: taggingManager.play.series + 1)
//                    }
//
//                    if odk == "K" {
//                        wasKick = true
//                    } else {
//                        wasKick = false
//                        lastOdk = odk
//                    }
                }

            // Down
            TapSelectView<Int>(title: "DN", options: [1, 2, 3], selected: $taggingManager.play.down, nulled: -1)
            
            // DIST: 10
            
            // Distance & Series
            VStack {
                
                NumberSelectView(title: "DIST", value: taggingManager.play.distance, pad: $numberPadFor, selected: .distance)
                
                NumberSelectView(title: "ST LN", value: taggingManager.play.startLine, pad: $numberPadFor, selected: .startLine)
                
                NumberSelectView(title: "END LN", value: taggingManager.play.endLine, pad: $numberPadFor, selected: .endLine)
            }
            .padding(.vertical, 32)
            
            VStack {
                NumberSelectView(title: "SERIES", value: taggingManager.play.odk == "K" ? nil : taggingManager.play.series, pad: $numberPadFor, selected: .series)
                
                FlagSelectView(selected: $taggingManager.play.flagged)
                
            }
            .padding(.vertical, 32)
            
            Spacer()
            
            VStack {
                PhotosPreviewView(photos: $photos, expandedPhotoIdx: $expandedPhotoIdx) {
#if targetEnvironment(simulator)
                    photos = [PlayData.PlayPhoto.dummy(), PlayData.PlayPhoto.dummy()]
#else
                    withAnimation(Animation.linear(duration: 0.1)) {
                        inCaptureView = true
                    }
#endif
                }
                Spacer()
//                Button("Next Play") {
//                    withAnimation(Animation.linear(duration: 0.1)) {
//                        taggingManager.nextPlay()
//                    }
//                }
                if !photos.isEmpty {
                    CTAButton(
                        title: "UPLOAD",
                        icon: CTAButton.Icon(name: "arrow.up.circle", width: 18, height: 18)
                    ) {
//                        uploadManager.upload(photos.map { x in x.data }, play: taggingManager.play)
                        
                        for idx in 0..<photos.count {
                            server.uploadPhoto(
                                play: taggingManager.play.toPlayData(),
                                idx: idx,
                                photo: photos[idx].toImage().jpegData(compressionQuality: 0.5)!
                            )
                        }
                        
                        // Haptics
                        hapticFeedback(style: .light)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            hapticFeedback(style: .heavy)
                        }
                        
                        
                        // Animation and automation (kys)
                        withAnimation(Animation.linear(duration: 0.1)) {
                            uploadAnimation = 0.95
                            taggingManager.nextPlay()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(Animation.linear(duration: 0.1)) {
                                photos = []
                                uploadAnimation = 1
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 32)
            .opacity(numberPadFor == .none ? 1 : 0)
            
            Spacer()
            
            VStack {
                Button(action: { server.stopCapturing(); change($screen, to: .modeSelect) }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .semibold, design: .default))
                        .foregroundColor(.white)
                }
                .padding(.vertical, 32)
                Button(action: {
                    let failed = uploadManager.getFailedTasks()
                    for idx in 0..<failed.count {
                        server.uploadPhoto(play: failed[idx].play, idx: idx, photo: failed[idx].photo)
                    }
                    
                }) {
                    CircularProgressView(progress: uploadManager.progress, error: uploadManager.error)
                }
                .disabled(uploadManager.error == nil)
            }
            .opacity(numberPadFor == .none ? 1 : 0)
            
        }
        .overlay {
            NumberPadView(forType: $numberPadFor, value: getNumberPadValue(), taggingManager: taggingManager)
        }
        .overlay {
            if inCaptureView {
                CaptureView(photos: $photos, exit: { withAnimation(Animation.linear(duration: 0.1)) { inCaptureView = false } })
                    .transition(.move(edge: .bottom))
            }
        }
        .overlay {
            // MARK: ADD ZOOM?
            ExpandedPhotoView(photos: $photos, expandedPhotoIdx: $expandedPhotoIdx, play: taggingManager.play)
        }
        .overlay {
            ErrorStackView(errors: server.errorStack)
        }
        .scaleEffect(uploadAnimation)
        
    }
    
    func getNumberPadValue() -> Binding<Int> {
        switch numberPadFor {
        case .series:
            return $series
        case .distance:
            return $distance
        case .startLine:
            return $startLine
        case .endLine:
            return $endLine
            
        // Should NEVER happen
        case .none:
            return $series
        }
    }
}

struct CTAButton: View {
    let title: String
    let icon: CTAButton.Icon
    let onClick: () -> Void
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 10) {
                Spacer()
                Text(title)
                    .foregroundColor(.white)
                    .fontWeight(.bold)
                
                Image(systemName: icon.name)
                    .resizable()
                    .frame(width: icon.width, height: icon.height)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.vertical, 12)
//            .padding(.horizontal, 24)
            .background(AppColors.secondary)
            .cornerRadius(8)
        }
    }
    
    struct Icon {
        let name: String
        let width: CGFloat
        let height: CGFloat
    }
}

struct CircularProgressView: View {
    let progress: Double
    let error: AppError?
    
    private let iconAnim: AnyTransition = .scale
    
    @State private var done: Bool = true
    
    var body: some View {
        ZStack {
            if let error = error {
                Image(systemName: error.icon)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.red)
                    .transition(iconAnim)
            } else if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.green)
                    .transition(iconAnim)
            } else {
                Image(systemName: "arrow.up")
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .foregroundColor(.white)
                    .transition(iconAnim)
            }
            
            Circle()
                .stroke(
                    Color.gray.opacity(0.5),
                    lineWidth: 4
                )
                .frame(width: 32, height: 32)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    error != nil ? Color.gray : Color.green,
                    style: StrokeStyle(
                        lineWidth: 4,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
                .frame(width: 32, height: 32)

        }
        .onChange(of: progress) { p in
            if p == 1 {
                withAnimation(Animation.easeInOut) {
                    done = true
                }
            } else {
                withAnimation(Animation.easeInOut) {
                    done = false
                }
            }
        }
    }
}

func hapticFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle) {
    let impactHeavy = UIImpactFeedbackGenerator(style: style)
    impactHeavy.impactOccurred()
}
