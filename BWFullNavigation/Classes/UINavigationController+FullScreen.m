//
//  UINavigationController+FullScreen.m
//  BWFullNavigation
//
//  Created by bairdweng on 2020/10/23.
//

#import "UINavigationController+FullScreen.h"
#import <objc/runtime.h>

@interface _FDFullscreenPopGestureRecognizerDelegate
    : NSObject <UIGestureRecognizerDelegate>

@property(nonatomic, weak) UINavigationController *navigationController;

@end

@implementation _FDFullscreenPopGestureRecognizerDelegate
- (BOOL)gestureRecognizerShouldBegin:
    (UIPanGestureRecognizer *)gestureRecognizer {
  // 当没有视图控制器被推入导航堆栈时忽略。
  if (self.navigationController.viewControllers.count <= 1) {
    return NO;
  }

  // 当活动视图控制器不允许交互式pop时忽略。
  UIViewController *topViewController =
      self.navigationController.viewControllers.lastObject;
  if (topViewController.bw_interactivePopDisabled) {
    return NO;
  }

  // 当起始位置超过左边缘允许的最大初始距离时忽略。
  CGPoint beginningLocation =
      [gestureRecognizer locationInView:gestureRecognizer.view];
  CGFloat maxAllowedInitialDistance =
      topViewController.bw_interactivePopMaxAllowedInitialDistanceToLeftEdge;
  if (maxAllowedInitialDistance > 0 &&
      beginningLocation.x > maxAllowedInitialDistance) {
    return NO;
  }

  // 当导航控制器当前处于转换状态时，忽略平移手势。
  if ([[self.navigationController valueForKey:@"_isTransitioning"] boolValue]) {
    return NO;
  }

  // 当手势从相反的方向开始时，防止调用处理程序。
  CGPoint translation =
      [gestureRecognizer translationInView:gestureRecognizer.view];
  BOOL isLeftToRight =
      [UIApplication sharedApplication].userInterfaceLayoutDirection ==
      UIUserInterfaceLayoutDirectionLeftToRight;
  CGFloat multiplier = isLeftToRight ? 1 : -1;
  if ((translation.x * multiplier) <= 0) {
    return NO;
  }

  return YES;
}

@end
// 结束

typedef void (^_FDViewControllerWillAppearInjectBlock)(
    UIViewController *viewController, BOOL animated);

@interface UIViewController (FDFullscreenPopGesturePrivate)

@property(nonatomic, copy)
    _FDViewControllerWillAppearInjectBlock bw_willAppearInjectBlock;

@end

@implementation UIViewController (FDFullscreenPopGesturePrivate)

+ (void)load {
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Method viewWillAppear_originalMethod =
        class_getInstanceMethod(self, @selector(viewWillAppear:));
    Method viewWillAppear_swizzledMethod =
        class_getInstanceMethod(self, @selector(bw_viewWillAppear:));
    method_exchangeImplementations(viewWillAppear_originalMethod,
                                   viewWillAppear_swizzledMethod);

    Method viewWillDisappear_originalMethod =
        class_getInstanceMethod(self, @selector(viewWillDisappear:));
    Method viewWillDisappear_swizzledMethod =
        class_getInstanceMethod(self, @selector(bw_viewWillDisappear:));
    method_exchangeImplementations(viewWillDisappear_originalMethod,
                                   viewWillDisappear_swizzledMethod);
  });
}

- (void)bw_viewWillAppear:(BOOL)animated {
  // 转发至主要实施。
  [self bw_viewWillAppear:animated];

  if (self.bw_willAppearInjectBlock) {
    self.bw_willAppearInjectBlock(self, animated);
  }
}

- (void)bw_viewWillDisappear:(BOOL)animated {
  // 转发至主要实施。
  [self bw_viewWillDisappear:animated];

  dispatch_after(
      dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)),
      dispatch_get_main_queue(), ^{
        UIViewController *viewController =
            self.navigationController.viewControllers.lastObject;
        if (viewController && !viewController.bw_prefersNavigationBarHidden) {
          [self.navigationController setNavigationBarHidden:NO animated:NO];
        }
      });
}

- (_FDViewControllerWillAppearInjectBlock)bw_willAppearInjectBlock {
  return objc_getAssociatedObject(self, _cmd);
}

- (void)setBw_willAppearInjectBlock:
    (_FDViewControllerWillAppearInjectBlock)block {
  objc_setAssociatedObject(self, @selector(bw_willAppearInjectBlock), block,
                           OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UINavigationController (FDFullscreenPopGesture)

+ (void)load {
  // Inject "-pushViewController:animated:"
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    Class class = [self class];

    SEL originalSelector = @selector(pushViewController:animated:);
    SEL swizzledSelector = @selector(bw_pushViewController:animated:);

    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);

    BOOL success = class_addMethod(class, originalSelector,
                                   method_getImplementation(swizzledMethod),
                                   method_getTypeEncoding(swizzledMethod));
    if (success) {
      class_replaceMethod(class, swizzledSelector,
                          method_getImplementation(originalMethod),
                          method_getTypeEncoding(originalMethod));
    } else {
      method_exchangeImplementations(originalMethod, swizzledMethod);
    }
  });
}

