import UIKit

struct HotTagsCoordinatorActions {
    let closeHotTags: (UIViewController) -> ()
}

class HotTagsViewController: UIViewController, Storyboarded, Alertable {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var viewModel: HotTagsViewModel!
    
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
        prepareUI()
        viewModel.getHotTags()
    }
    
    private func setup() {
        dataSource = viewModel.getDataSource()
        tableView.dataSource = dataSource
        tableView.delegate = self
        
        // Bindings
        viewModel.data.bind(self, queue: .main) { [weak self] data in
            guard let self = self else { return }
            self.dataSource?.updateData(data)
            self.tableView.reloadData()
        }
        
        viewModel.makeToast.bind(self, queue: .main) { [weak self] message in
            guard !message.isEmpty else { return }
            self?.makeToast(message: message)
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { [weak self] value in
            guard let self = self else { return }
            if value {
                self.makeToastActivity()
            } else {
                self.hideToastActivity()
            }
        }
    }
    
    private func prepareUI() {
        title = viewModel.screenTitle
        segmentedControl.setTitle(NSLocalizedString("Week", comment: ""), forSegmentAt: 0)
        segmentedControl.setTitle(NSLocalizedString("All Times", comment: ""), forSegmentAt: 1)
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

