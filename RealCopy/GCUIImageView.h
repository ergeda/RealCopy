//
//  GCUIImageView.h
//  RealCopy
//
//  Created by Yaming Xu on 2017/09/10.
//  Copyright © 2017 Yaming Xu. All rights reserved.
//

#import <UIKit/UIKit.h>

///Protocol Definition
@protocol GCUIImageViewDelegate <NSObject>

@optional
-(void)switchToCameraViewAndSaveImage:(UIImage*)image;

@end


@interface GCUIImageView : UIImageView

// Delegate Property
@property (nonatomic, weak) id <GCUIImageViewDelegate> delegate;

// API functions
-(void)setupWithRadarSize:(CGRect)rect;

@end
