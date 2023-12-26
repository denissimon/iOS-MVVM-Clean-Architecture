//
//  ImageDetailsViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//

import UIKit

class ImageDetailsViewController: UIViewController, Storyboarded {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var viewModel: ImageDetailsViewModel!
    
    static func instantiate(viewModel: ImageDetailsViewModel) -> ImageDetailsViewController {
        let vc = Self.instantiate(from: .imageDetails)
        vc.viewModel = viewModel
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        prepareUI()
        
        viewModel.loadLargeImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
       self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .plain, target: nil, action: nil)
    }
    
    private func setup() {
        // Bindings
        viewModel.data.bind(self, queue: .main) { [weak self] (largeImage) in
            if let largeImage = largeImage {
                self?.imageView.image = largeImage.image
            }
        }
        
        viewModel.shareImage.bind(self) { [weak self] (imageWrapperArray) in
            guard let self = self else { return }
            let activityVC = UIActivityViewController(activityItems: imageWrapperArray.toUIImageArray(), applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            self.present(activityVC, animated: true, completion: nil)
        }
        
        viewModel.showToast.bind(self, queue: .main) { [weak self] (text) in
            if !text.isEmpty {
                self?.view.makeToast(text, duration: AppConfiguration.Other.toastDuration, position: .bottom)
            }
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
    }
    
    // MARK: Actions
    
    @IBAction func onShareButton(_ sender: UIBarButtonItem) {
        viewModel.onShareButton()
    }
}
