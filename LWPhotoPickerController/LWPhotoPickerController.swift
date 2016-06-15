//
//  LWPhotoPickerController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit
import Photos

let kDidDoneSelectedAssetsNotification = "kDidDoneSelectedAssetsNotification"
typealias DidDoneSelectedAssetHandler = ((imageDatas: [NSData]) -> Void)

private let AlertTitle = NSLocalizedString("Photo Error", comment: "")
private let AlertMessage = NSLocalizedString("This app is not authorized to use Photo", comment: "")
private let AlertOk = NSLocalizedString("Cancel", comment: "")
private let AlertSetting = NSLocalizedString("Settings", comment: "")


private var PhotoPickerQueue = "PhotoPickerQueue"

class LWPhotoPickerController: NSObject {
    
    // MARK: - Properties
    
    private var authorizd: Bool = true
    private let queue: dispatch_queue_t = dispatch_queue_create(PhotoPickerQueue, DISPATCH_QUEUE_SERIAL)
    private var didDoneHandler: DidDoneSelectedAssetHandler?
    private var navigationController: UINavigationController?
    
    
    // MARK: - Life cycle
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector: #selector(LWPhotoPickerController.doneSelectedAssetsNotification(_:)),
                                                         name: kDidDoneSelectedAssetsNotification,
                                                         object: nil)
    }
    
    
    // Check Photo authorization status
    private func checkAuthorizationStatus() {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .Authorized:
            authorizd = true
        case .NotDetermined:
            dispatch_suspend(queue)
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) in
                if status != .Authorized {
                    self.authorizd = false
                }
                dispatch_resume(self.queue)
            })
        default:
            authorizd = false
            showAuthorizationAlert()
        }
    }

    
    // Show alert if authorization status is not .Authorized,
    private func showAuthorizationAlert() {
    
        let alertController = UIAlertController(title: AlertTitle,
                                                message: AlertMessage,
                                                preferredStyle: .Alert)
        let okAction = UIAlertAction(title: AlertOk,
                                     style: .Cancel,
                                     handler: nil)
        let settingAction = UIAlertAction(title: AlertSetting,
                                          style: .Default) { (_) in
                                            
                                            NSOperationQueue.mainQueue().addOperationWithBlock({ 
                                                 UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
                                            })
        }
        
        alertController.addAction(okAction)
        alertController.addAction(settingAction)
        
        let rootVC = UIApplication.sharedApplication().keyWindow?.rootViewController
        rootVC?.presentViewController(alertController, animated: true, completion: nil)
    }
    
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("LWPhotoPickerController deinit")
    }
    
    
    // MARK: - Notification
    
    func doneSelectedAssetsNotification(notification: NSNotification) {
        
        if let datas = notification.object as? [NSData] {
            didDoneHandler?(imageDatas: datas)
        }
        
        navigationController?.dismissViewControllerAnimated(true, completion: nil)
        navigationController = nil
    }
    
    
    // MARK: - Public methods
    
    func presentFromViewController(fromVC: UIViewController,
                                   maxSelectedCount count: UInt,
                                                    completionHandler: DidDoneSelectedAssetHandler?) {
    
        checkAuthorizationStatus()
        
        dispatch_async(queue) {
            dispatch_async(dispatch_get_main_queue(), {
                guard self.authorizd else { return }
                
                // Initial root table view controller
                let photoRootTVC = LWPhotoRootTableViewController()
                photoRootTVC.maxSelectedCount = count
                
                // Present vc
                self.navigationController = UINavigationController(rootViewController: photoRootTVC)
                fromVC.presentViewController(self.navigationController!, animated: true, completion: nil)
            })
        }
        
        didDoneHandler = completionHandler
    }
    
    
    
    
}