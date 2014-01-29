//
//  SDPullNavigationBar.m
//  ios-shared

//
//  Created by Brandon Sneed on 08/06/2013.
//  Copyright 2013-2014 SetDirection. All rights reserved.
//

#import "SDPullNavigationBar.h"

#import "SDPullNavigationBarBackground.h"
#import "SDPullNavigationBarTabButton.h"
#import "SDPullNavigationManager.h"
#import "UIDevice+machine.h"
#import "UIColor+SDExtensions.h"
#import "SDLayerAnimator.h"

static const CGFloat kDefaultMenuWidth = 320.0f;

static NSString* kSDRevealControllerFrontViewTranslationAnimationKey = @"frontViewTranslation";

typedef NS_ENUM( NSUInteger, SDRevealControllerState)
{
    SDRevealControllerShowsMenuController,
    SDRevealControllerShowsContentController
};

typedef NS_ENUM( NSUInteger, SDRevealControllerAnimationType)
{
    SDRevealControllerAnimationTypeStatic
};

typedef NS_ENUM( NSUInteger, SDRevealControllerType)
{
    SDRevealControllerTypeNone  = 0,
    SDRevealControllerTypeLeft  = 1,
    SDRevealControllerTypeRight = 2,
    SDRevealControllerTypeBoth  = (SDRevealControllerTypeLeft | SDRevealControllerTypeRight)
};

typedef void(^SDDefaultCompletionHandler)(BOOL finished);

typedef struct
{
    CGPoint initialTouchPoint;
    CGPoint currentTouchPoint;
} UIGestureRecognizerInteractionFlags;

typedef struct
{
    UIGestureRecognizerInteractionFlags recognizerFlags;
    CGPoint initialFrontViewPosition;
    CGFloat velocity;
    BOOL    isInteracting;
} SDMenuControllerInteractionFlags;

@interface SDPullNavigationMenuContainer : UIView   // This custom class used for debugging purposes.
@end

#pragma mark - SDPullNavigationBar

@interface SDPullNavigationBar()<UIGestureRecognizerDelegate>

@property (nonatomic, strong) SDPullNavigationBarBackground* navbarBackgroundView;
@property (nonatomic, strong) SDPullNavigationBarTabButton* tabButton;
@property (nonatomic, strong) SDPullNavigationMenuContainer* menuContainer;
@property (nonatomic, strong) UIView* menuBackgroundEffectsView;
@property (nonatomic, strong) UIImageView* menuBottomAdornmentView;
@property (nonatomic, assign) BOOL animating;
@property (nonatomic, assign) BOOL menuOpen;
@property (nonatomic, assign) CGFloat menuWidth;
@property (nonatomic, strong, readwrite) UIPanGestureRecognizer* revealPanGestureRecognizer;
@property (nonatomic, strong, readwrite) SDLayerAnimator* animator;
@property (nonatomic, assign, readwrite) SDMenuControllerInteractionFlags menuInteraction;
@property (nonatomic, assign) BOOL showBottomAdornment;

@end

@implementation SDPullNavigationBar

+ (void)setupDefaults
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:NO];

    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(-9999, -9999) forBarMetrics:UIBarMetricsDefault];

    SDPullNavigationBar* pullBarAppearance = [SDPullNavigationBar appearance];
    if ([UIDevice bcdSystemVersion] >= 0x070000)
    {
        pullBarAppearance.barTintColor = [UIColor colorWith8BitRed:29 green:106 blue:166 alpha:1.0f];
        pullBarAppearance.titleTextAttributes = @{ UITextAttributeTextColor : [UIColor whiteColor] };
        pullBarAppearance.tintColor = [UIColor whiteColor];
    }
    else
    {
        pullBarAppearance.tintColor = [UIColor colorWith8BitRed:23 green:108 blue:172 alpha:1.0];
    }
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(self != nil)
    {
        self.translucent = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusBarWillChangeRotationNotification:)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// Superview is known, start setting up our subviews.
