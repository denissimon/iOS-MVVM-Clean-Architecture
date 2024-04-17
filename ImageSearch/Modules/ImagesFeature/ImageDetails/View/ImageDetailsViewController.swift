import UIKit

class ImageDetailsViewController: UIViewController, Storyboarded, Alertable {
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var shareBarButtonItem: UIBarButtonItem!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var imageTitle: UILabel!
    
    private var viewModel: ImageDetailsViewModel!
    
    static func instantiate(viewModel: ImageDetailsViewModel) -> ImageDetailsViewController {
        let vc = Self.instantiate(from: .imageDetails)
        vc.viewModel = viewModel
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        prepareUI()
        
        viewModel.loadBigImage()
    }
    
    private func setup() {
        // Bindings
        viewModel.data.bind(self, queue: .main) { [weak self] (bigImage) in
            if let bigImage = bigImage {
                self?.imageView.image = bigImage.image
            }
        }
        
        viewModel.shareImage.bind(self) { [weak self] (imageWrapperArray) in
            guard let self = self else { return }
            let activityVC = UIActivityViewController(activityItems: imageWrapperArray.toUIImageArray(), applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            self.present(activityVC, animated: true, completion: nil)
        }
        
        viewModel.showToast.bind(self, queue: .main) { [weak self] (message) in
            guard !message.isEmpty else { return }
            self?.makeToast(message: message)
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { [weak self] (value) in
            guard let self = self else { return }
            if value {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
    private func prepareUI() {
        self.title = viewModel.getTitle()
        imageTitle.text = viewModel.image.title
    }
    
    // MARK: - Actions
    
    @IBAction func onShareButton(_ sender: UIBarButtonItem) {
        viewModel.onShareButton()
    }
}
