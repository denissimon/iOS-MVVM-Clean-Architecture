import UIKit

class CollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
      super.awakeFromNib()
      containerView.layer.masksToBounds = true
    }
}
