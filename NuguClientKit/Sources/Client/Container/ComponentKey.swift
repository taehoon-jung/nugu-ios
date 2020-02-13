//
//  ComponentKey.swift
//  NuguClientKit
//
//  Created by childc on 2020/01/09.
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

public struct ComponentKey {
    public enum Option {
        case all
        case representative
    }
    
    public var protocolType: Any.Type
    public var concreateType: Any.Type?
    public var option: Option
}

extension ComponentKey: Hashable {
    public static func == (lhs: ComponentKey, rhs: ComponentKey) -> Bool {
        return lhs.protocolType == rhs.protocolType
    }
    
    public func hash(into hasher: inout Hasher) {
        ObjectIdentifier(protocolType).hash(into: &hasher)
        
        // If multiple concreate class conform to protocol and All of them need to be registered, we can distinguish using concreate type and representative name both.
        if option == .all, concreateType != nil {
            ObjectIdentifier(concreateType!).hash(into: &hasher)
        }
    }
}