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
        viewModel.data.bind(self, queue: .main) { [weak self] bigImage in
            guard let self, let bigImage else { return }
            imageView.image = bigImage.uiImage
        }
        
        viewModel.shareImage.bind(self) { [weak self] imageWrappers in
            guard let self else { return }
            let activityVC = UIActivityViewController(activityItems: imageWrappers.toUIImageArray(), applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = navigationItem.leftBarButtonItem
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            present(activityVC, animated: true, completion: nil)
        }
        
        viewModel.makeToast.bind(self, queue: .main) { [weak self] message in
            guard let self, !message.isEmpty else { return }
            makeToast(message: message)
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { [weak self] value in
            guard let self else { return }
            if value {
                activityIndicator.isHidden = false
                activityIndicator.startAnimating()
            } else {
                activityIndicator.isHidden = true
                activityIndicator.stopAnimating()
            }
        }
    }
    
    private func prepareUI() {
        title = viewModel.getTitle()
        imageTitle.text = viewModel.image.title
    }
    
    // MARK: - Actions
    
    @IBAction func onShareButton(_ sender: UIBarButtonItem) {
        viewModel.onShareButton()
    }
}
