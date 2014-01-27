//
//  CALayer+SDConvenienceAnimations.m
//
//  Derived by Steven Woolgar on 01/16/2014.
//  Changes Copyright 2014 SetDirection. All rights reserved.
//

/*
    PKRevealController > CALayer+PKConvenienceAnimations.h
    Copyright (c) 2013 zuui.org (Philip Kluz). All rights reserved.
 
    The MIT License (MIT)
 
    Copyright (c) 2013 Philip Kluz
 
    Permission is hereby granted, free of charge, to any person obtaining a copy of
    this software and associated documentation files (the "Software"), to deal in
    the Software without restriction, including without limitation the rights to
    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
    the Software, and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:
 
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
 
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface CALayer (SDConvenienceAnimations)

#pragma mark - Methods

+ (CABasicAnimation*)animationFromAlpha:(CGFloat)fromValue
                                toAlpha:(CGFloat)toValue
                         timingFunction:(CAMediaTimingFunction *)timingFunction
                               duration:(NSTimeInterval)duration;

+ (CABasicAnimation*)animationFromTransformation:(CATransform3D)fromTransformation
                                toTransformation:(CATransform3D)toTransformation
                                  timingFunction:(CAMediaTimingFunction *)timingFunction
                                        duration:(NSTimeInterval)duration;


+ (CABasicAnimation*)animationFromPosition:(CGPoint)fromPosition
                                toPosition:(CGPoint)toPosition
                            timingFunction:(CAMediaTimingFunction *)timingFunction
                                  duration:(NSTimeInterval)duration;

- (void)animateToAlpha:(CGFloat)value
        timingFunction:(CAMediaTimingFunction *)timingFunction
              duration:(NSTimeInterval)duration
            alterModel:(BOOL)alterModel;

- (void)animateToTransform:(CATransform3D)toTransform
            timingFunction:(CAMediaTimingFunction*)timingFunction
                  duration:(NSTimeInterval)duration
                alterModel:(BOOL)alterModel;

- (void)animateToPoint:(CGPoint)toPoint
        timingFunction:(CAMediaTimingFunction*)timingFunction
              duration:(NSTimeInterval)duration
            alterModel:(BOOL)alterModel;

@end