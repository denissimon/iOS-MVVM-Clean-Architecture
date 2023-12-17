//
//  CollectionViewCell.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import UIKit

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
      super.awakeFromNib()
      containerView.layer.masksToBounds = true
    }
}
