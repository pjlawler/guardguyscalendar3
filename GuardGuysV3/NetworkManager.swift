//
//  NetworkManager.swift
//  GuardGuysV3
//
//  Created by Patrick Lawler on 2/12/25.
//



import SwiftUI

class ApproachDownloader: NSObject {
    
    typealias DownloadCompletionHandler = (Result<URL, Error>)->()
    typealias DownloadProgressHandler = (Double)->()
    
    private var progressHandler: DownloadProgressHandler?
    private var completionHandler: DownloadCompletionHandler?
    private var dataTask: URLSessionDownloadTask?
    private var observation: NSKeyValueObservation?
    private var defaultError: NSError = .init(domain: "DownloadError",
                                              code: 0,
                                              userInfo: [NSLocalizedDescriptionKey: "Error downloading the file!"])
    private var temporaryFileURL: URL?
    
    let fileManager = FileManager.default
    
    func downloadFile(fromURL url: URL, withProgress progress: DownloadProgressHandler?, fileLocation completion: DownloadCompletionHandler?) {
        
        self.progressHandler = progress
        self.completionHandler = completion
        self.temporaryFileURL = nil
        
        self.dataTask = URLSession.shared.downloadTask(with: url, completionHandler: { location, response, error in
            
            self.observation?.invalidate()
            guard let location = location else {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.completionHandler?(.failure(error ?? self.defaultError))
                }
                return
            }
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.temporaryFileURL = location
                self.completionHandler?(.success(location))
            }
        })
        
        dataTask?.resume()
        observation = dataTask?.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                let progress = Double(Int(progress.fractionCompleted * 1000)) / 10
                self.progressHandler?(progress)
            }
        }
    }
    func cancelDownload() {
        self.dataTask?.cancel()
        self.dataTask = nil
        self.observation?.invalidate()
    }
    func saveTempFileAs(filename name: String) throws -> URL? {
        do {
            guard let tempURL = temporaryFileURL else { throw NSError(domain: "FileManagerError", code: 1, userInfo: nil) }
            let path = try fileManager.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            let destURL = path.appendingPathComponent(name)
            if fileManager.fileExists(atPath: destURL.path) { try fileManager.removeItem(at: destURL) }
            try fileManager.moveItem(at: tempURL, to: destURL)
            return destURL
        }
        catch {
            throw error
        }
    }
    func convertToData() throws -> Data? {
        do {
            guard let tempURL = temporaryFileURL else { throw NSError(domain: "FileManagerError", code: 1, userInfo: nil) }
            let data = try Data(contentsOf: tempURL)
            try fileManager.removeItem(at: tempURL)
            return data
        }
        catch {
            throw error
        }
    }
}

extension ApproachDownloader: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async { self.progressHandler?(progress) }
    }
    func urlSession(_ session: URLSession,
                    downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async { self.completionHandler?(.success(location)) }
    }
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        guard let error = error else { return }
        DispatchQueue.main.async { self.completionHandler?(.failure(error)) }
    }
}


class NetworkManager: NSObject {
    
    @AppStorage("loggedInState") var isLoggedIn = false
    @AppStorage("loggedInUsername") var username = ""
    @AppStorage("loggedInUserId") var userId = 0
    @AppStorage("loggedInAsAdmin") var isAdmin = false
    @AppStorage("lastEventDownload") var lastDate = ""
    
    static let shared = NetworkManager()
    
    private override init() {}
    
    private func urlParameters(params: [String:Any]?) -> String {
        guard params != nil && params!.count > 0 else { return "" }
        var stringParameters = "?"
        for (key, value) in params! { stringParameters += String("\(key)=\(value)&")}
        let final = stringParameters.dropLast()
        return String(final)
    }
    private func bodyParameters(params: [String:Any]?) -> Data? {
        guard params != nil && params!.count > 0 else { return nil }
        do {
            let data = try JSONSerialization.data(withJSONObject: params!, options: .prettyPrinted)
            print(String(data: data, encoding: .utf8)!)
            return data
        }
        catch { return nil }
    }
    
