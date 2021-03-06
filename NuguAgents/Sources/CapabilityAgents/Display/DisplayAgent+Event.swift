//
//  DisplayAgent+Event.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 10/06/2019.
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

import NuguCore

// MARK: - CapabilityEventAgentable

extension DisplayAgent {
    public struct Event {
        let playServiceId: String
        let typeInfo: TypeInfo
        
        public enum TypeInfo {
            case elementSelected(token: String)
            case closeSucceeded
            case closeFailed
        }
    }
}

// MARK: - Eventable

extension DisplayAgent.Event: Eventable {
    public var payload: [String: Any] {
        var payload: [String: Any] = [
            "playServiceId": playServiceId
        ]
        switch typeInfo {
        case .elementSelected(let token):
            payload["token"] = token
        default:
            break
        }
        return payload
    }
    
    public var name: String {
        switch typeInfo {
        case .elementSelected:
            return "ElementSelected"
        case .closeSucceeded:
            return "CloseSucceeded"
        case .closeFailed:
            return "CloseFailed"
        }
    }
}

// MARK: - Equatable

extension DisplayAgent.Event.TypeInfo: Equatable {}
extension DisplayAgent.Event: Equatable {}
