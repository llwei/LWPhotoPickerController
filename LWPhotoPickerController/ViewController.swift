//
//  ViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private lazy var photoPicker: LWPhotoPickerController = {
        return LWPhotoPickerController()
    }()
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    
    // MARK: - Target actions
    
    @IBAction func showPhotoLibrary(sender: UIButton) {
        
        photoPicker.presentFromViewController(self, maxSelectedCount: 4) {
            [unowned self] (imageDatas) in
            
            print(imageDatas.count)
            if let data = imageDatas.first {
                print(data.length)
                self.imageView.image = UIImage(data: data)
            }
        }
    }


}

