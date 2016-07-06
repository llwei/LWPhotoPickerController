//
//  LWPhotoBaseViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/15.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  https://github.com/llwei/LWPhotoPickerController

import UIKit
import Photos

private let ScreenWidth = UIScreen.mainScreen().bounds.size.width
private let ScreenHeight = UIScreen.mainScreen().bounds.size.height

class LWPhotoBaseViewController: UIViewController {

    var maxSelectedCount: UInt = 1
    var assetResult: PHFetchResult?
    var original: Bool = false
    var selectedRestorationId = [String]()
    var doneItem: UIBarButtonItem!
    
    func didClickDoneItemAction() {
        guard let assetResult = assetResult where selectedRestorationId.count > 0 else { return }
        
        var results = [NSData]()
        var storeCount: Int = 0
        
        let option = PHImageRequestOptions()
        option.synchronous = true

        for i in 0..<assetResult.count {
            if let asset = assetResult[i] as? PHAsset {
                if selectedRestorationId.contains(asset.localIdentifier) {

                    let manager = PHImageManager.defaultManager()
                    manager.requestImageDataForAsset(asset,
                                                     options: option,
                                                     resultHandler: { (data: NSData?, _, _, _) in
                                                        
                                                        if let data = data {
                                                            if self.original {
                                                                results.append(data)
                                                            } else {
                                                                if let image = UIImage(data: data) {
                                                                    if let imageData = UIImageJPEGRepresentation(image, 0.5) {
                                                                        results.append(imageData)
                                                                    }
                                                                }
                                                            }
                                                        }
                                                        storeCount += 1
                                                        if storeCount == self.selectedRestorationId.count {
                                                            NSNotificationCenter.defaultCenter().postNotificationName(kDidDoneSelectedAssetsNotification, object: results)
                                                        }
                    })
                }
            }
        }
    }
    
    func activityIndicator() -> UIActivityIndicatorView {
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        indicator.startAnimating()
        
        return indicator
    }
    
    
}