- (void)willMoveToSuperview:(UIView*)newSuperview
{
    if(newSuperview)
    {
        // I tagged all of the view to be able to find them quickly when I am viewing the hierarchy in Spark Inspector or Reveal.

        // This is a navBar overlay which we can use to change navBar visuals.
        {
            self.navbarBackgroundView = [[SDPullNavigationBarBackground alloc] init];
            self.navbarBackgroundView.autoresizesSubviews = YES;
            self.navbarBackgroundView.userInteractionEnabled = NO;
            self.navbarBackgroundView.opaque = NO;
            self.navbarBackgroundView.backgroundColor = [UIColor clearColor];
            self.navbarBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.navbarBackgroundView.delegate = (id<SDPullNavigationBarOverlayProtocol>)self;
            self.navbarBackgroundView.frame = self.bounds;
            self.navbarBackgroundView.tag = 1;
        }

        // This is the hit area for showing the pulldown menu, as well as the area (at the bottom) where the nipple is shown.
        {
            self.tabButton = [[SDPullNavigationBarTabButton alloc] initWithNavigationBar:self];
            self.tabButton.tag = 2;
        }

        // This is the client's controller for the menu.
        {
            UIStoryboard* menuStoryBoard = [UIStoryboard storyboardWithName:[SDPullNavigationManager sharedInstance].globalMenuStoryboardId bundle:nil];
            self.menuController = [menuStoryBoard instantiateInitialViewController];
            self.menuController.view.clipsToBounds = YES;
            self.menuController.view.opaque = YES;
            self.menuController.view.tag = 3;
            self.menuController.view.translatesAutoresizingMaskIntoConstraints = YES;
            self.menuController.pullNavigationBarDelegate = self;

            self.menuWidth = kDefaultMenuWidth;
            if([self.menuController respondsToSelector:@selector(pullNavigationMenuWidth)])
                self.menuWidth = self.menuController.pullNavigationMenuWidth;
        }

        // The view that the client's menu lives in.
        {
            CGRect menuFrame = newSuperview.bounds;
            menuFrame.size.height = MIN(self.menuController.pullNavigationMenuHeight, self.availableHeight);

            self.menuContainer = [[SDPullNavigationMenuContainer alloc] initWithFrame:menuFrame];
            self.menuContainer.clipsToBounds = YES;
            self.menuContainer.backgroundColor = [UIColor clearColor];
            self.menuContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.menuContainer.translatesAutoresizingMaskIntoConstraints = YES;
            self.menuContainer.opaque = NO;

            self.menuContainer.layer.shadowColor = [UIColor blackColor].CGColor;
            self.menuContainer.layer.shadowOffset = (CGSize){ 0.0f, -3.0f };
            self.menuContainer.layer.shadowRadius = 3.0f;
            self.menuContainer.layer.shadowOpacity = 1.0;
            self.menuContainer.tag = 4;
        }

        // View that darkens the views behind and to the side of the menu.
        {
            self.menuBackgroundEffectsView = [[UIView alloc] initWithFrame:self.menuContainer.bounds];
            self.menuBackgroundEffectsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.menuBackgroundEffectsView.clipsToBounds = YES;
            self.menuBackgroundEffectsView.backgroundColor = [@"#00000033" uicolor];
            self.menuBackgroundEffectsView.opaque = NO;
            self.menuBackgroundEffectsView.tag = 5;
        }

        // This is the little nubbin' at the bottom of the menu. Don't show this on iPhone, don't show this if client has not set it.
        if([UIDevice iPad])
        {
            UIImage* menuAdornmentImage = [SDPullNavigationManager sharedInstance].menuAdornmentImage;
            if(menuAdornmentImage)
            {
                self.showBottomAdornment = YES;

                CGRect clientMenuFrame = self.menuController.view.frame;
                CGRect frame = (CGRect){ { clientMenuFrame.origin.x, clientMenuFrame.origin.y + clientMenuFrame.size.height },
                                         { clientMenuFrame.size.width, [SDPullNavigationManager sharedInstance].menuAdornmentImage.size.height } };
                self.menuBottomAdornmentView = [[UIImageView alloc] initWithFrame:frame];
                self.menuBottomAdornmentView.clipsToBounds = YES;
                self.menuBottomAdornmentView.backgroundColor = [UIColor clearColor];
                self.menuBottomAdornmentView.opaque = YES;
                self.menuBottomAdornmentView.image = menuAdornmentImage;
                self.menuBottomAdornmentView.tag = 6;
            }
        }

        [self insertSubview:self.navbarBackgroundView atIndex:1];
        [self addSubview:self.tabButton];
        [self.menuContainer addSubview:self.menuBackgroundEffectsView];
        [self.menuContainer addSubview:self.menuController.view];
        [self.menuContainer addSubview:self.menuBottomAdornmentView];
        [newSuperview insertSubview:self.menuContainer belowSubview:self];

        [self setupGestureRecognizers];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    NSInteger index = 0;
    if(self.subviews.count > 0)
        index = 1;

    CGFloat tabOffset = 8.0f;

    CGPoint navBarCenter = self.center;
    CGRect tabFrame = self.tabButton.frame;
    tabFrame.origin.x = (navBarCenter.x - (tabFrame.size.width * 0.5f));
    tabFrame.origin.y = self.bounds.size.height - (tabFrame.size.height - tabOffset);
    self.tabButton.frame = CGRectIntegral(tabFrame);
    
    [self addSubview:self.tabButton];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    self.navbarBackgroundView.frame = self.bounds;
}

- (void)setupGestureRecognizers
{
    UITapGestureRecognizer* openTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
    [self.tabButton addGestureRecognizer:openTapGesture];
    
    self.revealPanGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(didRecognizePanGesture:)];
    self.revealPanGestureRecognizer.maximumNumberOfTouches = 1;
    [self.tabButton addGestureRecognizer:self.revealPanGestureRecognizer];
    
    UITapGestureRecognizer* dismissTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissTapAction:)];
    dismissTapGesture.delegate = self;
    [self.menuContainer addGestureRecognizer:dismissTapGesture];
}

