//
//  ViewController.swift
//  Swift-LongImage
//
//  Created by jingwei on 2025/7/29.
//

import UIKit
import Kingfisher

class ViewController: UIViewController {

    let img = UIImageView(frame: CGRect(x: 50, y: 100, width: 200, height: 200))

    override func viewDidLoad() {
        super.viewDidLoad()
        img.backgroundColor = .lightGray
        img.contentMode = .scaleAspectFill
        view.addSubview(img)
        KingfisherManager.shared.cache.clearCache()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let url = URL(string: "https://cx-yyz-1251125656.cos.ap-shanghai.myqcloud.com/10_1_8_190/Dynamic/6827109415774b5d45ef6432.jpeg")
        //img.kf.setImage(with: url)
        
        // 长图使用
        //img.kf.setImage(with: url, options: [.processor(GrayscaleImageProcessor(hwRatio: 1))])
        
        // 正常的图可以使用
        let processor = DownsamplingImageProcessor(size: CGSize(width: 800, height: 800))
        img.kf.setImage(with: url, placeholder: nil, options: [.processor(processor)])
    }
    
    
    /// 原图如果是1000 * 1000 我们写100 * 100 会生成100* 100 的位图
    func downsample(imageAt imageURL: URL, to pointSize: CGSize, scale: CGFloat) -> UIImage {
        let sourceOpt = [kCGImageSourceShouldCache : false] as CFDictionary
        // 其他场景可以用createwithdata (data并未decode,所占内存没那么大),
        let source = CGImageSourceCreateWithURL(imageURL as CFURL, sourceOpt)!
        
        let maxDimension = max(pointSize.width, pointSize.height) * scale
        let downsampleOpt = [kCGImageSourceCreateThumbnailFromImageAlways : true,
                                     kCGImageSourceShouldCacheImmediately : true ,
                               kCGImageSourceCreateThumbnailWithTransform : true,
                                      kCGImageSourceThumbnailMaxPixelSize : maxDimension] as CFDictionary
        let downsampleImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOpt)!
        
        return UIImage(cgImage: downsampleImage)
    }
    
}


struct GrayscaleImageProcessor: ImageProcessor {
    let identifier = "com.example.kingfisher.grayscale"

    public var hwRatio: CGFloat = 1

    public init(hwRatio: CGFloat) {
        self.hwRatio = hwRatio
    }
    
    func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
        switch item {
        case .image(let image):
            return image
        case .data(let data):
            if let image = setImage(withUndecodedData: data, hwRatio: self.hwRatio) {
                return image
            }
            return DefaultImageProcessor.default.process(item: item, options: options)
        @unknown default:
            return nil
        }
    }

    func setImage(withUndecodedData imageData: Data?, hwRatio: CGFloat) -> UIImage? {
        guard let imageData = imageData else { return nil }
        // 1. 创建图像源（不立即解码）
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        
        // 2. 获取原始图像的像素尺寸
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
              let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
            return nil
        }
        let cropRect = CGRect(x: 0, y: 0, width: pixelWidth, height: pixelWidth * hwRatio)
        
        // 4. 先获取完整图像（仅解码一次）
        guard let fullImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return nil }
        guard let croppedCGImage = fullImage.cropping(to: cropRect) else {
            return nil
        }
        let croppedImage = UIImage(cgImage: croppedCGImage, scale: UIScreen.main.scale, orientation: .up)
        return croppedImage
    }
}

/*
 class CYDynamicBaseImageView: AnimatedImageView {
     func setImageFid(_ fid: String?, sourceSize: CGSize?, showSize: CGSize) {
         guard let fid = fid else { return }
         let url = URL(string: imgUrl(fid))
         var hwRadio: CGFloat = 1
         if let sourceSize = sourceSize {
             hwRadio = sourceSize.height / sourceSize.width
         }
         let placeholder = UIImage(named: "dynamic_placeholder")
         if hwRadio > 3 || hwRadio < 0.33 {
             self.kf.setImage(with: url, placeholder: placeholder, options: [.processor(GrayscaleImageProcessor(showSize: showSize))])
         } else {
             if fid.lowercased().hasSuffix(".gif") {
                 self.kf.setImage(with: url, placeholder: placeholder)
             } else {
                 let processor = DownsamplingImageProcessor(size: CGSize(width: 800, height: 800))
                 self.kf.setImage(with: url, placeholder: placeholder, options: [.processor(processor)])
             }
         }
     }
     
     func imgUrl(_ fid: String) -> String {
         guard let cos = CYLoginInfoManager.share().serListModel?.cosUrl else { return fid }
         return cos + "/" + fid
     }
 }
 
 // 超长图/超宽图 显示
 struct GrayscaleImageProcessor: ImageProcessor {
     let identifier = "com.example.kingfisher.sizedecode"

     public var showSize: CGSize = CGSizeMake(1, 1)

     public init(showSize: CGSize) {
         self.showSize = showSize
     }
     
     func process(item: ImageProcessItem, options: KingfisherParsedOptionsInfo) -> KFCrossPlatformImage? {
         switch item {
         case .image(let image):
             return image
         case .data(let data):
             if let image = setImage(withUndecodedData: data, showSize: self.showSize) {
                 return image
             }
             return DefaultImageProcessor.default.process(item: item, options: options)
         @unknown default:
             return nil
         }
     }

     func setImage(withUndecodedData imageData: Data?, showSize: CGSize) -> UIImage? {
         guard let imageData = imageData else { return nil }
         guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
         guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
               let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
               let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
             return nil
         }
         // 计算与显示区域等比例的裁剪尺寸
         let aspectRatio = showSize.width / showSize.height
         var cropWidth = pixelWidth
         var cropHeight = pixelHeight

         // 根据宽高比调整裁剪尺寸，保持显示比例
         if aspectRatio > 1 {
             // 超宽图：以高度为基准计算宽度
             cropWidth = min(cropHeight * aspectRatio, pixelWidth)
         } else {
             // 超长图/正方形：以宽度为基准计算高度
             cropHeight = min(cropWidth / aspectRatio, pixelHeight)
         }

         let cropRect = CGRect(x: 0, y: 0, width: cropWidth, height: cropHeight)
         guard let fullImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return nil }
         guard let croppedCGImage = fullImage.cropping(to: cropRect) else {
             return nil
         }
         let croppedImage = UIImage(cgImage: croppedCGImage, scale: UIScreen.main.scale, orientation: .up)
         return croppedImage
     }
 }


