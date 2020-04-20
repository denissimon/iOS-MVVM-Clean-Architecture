//
//  HotTagsListViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit
import Toast_Swift

class HotTagsListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: HotTagsListViewModel!
    weak var coordinatorDelegate: HotTagsListCoordinatorDelegate!
    
    private var dataSource: TagsDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel.getDataSource()
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        setup()
        
        // Get a list of hot tags
        viewModel.getFlickrHotTags(of: AppConstants.FlickrAPI.HotTagsListCount)
    }
    
    // Setup event-based delegation and bindings for the MVVM architecture
    private func setup() {
        // Delegation
        viewModel.updateData.addSubscriber(target: self, handler: { (self, _) in
            self.dataSource?.updateData(self.viewModel.getData())
            self.tableView.reloadData()
        })
        
        viewModel.showToast.addSubscriber(target: self, handler: { (self, text) in
            if !text.isEmpty {
                self.view.makeToast(text, duration: AppConstants.Other.ToastDuration, position: .bottom)
            }
        })
        
        // Bindings
        viewModel.activityIndicatorVisibility.didChanged.addSubscriber(target: self, handler: { (self, value) in
            if value.new {
                self.view.makeToastActivity(.center)
            } else {
                self.view.hideToastActivity()
            }
        })
    }
}

// MARK: - UITableViewDelegate

extension HotTagsListViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tagName = viewModel.getTagName(for: indexPath)
        coordinatorDelegate.hideListScreen(tappedTag: tagName, from: self)
    }
}
