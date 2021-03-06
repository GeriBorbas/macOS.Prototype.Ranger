//
//  ParameterStatusResponse.swift
//  PostgresClientKit
//
//  Copyright 2019 David Pitfield and the PostgresClientKit contributors
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

internal class ParameterStatusResponse: Response {
    
    override internal init(responseBody: Connection.ResponseBody) throws {
        
        assert(responseBody.responseType == "S")
        
        name = try responseBody.readUTF8String()
        value = try responseBody.readUTF8String()

        try super.init(responseBody: responseBody)
    }
    
    internal let name: String
    internal let value: String
    
    
    //
    // MARK: CustomStringConvertible
    //
    
    override internal var description: String {
        return super.description + "(name: \(name), value: \(value))"
    }
}

// EOF
