//
//  MDHomeContainerController.m
//  MomoChat
//
//  Created by YZK on 2017/6/5.
//  Copyright © 2017年 wemomo.com. All rights reserved.
//

#import "MDHomeContainerController.h"

const NSInteger kHomeContainerResponseWidth  = 50;
const CGFloat kHomeContainerDuration = 0.3;

@interface MDHomeContainerController ()
<CAAnimationDelegate,
UIGestureRecognizerDelegate>

@property (nonatomic,weak,readwrite) UIViewController *selectedViewController;
@property (nonatomic,assign) BOOL animating;

@end

@implementation MDHomeContainerController

- (instancetype)initWithCenterController:(UIViewController *)centerController
                          leftController:(UIViewController *)leftController {
    self = [super init];
    if (self) {
        self.centerVCL = centerController;
        self.leftVCL = leftController;
        
        UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] init];
        panRecognizer.maximumNumberOfTouches = 1;
        panRecognizer.delegate = self;
        [panRecognizer addTarget:self action:@selector(handleController:)];
        self.panGestureRecognizer = panRecognizer;
    }
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.screenTipView.superview) {
        [self.screenTipView show];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    CGRect frame = self.view.bounds;
    
    self.centerVCL.view.frame = frame;
    [self.view addSubview:self.centerVCL.view];
    [self addChildViewController:self.centerVCL];
    [self.centerVCL didMoveToParentViewController:self];
    self.selectedViewController = self.centerVCL;
    self.isCenter = YES;
    
    self.leftVCL.view.frame = frame;
    [self addChildViewController:self.leftVCL];
    [self.leftVCL didMoveToParentViewController:self];
    
//    [self.view addGestureRecognizer:self.panGestureRecognizer];
//    [self addScreenTipView];
}

- (void)addScreenTipView {
    BOOL hasShowUpTip = [[[MDContext currentUser] dbStateHoldProvider] hasShowedHomeUpScrollTip];
    if (!hasShowUpTip) {
        MDHomeEntranceScreenTipView *screenTipView = [[MDHomeEntranceScreenTipView alloc] initWithWithText:@"向上滑动查看更多" direction:MDHomeEntranceScreenScrollDirectionUp];
        screenTipView.swipeRecognizer.delegate = self;
        screenTipView.alpha = 0;
        self.screenTipView = screenTipView;
        [self.view addSubview:screenTipView];
    
        [[[MDContext currentUser] dbStateHoldProvider] setHasShowedHomeUpScrollTip:YES];
        [[[MDContext currentUser] dbStateHoldProvider] setLastHomeScreenTipTime:[NSDate date]];
    }else {
        BOOL hasShowRightTip = [[[MDContext currentUser] dbStateHoldProvider] hasShowedHomeRightScrollTip];
        if (hasShowRightTip) {
            return;
        }
        
        NSDate *lastTime = [[[MDContext currentUser] dbStateHoldProvider] lastHomeScreenTipTime];
        NSTimeInterval time = [lastTime timeIntervalSinceNow] * -1;
        if (time < 60*60*24 && time>0) {
            return;
        }

        MDHomeEntranceScreenTipView *screenTipView = [[MDHomeEntranceScreenTipView alloc] initWithWithText:@"向右横滑进入发布" direction:MDHomeEntranceScreenScrollDirectionRight];
        screenTipView.swipeRecognizer.delegate = self;
        screenTipView.alpha = 0;
        self.screenTipView = screenTipView;
        [self.view addSubview:screenTipView];

        [[[MDContext currentUser] dbStateHoldProvider] setHasShowedHomeRightScrollTip:YES];
        [[[MDContext currentUser] dbStateHoldProvider] setLastHomeScreenTipTime:[NSDate date]];
    }
}

- (void)willShowViewController {
    if (self.selectedViewController == self.leftVCL) {
        //说明要显示拍摄页面
        
        NSInteger count = [[[MDContext currentUser] dbStateHoldProvider] totalCountOfHomePhotoControllerShow];
        if (count<10) {
            [[[MDContext currentUser] dbStateHoldProvider] setTotalCountOfHomePhotoControllerShow:count+1];
        }
    }
}

