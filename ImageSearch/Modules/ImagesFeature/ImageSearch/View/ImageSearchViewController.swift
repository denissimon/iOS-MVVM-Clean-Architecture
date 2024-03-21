//
//  ImageSearchViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import UIKit

struct ImageSearchCoordinatorActions {
    let showImageDetails: (Image, ImageQuery) -> ()
    let showHotTags: (Event<ImageQuery>) -> ()
}

class ImageSearchViewController: UIViewController, Storyboarded, Alertable {
    
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var collectionViewTopConstraint: NSLayoutConstraint!
    
    private var viewModel: ImageSearchViewModel!
    
    private var dataSource: ImagesDataSource?
    
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
        let imageQuery = ImageQuery(query: "random")
        viewModel.searchImage(for: imageQuery)
    }
    
    private func setup() {
        dataSource = viewModel.getDataSource()
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        searchBar.delegate = self
        
        // Bindings
        viewModel.data.bind(self, queue: .main) { [weak self] (data) in
            guard let self = self else { return }
            self.dataSource?.updateData(data)
            self.collectionView.reloadData()
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }
        
        viewModel.sectionData.bind(self, queue: .main) { [weak self] (data) in
            guard let self = self else { return }
            self.dataSource?.updateData(data.0)
            self.collectionView.reloadSections(data.1)
        }
        
        viewModel.scrollTop.bind(self, queue: .main) { [weak self] (data) in
            guard let self = self else { return }
            self.scrollTop()
        }
        
        viewModel.showToast.bind(self, queue: .main) { [weak self] (message) in
            guard !message.isEmpty else { return }
            self?.makeToast(message: message)
        }
        
        viewModel.resetSearchBar.bind(self) { [weak self] _ in
            guard let self = self else { return }
            self.searchBar.text = nil
            self.searchBar.resignFirstResponder()
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { [weak self] (value) in
            guard let self = self else { return }
            if value {
                self.makeToastActivity()
                self.searchBar.isUserInteractionEnabled = false
                self.searchBar.placeholder = "..."
            } else {
                self.hideToastActivity()
                self.searchBar.isUserInteractionEnabled = true
                self.searchBar.placeholder = "Search"
            }
        }
        
        viewModel.collectionViewTopConstraint.bind(self) { [weak self] (value) in
            guard let self = self else { return }
            self.collectionViewTopConstraint.constant = CGFloat(value)
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
        searchBar.isUserInteractionEnabled = false
        self.searchBar.placeholder = "..."
        self.searchBar.layer.borderColor = UIColor.lightGray.cgColor
        self.searchBar.layer.borderWidth = 0.5
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
        
        if #available(iOS 11.0, *) {
            navigationItem.backButtonTitle = ""
        }
    }
    
    private func scrollTop() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let attributes = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) {
                self.collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - self.collectionView.contentInset.top), animated: true)
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onHotTagsBarButtonItem(_ sender: UIBarButtonItem) {
        let didSelectEvent = Event<ImageQuery>()
        didSelectEvent.subscribe(self) { [weak self] (query) in self?.viewModel.searchImage(for: query) }
        coordinatorActions?.showHotTags(didSelectEvent)
    }
    
    // MARK: - Other methods
    
    @objc func deviceOrientationDidChange(_ notification: Notification) {
        collectionView.reloadData()
    }
    
    @objc private func refreshImageData(_ sender: Any) {
        func endRefreshing() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.refreshControl.endRefreshing()
            }
        }
        guard let lastSearchQuery = viewModel.lastSearchQuery else {
            let imageQuery = ImageQuery(query: "random")
            self.viewModel.searchImage(for: imageQuery)
            endRefreshing()
            return
        }
        viewModel.searchImage(for: lastSearchQuery)
        endRefreshing()
    }
}

// MARK: - UISearchBarDelegate

extension ImageSearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        if let searchBarText = searchBar.text {
            let imageQuery = ImageQuery(query: searchBarText)
            viewModel.searchBarSearchButtonClicked(with: imageQuery)
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
        let selectedImage = viewModel.data.value[indexPath.section].searchResults[indexPath.row]
        if selectedImage.thumbnail == nil { return }
        coordinatorActions?.showImageDetails(selectedImage, viewModel.data.value[indexPath.section].searchQuery)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let section = viewModel.data.value[indexPath.section]
        if section.searchResults[indexPath.row].thumbnail == nil {
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
        return UIEdgeInsets(
            top: AppConfiguration.ImageCollection.verticleSpace,
            left: AppConfiguration.ImageCollection.horizontalSpace,
            bottom: AppConfiguration.ImageCollection.verticleSpace,
            right: AppConfiguration.ImageCollection.horizontalSpace
        )
    }
    
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return AppConfiguration.ImageCollection.horizontalSpace
    }
}
