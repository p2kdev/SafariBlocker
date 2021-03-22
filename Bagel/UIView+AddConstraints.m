//
//  UIView+AddConstraints.m
//  Bagel
//
//  Created by Chris Barker on 25/07/2020.
//  Copyright © 2020 Cocoa-Cabana Code Ltd. All rights reserved.
//

#import "UIView+AddConstraints.h"

@implementation UIView (AddConstraints)

-(void)addConstraintsTo:(UIView *)view withLeading:(CGFloat)leading withTrailing:(CGFloat)trailing withTop:(CGFloat)top withBottom:(CGFloat)bottom {

//    let constraint = NSLayoutConstraint(item: view, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: leading)

    if (leading != 0.0) {
        NSLayoutConstraint *leadingConstraint = [NSLayoutConstraint
                                                 constraintWithItem:view
                                                 attribute:NSLayoutAttributeLeading
                                                 relatedBy:NSLayoutRelationEqual
                                                 toItem:self
                                                 attribute:NSLayoutAttributeLeading
                                                 multiplier:1.0
                                                 constant:leading];

        [self addConstraint:leadingConstraint];
    }

    if (trailing != 0.0) {
        NSLayoutConstraint *trailingConstraint = [NSLayoutConstraint
                                                  constraintWithItem:view
                                                  attribute:NSLayoutAttributeTrailing
                                                  relatedBy:NSLayoutRelationEqual
                                                  toItem:self
                                                  attribute:NSLayoutAttributeTrailing
                                                  multiplier:1.0
                                                  constant:trailing];

        [self addConstraint:trailingConstraint];
    }

    if (top != 0.0) {
        NSLayoutConstraint *topConstraint = [NSLayoutConstraint
                                             constraintWithItem:view
                                             attribute:NSLayoutAttributeTop
                                             relatedBy:NSLayoutRelationEqual
                                             toItem:self
                                             attribute:NSLayoutAttributeTop
                                             multiplier:1.0
                                             constant:top];

        [self addConstraint:topConstraint];
    }

    if (bottom != 0.0) {
        NSLayoutConstraint *bottomConstraint = [NSLayoutConstraint
                                                constraintWithItem:view
                                                attribute:NSLayoutAttributeBottom
                                                relatedBy:NSLayoutRelationEqual
                                                toItem:self
                                                attribute:NSLayoutAttributeBottom
                                                multiplier:1.0
                                                constant:bottom];

        [self addConstraint:bottomConstraint];
    }

}

@end
