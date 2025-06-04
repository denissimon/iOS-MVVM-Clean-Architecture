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
        viewModel.data.bind(self) { [weak self] bigImage in
            guard let bigImage else { return }
            Task { @MainActor in
                self?.imageView.image = bigImage.uiImage
            }
        }
        
        viewModel.shareImage.bind(self) { [weak self] imageWrappers in
            Task { @MainActor in
                guard let self else { return }
                let activityVC = UIActivityViewController(activityItems: imageWrappers.toUIImageArray(), applicationActivities: nil)
                activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
                activityVC.popoverPresentationController?.permittedArrowDirections = .up
                self.present(activityVC, animated: true, completion: nil)
            }
        }
        
        viewModel.makeToast.bind(self) { [weak self] message in
            guard !message.isEmpty else { return }
            Task { @MainActor in
                self?.makeToast(message: message)
            }
        }
        
        viewModel.activityIndicatorVisibility.bind(self) { [weak self] value in
            Task { @MainActor in
                guard let self else { return }
                if value {
                    self.activityIndicator.isHidden = false
                    self.activityIndicator.startAnimating()
                } else {
                    self.activityIndicator.isHidden = true
                    self.activityIndicator.stopAnimating()
                }
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