- (void)bw_pushViewController:(UIViewController *)viewController
                     animated:(BOOL)animated {
  if (![self.interactivePopGestureRecognizer.view.gestureRecognizers
          containsObject:self.bw_fullscreenPopGestureRecognizer]) {

    // 将我们自己的手势识别器添加到内置屏幕边缘平移手势识别器的位置。

    [self.interactivePopGestureRecognizer.view
        addGestureRecognizer:self.bw_fullscreenPopGestureRecognizer];

    // 将手势事件转发到车载手势识别器的私有处理程序。
    NSArray *internalTargets =
        [self.interactivePopGestureRecognizer valueForKey:@"targets"];
    id internalTarget = [internalTargets.firstObject valueForKey:@"target"];
    SEL internalAction = NSSelectorFromString(@"handleNavigationTransition:");
    self.bw_fullscreenPopGestureRecognizer.delegate =
        self.bw_popGestureRecognizerDelegate;
    [self.bw_fullscreenPopGestureRecognizer addTarget:internalTarget
                                               action:internalAction];

    // 禁用板载手势识别器。
    self.interactivePopGestureRecognizer.enabled = NO;
  }

  // 处理首选的导航栏外观。
  [self bw_setupViewControllerBasedNavigationBarAppearanceIfNeeded:
            viewController];

  // 转发至主要实施。
  if (![self.viewControllers containsObject:viewController]) {
    [self bw_pushViewController:viewController animated:animated];
  }
}

- (void)bw_setupViewControllerBasedNavigationBarAppearanceIfNeeded:
    (UIViewController *)appearingViewController {
  if (!self.bw_viewControllerBasedNavigationBarAppearanceEnabled) {
    return;
  }

  __weak typeof(self) weakSelf = self;
  _FDViewControllerWillAppearInjectBlock block = ^(
      UIViewController *viewController, BOOL animated) {
    __strong typeof(weakSelf) strongSelf = weakSelf;
    if (strongSelf) {
      [strongSelf
          setNavigationBarHidden:viewController.bw_prefersNavigationBarHidden
                        animated:animated];
    }
  };

  // 安装程序将在出现的视图控制器中显示注入块。
  // 还要设置消失的视图控制器，因为不是每个视图控制器都被添加到其中
  // 通过推送（可能是通过“
  // -setViewControllers：”）进行堆栈。这个是控制显示器外观的核心。
  appearingViewController.bw_willAppearInjectBlock = block;
  UIViewController *disappearingViewController =
      self.viewControllers.lastObject;
  if (disappearingViewController &&
      !disappearingViewController.bw_willAppearInjectBlock) {
    disappearingViewController.bw_willAppearInjectBlock = block;
  }
}

- (_FDFullscreenPopGestureRecognizerDelegate *)bw_popGestureRecognizerDelegate {
  _FDFullscreenPopGestureRecognizerDelegate *delegate =
      objc_getAssociatedObject(self, _cmd);

  if (!delegate) {
    delegate = [[_FDFullscreenPopGestureRecognizerDelegate alloc] init];
    delegate.navigationController = self;

    objc_setAssociatedObject(self, _cmd, delegate,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return delegate;
}

- (UIPanGestureRecognizer *)bw_fullscreenPopGestureRecognizer {
  UIPanGestureRecognizer *panGestureRecognizer =
      objc_getAssociatedObject(self, _cmd);

  if (!panGestureRecognizer) {
    panGestureRecognizer = [[UIPanGestureRecognizer alloc] init];
    panGestureRecognizer.maximumNumberOfTouches = 1;

    objc_setAssociatedObject(self, _cmd, panGestureRecognizer,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  return panGestureRecognizer;
}

- (BOOL)bw_viewControllerBasedNavigationBarAppearanceEnabled {
  NSNumber *number = objc_getAssociatedObject(self, _cmd);
  if (number) {
    return number.boolValue;
  }
  self.bw_viewControllerBasedNavigationBarAppearanceEnabled = YES;
  return YES;
}

- (void)setBw_viewControllerBasedNavigationBarAppearanceEnabled:(BOOL)enabled {
  SEL key = @selector(bw_viewControllerBasedNavigationBarAppearanceEnabled);
  objc_setAssociatedObject(self, key, @(enabled),
                           OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@implementation UIViewController (FDFullscreenPopGesture)

- (BOOL)bw_interactivePopDisabled {
  return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBw_interactivePopDisabled:(BOOL)disabled {
  objc_setAssociatedObject(self, @selector(bw_interactivePopDisabled),
                           @(disabled), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)bw_prefersNavigationBarHidden {
  return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBw_prefersNavigationBarHidden:(BOOL)hidden {
  objc_setAssociatedObject(self, @selector(bw_prefersNavigationBarHidden),
                           @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


- (CGFloat)bw_interactivePopMaxAllowedInitialDistanceToLeftEdge
{
#if CGFLOAT_IS_DOUBLE
    return [objc_getAssociatedObject(self, _cmd) doubleValue];
#else
    return [objc_getAssociatedObject(self, _cmd) floatValue];
#endif
}

- (void)setBw_interactivePopMaxAllowedInitialDistanceToLeftEdge:(CGFloat)distance
{
    SEL key = @selector(bw_interactivePopMaxAllowedInitialDistanceToLeftEdge);
    objc_setAssociatedObject(self, key, @(MAX(0, distance)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end



