//
//  UIView+AddConstraints.h
//  Bagel
//
//  Created by Chris Barker on 25/07/2020.
//  Copyright © 2020 Cocoa-Cabana Code Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (AddConstraints)
-(void)addConstraintsTo:(UIView *)view withLeading:(CGFloat)leading withTrailing:(CGFloat)trailing withTop:(CGFloat)top withBottom:(CGFloat)bottom;
@end

NS_ASSUME_NONNULL_END
