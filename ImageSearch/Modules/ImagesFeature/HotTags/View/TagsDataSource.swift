import UIKit

class TagsDataSource: NSObject {
    
    private(set) var data = [TagListItemVM]()
    
    init(with data: [TagListItemVM]) {
        super.init()
        self.data = data
    }
    
    func updateData(_ data: [TagListItemVM]) {
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
