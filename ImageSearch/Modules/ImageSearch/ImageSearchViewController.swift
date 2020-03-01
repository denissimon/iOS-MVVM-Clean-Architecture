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
    weak var coordinatorDelegate: ShowDetailsCoordinatorDelegate!
    
    private var dataSource: ImagesDataSource?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataSource = viewModel.getDataSource()
        collectionView.dataSource = dataSource
        collectionView.delegate = self
        searchBar.delegate = self
        
        setup()
        prepareUI()
    }
    
    // Setup closure-based delegates and bindings for the MVVM architecture
    private func setup() {
        viewModel.updatesInData = { [weak self] in
            guard let self = self else { return }
            self.dataSource?.updateData(self.viewModel.getData())
            self.collectionView.reloadData()
        }
        
        viewModel.resetSearchBar = { [weak self] in
            self?.searchBar.text = nil
            self?.searchBar.resignFirstResponder()
        }
        
        viewModel.showActivityIndicator.didChanged.addSubscriber(target: self, handler: { (self, value) in
            if value.new {
                self.view.makeToastActivity(.center)
                self.searchBar.searchTextField.isEnabled = false
            } else {
                self.view.hideToastActivity()
                self.searchBar.searchTextField.isEnabled = true
            }
        })
        
        viewModel.showToast.didChanged.addSubscriber(target: self, handler: { (self, value) in
            if !value.new.isEmpty {
                self.view.makeToast(value.new, duration: 5.0, position: .bottom)
            }
        })
        
        viewModel.collectionViewTopConstraint.didChanged.addSubscriber(target: self, handler: { (self, value) in
            self.collectionViewTopConstraint.constant = CGFloat(value.new)
            UIView.animate(withDuration: 0.25) {
                self.view.layoutIfNeeded()
            }
        })
    }
    
    private func prepareUI() {
        searchBar.searchTextField.isEnabled = false
    }
}

// MARK: - UIScrollViewDelegate

extension ImageSearchViewController {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.panGestureRecognizer.translation(in: scrollView.superview).y > 0 {
            viewModel.scrollUp()
        } else {
            viewModel.scrollDown(Float(searchBar.frame.height))
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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedImage = viewModel.getImage(for: (indexPath.section, indexPath.row))
        let header = viewModel.getSearchString(for: indexPath.section)
        self.coordinatorDelegate.showDetails(of: selectedImage, header: header, from: self)
    }
}

// MARK: - Collection View Flow Layout Delegate

extension ImageSearchViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                          layout collectionViewLayout: UICollectionViewLayout,
                          sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemsPerRow = CGFloat(AppConstants.ImageCollection.itemsPerRow)
        let padding: CGFloat = CGFloat(AppConstants.ImageCollection.horizontalSpace)
        let collectionCellSize = collectionView.frame.size.width - (padding*(itemsPerRow+1))
        
        let width = collectionCellSize/itemsPerRow
        let height = CGFloat(viewModel.getHeightOfCell(width: Float(width)))
        
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(
            top: CGFloat(AppConstants.ImageCollection.verticleSpace),
            left: CGFloat(AppConstants.ImageCollection.horizontalSpace),
            bottom: CGFloat(AppConstants.ImageCollection.verticleSpace),
            right: CGFloat(AppConstants.ImageCollection.horizontalSpace)
        )
    }
    
    func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return CGFloat(AppConstants.ImageCollection.horizontalSpace)
    }
}
