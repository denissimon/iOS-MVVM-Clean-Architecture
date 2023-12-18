//
//  HotTagsListViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2020.
//

import UIKit

struct HotTagsListCoordinatorActions {
    let closeHotTagsList: (UIViewController) -> ()
}

class HotTagsListViewController: UIViewController, Storyboarded {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: HotTagsListViewModel!
    
    private var dataSource: TagsDataSource?
    
    private var coordinatorActions: HotTagsListCoordinatorActions?
    
    static func instantiate(viewModel: HotTagsListViewModel, actions: HotTagsListCoordinatorActions) -> HotTagsListViewController {
        let vc = Self.instantiate(from: .hotTagsList)
        vc.viewModel = viewModel
        vc.coordinatorActions = actions
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.getFlickrHotTags()
    }
    
    private func setup() {
        dataSource = viewModel.getDataSource()
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        // Bindings
        viewModel.data.bind(self, queue: .main) { (data) in
            self.dataSource?.updateData(data)
            self.tableView.reloadData()
        }
        
        viewModel.showToast.bind(self, queue: .main) { (text) in
            if !text.isEmpty {
                self.view.makeToast(text, duration: Constants.Other.toastDuration, position: .bottom)
            }
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { (value) in
            if value {
                self.view.makeToastActivity(.center)
            } else {
                self.view.hideToastActivity()
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onSelectedSegmentChange(_ sender: UISegmentedControl) {
        viewModel.onSelectedSegmentChange(sender.selectedSegmentIndex)
    }
    
    @IBAction func onDoneButton(_ sender: Any) {
        coordinatorActions?.closeHotTagsList(self)
    }
}

// MARK: - UITableViewDelegate

extension HotTagsListViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tagName = viewModel.data.value[indexPath.row].name
        viewModel.didSelect.trigger(ImageQuery(query: tagName))
        coordinatorActions?.closeHotTagsList(self)
    }
}

