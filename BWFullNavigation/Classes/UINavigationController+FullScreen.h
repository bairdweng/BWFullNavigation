//
//  UINavigationController+FullScreen.h
//  BWFullNavigation
//
//  Created by bairdweng on 2020/10/23.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (FullScreen)

@property (nonatomic, strong, readonly) UIPanGestureRecognizer *bw_fullscreenPopGestureRecognizer;
@property (nonatomic, assign) BOOL bw_viewControllerBasedNavigationBarAppearanceEnabled;

@end

NS_ASSUME_NONNULL_END



@interface UIViewController (FullScreen)

// 手势是否禁用
@property (nonatomic, assign) BOOL bw_interactivePopDisabled;

/// 表示这个视图控制器希望它的导航栏隐藏与否，
/// 当基于视图控制器的导航栏的外观启用时检查。
/// 默认为NO，栏更有可能显示。
@property (nonatomic, assign) BOOL bw_prefersNavigationBarHidden;

/// 当您开始交互式弹出时，允许的最大初始距离到左边缘
/// 姿态。默认为0，这意味着它将忽略这个限制。
@property (nonatomic, assign) CGFloat bw_interactivePopMaxAllowedInitialDistanceToLeftEdge;

@end
