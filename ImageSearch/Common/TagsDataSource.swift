//
//  TagsDataSource.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit

class TagsDataSource: NSObject {
    
    var data = [Tag]()
    
    init(with data: [Tag]) {
        super.init()
        updateData(data)
    }
    
    func updateData(_ data: [Tag]) {
        self.data = data
    }
}

// MARK: UITableViewDataSource

extension TagsDataSource: UITableViewDataSource {
        
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath)

        cell.textLabel?.text = data[indexPath.item].name
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
