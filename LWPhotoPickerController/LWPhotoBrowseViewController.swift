//
//  LWPhotoBrowseViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/14.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import Photos

private let CellIdentifier = "LWPhotoBrowseCell"
private let Scale: CGFloat = UIScreen.mainScreen().scale
private let ScreenWidth = UIScreen.mainScreen().bounds.size.width
private let ScreenHeight = UIScreen.mainScreen().bounds.size.height

private let SelectedBtnSize: CGFloat = 40.0
private let DoneTitle = NSLocalizedString("Done", comment: "")

typealias UpdateSelectedHandler = ((add: Bool, restorationId: String, indexPath: NSIndexPath) -> Void)

class LWPhotoBrowseViewController: LWPhotoBaseViewController, UICollectionViewDataSource, UICollectionViewDelegate {

    // MARK: - Properties
    
    var currentIndex: Int!
    
    private var doneItem: UIBarButtonItem!
    private var collectionView: UICollectionView!
    private var selectedButton: UIButton!
    private var updateSelectedHandler: UpdateSelectedHandler?
    
    
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

    private func initialRightDoneItem() -> UIBarButtonItem {
        // Done item
        let enabled = selectedRestorationId.count > 0
        let itemTitle = DoneTitle + (enabled ? "(" + "\(selectedRestorationId.count)" + ")" : "")
        
        let doneItem = UIBarButtonItem(title: itemTitle,
                                       style: .Done,
                                       target: self,
                                       action: #selector(LWPhotoBrowseViewController.doneItemWasClick))
        doneItem.enabled = enabled
        doneItem.tintColor = UIColor.orangeColor()
        
        return doneItem
    }
    
    
    private func initialCollectionView() -> UICollectionView {
        // Flow layout
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: ScreenWidth, height: ScreenHeight - 64)
        flowLayout.minimumLineSpacing = 0.0
        flowLayout.minimumInteritemSpacing = 0.0
        flowLayout.scrollDirection = .Horizontal
        
        // UICollection view
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: flowLayout)
        collectionView.pagingEnabled = true
        collectionView.backgroundColor = UIColor.blackColor()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Register cell class
        collectionView.registerClass(LWPhotoBrowseCell.self, forCellWithReuseIdentifier: CellIdentifier)
        
