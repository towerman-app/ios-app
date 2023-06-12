//
//  ServerModel.swift
//  Towerman
//
//  Created by Noah Azzaria-Byrne on 2023-04-02.
//

import Foundation
import SwiftUI

//private let serverUrl = "https://937e-199-216-105-26.ngrok-free.app"
//private let websocketUrl = "wss://937e-199-216-105-26.ngrok-free.app"

//private let serverUrl = "http://localhost:3001"
//private let websocketUrl = "ws://localhost:3001"

private let serverUrl = "https://towerman.app"
private let websocketUrl = "wss://towerman.app"

class ServerModel: ObservableObject {
    private var teams: TeamsManager? = nil
    private var uploads: UploadManager? = nil
    var photoCache: PhotoCache? = nil
    @Published var isConnected = false
    @Published var errorStack: Array<String> = []
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    func setTeamsManager(manager: TeamsManager) {
        self.teams = manager
    }
    
    func setUploadsManager(manager: UploadManager) {
        self.uploads = manager
    }
    
    func setPhotoCache(cache: PhotoCache) {
        self.photoCache = cache
    }
    
    func sendPing() async {
        while true {
            do {
                if isConnected {
                    try await webSocketTask?.send(.string("{ \"event\": \"ping\" }"))
                }
                
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            }
            catch {
                print("Error on ping... (doesn't matter)")
            }
            
        }
    }
    
