//
//  ImagesDataSource.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import UIKit

class ImagesDataSource: NSObject {
    
    var data = [ImageSearchResults]()
    
    init(with data: [ImageSearchResults]) {
        super.init()
        updateData(data)
    }
    
    func updateData(_ data: [ImageSearchResults]) {
        self.data = data
    }
}

// MARK: UICollectionViewDataSource

extension ImagesDataSource: UICollectionViewDataSource {
        
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return data.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return data[section].searchResults.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        let image = data[indexPath.section].searchResults[indexPath.row]
        cell.imageView.image = image.thumbnail?.image
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

