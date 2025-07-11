import UIKit

class TagsDataSource: NSObject {
    
    private(set) var data = [TagVM]()
    
    init(with data: [TagVM]) {
        super.init()
        self.data = data
    }
    
    func update(_ data: [TagVM]) {
        self.data = data
    }
}

// MARK: UITableViewDataSource

extension TagsDataSource: UITableViewDataSource {
        
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath)
        cell.textLabel?.text = data[indexPath.item].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        false
    }
}
