//
//  LWPhotoGridViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/14.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  https://github.com/llwei/LWPhotoPickerController

import UIKit
import Photos

private let CellIdentifier = "LWPhotoGridCell"
private let Scale: CGFloat = UIScreen.mainScreen().scale
private let ScreenWidth = UIScreen.mainScreen().bounds.size.width
private let ScreenHeight = UIScreen.mainScreen().bounds.size.height

private let HoriCount: Int = 4


class LWPhotoGridViewController: LWPhotoBaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, LWPhotoGridCellDelegate {

    
    // MARK: - Properties
    
    private let imageManager = PHCachingImageManager()
    private var originalItem: UIBarButtonItem!
    private var collectionView: UICollectionView!
    
   
    private var previousPreheatRect = CGRectZero
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageManager.stopCachingImagesForAllAssets()
        
        // Setup subviews
        setuplNavigationBar()
        collectionView = initialCollectionView()
        let toolBar = initialToolBar()
        
        // AutoLayout
        view.addSubview(collectionView)
        view.addSubview(toolBar)
        layout(withCollectionView: collectionView, toolBar: toolBar)
    }
    

    
    private func setuplNavigationBar() {
        // Add cancel item
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                         target: self,
                                         action: #selector(LWPhotoGridViewController.dismiss))
        navigationItem.rightBarButtonItem = cancelItem
    }
    
    
    private func initialCollectionView() -> UICollectionView {
    
        // Flow layout
        let flowLayout = UICollectionViewFlowLayout()
        let size = (ScreenWidth - CGFloat(HoriCount + 1)) / CGFloat(HoriCount)
        flowLayout.itemSize = CGSize(width: size, height: size)
        flowLayout.minimumLineSpacing = 1.0
        flowLayout.minimumInteritemSpacing = 1.0
        flowLayout.scrollDirection = .Vertical
        
        // UICollectionView
        let collectionView = UICollectionView(frame: CGRectZero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Register cell class
        collectionView.registerClass(LWPhotoGridCell.self, forCellWithReuseIdentifier: CellIdentifier)
        
        return collectionView
    }
    
    
    private func initialToolBar() -> UIToolbar {
    
        // Toolbar
        let toolBar = UIToolbar(frame: CGRectZero)
        toolBar.backgroundColor = UIColor.groupTableViewBackgroundColor()
        
        // Original item
        let originalItem = UIBarButtonItem(title: OriginalTitle,
                                           style: .Done,
                                           target: self,
                                           action: #selector(LWPhotoGridViewController.originalItemWasClick(_:)))
        originalItem.tintColor = UIColor.lightGrayColor()
        self.originalItem = originalItem
        
        // Space item
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace,
                                        target: self,
                                        action: nil)
        // Done item
        let doneItem = UIBarButtonItem(title: DoneTitle,
                                       style: .Done,
                                       target: self,
                                       action: #selector(LWPhotoGridViewController.didClickDoneItemAction))
        
        doneItem.enabled = false
        doneItem.tintColor = UIColor.orangeColor()
        self.doneItem = doneItem
        toolBar.setItems([originalItem, spaceItem, doneItem], animated: true)
        toolBar.tintColor = UIColor.darkGrayColor()
        
        return toolBar
    }
    
    
    private func layout(withCollectionView collectionView: UICollectionView, toolBar: UIToolbar) {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        
        let cHoriConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[collectionView]|",
                                                                              options: .DirectionLeadingToTrailing,
                                                                              metrics: nil,
                                                                              views: ["collectionView" : collectionView])
        let tHoriConstraints = NSLayoutConstraint.constraintsWithVisualFormat("H:|[toolBar]|",
                                                                              options: .DirectionLeadingToTrailing,
                                                                              metrics: nil,
                                                                              views: ["toolBar" : toolBar])
        let vertConstraints = NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView][toolBar(==44)]|",
                                                                             options: .DirectionLeadingToTrailing,
                                                                             metrics: ["44" : 44],
                                                                             views: ["toolBar" : toolBar, "collectionView" : collectionView])
        
        NSLayoutConstraint.activateConstraints(cHoriConstraints)
        NSLayoutConstraint.activateConstraints(tHoriConstraints)
        NSLayoutConstraint.activateConstraints(vertConstraints)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // Begin caching assets in and around collection view's visible rect.
        updateCachedAssets()
    }
    
    
    deinit {
        print("LWPhotoGridViewController deinit")
    }
    
    // MARK: - Target actions
    
    func dismiss() {
        NSNotificationCenter.defaultCenter().postNotificationName(kDidDoneSelectedAssetsNotification, object: nil)
    }
    
    
    func originalItemWasClick(sender: UIBarButtonItem) {
        
        original = !original
        if original {
            sender.tintColor = UIColor.orangeColor()
        } else {
            sender.tintColor = UIColor.lightGrayColor()
        }
    }
    
 
    
    
    func didClickPhotoGridCell(selectedButton button: UIButton, representedAssetIdentfier identifier: String?) {
        guard let identifier = identifier where selectedRestorationId.count < Int(maxSelectedCount) || button.selected else { return }
        
        button.selected = !button.selected
        
        // Update selectedRestorationId
        if button.selected {
            selectedRestorationId.append(identifier)
        } else {
            selectedRestorationId = selectedRestorationId.filter( { $0 != identifier} )
        }
        
        // Update doneItem
        doneItem.enabled = selectedRestorationId.count > 0
        doneItem.title = DoneTitle + (doneItem.enabled ? "(" + "\(selectedRestorationId.count)" + ")" : "")
    }

    
    
    // MARK: - Helper methods
    
    private func updateCachedAssets() {
        guard isViewLoaded() && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect
        var preheatRect = collectionView.bounds
        preheatRect = CGRectInset(preheatRect, 0.0, -0.5 * CGRectGetHeight(preheatRect))
        
        // Check if the collection view is showing an area that is significantly different to the last preheated area
        let delta = abs(Int32(CGRectGetMidY(preheatRect)) - Int32(CGRectGetMidY(previousPreheatRect)))
        if delta > Int32(CGRectGetHeight(collectionView.bounds) / 3) {
            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [NSIndexPath]()
            var removedIndexPaths = [NSIndexPath]()
            
            computeDifferenceBetweenRect(previousPreheatRect,
                                         andRect: preheatRect,
                                         removedHandler: { [unowned self] (removedRect) in
                                            
                                            if let indexPaths = self.collectionView.lw_indexPathsForElementsInRect(removedRect) {
                                                removedIndexPaths.appendContentsOf(indexPaths)
                                            }
                                            
                }, addedHandler: { [unowned self] (addedRect) in
                    
                    if let indexPaths = self.collectionView.lw_indexPathsForElementsInRect(addedRect) {
                        addedIndexPaths.appendContentsOf(indexPaths)
                    }
            })
            
            // Update the assets the PHCachingImageManager is caching
            let layoutSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            let size = CGSize(width: layoutSize.width * Scale, height: layoutSize.height * Scale)
            
            if let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths) {
                imageManager.startCachingImagesForAssets(assetsToStartCaching,
                                                         targetSize: size,
                                                         contentMode: .AspectFill,
                                                         options: nil)
            }
            if let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths) {
                imageManager.stopCachingImagesForAssets(assetsToStopCaching,
                                                        targetSize: size,
                                                        contentMode: .AspectFill,
                                                        options: nil)
            }
            
            // Store the preheat rect to compare against in the future
            previousPreheatRect = preheatRect
        }
    }
    
    private func computeDifferenceBetweenRect(oldRect: CGRect,
                                              andRect newRect: CGRect,
                                                      removedHandler: ((removedRect: CGRect) -> Void)?,
                                                      addedHandler: ((addedRect: CGRect) -> Void)?) {
        
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinX(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinX(newRect)
            
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: newMaxY - oldMinY)
                addedHandler?(addedRect: rectToAdd)
            }
            
            if newMinY > oldMinY  {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: newMinY - oldMinY)
                removedHandler?(removedRect: rectToRemove)
            }
            
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: oldMaxY - newMaxY)
                removedHandler?(removedRect: rectToRemove)
            }
            
            if newMinY < oldMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: oldMinY - newMinY)
                addedHandler?(addedRect: rectToAdd)
            }
            
        } else {
            addedHandler?(addedRect: newRect)
            removedHandler?(removedRect: oldRect)
        }
    }
    
    
    private func assetsAtIndexPaths(indexPaths: [NSIndexPath]) -> [PHAsset]? {
        guard indexPaths.count > 0 else { return nil }
        
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            if let asset = assetResult?[indexPath.item] as? PHAsset {
                assets.append(asset)
            }
        }

        return assets
    }
    
    private func updateOriginalTitle() {
        
    }
    
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetResult?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(CellIdentifier, forIndexPath: indexPath) as! LWPhotoGridCell
        
        cell.delegate = self
        
        if let asset = assetResult?[indexPath.row] as? PHAsset {
            cell.restorationIdentifier = asset.localIdentifier
            cell.didSelected = selectedRestorationId.contains(asset.localIdentifier)
            
            let layoutSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            let size = CGSize(width: layoutSize.width * Scale, height: layoutSize.height * Scale)
            
            imageManager.requestImageForAsset(asset,
                                              targetSize: size,
                                              contentMode: .AspectFill,
                                              options: nil,
                                              resultHandler: {
                                                (image: UIImage?, info: [NSObject : AnyObject]?) in
                                                
                                                if cell.restorationIdentifier == asset.localIdentifier {
                                                    cell.thumbnailImage = image
                                                }
            })
        }
        
        
        return cell
    }

    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let photoBrowseVC = LWPhotoBrowseViewController()
        photoBrowseVC.maxSelectedCount = maxSelectedCount
        photoBrowseVC.assetResult = assetResult
        photoBrowseVC.currentIndex = indexPath.item
        photoBrowseVC.selectedRestorationId = selectedRestorationId
        photoBrowseVC.original = original
        showViewController(photoBrowseVC, sender: self)
        
        photoBrowseVC.updateSelectedMarkHandler { (add, restorationId, indexPath) in
            // Update selectedRestorationId
            if add {
                self.selectedRestorationId.append(restorationId)
            } else {
                self.selectedRestorationId = self.selectedRestorationId.filter( { $0 != restorationId} )
            }
            self.collectionView.reloadItemsAtIndexPaths([indexPath])
            
            // Update doneItem
            self.doneItem.enabled = self.selectedRestorationId.count > 0
            self.doneItem.title = DoneTitle + (self.doneItem.enabled ? "(" + "\(self.selectedRestorationId.count)" + ")" : "")
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
}


