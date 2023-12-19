//
//  ImageSearchViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//

import UIKit

struct ImageSearchCoordinatorActions {
    let showImageDetails: (Image) -> ()
    let showHotTagsList: (Event<ImageQuery>) -> ()
}

class ImageSearchViewController: UIViewController, Storyboarded {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    
    var viewModel: ImageSearchViewModel!
    
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
        viewModel.searchFlickr(for: "random")
    }
    
    private func setup() {
        dataSource = viewModel.getDataSource()
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        searchBar.delegate = self
        
        // Bindings
        viewModel.data.bind(self, queue: .main) { (data) in
            self.dataSource?.updateData(data)
            self.collectionView.reloadData()
            self.scrollTop()
        }
        
        viewModel.showToast.bind(self, queue: .main) { (text) in
            if !text.isEmpty {
                self.view.makeToast(text, duration: AppConfiguration.Other.toastDuration, position: .bottom)
            }
        }
        
        viewModel.resetSearchBar.bind(self) { _ in
            self.searchBar.text = nil
            self.searchBar.resignFirstResponder()
        }
        
        viewModel.activityIndicatorVisibility.bind(self, queue: .main) { (value) in
            if value {
                self.view.makeToastActivity(.center)
                self.searchBar.isUserInteractionEnabled = false
                self.searchBar.placeholder = "..."
            } else {
                self.view.hideToastActivity()
                self.searchBar.isUserInteractionEnabled = true
                self.searchBar.placeholder = "Search"
            }
        }
        
        viewModel.collectionViewTopConstraint.bind(self) { (value) in
            self.collectionViewTopConstraint.constant = CGFloat(value)
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        }
        
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Other
        // Configure Refresh Control
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
        let imageQueryEvent = Event<ImageQuery>()
        imageQueryEvent.subscribe(self) { [weak self] (query) in self?.viewModel.searchFlickr(for: query.query) }
        coordinatorActions?.showHotTagsList(imageQueryEvent)
    }
    
    // MARK: - Other methods
    
    @objc func deviceOrientationDidChange(_ notification: Notification) {
        collectionView.reloadData()
    }
    
    @objc private func refreshImageData(_ sender: Any) {
        if !viewModel.lastTag.isEmpty {
            viewModel.searchBarSearchButtonClicked(with: viewModel.lastTag)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.refreshControl.endRefreshing()
            }
        }
    }
}

// MARK: - UISearchBarDelegate

extension ImageSearchViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        viewModel.searchBarSearchButtonClicked(with: searchBar.text)
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
        coordinatorActions?.showImageDetails(selectedImage)
    }
}

// MARK: - Collection View Flow Layout Delegate

extension ImageSearchViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemsPerRow = CGFloat()
        if UIApplication.shared.statusBarOrientation.isLandscape {
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
