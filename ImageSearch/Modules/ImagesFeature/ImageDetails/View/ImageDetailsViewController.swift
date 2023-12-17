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
    //weak var coordinatorDelegate: ShowDetailsCoordinatorDelegate!
    
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
        // Delegates
        viewModel.updateData.subscribe(self) { (largeImage) in
            self.imageView.image = largeImage.image
        }
            
        viewModel.shareImage.subscribe(self) { (imageWrapperArray) in
            let activityVC = UIActivityViewController(activityItems: imageWrapperArray.toUIImageArray(), applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            self.present(activityVC, animated: true, completion: nil)
        }
        
        viewModel.showToast.subscribe(self) { (text) in
            if !text.isEmpty {
                self.view.makeToast(text, duration: Constants.Other.toastDuration, position: .bottom)
            }
        }
        
        // Bindings
        viewModel.activityIndicatorVisibility.bind(self) { (value) in
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