    func makeApiRequestFor(_ requestInfo: RequestType, completion: @escaping (Result<Data, Error>) -> Void) {
        Task {
            do {
                let data = try await makeApiRequestFor(requestInfo)
                DispatchQueue.main.async {
                    completion(.success(data))
                }
            }
            catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    func makeApiRequestFor(_ requestInfo: RequestType) async throws -> Data {
        
        // updates where the parameters are stored
        let urlParams = requestInfo.paramType == "body" ? "" : urlParameters(params: requestInfo.parameters)
        let bodyParams = requestInfo.paramType == "body" ? bodyParameters(params: requestInfo.parameters) : nil
        
        guard let url = URL(string: "\(requestInfo.baseURL)\(requestInfo.path)\(urlParams)") else { throw NetworkErrors.invalidUrl }
        
        // creates the api request
        var request = URLRequest(url: url)
        request.httpMethod = requestInfo.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = bodyParams
        
        do {
            
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let responseData = response as? HTTPURLResponse else { throw NetworkErrors.unknownError }
            switch responseData.statusCode {
            case 200...299: return data
            default:
                let dictionary  = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String : AnyObject]
                let jsonData    = try JSONSerialization.data(withJSONObject: dictionary as Any)
                let error       = try JSONDecoder().decode(ErrorResponse.self, from: jsonData)
                throw NSError(domain: "NetworkError",
                              code: 0,
                              userInfo: [NSLocalizedDescriptionKey: error.errors?[0].message ?? "Unknown error"])
            }
        }
        catch {
            throw NSError(domain: "NetworkError",
                          code: 1,
                          userInfo: [NSLocalizedDescriptionKey: error.localizedDescription])
        }
    }
    
}

public enum RequestType: RequestTypeProtocol {
    
    case getMembers
    case addMember(data: UserData)
    case editMember(id: Int, data: UserData)
    case deleteMember(id: Int)
    case login(email: String, password: String)
    case getEvents(date: Date)
    case addEvent(data: SubmitEvent)
    case editEvent(id: Int, data: SubmitEvent)
    case deleteEvent(id: Int)
    case largeFileTest
    
    public var baseURL: URL {
        switch self {
        case .getMembers, .addMember, .editMember, .deleteMember, .login, .getEvents, .addEvent, .editEvent, .deleteEvent:
            return URL(string: "https://guardguys.herokuapp.com")!
        case .largeFileTest:
            return URL(string: "https://files.testfile.org/PDF/200MB-TESTFILE.ORG.pdf")!
        }
        
        
    }
    
