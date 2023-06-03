//
//  Extensions.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-04-03.
//

import Combine
import SwiftUI
extension View {
  var keyboardPublisher: AnyPublisher<Bool, Never> {
    Publishers
      .Merge(
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillShowNotification)
          .map { _ in true },
        NotificationCenter
          .default
          .publisher(for: UIResponder.keyboardWillHideNotification)
          .map { _ in false })
      .debounce(for: .seconds(0.1), scheduler: RunLoop.main)
      .eraseToAnyPublisher()
  }
}

extension Int {
    func fancy() -> String {
        if self == 0 {
            return "0"
        }
        if self % 10 == 1 {
            return "\(self)st"
        }
        
        if self % 10 == 2 {
            return "\(self)nd"
        }
        
        if self % 10 == 3 {
            return "\(self)rd"
        }
        return "\(self)th"
    }
}

extension UIDevice {
    static var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
