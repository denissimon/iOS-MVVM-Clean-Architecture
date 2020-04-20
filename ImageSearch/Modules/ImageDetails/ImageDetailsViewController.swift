//
//  ImageDetailsViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/20/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit
import Toast_Swift

class ImageDetailsViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var shareBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var viewModel: ImageDetailsViewModel!
    weak var coordinatorDelegate: ShowDetailsCoordinatorDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        prepareUI()
        
        viewModel.loadLargeImage()
    }
    
    // Setup event-based delegation and bindings for the MVVM architecture
    private func setup() {
        // Delegation
        viewModel.updateData.addSubscriber(target: self, handler: { (self, largeImage) in
            self.imageView.image = largeImage
        })
            
        viewModel.shareImage.addSubscriber(target: self, handler: { (self, imageToShare) in
            let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = self.navigationItem.leftBarButtonItem
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            self.present(activityVC, animated: true, completion: nil)
        })
        
        viewModel.showToast.addSubscriber(target: self, handler: { (self, text) in
            if !text.isEmpty {
                self.view.makeToast(text, duration: AppConstants.Other.ToastDuration, position: .bottom)
            }
        })
        
        // Bindings
        viewModel.activityIndicatorVisibility.didChanged.addSubscriber(target: self, handler: { (self, value) in
            if value.new {
                self.activityIndicator.startAnimating()
            } else {
                self.activityIndicator.stopAnimating()
            }
        })
    }
    
    private func prepareUI() {
        self.title = viewModel.getTitle()
    }
    
    // MARK: Actions
    
    @IBAction func onDoneButton(_ sender: UIBarButtonItem) {
        self.coordinatorDelegate.hideDetailsScreen(from: self)
    }
    
    @IBAction func onShareButton(_ sender: UIBarButtonItem) {
        viewModel.onShareButton()
    }
}
