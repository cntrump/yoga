/*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

@import Yoga;
#import "YGLayout.h"

NS_ASSUME_NONNULL_BEGIN

@interface YGLayout ()

@property(nonatomic, readonly) YGNodeRef node;

@property(nullable, nonatomic, readonly) UIView *rootYogaView;

- (instancetype)initWithView:(UIView *)view;

@end

@interface UIView (YogaKitAutoApplyLayout)

@property(nonatomic) CGFloat _yoga_maxLayoutWidth;

#if TARGET_OS_OSX
@property(nonatomic) BOOL _yoga_isFittingSize;
#endif

- (BOOL)_yoga_isAutoLayoutEnabled;

@end

NS_ASSUME_NONNULL_END
