//
//  LWPhotoBaseViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/15.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import Photos

private let ScreenWidth = UIScreen.mainScreen().bounds.size.width
private let ScreenHeight = UIScreen.mainScreen().bounds.size.height

class LWPhotoBaseViewController: UIViewController {

    var maxSelectedCount: UInt = 1
    var assetResult: PHFetchResult?
    var original: Bool = false
    var selectedRestorationId = [String]()

    
    func didClickDoneItemAction() {
        guard let assetResult = assetResult where selectedRestorationId.count > 0 else { return }
        
        var results = [NSData]()
        var storeCount: Int = 0
        
        let option = PHImageRequestOptions()
        option.synchronous = true
        option.version = .Original
        
        for i in 0..<assetResult.count {
            if let asset = assetResult[i] as? PHAsset {
                if selectedRestorationId.contains(asset.localIdentifier) {
                    let size: CGSize = original ? PHImageManagerMaximumSize : CGSize(width: CGFloat(asset.pixelWidth) / 3, height: CGFloat(asset.pixelHeight) / 3)
                    
                    let manager = PHImageManager.defaultManager()
                    manager.requestImageForAsset(asset,
                                                 targetSize: size,
                                                 contentMode: .Default,
                                                 options: option,
                                                 resultHandler: { (image: UIImage?, info: [NSObject : AnyObject]?) in
                                                    
                                                    if let data = UIImageJPEGRepresentation(image!, 1.0) {
                                                        results.append(data)
                                                        storeCount += 1
                                                        if storeCount == self.selectedRestorationId.count {
                                                            NSNotificationCenter.defaultCenter().postNotificationName(kDidDoneSelectedAssetsNotification, object: results)
                                                        }
                                                    }
                    })
                    
//                    manager.requestImageDataForAsset(asset,
//                                                     options: option,
//                                                     resultHandler: { (data: NSData?, _, _, _) in
//                                                        if let data = data {
//                                                            results.append(data)
//                                                            storeCount += 1
//                                                            if storeCount == self.selectedRestorationId.count {
//                                                                NSNotificationCenter.defaultCenter().postNotificationName(kDidDoneSelectedAssetsNotification, object: results)
//                                                            }
//                                                        }
//                    })
                }
            }
        }
    }
    
    /*
     6218385
     7580506
     
     1980798
     */
    
}
