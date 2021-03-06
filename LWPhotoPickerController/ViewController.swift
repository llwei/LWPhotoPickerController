//
//  ViewController.swift
//  LWPhotoPickerController
//
//  Created by lailingwei on 16/6/13.
//  Copyright © 2016年 lailingwei. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    fileprivate lazy var photoPicker: LWPhotoPickerController = {
        return LWPhotoPickerController()
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // MARK: - Target actions
    
    @IBAction func showPhotoLibrary(_ sender: UIButton) {
        
        photoPicker.show(withMaxSelectedCount: 9) {
            [unowned self] (imageDatas) in
            
            print(imageDatas.count)
            if let data = imageDatas.first {
                print(data.count)
                self.imageView.image = UIImage(data: data as Data)
            }
        }

    }


}