- (void)tapAction:(id)sender
{
    [self togglePullMenuWithCompletionBlock:nil];
}

#pragma mark - Gesture Handling

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    return ![touch.view isDescendantOfView:self.menuController.view];
}

- (void)dismissTapAction:(UITapGestureRecognizer*)sender
{
    if(self.menuOpen)
        [self dismissPullMenuWithCompletionBlock:nil];
}

- (void)didRecognizePanGesture:(UIPanGestureRecognizer*)recognizer
{
    switch(recognizer.state)
    {
        case UIGestureRecognizerStateBegan:
        {
            [self.animator stopAnimationForKey:kSDRevealControllerFrontViewTranslationAnimationKey];
            
            _menuInteraction.recognizerFlags.initialTouchPoint = [recognizer translationInView:self];
            _menuInteraction.initialFrontViewPosition = self.menuContainer.layer.position;
            _menuInteraction.isInteracting = YES;
            _menuInteraction.velocity = 0.0f;
            
            [self setInitialMenuSize];
            
            [recognizer setTranslation:CGPointZero inView:self];
            
            self.tabButton.hidden = YES;
            self.menuContainer.hidden = NO;
//            self.menuContainer.backgroundColor = [UIColor orangeColor];
            self.menuController.view.hidden = NO;
            if(self.showBottomAdornment)
                self.menuBottomAdornmentView.hidden = NO;
            self.menuOpen = YES;
            break;
        }
            
        case UIGestureRecognizerStateChanged:
        {
            _menuInteraction.recognizerFlags.currentTouchPoint = [recognizer translationInView:self];
            CGFloat newY = _menuInteraction.initialFrontViewPosition.y + (_menuInteraction.recognizerFlags.initialTouchPoint.y + _menuInteraction.recognizerFlags.currentTouchPoint.y);
            self.menuController.view.layer.position = (CGPoint){ _menuInteraction.initialFrontViewPosition.x, newY };
            break;
        }
            
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        default:
        {
            _menuInteraction.recognizerFlags.initialTouchPoint = CGPointZero;
            _menuInteraction.recognizerFlags.currentTouchPoint = CGPointZero;
            _menuInteraction.initialFrontViewPosition = CGPointZero;
            _menuInteraction.isInteracting = NO;
            _menuInteraction.velocity = 0.0f;
            break;
        }
    }
}

#pragma mark - Helpers

+ (UINavigationController*)navControllerWithViewController:(UIViewController*)viewController
{
    UINavigationController* navController = [[UINavigationController alloc] initWithNavigationBarClass:[self class] toolbarClass:nil];
    [navController setViewControllers:@[viewController]];
    navController.delegate = [SDPullNavigationManager sharedInstance];
    return navController;
}

- (void)statusBarWillChangeRotationNotification:(NSNotification*)notification
{
    [self dismissPullMenuWithoutAnimation];
}

