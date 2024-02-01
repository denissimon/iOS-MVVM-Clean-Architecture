//
//  HotTagsViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 04/11/2020.
//

import UIKit

struct HotTagsCoordinatorActions {
    let closeHotTags: (UIViewController) -> ()
}

class HotTagsViewController: UIViewController, Storyboarded {
    
    @IBOutlet weak var tableView: UITableView!
    
    var viewModel: HotTagsViewModel!
    
    private var dataSource: TagsDataSource?
    
    private var coordinatorActions: HotTagsCoordinatorActions?
    
    static func instantiate(viewModel: HotTagsViewModel, actions: HotTagsCoordinatorActions) -> HotTagsViewController {
        let vc = Self.instantiate(from: .hotTags)
        vc.viewModel = viewModel
        vc.coordinatorActions = actions
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.getHotTags()
    }
    
    private func setup() {
        dataSource = viewModel.getDataSource()
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        // Bindings
        viewModel.data.bind(self, queue: .main) { [weak self] (data) in
            guard let self = self else { return }
            self.dataSource?.updateData(data)
            self.tableView.reloadData()
        }
        
        viewModel.showToast.bind(self, queue: .main) { [weak self] (text) in
            if !text.isEmpty {
                self?.view.makeToast(text, duration: AppConfiguration.Other.toastDuration, position: .bottom)
            }
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { [weak self] (value) in
            guard let self = self else { return }
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
        coordinatorActions?.closeHotTags(self)
    }
}

// MARK: - UITableViewDelegate

extension HotTagsViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tagName = viewModel.data.value[indexPath.row].name
        let imageQuery = ImageQuery(query: tagName)
        viewModel.didSelect.notify(imageQuery)
        coordinatorActions?.closeHotTags(self)
    }
}

