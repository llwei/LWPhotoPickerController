//
//  LWPhotoRootTableViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  https://github.com/llwei/LWPhotoPickerController

import UIKit
import Photos

private let CellIdentifier = "LWPhotoRootCell"
private let CellHeight: CGFloat = 60.0


class LWPhotoRootTableViewController: UITableViewController {

    
    // MARK: Properties
    
    var maxSelectedCount: UInt = 1
    fileprivate var smartLibrarys = [[String : PHFetchResult<AnyObject>]]()
    
    
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Register table view cell
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CellIdentifier)
    
        setupNavigationBar()
        fetchAssetCollections()
    }
    
    
    fileprivate func setupNavigationBar() {
        // Add cancel item
        let cancelItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                         target: self,
                                         action: #selector(LWPhotoRootTableViewController.dismissSelf))
        navigationItem.leftBarButtonItem = cancelItem
        navigationController?.navigationBar.tintColor = UIColor.darkGray
    }

    fileprivate func fetchAssetCollections() {
        
        let smartAssetCollections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum,
                                                                            subtype: .albumRegular,
                                                                            options: nil)
        for index in 0..<smartAssetCollections.count {
            let collection = smartAssetCollections[index]
            let fetchResult = PHAsset.fetchAssets(in: collection, options: nil)
            if let asset = fetchResult.firstObject {
                if asset.mediaType == .image {
                    let localizedTitle = (collection.localizedTitle ?? "") + "(" + "\(fetchResult.count)" + ")"
                    smartLibrarys.append([localizedTitle : fetchResult as! PHFetchResult<AnyObject>])
                }
            }
            
        }
    }
    
    deinit {
        print("LWPhotoRootTableViewController deinit")
    }
    
    
    // MARK: - Target actions
    
    func dismissSelf() {
        NotificationCenter.default.post(name: Notification.Name(rawValue: kDidDoneSelectedAssetsNotification), object: nil)
    }
    
    
    // MARK: - Table view data source


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return smartLibrarys.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier, for: indexPath)
        
        cell.accessoryType = .disclosureIndicator
        
        cell.textLabel?.text = smartLibrarys[(indexPath as NSIndexPath).row].first?.0
        if let asset = smartLibrarys[(indexPath as NSIndexPath).row].first?.1.firstObject as? PHAsset {
            let scale = UIScreen.main.scale
            let size = CGSize(width: CellHeight * scale, height: CellHeight * scale)
            
            PHImageManager.default().requestImage(for: asset,
                                                  targetSize: size,
                                                  contentMode: .aspectFill,
                                                  options: nil,
                                                  resultHandler: {
                                                    (image: UIImage?, info: [AnyHashable: Any]?) in
                                                        cell.imageView?.image = image
                                                        cell.setNeedsLayout()
            })
        }
        
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CellHeight
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        showPhotoGridViewController(selectedIndex: (indexPath as NSIndexPath).row)
    }
    
    
    // MARK: - Helper methods
    
    fileprivate func showPhotoGridViewController(selectedIndex index: Int) {
        
        let photoGridViewController = LWPhotoGridViewController()
        photoGridViewController.maxSelectedCount = maxSelectedCount
        photoGridViewController.title = smartLibrarys[index].first?.0
        photoGridViewController.assetResult = smartLibrarys[index].first!.1
        navigationController?.show(photoGridViewController, sender: self)
    }
    
    
    
}


