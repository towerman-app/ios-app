//
//  Team.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-03-03.
//

import Foundation

struct Team: Identifiable {
    init(_ name: String, _ owner: Team.Member, id: String = UUID().uuidString, members: [Member] = []) {
        self.name = name
        self.id = id
        self.members = members
        self.owner = owner.email
        self.game = nil
//        self.members.append(owner)
    }
    var name: String
    var id: String
    var members: [Member]
    let owner: String
    var game: Game?
    
    struct Member: Identifiable {
        init(name: String, email: String? = nil, isCapturer: Bool = false) {
            self._name = name
            self.email = email ?? name.replacingOccurrences(of: " ", with: "").lowercased() + "@example.com"
            self.isCapturer = isCapturer
        }
        let _name: String?
        let email: String
        var isViewing: Bool = false
        var isCapturer: Bool = false
        var isCapturing: Bool = false
        var id: String { email }
        
        func name() -> String {
            return (_name != nil) ? _name! : "Member"
        }
    }
}
