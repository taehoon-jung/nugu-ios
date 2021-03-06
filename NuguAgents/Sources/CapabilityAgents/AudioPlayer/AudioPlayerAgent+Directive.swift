//
//  AudioPlayerAgent+Directive.swift
//  NuguAgents
//
//  Created by yonghoonKwon on 24/04/2019.
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

// MARK: - CapabilityDirectiveAgentable

extension AudioPlayerAgent {
    public enum DirectiveTypeInfo: CaseIterable {
        case play
        case stop
        case pause
    }
}

// MARK: - DirectiveTypeInforable

extension AudioPlayerAgent.DirectiveTypeInfo: DirectiveTypeInforable {
    public var namespace: String { "AudioPlayer" }
    
    public var name: String {
        switch self {
        case .play: return "Play"
        case .stop: return "Stop"
        case .pause: return "Pause"
        }
    }
    
    public var medium: DirectiveMedium {
        switch self {
        case .play: return .audio
        case .stop: return .audio
        case .pause: return .audio
        }
    }

    public var isBlocking: Bool {
        switch self {
        case .play: return false
        case .stop: return false
        case .pause: return false
        }
    }
}
