//
//  UIImage+Resize.h
//  Leaves
//
//  Created by Ivor Prebeg on 6/7/12.
//  Copyright (c) 2012 ivor.prebeg@gmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (Resize)

- (UIImage *) scaleToSize: (CGSize)size;
- (UIImage *) scaleProportionalToSize: (CGSize)size;

@end
