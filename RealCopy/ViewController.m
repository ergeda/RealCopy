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
#import "SVProgressHUD.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController () <CACameraSessionDelegate, GCUIImageViewDelegate>

@property (nonatomic, strong) CameraSessionView *cameraView;
@property (nonatomic, strong) GCUIImageView *imageView;
@property (nonatomic, strong) UIButton *syncToWindows;
@property (nonatomic, strong) NSMutableArray *savedImages;
@property (nonatomic, strong) UISwipeGestureRecognizer *recognizer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _recognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeFrom:)];
    [_recognizer setDirection:UISwipeGestureRecognizerDirectionUp];
    
    _savedImages = [[NSMutableArray alloc] init];
    
    _cameraView = [[CameraSessionView alloc] initWithFrame:self.view.frame];
    _cameraView.delegate = self;
    
    [self.view addSubview:_cameraView];
}

-(void)didCaptureImage:(UIImage *)image {
    // remove camera view and show still image
    [_cameraView removeFromSuperview];

    // prepare image view
    if (_imageView == nil) {
        _imageView = [[GCUIImageView alloc] init];
    }
    _imageView.delegate = self;
    [_imageView setImage:image];
    [_imageView setFrame:[[UIScreen mainScreen] bounds]];
    [_imageView setupWithRadarSize:[_cameraView radarSize]];
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
    // show results
    [self showSavedImage:image];
    
    // remove still image view and add back camera view
    [_imageView removeFromSuperview];
    [self.view addSubview:_cameraView];
}

-(void)showSavedImage:(UIImage*)image
{
    // layout the result and button
    NSUInteger count = [_savedImages count];
    CGFloat width = 118;
    CGFloat height = 118;
    CGFloat left = 5 + (count % 3)*(width + 5);
    CGFloat top = 20 + (count / 3)*(height + 5);
    
    // lazy man style
    if (_syncToWindows) [_syncToWindows removeFromSuperview];
    else _syncToWindows = [UIButton buttonWithType:UIButtonTypeSystem];
    [_syncToWindows setFrame:CGRectMake(5, top + (height + 5), 365, 50)];
    [_syncToWindows setTitle:@"Copy to Windows" forState:UIControlStateNormal];
    _syncToWindows.titleLabel.font = [UIFont systemFontOfSize:20.0];
    [_syncToWindows setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_syncToWindows addTarget:self action:@selector(inputManager:) forControlEvents:UIControlEventTouchUpInside];
    [_cameraView addSubview:_syncToWindows];
    
    [_savedImages addObject:image];
    UIImageView* savedImageView = [[UIImageView alloc] init];
    [savedImageView setImage:image];
    [savedImageView setFrame:CGRectMake(left, top, width, height)];
    [savedImageView setBackgroundColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5f]];
    [savedImageView.layer setBorderColor: [[UIColor whiteColor] CGColor]];
    [savedImageView.layer setBorderWidth: 1.0];
    [savedImageView setTag:(NSInteger)count];
    savedImageView.userInteractionEnabled = YES;
    [savedImageView addGestureRecognizer:_recognizer];
    
    [_cameraView addSubview:savedImageView];
    
    // save image to album
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
    // sync to OneDrive/GoogleDrive
}

-(void)syncToCloud
{
    [SVProgressHUD show];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // code to upload
        [NSThread sleepForTimeInterval:5.0f];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [SVProgressHUD dismiss];
        });
    });

}

#pragma mark - User Interaction

-(void)inputManager:(id)sender {
    //If sender does not inherit from 'UIButton', return
    if (![sender isKindOfClass:[UIButton class]]) return;
    
    [self syncToCloud];
}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    //Get the View
    UIImageView *imageView = (UIImageView*)recognizer.view;
    [imageView removeFromSuperview];
    
    [_savedImages removeObjectAtIndex:[imageView tag]];
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
