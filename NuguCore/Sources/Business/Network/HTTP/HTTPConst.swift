//
//  HTTPConst.swift
//  NuguCore
//
//  Created by DCs-OfficeMBP on 04/07/2019.
//  Copyright (c) 2019 SK Telecom Co., Ltd. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// HTTP method definitions.
///
/// See https://tools.ietf.org/html/rfc7231#section-4.3
public enum HTTPMethod: String {
    case options = "OPTIONS"
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case trace   = "TRACE"
    case connect = "CONNECT"
}

public enum HTTPStatusCode: Int {
    case ok = 200
    case badRequest = 400
    case unauthorized = 401
    case forbidden = 403
    case notFound = 404
    case serverError = 500
}

public enum HTTPConst {
    public static let boundary = "this-is-a-boundary"
    public static let carriageReturn = "\r".data(using: .utf8)![0]
    public static let LineFeed = "\n".data(using: .utf8)![0]
    public static let colon = ":".data(using: .utf8)![0]
}
