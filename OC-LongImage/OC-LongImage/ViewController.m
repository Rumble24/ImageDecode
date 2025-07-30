//
//  ViewController.m
//  OC-LongImage
//
//  Created by jingwei on 2025/7/28.
//

#import "ViewController.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "UIView+WebCache.h"
#import "FLAnimatedImage.h"
#import "SDWebImageDownloader.h"


@interface CYDynamicImageView : FLAnimatedImageView
@end
@implementation CYDynamicImageView
@end

@interface ViewController ()

@property (nonatomic, strong) CYDynamicImageView *imgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imgView = [[CYDynamicImageView alloc]init];
    self.imgView.backgroundColor = UIColor.lightGrayColor;
    self.imgView.contentMode = UIViewContentModeScaleAspectFill;
    self.imgView.frame = CGRectMake(50, 100, 200, 200);
    self.imgView.layer.masksToBounds = YES;
    [self.view addSubview:self.imgView];
    
    //[[SDWebImageManager sharedManager].imageCache clearWithCacheType:SDImageCacheTypeAll completion:nil];
}

/*
 1.直接使用 sd_setImageWithURL 解码占用大量内存 80m
 2.测试 sd_internal 解码占用大量内存 80m
 3.使用 自行解码 ok 占用8m内存
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSURL *url = [NSURL URLWithString:@"https://cx-yyz-1251125656.cos.ap-shanghai.myqcloud.com//10_1_8_190/Dynamic/687efe485892fc5a8e8d33d0.jpg"];
//    [self.imgView sd_setImageWithURL:url placeholderImage:nil];

//    [self.imgView sd_internalSetImageWithURL:url placeholderImage:nil options:0 context:nil setImageBlock:^(UIImage * _Nullable image, NSData * _Nullable imageData, SDImageCacheType cacheType, NSURL * _Nullable imageURL) {
//    } progress:nil completed:nil];
    
    SDWebImageDownloader *loader = [SDWebImageDownloader sharedDownloader];
    [loader requestImageWithURL:url options:0 context:nil progress:nil completed:^(UIImage * _Nullable image, NSData * _Nullable data, NSError * _Nullable error, BOOL finished) {
        CGFloat size = image.size.width;
        [self setImageWithUndecodedData:data cropRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    }];
}

- (void)setImageWithUndecodedData:(NSData *)imageData cropRect:(CGRect)cropRect {
    if (!imageData) return;
    
    // 后台线程处理，避免阻塞主线程
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        @autoreleasepool {
            // 1. 创建图像源（不立即解码）
            CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
            if (!imageSource) return;
        NSLog(@"---- 创建图像源（不立即解码）-----");
            
            // 2. 获取原始图像的像素尺寸
            CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
            NSNumber *widthNum = (__bridge NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth);
            NSNumber *heightNum = (__bridge NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight);
            CGFloat pixelWidth = [widthNum floatValue];
            CGFloat pixelHeight = [heightNum floatValue];
            CFRelease(properties);
            
            // 3. 计算裁剪区域（转换为像素坐标）
            CGRect pixelCropRect = CGRectMake(
                cropRect.origin.x,
                cropRect.origin.y,
                cropRect.size.width,
                cropRect.size.height
            );
            
            // 校验裁剪区域有效性
            if (pixelCropRect.origin.x < 0 || pixelCropRect.origin.y < 0 ||
                pixelCropRect.origin.x + pixelCropRect.size.width > pixelWidth ||
                pixelCropRect.origin.y + pixelCropRect.size.height > pixelHeight) {
                CFRelease(imageSource);
                return;
            }

            
//            // 5. 对完整图像进行裁剪
//            CGImageRef croppedCGImage = CGImageCreateWithImageInRect(fullImage, pixelCropRect);
//            CGImageRelease(fullImage); // 及时释放完整图像，减少内存占用
//            if (!croppedCGImage) return;
            

//            CGImageRelease(croppedCGImage);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            // 4. 兼容方案：先获取完整图像（仅解码一次）
            CGImageRef fullImage = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
            CFRelease(imageSource);
            if (!fullImage) return;
            NSLog(@"---- 先获取完整图像（仅解码一次）-----");

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // 6. 转换为 UIImage 并在主线程显示
                UIImage *croppedImage = [[UIImage alloc] initWithCGImage:fullImage
                                                                   scale:[UIScreen mainScreen].scale
                                                             orientation:UIImageOrientationUp];
                CGImageRelease(fullImage);
                NSLog(@"---- 转换为 UIImage 并在主线程显示）-----");

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    
                    UIImage *img = [croppedImage imageByPreparingForDisplay];
                    NSLog(@"---- imageByPreparingForDisplay-----");

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        dispatch_async(dispatch_get_main_queue(), ^{
                            self.imgView.image = img;
                        });
                    });
                });
                
                
                
            });
        });


//        }
    });
}
@end



