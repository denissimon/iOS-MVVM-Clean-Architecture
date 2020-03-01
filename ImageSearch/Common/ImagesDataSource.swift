//
//  ImagesDataSource.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AppConstants.ImageCollection.reuseCellIdentifier, for: indexPath) as! CollectionViewCell
        let image = data[indexPath.section].searchResults[indexPath.row]
        cell.imageView.image = image.thumbnail
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            if let headerView =  collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: AppConstants.ImageCollection.reuseHeaderIdentifier, for: indexPath) as? CollectionViewHeader {
                let searchString = data[indexPath.section].searchString
                headerView.label.text = searchString
                return headerView
            }
        }

        return UICollectionReusableView()
    }
}

