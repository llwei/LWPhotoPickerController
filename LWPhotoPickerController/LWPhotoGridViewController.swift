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
private let Scale: CGFloat = UIScreen.main.scale
private let ScreenWidth = UIScreen.main.bounds.size.width
private let ScreenHeight = UIScreen.main.bounds.size.height

private let HoriCount: Int = 4


class LWPhotoGridViewController: LWPhotoBaseViewController, UICollectionViewDataSource, UICollectionViewDelegate, LWPhotoGridCellDelegate {

    
    // MARK: - Properties
    
    fileprivate let imageManager = PHCachingImageManager()
    fileprivate var originalItem: UIBarButtonItem!
    fileprivate var collectionView: UICollectionView!
    
   
    fileprivate var previousPreheatRect = CGRect.zero
    
    
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
    

    
    fileprivate func setuplNavigationBar() {
        // Add cancel item
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                         target: self,
                                         action: #selector(LWPhotoGridViewController.dismissSelf))
        navigationItem.rightBarButtonItem = cancelItem
    }
    
    
    fileprivate func initialCollectionView() -> UICollectionView {
    
        // Flow layout
        let flowLayout = UICollectionViewFlowLayout()
        let size = (ScreenWidth - CGFloat(HoriCount + 1)) / CGFloat(HoriCount)
        flowLayout.itemSize = CGSize(width: size, height: size)
        flowLayout.minimumLineSpacing = 1.0
        flowLayout.minimumInteritemSpacing = 1.0
        flowLayout.scrollDirection = .vertical
        
        // UICollectionView
        let collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = UIColor.white
        collectionView.dataSource = self
        collectionView.delegate = self
        
        // Register cell class
        collectionView.register(LWPhotoGridCell.self, forCellWithReuseIdentifier: CellIdentifier)
        
        return collectionView
    }
    
    
    fileprivate func initialToolBar() -> UIToolbar {
    
        // Toolbar
        let toolBar = UIToolbar(frame: CGRect.zero)
        toolBar.backgroundColor = UIColor.groupTableViewBackground
        
        // Original item
        let originalItem = UIBarButtonItem(title: OriginalTitle,
                                           style: .done,
                                           target: self,
                                           action: #selector(LWPhotoGridViewController.originalItemWasClick(_:)))
        originalItem.tintColor = UIColor.lightGray
        self.originalItem = originalItem
        
        // Space item
        let spaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace,
                                        target: self,
                                        action: nil)
        // Done item
        let doneItem = UIBarButtonItem(title: DoneTitle,
                                       style: .done,
                                       target: self,
                                       action: #selector(LWPhotoGridViewController.didClickDoneItemAction))
        
        doneItem.isEnabled = false
        doneItem.tintColor = UIColor.orange
        self.doneItem = doneItem
        toolBar.setItems([originalItem, spaceItem, doneItem], animated: true)
        toolBar.tintColor = UIColor.darkGray
        
        return toolBar
    }
    
    
    fileprivate func layout(withCollectionView collectionView: UICollectionView, toolBar: UIToolbar) {
        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        toolBar.translatesAutoresizingMaskIntoConstraints = false
        
        let cHoriConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[collectionView]|",
                                                                              options: NSLayoutFormatOptions(),
                                                                              metrics: nil,
                                                                              views: ["collectionView" : collectionView])
        let tHoriConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[toolBar]|",
                                                                              options: NSLayoutFormatOptions(),
                                                                              metrics: nil,
                                                                              views: ["toolBar" : toolBar])
        let vertConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[collectionView][toolBar(==44)]|",
                                                                             options: NSLayoutFormatOptions(),
                                                                             metrics: ["44" : 44],
                                                                             views: ["toolBar" : toolBar, "collectionView" : collectionView])
        
        NSLayoutConstraint.activate(cHoriConstraints)
        NSLayoutConstraint.activate(tHoriConstraints)
        NSLayoutConstraint.activate(vertConstraints)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Begin caching assets in and around collection view's visible rect.
        updateCachedAssets()
    }
    
    
    deinit {
        print("LWPhotoGridViewController deinit")
    }
    
    // MARK: - Target actions
    
    func dismissSelf() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: kDidDoneSelectedAssetsNotification), object: nil)
    }
    
    
    func originalItemWasClick(_ sender: UIBarButtonItem) {
        
        original = !original
        if original {
            sender.tintColor = UIColor.orange
        } else {
            sender.tintColor = UIColor.lightGray
        }
    }
    
 
    
    
    func didClickPhotoGridCell(selectedButton button: UIButton, representedAssetIdentfier identifier: String?) {
        guard let identifier = identifier , selectedRestorationId.count < Int(maxSelectedCount) || button.isSelected else { return }
        
        button.isSelected = !button.isSelected
        
        // Update selectedRestorationId
        if button.isSelected {
            selectedRestorationId.append(identifier)
        } else {
            selectedRestorationId = selectedRestorationId.filter( { $0 != identifier} )
        }
        
        // Update doneItem
        doneItem.isEnabled = selectedRestorationId.count > 0
        doneItem.title = DoneTitle + (doneItem.isEnabled ? "(" + "\(selectedRestorationId.count)" + ")" : "")
    }

    
    
    // MARK: - Helper methods
    
    fileprivate func updateCachedAssets() {
        guard isViewLoaded && view.window != nil else { return }
        
        // The preheat window is twice the height of the visible rect
        var preheatRect = collectionView.bounds
        preheatRect = preheatRect.insetBy(dx: 0.0, dy: -0.5 * preheatRect.height)
        
        // Check if the collection view is showing an area that is significantly different to the last preheated area
        let delta = abs(Int32(preheatRect.midY) - Int32(previousPreheatRect.midY))
        if delta > Int32(collectionView.bounds.height / 3) {
            // Compute the assets to start caching and to stop caching.
            var addedIndexPaths = [IndexPath]()
            var removedIndexPaths = [IndexPath]()
            
            computeDifferenceBetweenRect(previousPreheatRect,
                                         andRect: preheatRect,
                                         removedHandler: { [unowned self] (removedRect) in
                                            
                                            if let indexPaths = self.collectionView.lw_indexPathsForElementsInRect(removedRect) {
                                                removedIndexPaths.append(contentsOf: indexPaths)
                                            }
                                            
                }, addedHandler: { [unowned self] (addedRect) in
                    
                    if let indexPaths = self.collectionView.lw_indexPathsForElementsInRect(addedRect) {
                        addedIndexPaths.append(contentsOf: indexPaths)
                    }
            })
            
            // Update the assets the PHCachingImageManager is caching
            let layoutSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            let size = CGSize(width: layoutSize.width * Scale, height: layoutSize.height * Scale)
            
            if let assetsToStartCaching = assetsAtIndexPaths(addedIndexPaths) {
                imageManager.startCachingImages(for: assetsToStartCaching,
                                                         targetSize: size,
                                                         contentMode: .aspectFill,
                                                         options: nil)
            }
            if let assetsToStopCaching = assetsAtIndexPaths(removedIndexPaths) {
                imageManager.stopCachingImages(for: assetsToStopCaching,
                                                        targetSize: size,
                                                        contentMode: .aspectFill,
                                                        options: nil)
            }
            
            // Store the preheat rect to compare against in the future
            previousPreheatRect = preheatRect
        }
    }
    
    fileprivate func computeDifferenceBetweenRect(_ oldRect: CGRect,
                                              andRect newRect: CGRect,
                                                      removedHandler: ((_ removedRect: CGRect) -> Void)?,
                                                      addedHandler: ((_ addedRect: CGRect) -> Void)?) {
        
        if newRect.intersects(oldRect) {
            let oldMaxY = oldRect.maxY
            let oldMinY = oldRect.minX
            let newMaxY = newRect.maxY
            let newMinY = newRect.minX
            
            if newMaxY > oldMaxY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: newMaxY - oldMinY)
                addedHandler?(rectToAdd)
            }
            
            if newMinY > oldMinY  {
                let rectToRemove = CGRect(x: newRect.origin.x, y: oldMinY, width: newRect.size.width, height: newMinY - oldMinY)
                removedHandler?(rectToRemove)
            }
            
            if newMaxY < oldMaxY {
                let rectToRemove = CGRect(x: newRect.origin.x, y: newMaxY, width: newRect.size.width, height: oldMaxY - newMaxY)
                removedHandler?(rectToRemove)
            }
            
            if newMinY < oldMinY {
                let rectToAdd = CGRect(x: newRect.origin.x, y: newMinY, width: newRect.size.width, height: oldMinY - newMinY)
                addedHandler?(rectToAdd)
            }
            
        } else {
            addedHandler?(newRect)
            removedHandler?(oldRect)
        }
    }
    
    
    fileprivate func assetsAtIndexPaths(_ indexPaths: [IndexPath]) -> [PHAsset]? {
        guard indexPaths.count > 0 else { return nil }
        
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            if let asset = assetResult?[(indexPath as NSIndexPath).item] as? PHAsset {
                assets.append(asset)
            }
        }

        return assets
    }
    
    fileprivate func updateOriginalTitle() {
        
    }
    
    
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return assetResult?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CellIdentifier, for: indexPath) as! LWPhotoGridCell
        
        cell.delegate = self
        
        if let asset = assetResult?[(indexPath as NSIndexPath).row] as? PHAsset {
            cell.restorationIdentifier = asset.localIdentifier
            cell.didSelected = selectedRestorationId.contains(asset.localIdentifier)
            
            let layoutSize = (collectionView.collectionViewLayout as! UICollectionViewFlowLayout).itemSize
            let size = CGSize(width: layoutSize.width * Scale, height: layoutSize.height * Scale)
            
            imageManager.requestImage(for: asset,
                                              targetSize: size,
                                              contentMode: .aspectFill,
                                              options: nil,
                                              resultHandler: {
                                                (image: UIImage?, info: [AnyHashable: Any]?) in
                                                
                                                if cell.restorationIdentifier == asset.localIdentifier {
                                                    cell.thumbnailImage = image
                                                }
            })
        }
        
        
        return cell
    }

    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let photoBrowseVC = LWPhotoBrowseViewController()
        photoBrowseVC.maxSelectedCount = maxSelectedCount
        photoBrowseVC.assetResult = assetResult
        photoBrowseVC.currentIndex = (indexPath as NSIndexPath).item
        photoBrowseVC.selectedRestorationId = selectedRestorationId
        photoBrowseVC.original = original
        show(photoBrowseVC, sender: self)
        
        photoBrowseVC.updateSelectedMarkHandler { (add, restorationId, indexPath) in
            // Update selectedRestorationId
            if add {
                self.selectedRestorationId.append(restorationId)
            } else {
                self.selectedRestorationId = self.selectedRestorationId.filter( { $0 != restorationId} )
            }
            self.collectionView.reloadItems(at: [indexPath as IndexPath])
            
            // Update doneItem
            self.doneItem.isEnabled = self.selectedRestorationId.count > 0
            self.doneItem.title = DoneTitle + (self.doneItem.isEnabled ? "(" + "\(self.selectedRestorationId.count)" + ")" : "")
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateCachedAssets()
    }
    
}


