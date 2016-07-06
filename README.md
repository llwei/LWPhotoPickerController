# LWPhotoPickerController
基于Photos的图片多选器


Deployment Target 8.0
    
一、用法：
    
    // 1、初始化 LWPhotoPickerController
    private lazy var photoPicker: LWPhotoPickerController = {
        return LWPhotoPickerController()
    }()

    // 2、弹出显示 withMaxSelectedCount为图片的最大选择数量
    photoPicker.show(withMaxSelectedCount: 9) {
        [unowned self] (imageDatas) in

        if let data = imageDatas.first {
            self.imageView.image = UIImage(data: data)
        }
    }

![(logo)](http://code4app.com/data/attachment/forum/201607/06/193806ce5wjpq5atzot7sq.png)
![(logo)](http://code4app.com/data/attachment/forum/201607/06/194134anwzxsrhnsnu5ss6.png)
