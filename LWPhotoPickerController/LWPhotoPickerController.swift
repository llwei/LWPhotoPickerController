//
//  LWPhotoPickerController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//
//  https://github.com/llwei/LWPhotoPickerController

import UIKit
import Photos

private let AlertTitle = NSLocalizedString("错误", comment: "")
private let AlertMessage = NSLocalizedString("该应用未获取访问相册的权限", comment: "")
private let AlertOk = NSLocalizedString("确定", comment: "")
private let AlertSetting = NSLocalizedString("设置", comment: "")
let OriginalTitle = NSLocalizedString("原图", comment: "")
let DoneTitle = NSLocalizedString("完成", comment: "")

let kDidDoneSelectedAssetsNotification = "kDidDoneSelectedAssetsNotification"
typealias DidDoneSelectedAssetHandler = ((_ imageDatas: [Data]) -> Void)
private var PhotoPickerQueue = "PhotoPickerQueue"


class LWPhotoPickerController: NSObject {
    
    // MARK: - Properties
    
    fileprivate var authorizd: Bool = true
    fileprivate let queue: DispatchQueue = DispatchQueue(label: PhotoPickerQueue, attributes: [])
    fileprivate var didDoneHandler: DidDoneSelectedAssetHandler?
    fileprivate var navigationController: UINavigationController?
    
    
    // MARK: - Life cycle
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(LWPhotoPickerController.doneSelectedAssetsNotification(_:)),
                                               name: NSNotification.Name(rawValue: kDidDoneSelectedAssetsNotification),
                                               object: nil)
    }
    
    
    // Check Photo authorization status
    fileprivate func checkAuthorizationStatus() {
        
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            authorizd = true
        case .notDetermined:
            queue.suspend()
            PHPhotoLibrary.requestAuthorization({
                (status: PHAuthorizationStatus) in
                
                if status != .authorized {
                    self.authorizd = false
                }
                self.queue.resume()
            })
        default:
            authorizd = false
            showAuthorizationAlert()
        }
    }

    
    // Show alert if authorization status is not .Authorized,
    fileprivate func showAuthorizationAlert() {
    
        let alertController = UIAlertController(title: AlertTitle,
                                                message: AlertMessage,
                                                preferredStyle: .alert)
        let okAction = UIAlertAction(title: AlertOk,
                                     style: .cancel,
                                     handler: nil)
        let settingAction = UIAlertAction(title: AlertSetting,
                                          style: .default) { (_) in
                                            OperationQueue.main.addOperation({ 
                                                 UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
                                            })
        }
        
        alertController.addAction(okAction)
        alertController.addAction(settingAction)
        
        let rootVC = UIApplication.shared.keyWindow?.rootViewController
        rootVC?.present(alertController, animated: true, completion: nil)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("LWPhotoPickerController deinit")
    }
    
    
    // MARK: - Notification
    
    func doneSelectedAssetsNotification(_ notification: Notification) {
        
        if let datas = notification.object as? [Data] {
            didDoneHandler?(datas)
        }
        
        navigationController?.dismiss(animated: true, completion: nil)
        navigationController = nil
    }
    
    
    // MARK: - Public methods
    
    /**
     弹出图片选择器
     
     - parameter count:             选择图片数量的最大值
     - parameter completionHandler: 结束回调
     */
    func show(withMaxSelectedCount count: UInt, completionHandler: DidDoneSelectedAssetHandler?) {
    
        checkAuthorizationStatus()
        
        queue.async {
            DispatchQueue.main.async(execute: {
                guard self.authorizd else { return }
                
                // Initial root table view controller
                let photoRootTVC = LWPhotoRootTableViewController()
                photoRootTVC.maxSelectedCount = count
                
                // Present vc
                self.navigationController = UINavigationController(rootViewController: photoRootTVC)
                if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
                    rootVC.present(self.navigationController!, animated: true, completion: nil)
                }
            })
        }
        
        didDoneHandler = completionHandler
    }
    
    
    
    
}
