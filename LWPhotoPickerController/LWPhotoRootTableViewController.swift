//
//  LWPhotoRootTableViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import Photos

private let CellIdentifier = "LWPhotoRootCell"
private let CellHeight: CGFloat = 60.0


class LWPhotoRootTableViewController: UITableViewController {

    
    // MARK: Properties
    
    var maxSelectedCount: UInt = 1
    private var smartLibrarys = [[String : PHFetchResult]]()
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register table view cell
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
    
        setupNavigationBar()
        fetchAssetCollections()
    }
    
    
    private func setupNavigationBar() {
        // Add cancel item
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .Cancel,
                                         target: self,
                                         action: #selector(LWPhotoRootTableViewController.dismiss))
        navigationItem.leftBarButtonItem = cancelItem
        navigationController?.navigationBar.tintColor = UIColor.darkGrayColor()
    }

    private func fetchAssetCollections() {
        
        let smartAssetCollections = PHAssetCollection.fetchAssetCollectionsWithType(.SmartAlbum,
                                                                                    subtype: .AlbumRegular,
                                                                                    options: nil)
        for index in 0..<smartAssetCollections.count {
            if let collection = smartAssetCollections[index] as? PHAssetCollection {
                let fetchResult = PHAsset.fetchAssetsInAssetCollection(collection, options: nil)
                if let asset = fetchResult.firstObject as? PHAsset {
                    if asset.mediaType == .Image {
                        let localizedTitle = (collection.localizedTitle ?? "") + "(" + "\(fetchResult.count)" + ")"
                        smartLibrarys.append([localizedTitle : fetchResult])
                    }
                }
            }
        }
    }
    
    deinit {
        print("LWPhotoRootTableViewController deinit")
    }
    
    
    // MARK: - Target actions
    
    func dismiss() {
        NSNotificationCenter.defaultCenter().postNotificationName(kDidDoneSelectedAssetsNotification, object: nil)
    }
    
    
    // MARK: - Table view data source


    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return smartLibrarys.count
    }

    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(CellIdentifier, forIndexPath: indexPath)
        
        cell.accessoryType = .DisclosureIndicator
        
        cell.textLabel?.text = smartLibrarys[indexPath.row].first?.0
        if let asset = smartLibrarys[indexPath.row].first?.1.firstObject as? PHAsset {
            let scale = UIScreen.mainScreen().scale
            let size = CGSize(width: CellHeight * scale, height: CellHeight * scale)
            
            PHImageManager.defaultManager().requestImageForAsset(asset,
                                                                 targetSize: size,
                                                                 contentMode: .AspectFill,
                                                                 options: nil,
                                                                 resultHandler: {
                                                                    (image: UIImage?, info: [NSObject : AnyObject]?) in
                                                                    
                                                                    cell.imageView?.image = image
                                                                    cell.setNeedsLayout()
            })
        }
        
        
        return cell
    }
    
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return CellHeight
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        showPhotoGridViewController(selectedIndex: indexPath.row)
    }
    
    
    // MARK: - Helper methods
    
    private func showPhotoGridViewController(selectedIndex index: Int) {
        
        let photoGridViewController = LWPhotoGridViewController()
        photoGridViewController.maxSelectedCount = maxSelectedCount
        photoGridViewController.title = smartLibrarys[index].first?.0
        photoGridViewController.assetResult = smartLibrarys[index].first!.1
        navigationController?.showViewController(photoGridViewController, sender: self)
    }
    
    
    
}


