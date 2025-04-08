import UIKit

class ImagesDataSource: NSObject {
    
    private(set) var data = [ImageSearchResultsListItemVM]()
    
    init(with data: [ImageSearchResultsListItemVM]) {
        super.init()
        self.data = data
    }
    
    func updateData(_ data: [ImageSearchResultsListItemVM]) {
        self.data = data
    }
}

// MARK: UICollectionViewDataSource

extension ImagesDataSource: UICollectionViewDataSource {
        
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].searchResults_.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        let image = data[indexPath.section].searchResults_[indexPath.row]
        cell.imageView.image = image.thumbnail?.uiImage
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            if let headerView =  collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "CollectionViewHeader", for: indexPath) as? CollectionViewHeader {
                let searchQuery = data[indexPath.section].searchQuery.query
                headerView.label.text = searchQuery
                return headerView
            }
        }

        return UICollectionReusableView()
    }
}

