//
//  Bagel.h
//  Bagel
//
//  Created by Chris Barker on 25/07/2020.
//  Copyright © 2020 Cocoa-Cabana Code Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Bagel : NSObject

+ (Bagel *) shared;

@property CGFloat speed;
@property CGFloat wait;
@property UIColor *textColor;
@property UIColor *backgroundColor;
@property NSInteger lineCount;
@property UIFont *font;
@property NSTextAlignment textAlignment;
@property CGFloat bottomConstraint;

NS_ASSUME_NONNULL_END

-(void)pop:(UIView * _Nullable) view withMessage:(NSString * _Nonnull) message;

@end
