//
//  ImageSearchViewController.swift
//  ImageSearch
//
//  Created by Denis Simon on 02/19/2020.
//  Copyright © 2020 Denis Simon. All rights reserved.
//

import UIKit
import Toast_Swift

class ImageSearchViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    
    var viewModel: ImageSearchViewModel!
    weak var showDetailsCoordinatorDelegate: ShowDetailsCoordinatorDelegate!
    weak var hotTagsListCoordinatorDelegate: HotTagsListCoordinatorDelegate!
    
    private var dataSource: ImagesDataSource?
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel.getDataSource()
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        searchBar.delegate = self
        
        setup()
        prepareUI()
        
        // Get some random images at the app's start
        viewModel.searchFlickr(for: "random")
    }
    
    private func setup() {
        // Delegation
        viewModel.updateData.addSubscriber(target: self, handler: { (self, _) in
            self.dataSource?.updateData(self.viewModel.getData())
            self.collectionView.reloadData()
        })
          
        viewModel.resetSearchBar.addSubscriber(target: self, handler: { (self, _) in
            self.searchBar.text = nil
            self.searchBar.resignFirstResponder()
        })
        
        viewModel.showToast.addSubscriber(target: self, handler: { (self, text) in
            if !text.isEmpty {
                self.view.makeToast(text, duration: AppConstants.Other.ToastDuration, position: .bottom)
            }
        })
        
        viewModel.scrollTop.addSubscriber(target: self, handler: { (self, _) in
            if let attributes = self.collectionView.collectionViewLayout.layoutAttributesForSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) {
                self.collectionView.setContentOffset(CGPoint(x: 0, y: attributes.frame.origin.y - self.collectionView.contentInset.top), animated: true)
            }
        })
        
        // Bindings
        viewModel.activityIndicatorVisibility.didChanged.addSubscriber(target: self, handler: { (self, value) in
            if value.new {
                self.view.makeToastActivity(.center)
                self.searchBar.isUserInteractionEnabled = false
                self.searchBar.placeholder = "Searching..."
            } else {
                self.view.hideToastActivity()
                self.searchBar.isUserInteractionEnabled = true
                self.searchBar.placeholder = "Search"
            }
        })
        
        viewModel.collectionViewTopConstraint.didChanged.addSubscriber(target: self, handler: { (self, value) in
            self.collectionViewTopConstraint.constant = CGFloat(value.new)
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        })
        
        // Notifications
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
        
        // Other
        // Configure Refresh Control
        refreshControl.addTarget(self, action: #selector(refreshImageData(_:)), for: .valueChanged)

    }
    
    private func prepareUI() {
        searchBar.isUserInteractionEnabled = false
        self.searchBar.placeholder = "Searching..."
        self.searchBar.layer.borderColor = UIColor.lightGray.cgColor
        self.searchBar.layer.borderWidth = 0.5
        
        if #available(iOS 10.0, *) {
            collectionView.refreshControl = refreshControl
        } else {
            collectionView.addSubview(refreshControl)
        }
    }
    
    // MARK: - Actions
    
    @IBAction func onHotTagsBarButtonItem(_ sender: UIBarButtonItem) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            self.hotTagsListCoordinatorDelegate.showListScreen(from: self)
        }
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
        let selectedImage = viewModel.getImage(for: (indexPath.section, indexPath.row))
        let header = viewModel.getSearchString(for: indexPath.section)
        self.showDetailsCoordinatorDelegate.showDetailsScreen(of: selectedImage, header: header, from: self)
    }
}

// MARK: - Collection View Flow Layout Delegate

extension ImageSearchViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          sizeForItemAt indexPath: IndexPath) -> CGSize {
        var itemsPerRow = CGFloat()
        if UIApplication.shared.statusBarOrientation.isLandscape {
            itemsPerRow = AppConstants.ImageCollection.ItemsPerRowInHorizOrient
        } else {
            itemsPerRow = AppConstants.ImageCollection.ItemsPerRowInVertOrient
        }
        
        let padding = AppConstants.ImageCollection.HorizontalSpace
        let collectionCellSize = collectionView.frame.size.width - (padding*(itemsPerRow+1))
        
        let width = collectionCellSize/itemsPerRow
        let height = CGFloat(viewModel.getHeightOfCell(width: Float(width)))
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: AppConstants.ImageCollection.VerticleSpace,
            left: AppConstants.ImageCollection.HorizontalSpace,
            bottom: AppConstants.ImageCollection.VerticleSpace,
            right: AppConstants.ImageCollection.HorizontalSpace
        )
    }
    
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return AppConstants.ImageCollection.HorizontalSpace
    }
}