- (void)resetViewController:(UIViewController *)vc {
    vc.view.transform = CGAffineTransformIdentity;
    vc.view.frame = self.view.bounds;
}
- (void)resetAllViewController {
    [self resetViewController:self.leftVCL];
    [self resetViewController:self.centerVCL];
}


#pragma mark - gesture recognizer

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    //    不允许手势执行，
    //    3、不在侧滑响应范围，或者反向滑，就向下传递
    if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
        
        UIPanGestureRecognizer * recognizer = (UIPanGestureRecognizer *)gestureRecognizer;
        
        CGFloat dx = [recognizer locationInView:recognizer.view].x;
        CGPoint velocity = [recognizer velocityInView:recognizer.view];
        
        if (self.screenTipView.superview && self.screenTipView.swipeRecognizer.direction != UISwipeGestureRecognizerDirectionRight) {
            //提示页显示 且 提示页滑动方向不是向右，此时禁止滑动手势
            return NO;
        }
        
        //上下滑
        if ( fabs(velocity.x) < fabs(velocity.y) ) {
            return NO;
        }
        
        //用户当前在center且向左滑
        if (velocity.x < 0 && self.isCenter ) {
            return NO;
        }
        
        //用户当前在left且向右滑
        if (velocity.x > 0 && !self.isCenter) {
            return NO;
        }
        
        //用户不在左滑区域
        if (velocity.x < 0 && dx < MDScreenWidth- kHomeContainerResponseWidth) {
            return NO;
        }
        
        
        return self.navigationController.viewControllers.count == 1 && !self.animating;
    }
    
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(nonnull UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer isKindOfClass:[UISwipeGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

- (void)handleController:(UIPanGestureRecognizer *)recognizer {
    
    //横向位移量
    CGFloat dtx = [recognizer translationInView:recognizer.view].x;
    
    UIViewController *fromVCL = self.selectedViewController;
    UIViewController *toVCL = self.isCenter ? self.leftVCL : self.centerVCL;
    
    CGRect fromRect = self.view.bounds;
    fromRect.origin.x = (self.isCenter ? -1 : 1) * fromRect.size.width;
    
    CGRect toRect = fromRect;
    toRect.origin.x = -1 * toRect.origin.x;
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [toVCL beginAppearanceTransition:YES animated:YES];
        [fromVCL beginAppearanceTransition:NO animated:YES];
        
        [self resetAllViewController];
        toVCL.view.frame = fromRect;
        [self.view addSubview:toVCL.view];
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        toVCL.view.transform = CGAffineTransformMakeTranslation(dtx, 0);
        fromVCL.view.transform = CGAffineTransformMakeTranslation(dtx, 0);
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded ||
             recognizer.state == UIGestureRecognizerStateCancelled) {
        
        CGFloat progress = fabs(dtx / recognizer.view.bounds.size.width);
        CGPoint velocity = [recognizer velocityInView:recognizer.view];
        
        if (velocity.x >= 700 && dtx >= 50) {
            //快速侧滑，并且侧滑距离超过50，直接pop页面
            //防止有时虽然是快速侧滑，但是距离很短的误操作
            [self successTransicationWithToRect:toRect fromVCL:fromVCL toVCL:toVCL];
        }else{
            //缓慢侧滑，根据位置选择是否pop页面
            if (progress > 0.5) {
                [self successTransicationWithToRect:toRect fromVCL:fromVCL toVCL:toVCL];
            }
            else {
                [self cancelTransicationWithToRect:toRect fromVCL:fromVCL toVCL:toVCL];
            }
        }
        
    }
}

- (void)successTransicationWithToRect:(CGRect)toRect
                              fromVCL:(UIViewController *)fromVCL
                                toVCL:(UIViewController *)toVCL {
    
    self.isCenter = (toVCL == self.centerVCL);
    self.animating = YES;
    
    [UIView animateWithDuration:kHomeContainerDuration animations:^{
        toVCL.view.frame = self.view.bounds;
        fromVCL.view.frame = toRect;
    } completion:^(BOOL finished) {
        self.animating = NO;
        
        [self resetAllViewController];
        [fromVCL.view removeFromSuperview];
        
        /*
         view的层级变化一定要在beginAppearanceTransition和endAppearanceTransition之间。
         否则view层级变化也会触发生命周期，导致生命周期触发2次。
         */
        [toVCL endAppearanceTransition];
        [fromVCL endAppearanceTransition];
    }];
    
    self.selectedViewController = toVCL;
    [self willShowViewController];
}
- (void)cancelTransicationWithToRect:(CGRect)toRect
                             fromVCL:(UIViewController *)fromVCL
                               toVCL:(UIViewController *)toVCL {
    
    self.animating = YES;

    [fromVCL beginAppearanceTransition:YES animated:YES];
    [toVCL beginAppearanceTransition:NO animated:YES];

    [UIView animateWithDuration:kHomeContainerDuration animations:^{
        toVCL.view.transform = CGAffineTransformIdentity;
        self.selectedViewController.view.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.animating = NO;

        [self resetAllViewController];
        [toVCL.view removeFromSuperview];

        /*
         view的层级变化一定要在beginAppearanceTransition和endAppearanceTransition之间。
         否则view层级变化也会触发生命周期，导致生命周期触发2次。
         */
        [toVCL endAppearanceTransition];
        [fromVCL endAppearanceTransition];
    }];
    
    [self willShowViewController];
}


#pragma mark - animation

- (void)scrollToLeftWithAnimated:(BOOL)animated {
    [self scrollToLeftWithAnimated:animated needAppearCallBack:YES];
}

- (void)scrollToLeftWithAnimated:(BOOL)animated needAppearCallBack:(BOOL)need {
    if (self.animating) {
        return;
    }
    if (self.selectedViewController == self.leftVCL) {
        return;
    }
    
    self.isCenter = NO;
    self.animating = YES;
    [self resetAllViewController];
    
    if (need) {
        [self.leftVCL beginAppearanceTransition:YES animated:animated];
        [self.centerVCL beginAppearanceTransition:NO animated:animated];
    }
    
    [self.view addSubview:self.leftVCL.view];
    [self.centerVCL.view removeFromSuperview];
    
    if (animated) {
        CATransition *caTransition = [CATransition animation];
        caTransition.delegate = self;
        caTransition.duration = kHomeContainerDuration;
        caTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        caTransition.type = kCATransitionPush;
        caTransition.subtype = kCATransitionFromLeft;
        [caTransition setValue:@(need) forKey:@"needAppearCallBack"];
        [self.view.layer addAnimation:caTransition forKey:@"left"];
    }else {
        self.animating = NO;
        
        if (need) {
            [self.leftVCL endAppearanceTransition];
            [self.centerVCL endAppearanceTransition];
        }
    }
    
    self.selectedViewController = self.leftVCL;
    [self willShowViewController];
}

- (void)scrollToCenterWithAnimated:(BOOL)animated {
    [self scrollToCenterWithAnimated:animated needAppearCallBack:YES];
}
- (void)scrollToCenterWithAnimated:(BOOL)animated needAppearCallBack:(BOOL)need {
    if (self.animating) {
        return;
    }
    if (self.selectedViewController == self.centerVCL) {
        return;
    }
    self.isCenter = YES;
    self.animating = YES;
    [self resetAllViewController];

    if (need) {
        [self.centerVCL beginAppearanceTransition:YES animated:animated];
        [self.leftVCL beginAppearanceTransition:NO animated:animated];
    }
    
    [self.view addSubview:self.centerVCL.view];
    [self.leftVCL.view removeFromSuperview];
    
    if (animated) {
        CATransition *caTransition = [CATransition animation];
        caTransition.delegate = self;
        caTransition.duration = kHomeContainerDuration;
        caTransition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        caTransition.type = kCATransitionPush;
        caTransition.subtype = kCATransitionFromRight;
        [caTransition setValue:@(need) forKey:@"needAppearCallBack"];
        [self.view.layer addAnimation:caTransition forKey:@"center"];
        
    }else {
        self.animating = NO;
        
        if (need) {
            [self.leftVCL endAppearanceTransition];
            [self.centerVCL endAppearanceTransition];
        }
    }
    
    self.selectedViewController = self.centerVCL;
    [self willShowViewController];
}




- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    self.animating = NO;
    
    BOOL need = [[anim valueForKey:@"needAppearCallBack"] boolValue];
    if (need) {
        [self.leftVCL endAppearanceTransition];
        [self.centerVCL endAppearanceTransition];
    }
}

@end