protocol LWPhotoGridCellDelegate: class {
    func didClickPhotoGridCell(selectedButton button: UIButton, representedAssetIdentfier identifier: String?)
}


class LWPhotoGridCell: UICollectionViewCell {

    
    // MARK: - Properties
    
    private let imageView = UIImageView()
    private let selectedButton = UIButton(type: .Custom)

    weak var delegate: LWPhotoGridCellDelegate?
    var representedAssetIdentifier: String?
    var thumbnailImage: UIImage? {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    var didSelected: Bool = false {
        didSet {
            selectedButton.selected = didSelected
        }
    }
    
    
    
    // MARK: - Life cycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
    
        // Image view
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        // Selected button
        selectedButton.setBackgroundImage(UIImage(named: "AGIPC-Checkmark-0"), forState: .Normal)
        selectedButton.setBackgroundImage(UIImage(named: "AGIPC-Checkmark-1"), forState: .Selected)
        selectedButton.addTarget(self,
                                 action: #selector(LWPhotoGridCell.didClickSelectedButton(_:)),
                                 forControlEvents: .TouchUpInside)
        contentView.addSubview(selectedButton)
        
        addConstranints()
    }
    
    private func addConstranints() {
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        selectedButton.translatesAutoresizingMaskIntoConstraints = false
        
        let imgViewHs = NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|",
                                                                       options: .DirectionLeadingToTrailing,
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        let imgViewVs = NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|",
                                                                       options: .DirectionLeadingToTrailing,
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        let btnWith = NSLayoutConstraint(item: selectedButton,
                                         attribute: .Width,
                                         relatedBy: .Equal,
                                         toItem: imageView,
                                         attribute: .Width,
                                         multiplier: 0.3,
                                         constant: 0.0)
        let btnHeight = NSLayoutConstraint(item: selectedButton,
                                           attribute: .Height,
                                           relatedBy: .Equal,
                                           toItem: imageView,
                                           attribute: .Height,
                                           multiplier: 0.3,
                                           constant: 0.0)
        let btnTop = NSLayoutConstraint(item: selectedButton,
                                        attribute: .Top,
                                        relatedBy: .Equal,
                                        toItem: imageView,
                                        attribute: .Top,
                                        multiplier: 1.0,
                                        constant: 0.0)
        let btnRight = NSLayoutConstraint(item: selectedButton,
                                          attribute: .Right,
                                          relatedBy: .Equal,
                                          toItem: imageView,
                                          attribute: .Right,
                                          multiplier: 1.0,
                                          constant: 0.0)
        
        NSLayoutConstraint.activateConstraints(imgViewHs)
        NSLayoutConstraint.activateConstraints(imgViewVs)
        NSLayoutConstraint.activateConstraints([btnHeight, btnWith, btnTop, btnRight])
    }
    
    
    // MARK: - Target actions
    
    func didClickSelectedButton(sender: UIButton) {
        delegate?.didClickPhotoGridCell(selectedButton: sender, representedAssetIdentfier: restorationIdentifier)
    }
    
}

extension UICollectionView {
    
    func lw_indexPathsForElementsInRect(rect: CGRect) -> [NSIndexPath]? {
        guard let allLayoutAttributes = collectionViewLayout.layoutAttributesForElementsInRect(rect) where allLayoutAttributes.count > 0 else { return nil }
        
        var indexPaths = [NSIndexPath]()
        for layoutAttributes in allLayoutAttributes {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        return indexPaths
    }
    
}


