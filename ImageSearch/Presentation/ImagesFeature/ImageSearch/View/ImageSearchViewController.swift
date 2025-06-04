import UIKit

struct ImageSearchCoordinatorActions {
    let showImageDetails: (ImageListItemVM, ImageQuery, Event<Image>) -> ()
    let showHotTags: (Event<String>) -> ()
}

class ImageSearchViewController: UIViewController, Storyboarded, Alertable {
    
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewTopConstraint: NSLayoutConstraint!
    
    private var viewModel: ImageSearchViewModel!
    
    private let refreshControl = UIRefreshControl()
    
    private var coordinatorActions: ImageSearchCoordinatorActions?
    
    static func instantiate(viewModel: ImageSearchViewModel, actions: ImageSearchCoordinatorActions) -> ImageSearchViewController {
        let vc = Self.instantiate(from: .imageSearch)
        vc.viewModel = viewModel
        vc.coordinatorActions = actions
        return vc
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setup()
        prepareUI()
        
        // Get some random images at the app's start
        viewModel.searchImages(for: "random")
    }
    
    private func setup() {
        collectionView.dataSource = self
        collectionView.delegate = self
        searchBar.delegate = self
        
        // Bindings
        viewModel.data.bind(self, queue: .main) { [weak self] data in
            guard let self, data.reload else { return }
            collectionView.reloadData()
            if refreshControl.isRefreshing {
                refreshControl.endRefreshing()
            }
        }
        
        viewModel.sectionData.bind(self, queue: .main) { [weak self] data in
            guard let self else { return }
            collectionView.reloadSections(data)
        }
        
        viewModel.scrollTop.bind(self, queue: .main) { [weak self] _ in
            self?.scrollTop()
        }
        
        viewModel.makeToast.bind(self, queue: .main) { [weak self] message in
            guard let self, !message.isEmpty else { return }
            makeToast(message: message)
        }
        
        viewModel.resetSearchBar.bind(self) { [weak self] _ in
            guard let self else { return }
            searchBar.text = nil
            searchBar.resignFirstResponder()
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { [weak self] value in
            guard let self else { return }
            if value {
                makeToastActivity()
                searchBar.isUserInteractionEnabled = false
                searchBar.placeholder = "..."
            } else {
                hideToastActivity()
                searchBar.isUserInteractionEnabled = true
                searchBar.placeholder = NSLocalizedString("Search", comment: "")
            }
        }
        
        viewModel.collectionViewTopConstraint.bind(self) { [weak self] value in
            guard let self else { return }
            collectionViewTopConstraint.constant = CGFloat(value)
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Other
        refreshControl.addTarget(self, action: #selector(refreshImageData(_:)), for: .valueChanged)
    }
    
    private func prepareUI() {
        title = viewModel.screenTitle
        searchBar.isUserInteractionEnabled = false
        searchBar.placeholder = "..."
        searchBar.layer.borderColor = UIColor.lightGray.cgColor
        searchBar.layer.borderWidth = 0.5
        
        collectionView.refreshControl = refreshControl
        
        navigationItem.backButtonTitle = ""
    }
    
    private func scrollTop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            if let attributes = collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) {
                collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - collectionView.contentInset.top), animated: true)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onHotTagsBarButtonItem(_ sender: UIBarButtonItem) {
        let didSelect = Event<String>()
        didSelect.subscribe(self) { [weak self] query in self?.viewModel.searchImages(for: query) }
        coordinatorActions?.showHotTags(didSelect)
    }
    
    // MARK: - Other methods
    
    @objc func deviceOrientationDidChange(_: Notification) {
        collectionView.reloadData()
    }
    
    @objc private func refreshImageData(_ sender: Any) {
        func endRefreshing() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                refreshControl.endRefreshing()
            }
        }
        guard let lastQuery = viewModel.lastQuery else {
            viewModel.searchImages(for: "random")
            endRefreshing()
            return
        }
        viewModel.searchImages(for: lastQuery.query)
        endRefreshing()
    }
}

// MARK: - UISearchBarDelegate

extension ImageSearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchBarText = searchBar.text {
            viewModel.searchBarSearchButtonClicked(with: searchBarText)
        }
    }
    
    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = true
        return true
    }
    
    func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
        searchBar.showsCancelButton = false
        return true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
    }
}

// MARK: - UICollectionViewDataSource

extension ImageSearchViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        viewModel.data.value.searches.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.data.value.searches[section]._searchResults.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! CollectionViewCell
        let image = viewModel.data.value.searches[indexPath.section]._searchResults[indexPath.row]
        cell.imageView.image = image.thumbnail?.uiImage
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            if let headerView =  collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "ImageSectionHeader", for: indexPath) as? CollectionViewHeader {
                let searchQuery = viewModel.data.value.searches[indexPath.section].searchQuery.query
                headerView.label.text = searchQuery
                return headerView
            }
        }
        return UICollectionReusableView()
    }
}

// MARK: - UICollectionViewDelegate

extension ImageSearchViewController: UICollectionViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0 {
            viewModel.scrollUp()
        } else {
            viewModel.scrollDown(Float(searchBar.frame.height))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedImage = viewModel.data.value.searches[indexPath.section]._searchResults[indexPath.row]
        if selectedImage.thumbnail == nil { return }
        
        let query = viewModel.data.value.searches[indexPath.section].searchQuery
        
        let didFinish = Event<Image>()
        didFinish.subscribe(self) { [weak self] image in self?.viewModel.updateImage(image, indexPath: indexPath) }
        
        coordinatorActions?.showImageDetails(selectedImage, query, didFinish)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let section = viewModel.data.value.searches[indexPath.section]
        if section._searchResults[indexPath.row].thumbnail == nil {
            viewModel.updateSection(section.id)
        }
    }
}

// MARK: - Collection View Flow Layout Delegate

extension ImageSearchViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemsPerRow = CGFloat()
        if UIWindow.isLandscape {
            itemsPerRow = AppConfiguration.ImageCollection.itemsPerRowInHorizOrient
        } else {
            itemsPerRow = AppConfiguration.ImageCollection.itemsPerRowInVertOrient
        }
        
        let padding = AppConfiguration.ImageCollection.horizontalSpace
        let collectionCellSize = collectionView.frame.size.width - (padding*(itemsPerRow+1))
        
        let width = collectionCellSize/itemsPerRow
        let height = CGFloat(viewModel.getHeightOfCell(width: Float(width)))
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(
            top: AppConfiguration.ImageCollection.verticleSpace,
            left: AppConfiguration.ImageCollection.horizontalSpace,
            bottom: AppConfiguration.ImageCollection.verticleSpace,
            right: AppConfiguration.ImageCollection.horizontalSpace
        )
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        AppConfiguration.ImageCollection.horizontalSpace
    }
}