protocol LWPhotoGridCellDelegate: class {
    func didClickPhotoGridCell(selectedButton button: UIButton, representedAssetIdentfier identifier: String?)
}


class LWPhotoGridCell: UICollectionViewCell {

    
    // MARK: - Properties
    
    fileprivate let imageView = UIImageView()
    fileprivate let selectedButton = UIButton(type: .custom)

    weak var delegate: LWPhotoGridCellDelegate?
    var representedAssetIdentifier: String?
    var thumbnailImage: UIImage? {
        didSet {
            imageView.image = thumbnailImage
        }
    }
    var didSelected: Bool = false {
        didSet {
            selectedButton.isSelected = didSelected
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
    
    fileprivate func setupSubviews() {
    
        // Image view
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        contentView.addSubview(imageView)
        
        // Selected button
        selectedButton.setBackgroundImage(UIImage(named: "LWPhotoPickerController.bundle/Resources/AGIPC-Checkmark-0.png"), for: UIControlState())
        selectedButton.setBackgroundImage(UIImage(named: "LWPhotoPickerController.bundle/Resources/AGIPC-Checkmark-1,png"), for: .selected)
        selectedButton.addTarget(self,
                                 action: #selector(LWPhotoGridCell.didClickSelectedButton(_:)),
                                 for: .touchUpInside)
        contentView.addSubview(selectedButton)
        
        addConstranints()
    }
    
    fileprivate func addConstranints() {
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        selectedButton.translatesAutoresizingMaskIntoConstraints = false
        
        let imgViewHs = NSLayoutConstraint.constraints(withVisualFormat: "H:|[imageView]|",
                                                                       options: NSLayoutFormatOptions(),
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        let imgViewVs = NSLayoutConstraint.constraints(withVisualFormat: "V:|[imageView]|",
                                                                       options: NSLayoutFormatOptions(),
                                                                       metrics: nil,
                                                                       views: ["imageView" : imageView])
        let btnWith = NSLayoutConstraint(item: selectedButton,
                                         attribute: .width,
                                         relatedBy: .equal,
                                         toItem: imageView,
                                         attribute: .width,
                                         multiplier: 0.3,
                                         constant: 0.0)
        let btnHeight = NSLayoutConstraint(item: selectedButton,
                                           attribute: .height,
                                           relatedBy: .equal,
                                           toItem: imageView,
                                           attribute: .height,
                                           multiplier: 0.3,
                                           constant: 0.0)
        let btnTop = NSLayoutConstraint(item: selectedButton,
                                        attribute: .top,
                                        relatedBy: .equal,
                                        toItem: imageView,
                                        attribute: .top,
                                        multiplier: 1.0,
                                        constant: 0.0)
        let btnRight = NSLayoutConstraint(item: selectedButton,
                                          attribute: .right,
                                          relatedBy: .equal,
                                          toItem: imageView,
                                          attribute: .right,
                                          multiplier: 1.0,
                                          constant: 0.0)
        
        NSLayoutConstraint.activate(imgViewHs)
        NSLayoutConstraint.activate(imgViewVs)
        NSLayoutConstraint.activate([btnHeight, btnWith, btnTop, btnRight])
    }
    
    
    // MARK: - Target actions
    
    func didClickSelectedButton(_ sender: UIButton) {
        delegate?.didClickPhotoGridCell(selectedButton: sender, representedAssetIdentfier: restorationIdentifier)
    }
    
}

extension UICollectionView {
    
    func lw_indexPathsForElementsInRect(_ rect: CGRect) -> [IndexPath]? {
        guard let allLayoutAttributes = collectionViewLayout.layoutAttributesForElements(in: rect) , allLayoutAttributes.count > 0 else { return nil }
        
        var indexPaths = [IndexPath]()
        for layoutAttributes in allLayoutAttributes {
            let indexPath = layoutAttributes.indexPath
            indexPaths.append(indexPath)
        }
        return indexPaths
    }
    
}


