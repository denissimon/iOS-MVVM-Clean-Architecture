import SwiftUI

@MainActor
class HotTagsViewModelBridgeWrapper: ObservableObject {
    
    var viewModel: HotTagsViewModel?
    
    weak var hostingController: UIViewController?
    
    @Published private(set) var data: [TagVM] = []
    
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
        viewModel?.data.bind(self) { [weak self] data in
            Task { @MainActor in
                self?.data = data
            }
        }
        
        viewModel?.makeToast.bind(self) { [weak self] message in
            guard !message.isEmpty else { return }
            Task { @MainActor in
                self?.hostingController?.view.makeToast(message)
            }
        }
        
        viewModel?.activityIndicatorVisibility.bind(self) { [weak self] value in
            Task { @MainActor in
                guard let hostingController = self?.hostingController else { return }
                if value {
                    hostingController.view.makeToastActivity(.center)
                } else {
                    hostingController.view.hideToastActivity()
                }
            }
        }
    }
}
