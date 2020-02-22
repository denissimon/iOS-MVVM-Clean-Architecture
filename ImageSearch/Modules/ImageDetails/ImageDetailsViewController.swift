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
    
    var viewModel: ImageDetailsViewModel!
    weak var coordinatorDelegate: ShowDetailsCoordinatorDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setup()
        self.prepareUI()
    }
    
    // Setup "delegations through closures" and bindings for MVVM architecture
    private func setup() {
        viewModel.updatesInData = { [weak self] largeImage in
            self?.imageView.image = largeImage
        }
        
        viewModel.shareImage = { [weak self] imageToShare in
            let activityVC = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
            activityVC.popoverPresentationController?.barButtonItem = self?.navigationItem.leftBarButtonItem
            activityVC.popoverPresentationController?.permittedArrowDirections = .up
            self?.present(activityVC, animated: true, completion: nil)
        }

        viewModel.showToast.didChanged.addSubscriber(target: self, handler: { (self, value) in
            if !value.new.isEmpty {
                self.view.makeToast(value.new, duration: 5.0, position: .bottom)
            }
        })
    }
    
    private func prepareUI() {
        self.title = viewModel.getTitle()
    }
    
    
    // MARK: Actions
    
    @IBAction func onDoneButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onShareButton(_ sender: UIBarButtonItem) {
        viewModel.onShareButton()
    }
}
