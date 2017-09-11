//
//  CameraShutterButton.m
//  CameraWithAVFoundation
//
//  Created by Gabriel Alvarado on 1/24/15.
//  Copyright (c) 2015 Gabriel Alvarado. All rights reserved.
//

#import "BackgroundSetterButton.h"
#import "CameraStyleKitClass.h"

@implementation BackgroundSetterButton

- (void)drawRect:(CGRect)rect {
    [CameraStyleKitClass drawBackgroundSetterWithFrame:self.bounds];
}

@end
