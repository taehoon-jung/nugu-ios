//
//  DisplayBodyListView.swift
//  SampleApp
//
//  Created by jin kim on 2019/11/06.
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

import UIKit

final class DisplayBodyListView: DisplayView {
    
    @IBOutlet private weak var tableView: UITableView!
        
    override var displayPayload: String? {
        didSet {
            guard let payloadData = displayPayload?.data(using: .utf8),
                let displayItem = try? JSONDecoder().decode(DisplayBodyListTemplate.self, from: payloadData) else { return }
            
            titleLabel.text = displayItem.title.text.text
            titleLabel.textColor = UIColor.textColor(rgbHexString: displayItem.title.text.color)
            backgroundColor = UIColor.backgroundColor(rgbHexString: displayItem.background?.color)
            if let logoUrl = displayItem.title.logo.sources.first?.url {
                logoImageView.loadImage(from: logoUrl)
                logoImageView.isHidden = false
            } else {
                logoImageView.isHidden = true
            }
            
            templateBodyListItems = displayItem.listItems
            tableView.reloadData()
        }
    }
    
    private var templateBodyListItems: [DisplayBodyListTemplate.Item]?
    
    override func loadFromXib() {
        // swiftlint:disable force_cast
        let view = Bundle.main.loadNibNamed("DisplayListView", owner: self)?.first as! UIView
        // swiftlint:enable force_cast
        view.frame = bounds
        addSubview(view)
        addBorderToTitleContainerView()
        tableView.backgroundColor = UIColor(named: "BackgroundColor")
        tableView.register(UINib(nibName: "DisplayBodyListViewCell", bundle: nil), forCellReuseIdentifier: "DisplayBodyListViewCell")
    }
}

extension DisplayBodyListView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return templateBodyListItems?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // swiftlint:disable force_cast
        let displayBodyListViewCell = tableView.dequeueReusableCell(withIdentifier: "DisplayBodyListViewCell") as! DisplayBodyListViewCell
        // swiftlint:enable force_cast
        displayBodyListViewCell.configure(index: String(indexPath.row + 1), item: templateBodyListItems?[indexPath.row])
        return displayBodyListViewCell
    }
}

extension DisplayBodyListView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        onItemSelect?(templateBodyListItems?[indexPath.row].token)
    }
}
