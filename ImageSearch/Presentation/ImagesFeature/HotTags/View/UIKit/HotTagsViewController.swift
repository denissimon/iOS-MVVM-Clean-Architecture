import UIKit

class HotTagsViewController: UIViewController, Storyboarded, Alertable {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    private var viewModel: HotTagsViewModel!
    
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
        tableView.dataSource = self
        tableView.delegate = self
        
        // Bindings
        viewModel.data.bind(self) { [weak self] data in
            Task { @MainActor in
                self?.tableView.reloadData()
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
                    self.makeToastActivity()
                } else {
                    self.hideToastActivity()
                }
            }
        }
    }
    
    private func prepareUI() {
        title = viewModel.screenTitle
        segmentedControl.setTitle(NSLocalizedString(TagsSegmentType.allCases[0].rawValue, comment: ""), forSegmentAt: 0)
        segmentedControl.setTitle(NSLocalizedString(TagsSegmentType.allCases[1].rawValue, comment: ""), forSegmentAt: 1)
    }
    
    // MARK: - Actions
    
    @IBAction func onSelectedSegmentChange(_ sender: UISegmentedControl) {
        viewModel.onSelectedSegmentChange(sender.selectedSegmentIndex)
    }
    
    @IBAction func onDoneButton(_ sender: Any) {
        coordinatorActions?.closeHotTags(self)
    }
}

// MARK: - UITableViewDataSource

extension HotTagsViewController: UITableViewDataSource {
        
    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.data.value.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TagCell", for: indexPath)
        cell.textLabel?.text = viewModel.data.value[indexPath.item].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        false
    }
}

// MARK: - UITableViewDelegate

extension HotTagsViewController: UITableViewDelegate {
        
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tagName = viewModel.data.value[indexPath.row].name
        viewModel.triggerDidSelect(tagName: tagName)
        coordinatorActions?.closeHotTags(self)
    }
}

