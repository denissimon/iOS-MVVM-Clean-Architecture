import SwiftUI

class HotTagsViewModelBridgeWrapper: ObservableObject {
    
    var viewModel: HotTagsViewModel?
    
    weak var hostingController: UIViewController?
    
    @Published private(set) var data = [TagListItemVM]()
    
    var screenTitle: String {
        viewModel?.screenTitle ?? ""
    }
    
    var selectedSegment: TagsSegmentType = .week {
        didSet {
            switch selectedSegment {
            case .week:
                viewModel?.onSelectedSegmentChange(0)
            case .allTimes:
                viewModel?.onSelectedSegmentChange(1)
            }
        }
    }
    
    init(viewModel: HotTagsViewModel?) {
        self.viewModel = viewModel
        bind()
    }
    
    private func bind() {
        viewModel?.data.bind(self, queue: .main) { [weak self] data in
            self?.data = data
        }
        
        viewModel?.makeToast.bind(self, queue: .main) { [weak self] message in
            guard let self, !message.isEmpty else { return }
            hostingController?.view.makeToast(message)
        }
        
        viewModel?.activityIndicatorVisibility.bind(self, queue: .main) { [weak self] value in
            guard let hostingController = self?.hostingController else { return }
            if value {
                hostingController.view.makeToastActivity(.center)
            } else {
                hostingController.view.hideToastActivity()
            }
        }
    }
}
