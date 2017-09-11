//
//  CameraShutterButton.m
//  CameraWithAVFoundation
//
//  Created by Gabriel Alvarado on 1/24/15.
//  Copyright (c) 2015 Gabriel Alvarado. All rights reserved.
//

#import "ForegroundSetterButton.h"
#import "CameraStyleKitClass.h"

@implementation ForegroundSetterButton

- (void)drawRect:(CGRect)rect {
    [CameraStyleKitClass drawForegroundSetterWithFrame:self.bounds];
}

@end
