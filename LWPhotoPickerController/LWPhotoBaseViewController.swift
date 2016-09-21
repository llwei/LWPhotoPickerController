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

private let ScreenWidth = UIScreen.main.bounds.size.width
private let ScreenHeight = UIScreen.main.bounds.size.height

class LWPhotoBaseViewController: UIViewController {

    var maxSelectedCount: UInt = 1
    var assetResult: PHFetchResult<AnyObject>?
    var original: Bool = false
    var selectedRestorationId = [String]()
    var doneItem: UIBarButtonItem!
    
    func didClickDoneItemAction() {
        guard let assetResult = assetResult , selectedRestorationId.count > 0 else { return }
        
        var results = [Data]()
        var storeCount: Int = 0
        
        let option = PHImageRequestOptions()
        option.isSynchronous = true

        for i in 0..<assetResult.count {
            if let asset = assetResult[i] as? PHAsset {
                if selectedRestorationId.contains(asset.localIdentifier) {

                    let manager = PHImageManager.default()
                    manager.requestImageData(for: asset,
                                                     options: option,
                                                     resultHandler: { (data: Data?, _, _, _) in
                                                        
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
                                                            NotificationCenter.default.post(name: Notification.Name(rawValue: kDidDoneSelectedAssetsNotification), object: results)
                                                        }
                    })
                }
            }
        }
    }
    
    func activityIndicator() -> UIActivityIndicatorView {
        
        let indicator = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        indicator.startAnimating()
        
        return indicator
    }
    
    
}
