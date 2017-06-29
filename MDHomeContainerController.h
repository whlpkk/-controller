//
//  MDHomeContainerController.h
//  MomoChat
//
//  Created by YZK on 2017/6/5.
//  Copyright © 2017年 wemomo.com. All rights reserved.
//

#import "MDViewController.h"
#import "MDHomeEntranceScreenTipView.h"

@interface MDHomeContainerController : MDViewController

- (instancetype)initWithCenterController:(UIViewController *)centerController
                          leftController:(UIViewController *)leftController;

@property (nonatomic,strong) UIViewController *centerVCL;
@property (nonatomic,strong) UIViewController *leftVCL;

@property (nonatomic,strong) MDHomeEntranceScreenTipView *screenTipView;

@property (nonatomic,strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic,weak,readonly) UIViewController *selectedViewController;

@property (nonatomic,assign) BOOL isCenter;

- (void)scrollToLeftWithAnimated:(BOOL)animated;
- (void)scrollToLeftWithAnimated:(BOOL)animated needAppearCallBack:(BOOL)need;
- (void)scrollToCenterWithAnimated:(BOOL)animated;
- (void)scrollToCenterWithAnimated:(BOOL)animated needAppearCallBack:(BOOL)need;

@end
