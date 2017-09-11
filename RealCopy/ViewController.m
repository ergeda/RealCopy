//
//  ViewController.m
//  RealCopy
//
//  Created by Yaming Xu on 2017/09/10.
//  Copyright © 2017 Yaming Xu. All rights reserved.
//

#import "ViewController.h"
#import "CameraSessionView.h"
#import "GCUIImageView.h"

@interface ViewController () <CACameraSessionDelegate, GCUIImageViewDelegate>

@property (nonatomic, strong) CameraSessionView *cameraView;
@property (nonatomic, strong) GCUIImageView *imageView;
@property (nonatomic, strong) NSMutableArray *savedImages;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _cameraView = [[CameraSessionView alloc] initWithFrame:self.view.frame];
    _cameraView.delegate = self;
    
    [self.view addSubview:_cameraView];
}

-(void)didCaptureImage:(UIImage *)image {
    // save image to album
    //UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    
    // remove camera view and show still image
    [self.cameraView removeFromSuperview];

    // prepare image view
    if (_imageView == nil) {
        _imageView = [[GCUIImageView alloc] init];
    }
    _imageView.delegate = self;
    [_imageView setImage:image];
    [_imageView setFrame:[[UIScreen mainScreen] bounds]];
    [_imageView setup];
    [self.view addSubview:_imageView];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GCUIImageViewDelegate protoc
-(void)switchToCameraViewAndSaveImage:(UIImage*)image
{
    [_savedImages addObject:image];
    
    [_imageView removeFromSuperview];
    [self.view addSubview:_cameraView];
}

#pragma mark - image saving error handler

-(void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                       message:@"Image saving fails..."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

@end
