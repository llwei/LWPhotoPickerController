//
//  LWPhotoBrowseViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/14.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  https://github.com/llwei/LWPhotoPickerController

import UIKit
import Photos

private let CellIdentifier = "LWPhotoBrowseCell"
private let Scale: CGFloat = UIScreen.main.scale
private let ScreenWidth = UIScreen.main.bounds.size.width
private let ScreenHeight = UIScreen.main.bounds.size.height

private let SelectedBtnSize: CGFloat = 40.0

typealias UpdateSelectedHandler = ((_ add: Bool, _ restorationId: String, _ indexPath: IndexPath) -> Void)

class LWPhotoBrowseViewController: LWPhotoBaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Properties
    
    var currentIndex: Int!
    
    fileprivate var collectionView: UICollectionView!
    fileprivate var selectedButton: UIButton!
    fileprivate var updateSelectedHandler: UpdateSelectedHandler?
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup subviews
        doneItem = initialRightDoneItem()
        navigationItem.rightBarButtonItem = doneItem
        
        collectionView = initialCollectionView()
        view.addSubview(collectionView)
        
        selectedButton = initialSelectedButton()
        view.addSubview(selectedButton)
        
        // Add Constraints
        layoutCollectionView(collectionView, selectedButton: selectedButton)
        
        // Update title and selected button state
        updateTitleAndSelectedButton(withCurrentIndex: currentIndex)
    }

    fileprivate func initialRightDoneItem() -> UIBarButtonItem {
        // Done item
        let enabled = selectedRestorationId.count > 0
        let itemTitle = DoneTitle + (enabled ? "(" + "\(selectedRestorationId.count)" + ")" : "")
        
        let doneItem = UIBarButtonItem(title: itemTitle,
                                       style: .done,
                                       target: self,
                                       action: #selector(LWPhotoBrowseViewController.didClickDoneItemAction))
        doneItem.isEnabled = enabled
        doneItem.tintColor = UIColor.orange
        
        return doneItem
    }
    
    
    fileprivate func initialCollectionView() -> UICollectionView {
        // Flow layout
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: ScreenWidth, height: ScreenHeight - 64)
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.scrollDirection = .horizontal
        
        // UICollection view
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.isPagingEnabled = true
        collectionView.backgroundColor = UIColor.black
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Register cell class
        collectionView.register(LWPhotoBrowseCell.self, forCellWithReuseIdentifier: CellIdentifier)
        
        return collectionView
    }
    
    fileprivate func initialSelectedButton() -> UIButton {
        
        let selectedButton = UIButton(type: .custom)
        selectedButton.setBackgroundImage(UIImage(named: "AGIPC-Checkmark-0"), for: UIControlState())
        selectedButton.setBackgroundImage(UIImage(named: "AGIPC-Checkmark-1"), for: .selected)
        selectedButton.addTarget(self,
                                 action: #selector(LWPhotoBrowseViewController.didClickSelectedButton(_:)),
                                 for: .touchUpInside)
        
        return selectedButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Scroll to current index
        let indexPath = IndexPath(item: currentIndex, section: 0)
        let after = DispatchTime.now() + Double(Int64(NSEC_PER_SEC) / 20) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: after) { 
            self.collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition(), animated: false)
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let statusBarHidden = UIApplication.shared.isStatusBarHidden
        let navigationBarHeight = navigationController?.navigationBar.bounds.size.height ?? 44.0
        let flowLayout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        flowLayout.itemSize = CGSize(width: view.bounds.size.width, height: view.bounds.size.height - navigationBarHeight - (statusBarHidden ? 0 : 20))
        collectionView.collectionViewLayout = flowLayout
    }
    
    
    deinit {
        print("LWPhotoBrowseViewController deinit")
    }
    
    
    // MARK: - Helper methods
    
    fileprivate func layoutCollectionView(_ collectionView: UICollectionView, selectedButton: UIButton) {
        
        // CollectionView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let horiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|",
                                                                             options: NSLayoutFormatOptions(),
                                                                             metrics: nil,
                                                                             views: ["collectionView" : collectionView])
        let vertiConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView]|",
                                                                              options: NSLayoutFormatOptions(),
                                                                              metrics: nil,
                                                                              views: ["collectionView" : collectionView])
        NSLayoutConstraint.activate(horiConstraints)
        NSLayoutConstraint.activate(vertiConstraints)
        
        // SelectedButton
        selectedButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonWidth = NSLayoutConstraint(item: selectedButton,
                                             attribute: .width,
                                             relatedBy: .equal,
                                             toItem: nil,
                                             attribute: .notAnAttribute,
                                             multiplier: 1.0,
                                             constant: SelectedBtnSize)
        let buttonHeight = NSLayoutConstraint(item: selectedButton,
                                              attribute: .height,
                                              relatedBy: .equal,
                                              toItem: nil,
                                              attribute: .notAnAttribute,
                                              multiplier: 1.0,
                                              constant: SelectedBtnSize)
        let buttonTop = NSLayoutConstraint(item: selectedButton,
                                           attribute: .top,
                                           relatedBy: .equal,
                                           toItem: view,
                                           attribute: .top,
                                           multiplier: 1.0,
                                           constant: SelectedBtnSize / 4 + 64)
        let buttonRight = NSLayoutConstraint(item: selectedButton,
                                             attribute: .right,
                                             relatedBy: .equal,
                                             toItem: view,
                                             attribute: .right,
                                             multiplier: 1.0,
                                             constant: -SelectedBtnSize / 4)
        
        NSLayoutConstraint.activate([buttonWidth, buttonHeight, buttonTop, buttonRight])
    }
    
    
    fileprivate func updateTitleAndSelectedButton(withCurrentIndex page: Int) {
    
        // Update title
        currentIndex = page
        title = "\(page + 1)" + "/" + "\(assetResult?.count ?? 1)"
        
        // Update selected button
        if let asset = assetResult?[page] as? PHAsset {
            selectedButton.isSelected = selectedRestorationId.contains(asset.localIdentifier)
        }
    }
    
    
    
    // MARK: - Target actions
    
    func didClickSelectedButton(_ sender: UIButton) {
        guard selectedRestorationId.count < Int(maxSelectedCount) || sender.isSelected else { return }
        
        sender.isSelected = !sender.isSelected
        
        // Update selectedRestorationId
        let page = Int(collectionView.contentOffset.x / ScreenWidth)
        let indexPath = IndexPath(item: page, section: 0)
        if let asset = assetResult?[page] as? PHAsset {
            if sender.isSelected {
                selectedRestorationId.append(asset.localIdentifier)
                updateSelectedHandler?(true, asset.localIdentifier, indexPath)
            } else {
                selectedRestorationId = selectedRestorationId.filter( {$0 != asset.localIdentifier} )
                updateSelectedHandler?(false, asset.localIdentifier, indexPath)
            }
        }
        
        // Update doneItem
        doneItem.isEnabled = selectedRestorationId.count > 0
        doneItem.title = DoneTitle + (doneItem.isEnabled ? "(" + "\(selectedRestorationId.count)" + ")" : "")
    }
    
    
    
    // MARK: - Public methods
    
    func updateSelectedMarkHandler(_ handler: UpdateSelectedHandler?) {
        updateSelectedHandler = handler
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetResult?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! LWPhotoBrowseCell
        
        if let asset = assetResult?[(indexPath as NSIndexPath).item] as? PHAsset {
            cell.representedAssetIdentifier = asset.localIdentifier
            
            let option = PHImageRequestOptions()
            option.isSynchronous = false          // 如果为true，则下面的handler只调用一次，false会调用多出（第一次会比较模糊）
            
            let size = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
            PHImageManager.default().requestImage(for: asset,
                                                                 targetSize: size,
                                                                 contentMode: .aspectFit,
                                                                 options: option,
                                                                 resultHandler: { (image: UIImage?, info: [AnyHashable: Any]?) in
                                                                    
                                                                    if cell.representedAssetIdentifier == asset.localIdentifier {
                                                                        cell.image = image
                                                                    }
            })
            
        }
        
        return cell
    }

    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        
        let page = Int(scrollView.contentOffset.x / ScreenWidth)
        updateTitleAndSelectedButton(withCurrentIndex: page)
    }
    
}



class LWPhotoBrowseCell: UICollectionViewCell, UIScrollViewDelegate {
    
    // MARK: - Properties
    
    var representedAssetIdentifier: String?
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    fileprivate lazy var imageView: UIImageView = {
        let lazyImageView = UIImageView()
        lazyImageView.contentMode = .scaleAspectFit
        return lazyImageView
    }()

    
    // MARK: - Life cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        addConstranints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
 
    fileprivate func addConstranints() {
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        let imgViewHs = NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|",
                                                                       options: NSLayoutFormatOptions(),
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        let imgViewVs = NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|",
                                                                       options: NSLayoutFormatOptions(),
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        
        NSLayoutConstraint.activate(imgViewHs)
        NSLayoutConstraint.activate(imgViewVs)
    }
    
    
    // MARK: - UIScrollViewDelegate
    
}

