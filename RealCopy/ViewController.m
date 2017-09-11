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

@interface ViewController () <CACameraSessionDelegate>

@property (nonatomic, strong) CameraSessionView *cameraView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
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
    GCUIImageView* stillImageView = [[GCUIImageView alloc] init];
    [stillImageView setImage:image];
    [stillImageView setFrame:[[UIScreen mainScreen] bounds]];
    [self.view addSubview:stillImageView];
    [stillImageView setup];
}

- (BOOL)shouldAutorotate
{
    return NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - image saving error handler

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
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