        return collectionView
    }
    
    private func initialSelectedButton() -> UIButton {
        
        let selectedButton = UIButton(type: .Custom)
        selectedButton.setBackgroundImage(UIImage(named: "AGIPC-Checkmark-0"), forState: .Normal)
        selectedButton.setBackgroundImage(UIImage(named: "AGIPC-Checkmark-1"), forState: .Selected)
        selectedButton.addTarget(self,
                                 action: #selector(LWPhotoBrowseViewController.didClickSelectedButton(_:)),
                                 forControlEvents: .TouchUpInside)
        
        return selectedButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Scroll to current index
        let indexPath = NSIndexPath(forItem: currentIndex, inSection: 0)
        let after = dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC) / 20)
        dispatch_after(after, dispatch_get_main_queue()) { 
            self.collectionView.scrollToItemAtIndexPath(indexPath, atScrollPosition: .None, animated: false)
        }
        
    }
    
    deinit {
        print("LWPhotoBrowseViewController deinit")
    }
    
    
    // MARK: - Helper methods
    
    private func layoutCollectionView(collectionView: UICollectionView, selectedButton: UIButton) {
        
        // CollectionView
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        let horiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|",
                                                                             options: .DirectionLeadingToTrailing,
                                                                             metrics: nil,
                                                                             views: ["collectionView" : collectionView])
        let vertiConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|",
                                                                              options: .DirectionLeadingToTrailing,
                                                                              metrics: nil,
                                                                              views: ["collectionView" : collectionView])
        NSLayoutConstraint.activateConstraints(horiConstraints)
        NSLayoutConstraint.activateConstraints(vertiConstraints)
        
        // SelectedButton
        selectedButton.translatesAutoresizingMaskIntoConstraints = false
        let buttonWidth = NSLayoutConstraint(item: selectedButton,
                                             attribute: .Width,
                                             relatedBy: .Equal,
                                             toItem: nil,
                                             attribute: .NotAnAttribute,
                                             multiplier: 1.0,
                                             constant: SelectedBtnSize)
        let buttonHeight = NSLayoutConstraint(item: selectedButton,
                                              attribute: .Height,
                                              relatedBy: .Equal,
                                              toItem: nil,
                                              attribute: .NotAnAttribute,
                                              multiplier: 1.0,
                                              constant: SelectedBtnSize)
        let buttonTop = NSLayoutConstraint(item: selectedButton,
                                           attribute: .Top,
                                           relatedBy: .Equal,
                                           toItem: view,
                                           attribute: .Top,
                                           multiplier: 1.0,
                                           constant: SelectedBtnSize / 4 + 64)
        let buttonRight = NSLayoutConstraint(item: selectedButton,
                                             attribute: .Right,
                                             relatedBy: .Equal,
                                             toItem: view,
                                             attribute: .Right,
                                             multiplier: 1.0,
                                             constant: -SelectedBtnSize / 4)
        
        NSLayoutConstraint.activateConstraints([buttonWidth, buttonHeight, buttonTop, buttonRight])
    }
    
    
    private func updateTitleAndSelectedButton(withCurrentIndex page: Int) {
    
        // Update title
        currentIndex = page
        title = "\(page + 1)" + "/" + "\(assetResult?.count)"
        
        // Update selected button
        if let asset = assetResult?[page] as? PHAsset {
            selectedButton.selected = selectedRestorationId.contains(asset.localIdentifier)
        }
    }
    
    
    
    // MARK: - Target actions
    
    func didClickSelectedButton(sender: UIButton) {
        guard selectedRestorationId.count < Int(maxSelectedCount) || sender.selected else { return }
        
        sender.selected = !sender.selected
        
        // Update selectedRestorationId
        let page = Int(collectionView.contentOffset.x / ScreenWidth)
        let indexPath = NSIndexPath(forItem: page, inSection: 0)
        if let asset = assetResult?[page] as? PHAsset {
            if sender.selected {
                selectedRestorationId.append(asset.localIdentifier)
                updateSelectedHandler?(add: true, restorationId: asset.localIdentifier, indexPath: indexPath)
            } else {
                selectedRestorationId = selectedRestorationId.filter( {$0 != asset.localIdentifier} )
                updateSelectedHandler?(add: false, restorationId: asset.localIdentifier, indexPath: indexPath)
            }
        }
        
        // Update doneItem
        doneItem.enabled = selectedRestorationId.count > 0
        doneItem.title = DoneTitle + (doneItem.enabled ? "(" + "\(selectedRestorationId.count)" + ")" : "")
    }
    
    
    func doneItemWasClick() {
        didClickDoneItemAction()
    }
    
    
    // MARK: - Public methods
    
    func updateSelectedMarkHandler(handler: UpdateSelectedHandler?) {
        updateSelectedHandler = handler
    }
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetResult?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! LWPhotoBrowseCell
        
        if let asset = assetResult?[indexPath.item] as? PHAsset {
            cell.representedAssetIdentifier = asset.localIdentifier
            
            let option = PHImageRequestOptions()
            option.synchronous = false          // 如果为true，则下面的handler只调用一次，false会调用多出（第一次会比较模糊）
            
            let size = CGSize(width: CGFloat(asset.pixelWidth), height: CGFloat(asset.pixelHeight))
            PHImageManager.defaultManager().requestImageForAsset(asset,
                                                                 targetSize: size,
                                                                 contentMode: .Default,
                                                                 options: option,
                                                                 resultHandler: { (image: UIImage?, info: [NSObject : AnyObject]?) in
                                                                    
                                                                    if cell.representedAssetIdentifier == asset.localIdentifier {
                                                                        cell.image = image
                                                                    }
            })
            
        }
        
        return cell
    }

    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        
        let page = Int(scrollView.contentOffset.x / ScreenWidth)
        updateTitleAndSelectedButton(withCurrentIndex: page)
    }
    
}



class LWPhotoBrowseCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var representedAssetIdentifier: String?
    var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }
    
    private var imageView = UIImageView()
    
    
    // MARK: - Life cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.contentMode = .ScaleAspectFit
        contentView.addSubview(imageView)
        
        addConstranints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
 
    private func addConstranints() {
    
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        let imgViewHs = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|",
                                                                       options: .DirectionLeadingToTrailing,
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        let imgViewVs = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|",
                                                                       options: .DirectionLeadingToTrailing,
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        
        NSLayoutConstraint.activateConstraints(imgViewHs)
        NSLayoutConstraint.activateConstraints(imgViewVs)
    }
    
}