    public var path: String {
        switch self {
            
        case .login(_, _):
            return "/api/users/login"
            
        case .getMembers, .addMember:
            return "/api/users/"
            
        case let .editMember(id, _):
            return "/api/users/\(id)"
            
        case let .deleteMember(id):
            return "/api/users/\(id)"
            
        case let .getEvents(date):
            return "/api/events/weekof/\(date.toString())"
            
        case .addEvent:
            return "/api/events/"
            
        case let .editEvent(id, _):
            return "/api/events/\(id)"
            
        case let .deleteEvent(id):
            return "/api/events/\(id)"
        case .largeFileTest:
            return "/PDF/200MB-TESTFILE.ORG.pdf"
        }
    }
    public var method: MethodTypes {
        switch self {
        case .getMembers, .getEvents:
            return .get
        case .addMember, .login, .addEvent:
            return .post
        case .editMember, .editEvent:
            return .put
        case .deleteMember, .deleteEvent:
            return .delete
        case .largeFileTest:
            return .get
        }
    }
    public var parameters: [String : Any]? {
        
        switch self {
        case .largeFileTest: return nil
        case .getMembers, .deleteMember, .getEvents, .deleteEvent: return nil
            
        case let .login(email, password):
            var dict: [String:Any] = [:]
            dict["email"] = email
            dict["password"] = password
            return dict
            
        case let .addMember(data):
            var dict: [String:Any] = [:]
            if data.username != nil { dict["username"] = data.username }
            if data.email != nil { dict["email"] = data.email }
            if data.password != nil || data.password == "" { dict["password"] = data.password }
            if data.isAdmin != nil { dict["isAdmin"] = data.isAdmin }
            return dict
            
            
        case let .editMember( _, data):
            var dict: [String:Any] = [:]
            if data.username != nil { dict["username"] = data.username }
            if data.email != nil { dict["email"] = data.email }
            if data.password != nil && data.password != "" { dict["password"] = data.password }
            if data.isAdmin != nil { dict["isAdmin"] = data.isAdmin }
            return dict
            
        case let .editEvent(_, data):
            var dict: [String:Any?] = [:]
            if data.date != nil { dict["date"] = data.date }
            if data.event != nil { dict["event"] = data.event }
            if data.onsite != nil { dict["onsite"] = data.onsite }
            if data.notes != nil { dict["notes"] = data.notes }
            if data.duration != nil { dict["duration"] =  data.duration }
            if data.userId != nil {
                dict["user_id"] = data.userId == -1 ? nil as Any? : data.userId }
            return dict as [String : Any]
            
        case let .addEvent(data):
            var dict: [String:Any?] = [:]
            if data.date != nil { dict["date"] = data.date }
            if data.event != nil { dict["event"] = data.event }
            if data.onsite != nil { dict["onsite"] = data.onsite }
            if data.notes != nil { dict["notes"] = data.notes }
            if data.duration != nil { dict["duration"] =  data.duration }
            if data.userId != nil { dict["user_id"] = data.userId == -1 ? nil as Any? : data.userId }
            return dict as [String : Any]
            
        }
        
        
    }
    public var paramType: String {
        switch self {
        case .addMember, .editMember, .login, .addEvent, .editEvent:
            return "body"
        default: return "url"
        }
    }
    
    
}

public protocol RequestTypeProtocol {
    var baseURL: URL { get }
    var path: String { get }
    var method: MethodTypes { get }
    var paramType: String { get }
}

public enum MethodTypes: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public struct LoginResult: Codable {
    let user: UserData?
    let message: String?
}

enum NetworkErrors: String, Error {
    case emailValidation = "Unable able to validate email format. Please try again."
    case usernameValidation = "The user name must be at least 3 letters!"
    case passwordValidation = "The password must be at least 3 letters!"
    case jsonEncoder = "Unable to encode json"
    case jsonDecoder = "The system is unable to decode the received json"
    case invalidUrl = "The url is invalid"
    case networkFailure = "Unable to get a valid return from the server"
    case invalidResponse = "The response was invalid"
    case notInstructor = "This user is not an instructor"
    case unauthorized = "The user is no longer authrorized"
    case pdfConversion = "Unable to convert the data to pdf"
    case unknownError = "This operation caused an unknown error, please try again."
}

struct ErrorResponse: Codable {
    let name: String
    let errors: [ErrorData]?
}

struct ErrorData: Codable {
    let message: String?
    let type: String?
    let path: String?
    let value: String?
    let origin: String?
}


public struct SubmitEvent {
    let event: String?
    let date: String?
    let duration: Int64?
    let onsite: Bool?
    let userId: Int?
    let notes: String?
}

class DataDownloader {
    
    
    typealias completionClosure = ((Bool) ->Void)
    typealias progressClosure = ((Double)->Void)
    
    var handleDownloadedData: completionClosure!
    var handleDownloadedProgressPercent: progressClosure!
    
    var downloadProgress: Double = 0 {
        didSet { handleDownloadedProgressPercent(downloadProgress) }
    }
    var downloadComplete: Bool? {
        didSet { handleDownloadedData(downloadComplete ?? false) }
    }
    
    var dataTask: URLSessionDownloadTask?
    var observation: NSKeyValueObservation?
    
    func cancelDownload() {
        self.observation?.invalidate()
        self.dataTask?.cancel()
        self.dataTask = nil
    }
    
    //    func deleteDownload(_ resource: ResourcePublicationModel) {
    //        ResourceDataManager.shared.deleteResourceItem(uuid: resource.id) { _ in
    //            print("deleted")
    //        }
    //    }
    
    func storeResourceToCoreData(downloadUrl: URL, progress: @escaping (Double)->(), success: @escaping (Bool)->()) {
        
        self.handleDownloadedData = success
        self.handleDownloadedProgressPercent = progress
        
        dataTask = URLSession.shared.downloadTask(with: downloadUrl) { location, _, error in
            
            self.observation?.invalidate()
            
            guard let location = location, error == nil else {
                self.downloadComplete = false
                return
            }
            
            //            DispatchQueue.main.async {
            //                let item = self.item.storeItem
            //                ApproachFileSystemManager.shared.moveDownloadedFileTo(uuid: item.id, currentLocation: location)
            //                ResourceDataManager.shared.storeResourceItem(item: item) { error in
            //                    self.downloadComplete = true
            //                }
            //            }
        }
        dataTask?.resume()
        
        observation = dataTask?.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async { [self] in
                self.downloadProgress = progress.fractionCompleted
            }
        }
        
    }
    
}


