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
        
        setup()
        
        // Get a list of hot tags
        viewModel.getFlickrHotTags(of: Constants.FlickrAPI.HotTagsListCount)
    }
    
    private func setup() {
        dataSource = viewModel.getDataSource()
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        // Delegates
        viewModel.updateData.addSubscriber(target: self, handler: { (self, data) in
            self.dataSource?.updateData(data)
            self.tableView.reloadData()
        })
        
        viewModel.showToast.addSubscriber(target: self, handler: { (self, text) in
            if !text.isEmpty {
                self.view.makeToast(text, duration: Constants.Other.ToastDuration, position: .bottom)
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
    
    // MARK: - Actions
    
    @IBAction func onTagsTypeChange(_ sender: UISegmentedControl) {
        viewModel.onTagsTypeChange(sender.selectedSegmentIndex)
    }
}

// MARK: - UITableViewDelegate

extension HotTagsListViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tagName = viewModel.getTagName(for: indexPath)
        coordinatorDelegate.hideListScreen(tappedTag: tagName, from: self)
    }
}

