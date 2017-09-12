//
//  CameraShutterButton.m
//  CameraWithAVFoundation
//
//  Created by Gabriel Alvarado on 1/24/15.
//  Copyright (c) 2015 Gabriel Alvarado. All rights reserved.
//

#import "CameraShutterButton.h"
#import "CameraStyleKitClass.h"

@interface CameraShutterButton()

@property (nonatomic, strong) UIColor *foregroundColor;

@end

@implementation CameraShutterButton

- (void)drawRect:(CGRect)rect {
    [CameraStyleKitClass drawCameraShutterWithFrame:self.bounds withForegroundColor:_foregroundColor];
}

-(void)setForegroundColor:(UIColor *)foregroundColor {
    _foregroundColor = foregroundColor;
}

@end
