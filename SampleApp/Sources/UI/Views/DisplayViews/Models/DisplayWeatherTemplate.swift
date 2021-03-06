//
//  DisplayWeatherTemplate.swift
//  SampleApp
//
//  Created by jin kim on 2019/12/13.
//  Copyright © 2019 SK Telecom Co., Ltd. All rights reserved.
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

struct DisplayWeatherTemplate: Decodable {
    let playServiceId: String
    let token: String?
    let duration: DisplayCommonTemplate.Common.Duration?
    let title: DisplayCommonTemplate.Common.Title
    let background: DisplayCommonTemplate.Common.Background?
    let content: Content
    
    struct Content: Decodable {
        let header: DisplayCommonTemplate.Common.Text?
        let image: DisplayCommonTemplate.Common.Image?
        let temperature: Temperature?
        let body: DisplayCommonTemplate.Common.Text?
        let listItems: [Item]?
        
        struct Temperature: Decodable {
            let current: DisplayCommonTemplate.Common.Text?
            let max: DisplayCommonTemplate.Common.Text?
            let min: DisplayCommonTemplate.Common.Text?
        }
        
        struct Item: Decodable {
            let header: DisplayCommonTemplate.Common.Text?
            let image: DisplayCommonTemplate.Common.Image?
            let body: DisplayCommonTemplate.Common.Text?
            let footer: DisplayCommonTemplate.Common.Text?
        }
    }
}
