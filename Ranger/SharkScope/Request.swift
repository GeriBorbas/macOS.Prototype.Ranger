//
//  Images+Remote.swift
//  Cast
//
//  Created by Geri Borbás on 2019. 02. 26..
//  Copyright © 2019. Geri Borbás. All rights reserved.
//

import Foundation


enum RequestError: Error
{
    case urlCreationError
    case endpointNotExist
    case apiError(_: Error)
    case responseError
    case noData
    case noStringData
    case jsonSerializationError(_: Error)
    case jsonDecodingError(_: Error)
    case noJSONData
}


class Request
{
    
    
    static var log: Bool = false
    
    
    public func fetch(path: String,
                      parameters: [String: String],
                      completion: @escaping (Result<Response, RequestError>) -> Void)
    {
        // Lookup cache first.
        let cache = Cache()
        if let cachedResponse = cache.cachedResponse(for: path, parameters: parameters)
        {
            print("Found JSON cache, skip request.")
            
            return completion(.success(cachedResponse))
        }
        
        // Create URL Components.
        var urlComponents = URLComponents()
            urlComponents.scheme = "https"
            urlComponents.host = "sharkscope.com"
            urlComponents.path = "/api/searcher/" + path
            urlComponents.queryItems = parameters.map { eachElement in URLQueryItem(name: eachElement.key, value: eachElement.value) }
        
        // Create URL.
        guard let url: URL = urlComponents.url
        else { return completion(.failure(RequestError.urlCreationError)) }
        
        // Request.
        var request = URLRequest(url: url)
            request.httpMethod = "GET"
        
        // Load configuration.
        let configuration = SharkScope.Configuration.load()
        
        // Headers.
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(configuration.Username, forHTTPHeaderField: "Username")
        request.setValue(configuration.Password, forHTTPHeaderField: "Password")
        request.setValue(configuration.UserAgent, forHTTPHeaderField: "User-Agent")
        
        // Create task.
        let task = URLSession.shared.dataTask(with: request)
        {
            data, response, error -> Void in
            
            // Only without error.
            if let error = error
            { return completion(.failure(RequestError.apiError(error))) }
                
            // Only having response.
            guard let response = response as? HTTPURLResponse
            else { return completion(.failure(RequestError.responseError)) }
                
            // Only having data.
            guard let data = data
            else { return completion(.failure(RequestError.noData)) }
                
            // Only with string data.
            guard let dataString = String(data: data, encoding: .utf8)
            else { return completion(.failure(RequestError.noStringData)) }
                        
            // JSON.
            var JSON: Dictionary<String, AnyObject> = [:]
            do { JSON = try JSONSerialization.jsonObject(with: data) as! Dictionary<String, AnyObject> }
            catch { return completion(.failure(RequestError.jsonSerializationError(error))) }
            
            // Log.
            if (Request.log)
            {
                print("statusCode: \(response.statusCode)")
                print("dataString: \(dataString)")
                print("JSON: \(JSON)")
            }

            // Cache.
            if let cacheFileURL = cache.cacheFileURL(for: path, parameters: parameters)
            {
                // Create pretty JSON.
                var _JSONdata: Data?
                do { _JSONdata = try JSONSerialization.data(withJSONObject: JSON, options: [.prettyPrinted]) }
                catch { print("Could not serialize JSON. \(error)") }
                
                // Create String (if any JSON).
                let JSONdata = _JSONdata ?? Data()
                let JSONstring = String(data: JSONdata, encoding: String.Encoding.utf8)!
                
                // Save.
                do { try JSONstring.write(to: cacheFileURL, atomically: true, encoding: String.Encoding.utf8) }
                catch { print("Could not cahce file. \(error)") }
            }
            
            // Decode.
            var _decodedResponse: Response?
            do { _decodedResponse = try JSONDecoder().decode(Response.self, from: data) }
            catch { return completion(.failure(RequestError.jsonDecodingError(error))) }
            
            // Only with JSON data.
            guard let decodedResponse = _decodedResponse
            else { return completion(.failure(RequestError.noJSONData)) }
            
            // Return on the main thread.
            DispatchQueue.main.async()
            { completion(.success(decodedResponse)) }
        }

        task.resume()
    }
}


// MARK: - Shortcuts

extension Request
{
    
    
    public func fetch(completion: @escaping (Result<Response, RequestError>) -> Void)
    {
        // "metadata" // 3.1.1. METADATA
        // 3.6.1. (!!!)
        // 3.3.1.
        fetch(path: "networks/pokerstars/players/Borbas.Geri", completion: completion)
    }
    
    public func fetch(path: String,
                      completion: @escaping (Result<Response, RequestError>) -> Void)
    {
        fetch(path: path, parameters: [:], completion: completion) // "hash": "aef83e3d1f034d04321d61099076ef00"
    }
}