- (void)togglePullMenuWithCompletionBlock:(void (^)(void))completion
{
    if(!self.animating)
    {
        self.animating = YES;

        [self setInitialMenuSize];
        [self.superview insertSubview:self.menuContainer belowSubview:self];
        self.menuContainer.hidden = NO;

        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^
        {
            self.tabButton.tuckedTab = !self.menuOpen;
            if(!self.menuOpen)
                [self.tabButton setNeedsDisplay];

            CGFloat height = self.menuOpen ? 0.0f : MIN(self.menuController.pullNavigationMenuHeight, self.availableHeight);
            CGFloat width = [UIDevice iPad] ? self.menuWidth : self.menuController.view.frame.size.width;

            self.menuController.view.frame = (CGRect){ { self.frame.size.width * 0.5f - self.menuController.view.bounds.size.width * 0.5f, self.frame.size.height + 20.0f }, { width, height } };
            if(self.showBottomAdornment)
                self.menuBottomAdornmentView.frame = (CGRect){{self.menuController.view.frame.origin.x, self.menuController.view.frame.origin.y + height }, self.menuBottomAdornmentView.frame.size };

            self.menuOpen = !self.menuOpen;
         }
         completion:^(BOOL finished)
         {
             if(self.menuOpen == NO)
                 [self.tabButton setNeedsDisplay];
             self.animating = NO;
             self.menuContainer.hidden = !self.menuOpen;
             if(self.showBottomAdornment)
                 self.menuBottomAdornmentView.hidden = !self.menuOpen;

             if(self.menuOpen == NO)
                 [self.menuContainer removeFromSuperview];

             if(completion)
                 completion();
         }];
    }
    else
    {
        // Don't forget that if we did not need to dismiss the menu, then we should still call the completion block.
        if(completion)
            completion();
    }
}

- (void)setInitialMenuSize
{
    if([UIDevice iPad] && !self.menuOpen)
    {
        if(self.showBottomAdornment)
        {
            self.menuController.view.frame = (CGRect){{ self.superview.frame.size.width * 0.5f - self.menuWidth * 0.5f, self.navigationBarHeight }, { self.menuWidth, 0.0f } };
            self.menuBottomAdornmentView.frame = (CGRect){ { self.menuController.view.frame.origin.x, self.menuController.view.frame.origin.y + self.menuController.view.frame.size.height },
                                                           { self.menuController.view.frame.size.width, [SDPullNavigationManager sharedInstance].menuAdornmentImage.size.height } };
        }
    }
}

- (void)dismissPullMenuWithoutAnimation
{
    self.menuContainer.hidden = YES;

    self.tabButton.tuckedTab = YES;
    CGFloat width = [UIDevice iPad] ? self.menuWidth : self.menuController.view.frame.size.width;

    self.menuController.view.frame = (CGRect){ { self.frame.size.width * 0.5f - self.menuController.view.bounds.size.width * 0.5f, self.frame.size.height + 20.0f }, { width, 0.0f } };
    if(self.showBottomAdornment)
    {
        self.menuBottomAdornmentView.frame = (CGRect){{self.menuController.view.frame.origin.x, self.menuController.view.frame.origin.y + self.menuController.view.frame.size.height }, self.menuBottomAdornmentView.frame.size };
        self.menuBottomAdornmentView.hidden = YES;
    }
    self.menuOpen = NO;

    [self.menuContainer removeFromSuperview];
}

- (void)dismissPullMenuWithCompletionBlock:(void (^)(void))completion
{
    if(self.menuOpen)
    {
        [self togglePullMenuWithCompletionBlock:completion];
    }
}

- (CGFloat)availableHeight
{
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    UIWindow* topMostWindow = [UIApplication sharedApplication].windows.lastObject;
    CGSize topMostWindowSize = topMostWindow.bounds.size;
    CGFloat height = UIInterfaceOrientationIsPortrait(orientation) ? MAX(topMostWindowSize.height, topMostWindowSize.width) : MIN(topMostWindowSize.height, topMostWindowSize.width);

    CGFloat navHeight = self.navigationBarHeight;

    // Take into account the menuAdornment at the bottom of the menu and some extra so that the adornment does not butt up against the bottom of the screen.
    navHeight += _menuBottomAdornmentView.frame.size.height + (_menuBottomAdornmentView ? 2.0f : 0.0f);

    return height - navHeight;
}

- (CGFloat)navigationBarHeight
{
    CGFloat navHeight = self.frame.size.height;
    
    if(navHeight == 0.0f)
        navHeight += 44.0f;
    navHeight += MIN([UIApplication sharedApplication].statusBarFrame.size.height, [UIApplication sharedApplication].statusBarFrame.size.width);

    return navHeight;
}

@end

@implementation SDPullNavigationMenuContainer

#ifdef DEBUG

- (void)layoutSubviews
{
    [super layoutSubviews];

}

#endif

@end
