//
//  UploadManager.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-02-26.
//

import Foundation
import SwiftUI

class UploadManager: ObservableObject {
    @Published var tasks: [Upload] = []
    
    @Published var progress: Double = 1
    @Published var error: AppError? = nil
    
    static func initial() -> UploadManager {
        return UploadManager()
    }
    
    func upload(name: String, photo: Data, play: PlayData) {
        if let idx = tasks.firstIndex(where: { task in task.name == name }) {
            tasks[idx].error = nil
            tasks[idx].done = false
        } else {
            tasks.append(Upload(name: name, photo: photo, play: play))
        }
        self.progress = self.updateProgress()

    }
    
    func onDone(name: String) {
        let idx = self.tasks.firstIndex { task in task.name == name }
        guard let idx = idx else { return }
        self.tasks[idx].done = true
        
        self.progress = self.updateProgress()
    }
    
    func onError(name: String, error: String) {
        let idx = self.tasks.firstIndex { task in task.name == name }
        guard let idx = idx else { return }
        self.tasks[idx].error = error
        self.tasks[idx].done = true
        
        self.progress = self.updateProgress()
    }
    
    func getFailedTasks() -> Array<Upload> {
        return self.tasks.filter { task in task.error != nil }
    }
    
//    func tryAgain() {
//        for (idx, task) in tasks.enumerated() {
//            if task.error == nil { continue }
//            self.tasks[idx].done = false
//            self.tasks[idx].error = nil
//            startUpload(task, succeed: true)
//        }
//        self.error = nil
//        self.progress = self.updateProgress()
//    }
    
//    private func startUpload(_ task: Upload, succeed: Bool? = nil) {
//        DispatchQueue.main.asyncAfter(deadline: .now() + (0.5 + Double(task.idx)/2)) {
//            let error: AppError? = succeed != nil && !succeed! ? AppError.connection() : nil
//
//            let idx = self.tasks.firstIndex { x in x.id == task.id }
//            guard let idx = idx else { return }
//
//            self.tasks[idx].done = true
//            self.tasks[idx].error = error
//            if error != nil {
//                withAnimation(Animation.easeInOut) {
//                    self.error = error
//                }
//            }
//            self.progress = self.updateProgress()
//        }
//    }
    
    private func updateProgress() -> Double {
        if tasks.isEmpty {
            return 1
        }
        
        let done = tasks.filter { task in task.done && task.error == nil }
        if done.count == 0 { return 0 }
        if done.count == tasks.count {
            tasks = []
            return 1
        }
        return Double(done.count) / Double(tasks.count)
    }
}