    func signIn(email: String, name: String, token: String, onComplete: @escaping (Result<Any?>) -> Void) {
        let data: [String: Any] = [
            "email": email,
            "name": name,
            "token": token
        ]
        
        guard let json = try? JSONSerialization.data(withJSONObject: data) else {
            print("Failed to encode order")
            return
        }
        
        self.request(endpoint: .sign_in, method: .POST, json: json) { data, error in
            if let data = data {
                if let networkResult = try? JSONDecoder().decode(NetworkResponse.self, from: data) {
                    if networkResult.success {
                        onComplete(Result.success())
                    } else {
                        onComplete(Result.error(networkResult.error ?? "Server Error"))
                    }
                } else {
                    print("Invalid response")
                    onComplete(Result.error("Invalid Response"))
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
                onComplete(Result.error("HTTP Request Failed"))
            }
        }
    }
    
    func createTeam(
        token: String,
        name: String,
        members: [Team.Member],
        OAuthRefreshToken: String,
        capturer: Team.Member?,
        onComplete: @escaping (Result<String>) -> Void
    ) {
        var data: [String: Any] = [
            "token": token,
            "name": name,
            "memberEmails": members.map { x in x.email },
            "persisterService": "googleDrive",
            "persisterToken": OAuthRefreshToken
        ]
        
        if let capturer = capturer {
            data["capturer"] = capturer.email
        }
        guard let json = try? JSONSerialization.data(withJSONObject: data) else {
            print("Failed to encode order")
            return
        }
        
        self.request(endpoint: .create_team, method: .POST, json: json) { data, error in
            if let data = data {
                if let networkResult = try? JSONDecoder().decode(NetworkResponse.self, from: data) {
                    if networkResult.success {
                        do {
                            let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String:Any]
                            // Parse JSON data
                            if let teamId = jsonResult?["teamId"] as? String {
                                onComplete(Result.success(teamId))
                                return
                            }
                        } catch {
                            print("Failed to JSON")
                            print(error)
                        }
                        onComplete(Result.error("Invalid JSON"))

                    } else {
                        onComplete(Result.error(networkResult.error ?? "Server Error"))
                    }
                } else {
                    print("Invalid response")
                    onComplete(Result.error("Invalid Response"))
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
                onComplete(Result.error("HTTP Request Failed"))
            }
        }
    }
    
    func getTeams(token: String, onComplete: @escaping (Result<[Team]>) -> Void) {
        self.request(endpoint: .teams, method: .GET, query: ["token": token]) { data, error in
            if let data = data {
                if let networkResult = try? JSONDecoder().decode(NetworkResponse.self, from: data) {
                    if networkResult.success {
                        if let teamsResult = try? JSONDecoder().decode(TeamsResponse.self, from: data) {
                            onComplete(Result.success(teamsResult.teams.map { x in x.toTeam() }))
                        } else {
                            onComplete(Result.error("Failed to Parse JSON"))
                        }

                    } else {
                        onComplete(Result.error(networkResult.error ?? "Server Error"))
                    }
                } else {
                    print("Invalid response")
                    onComplete(Result.error("Invalid Response"))
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
                onComplete(Result.error("HTTP Request Failed"))
            }
        }
    }
    
    func auth(token: String, teamId: String, onComplete: @escaping (Result<String>) -> Void) {
        self.request(endpoint: .auth, method: .GET, query: ["token": token, "teamId": teamId]) { data, error in
            if let data = data {
                if let networkResult = try? JSONDecoder().decode(NetworkResponse.self, from: data) {
                    if networkResult.success {
                        do {
                            let jsonResult = try JSONSerialization.jsonObject(with: data) as? [String:Any]
                            // Parse JSON data
                            if let token = jsonResult?["token"] as? String {
                                onComplete(Result.success(token))
                                return
                            }
                        } catch {
                            print("Failed to JSON")
                            print(error)
                        }
                        onComplete(Result.error("Invalid JSON"))

                    } else {
                        onComplete(Result.error(networkResult.error ?? "Server Error"))
                    }
                } else {
                    print("Invalid response")
                    onComplete(Result.error("Invalid Response"))
                }
            } else if let error = error {
                print("HTTP Request Failed \(error)")
                onComplete(Result.error("HTTP Request Failed"))
            }
        }
    }
    
    private func request(endpoint: Route, method: RequestMethod, json: Data? = nil, query: [String: String]? = nil, onComplete:  @escaping (Data?, Error?) -> Void) {
        var request: URLRequest
        if let query = query {
            var components = URLComponents(string: serverUrl + endpoint.rawValue)!
            components.queryItems = query.map { (key, value) in
                URLQueryItem(name: key, value: value)
            }
            components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
            request = URLRequest(url: components.url!)
        } else {
            request = URLRequest(url: URL(string: serverUrl + endpoint.rawValue)!)
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = method.rawValue
        
        let task: URLSessionTask
        if method == .POST {
            task = URLSession.shared.uploadTask(with: request, from: json) { data, response, error in
                onComplete(data, error)
            }
        } else {
            task = URLSession.shared.dataTask(with: request) { data, response, error in
                onComplete(data, error)
            }
        }
        
        task.resume()
    }
    
    func connect(authToken: String) {
        guard let url = URL(string: websocketUrl + "/?token=" + authToken) else { return }
        let request = URLRequest(url: url)
        webSocketTask = URLSession.shared.webSocketTask(with: request)
        webSocketTask?.resume()
        
        self.receiveMessage()
        
        for i in 0..<5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                if self.isConnected { return }
                self.webSocketTask?.send(.string("{ \"event\": \"ping\" }")) { error in
                    if let error = error {
                        print(error.localizedDescription)
                    } else if !self.isConnected {
                        DispatchQueue.main.async {
                            self.isConnected = true
                        }
                    }
                }
            }
        }
    }
    
    func disconnect() {
        DispatchQueue.main.async {
            self.isConnected = false
            self.webSocketTask?.cancel()
        }
    }
    
    private func receiveMessage() {
        webSocketTask?.receive { result in
            switch result {
            case .failure(let error):
                print(error.localizedDescription)
                self.disconnect()
                return
            case .success(let message):
                switch message {
                case .string(let text):
                    self.handle(text)
                case .data(_):
                    print("DATA")
                    // Handle binary data
                    break
                @unknown default:
                    break
                }
            }
            
            self.receiveMessage()
        }
    }
    
    private func handle(_ string: String) {
        let data = string.data(using: .utf8)!
        guard let json = try? JSONSerialization.jsonObject(with: data, options : .allowFragments) as? Dictionary<String,Any> else {
            print("BAD JSON")
            return
        }
        guard let event = json["event"] as? String else { return }
        let success = json["success"] as? Bool ?? true
        
        print("\(event): \(success)")
        switch event {
        case Event.start_game.rawValue:
            if success {
                teams?.startGame(withName: json["name"] as? String ?? "New game")
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.end_game.rawValue:
            if success {
                teams?.endGame()
                photoCache?.clear()
            } else {
                self.addError(json["error"] as? String)
            }
            
        case Event.rename_team.rawValue:
            if success {
                teams?.rename(to: json["name"] as? String ?? "New name")
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.add_member.rawValue:
            if success {
                guard let name = json["name"] as? String else { return }
                guard let email = json["email"] as? String else { return }
                teams?.add(member: Team.Member(name: name, email: email))
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.remove_member.rawValue:
            if success {
                guard let email = json["email"] as? String else { return }
                teams?.remove(email: email)
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.set_capturer.rawValue:
            if success {
                guard let email = json["email"] as? String else { return }
                teams?.setCapturer(to: email)
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.start_capturing.rawValue:
            if success {
                teams?.setCapturing(to: true)
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.stop_capturing.rawValue:
            teams?.setCapturing(to: false)
            if success {
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.start_viewing.rawValue:
            if success {
                guard let emails = json["emails"] as? Array<String> else { return }
                emails.forEach { email in
                    teams?.setViewing(email: email, to: true)
                }
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.stop_viewing.rawValue:
            if success {
                guard let emails = json["emails"] as? Array<String> else { return }
                emails.forEach { email in
                    teams?.setViewing(email: email, to: false)
                }
            } else {
                self.addError(json["error"] as? String)
            }
            break
            
        case Event.photo.rawValue:
            if success {
                guard let name = json["name"] as? String else { return }
                uploads?.onDone(name: name)
                
                guard let base64 = json["photo"] as? String else { return }
                guard let photoData = Data(base64Encoded: base64) else { return }

                print(name)
                let playPhoto = PlayPhoto.parse(name: name, photo: photoData)
                guard let playPhoto = playPhoto else { return }
                
                photoCache?.add(playPhoto)
            } else {
                guard let name = json["play"] as? String else { return }
                guard let error = json["error"] as? String else { return }
                uploads?.onError(name: name, error: error)
                addError(error)
            }
            
        default:
            print(event)
            break
        }
    }
    
    
    func addError(_ e: String?) {
        DispatchQueue.main.async {
            withAnimation(Animation.linear(duration: 0.2)) {
                self.errorStack.append(e ?? "Server Error")
            }            
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(Animation.linear(duration: 0.2)) {
                let _ = self.errorStack.removeFirst()                
            }
        }
    }
    
    func startGame(name: String) {
        if !isConnected { return }
        let data = SocketEvent(event: Event.start_game.rawValue, data: ["name": name])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func endGame() {
        if !isConnected { return }
        let data = SocketEvent(event: Event.end_game.rawValue, data: [:])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func renameTeam(to name: String) {
        if !isConnected { return }
        let data = SocketEvent(event: Event.rename_team.rawValue, data: ["name": name])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func addMember(member: Team.Member) {
        if !isConnected { return }
        let data = SocketEvent(event: Event.add_member.rawValue, data: ["email": member.email])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func setCapturer(email: String) {
        if !isConnected { return }
        let data = SocketEvent(event: Event.set_capturer.rawValue, data: ["email": email])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func removeMember(email: String) {
        if !isConnected { return }
        let data = SocketEvent(event: Event.remove_member.rawValue, data: ["email": email])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func startCapturing() {
        if !isConnected { return }
        let data = SocketEvent(event: Event.start_capturing.rawValue, data: [:])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func stopCapturing() {
        if !isConnected { return }
        let data = SocketEvent(event: Event.stop_capturing.rawValue, data: [:])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func startViewing() {
        if !isConnected { return }
        let data = SocketEvent(event: Event.start_viewing.rawValue, data: [:])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func stopViewing() {
        if !isConnected { return }
        let data = SocketEvent(event: Event.stop_viewing.rawValue, data: [:])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func requestPhotos() {
        if !isConnected { return }
        guard let photoCache = photoCache else { return }
        
        print("Requesting photos...")
        let data = "[" + photoCache.names.map { x in "\"\(x)\"" }.joined(separator: ", ") + "]"
        var string = "{\"event\": \"\(Event.photo_cache.rawValue)\", "
        string += "\"cached\": \(data)"
        string += "}"
        
        self.webSocketTask?.send(.string(string)) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
    
    func uploadPhoto(play: PlayData, idx: Int, photo: Data) {
        if !isConnected { return }
        
        let name = play.name() + "#\(idx)"
        uploads?.upload(name: name, photo: photo, play: play)
        
        let data = SocketEvent(event: Event.photo.rawValue, data: ["play": name, "photo": photo.base64EncodedString()])
        self.webSocketTask?.send(.string(data.toString())) { error in
            if let error = error {
                print(error.localizedDescription)
                self.isConnected = false
            }
        }
    }
}

struct NetworkResponse: Decodable {
    let success: Bool
    let error: String?
}

struct SocketEvent {
    let event: Event.RawValue
    let data: [String: String]
    
    func toString() -> String {
        var string = "{\"event\": \"\(event)\""
        data.forEach { key, value in
            string += ",\"\(key)\": \"\(value)\""
        }
        string += "}"
        return string
    }
}

private struct TeamsResponse: Decodable {
    let teams: [RemoteTeam]
    
    struct RemoteTeam: Decodable {
        let name: String
        let teamId: String
        let members: [Member]
        let owner: Member
        
        struct Member: Decodable {
            let name: String
            let email: String
            
            func toMember() -> Team.Member {
                return Team.Member(name: name, email: email)
            }
        }
        
        func toTeam() -> Team {
            return Team(name, owner.toMember(), id: teamId, members: members.map { x in x.toMember() })
        }
    }
}

struct Result<T: Any> {
    let success: Bool
    let data: T?
    let error: String?
}

extension Result where T == Any {
    static func success() -> Result<Any?> {
        return Result<Any?>(success: true, data: nil, error: nil)
    }
    
    static func success<T>(_ data: T) -> Result<T> {
        return Result<T>(success: true, data: data, error: nil)
    }
    
    static func error<T>(_ error: String) -> Result<T> {
        return Result<T>(success: false, data: nil, error: error)
    }
}

enum RequestMethod: String, CaseIterable {
    case GET = "GET"
    case POST = "POST"
}

enum Route: String, CaseIterable {
    case sign_in = "/sign-in"
    case auth = "/auth"
    
    case create_team = "/create-team"
    case delete_team = "/delete-team"
    case teams = "/teams"
}

enum Event: String, CaseIterable {
    case connection = "connection"
    
    case start_game = "start_game"
    case end_game = "end_game"
    
    case photo = "photo"
    case photo_cache = "photo_cache"
    
    case add_member = "add_member"
    case remove_member = "remove_member"
    case set_capturer = "set_capturer"
    
    case start_capturing = "start_capturing"
    case stop_capturing = "stop_capturing"
    
    case start_viewing = "start_viewing"
    case stop_viewing = "stop_viewing"
    
    case rename_team = "rename_team"
}

