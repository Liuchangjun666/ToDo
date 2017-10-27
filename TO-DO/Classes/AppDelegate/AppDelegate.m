//
//  AppDelegate.m
//  TO-DO
//
//  Created by Siegrain on 16/5/7.
//  Copyright © 2016年 com.siegrain. All rights reserved.
//

#import "AppDelegate.h"
#import "CDTodo.h"
#import "DrawerTableViewController.h"
#import "HomeViewController.h"
#import "RTRootNavigationController.h"
#import "JVFloatingDrawerSpringAnimator.h"
#import "LCSyncRecord.h"
#import "LCTodo.h"
#import "LoginViewController.h"
#import "NEHTTPEye.h"
#import "MRTodoDataManager.h"
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <UserNotifications/UserNotifications.h>

// FIXME: SecPolicy对象上会发生莫名其妙的内存泄漏，不知道怎么解决，每次就漏那么一点，不管他。
// FIXME: 在访问NSFileManager的时候，有时会出现error: can't allocate region，无法申请内存的Bug，但是用Leaks看了感觉没问题，而且模拟器上没有，真机虽然报错但是不崩溃，就先不管。

static BOOL const kEnableViewControllerStateHolder = YES;

@interface AppDelegate () <UNUserNotificationCenterDelegate>
/* 视图状态存储 */
@property(nonatomic, strong) NSMutableDictionary *stateHolder;
@end

@implementation AppDelegate
#pragma mark - accessors

+ (AppDelegate *)globalDelegate {
    return (AppDelegate *) [UIApplication sharedApplication].delegate;
}

+ (NSString *)homeViewControllerKey {
    return Localized(@"Home");
}

#pragma mark - application delegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setup];
     
    return YES;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [self clearStateHolder];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [MagicalRecord cleanUp];
}

#pragma mark - initial

- (void)setup {
    _stateHolder = [NSMutableDictionary new];
    
    [self setupNetworkEye];
    [self setupDDLog];
    [self setupMagicalRecord];
    [self setupLeanCloud];
    [self setupReachability];
    [self setupAmap];
    [self setupDrawerViewController];
    [self setupUser];
    [self setupRemoteNotification];
    
    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    NSLog(@"%@", [self sandboxUrl]);
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    [self.window makeKeyAndVisible];    //不要把这句放到最下面去，如果同步的话会黑屏一段时间...
    
    // validate user
    if (_lcUser) {
        [self logIn];
    } else {
        [self switchRootViewController:[LoginViewController new] isNavigation:NO key:nil];
    }
}

- (void)setupUser {
    _lcUser = [LCUser currentUser];
    if (_lcUser) _cdUser = [CDUser userWithLCUser:_lcUser];
    
    DDLogInfo(@"当前用户：%@", _lcUser.username);
}

- (void)setupNetworkEye {
#if defined(DEBUG)|| defined(_DEBUG)
    [NEHTTPEye setEnabled:YES];
#else
    [NEHTTPEye setEnabled:NO];
#endif
}

- (void)setupLeanCloud {
    // setup leanCloud with appId and key
    [AVOSCloud setApplicationId:kLeanCloudAppID clientKey:kLeanCloudAppKey];
    
    // register subclasses
    [LCSyncRecord registerSubclass];
    [LCSync registerSubclass];
    [LCUser registerSubclass];
    [LCTodo registerSubclass];
}

- (void)setupDrawerViewController {
    _drawerViewController = [JVFloatingDrawerViewController new];
    _drawerViewController.leftDrawerWidth = (CGFloat) (kScreenWidth * 0.5);
    JVFloatingDrawerSpringAnimator *animator = [JVFloatingDrawerSpringAnimator new];
    animator.animationDuration = 0.5;
    animator.initialSpringVelocity = 2;
    animator.springDamping = 0.8;
    
    _drawerViewController.animator = animator;
    _drawerViewController.leftViewController = [DrawerTableViewController new];
    _drawerViewController.backgroundImage = [UIImage imageNamed:@"drawerbg"];
}

- (void)setupDDLog {
    [DDLog addLogger:[DDTTYLogger sharedInstance]];
    [[DDTTYLogger sharedInstance] setColorsEnabled:YES];  //允许颜色
    [[DDTTYLogger sharedInstance] setForegroundColor:[UIColor blueColor] backgroundColor:nil forFlag:DDLogFlagInfo];
    
    DDFileLogger *fileLogger = [[DDFileLogger alloc] init];  // File Logger
    fileLogger.rollingFrequency = 60 * 60 * 24;              // 24 hour rolling
    fileLogger.logFileManager.maximumNumberOfLogFiles = 7;   //最长保留一周
    [DDLog addLogger:fileLogger];
}

- (void)setupAmap {
    [AMapServices sharedServices].apiKey = kAmapKey;
}

- (void)setupMagicalRecord {
    [MagicalRecord setupAutoMigratingCoreDataStack];
}

- (void)setupReachability {
    LocalConnection *localConnection = [LocalConnection sharedInstance];
    [localConnection startNotifier];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(networkChanged) name:kLocalConnectionChangedNotification object:nil];
}

- (void)truncateLocalData {
    [CDUser MR_truncateAll];
    [CDTodo MR_truncateAll];
}

- (void)insertTestTodoToLC {
    NSMutableArray *array = [NSMutableArray array];
    for (int i = 0; i < 148; i++) {
        LCTodo *todo = [LCTodo object];
        todo.title = [NSString stringWithFormat:@"Test data：%d", i];
        todo.sgDescription = [NSString stringWithFormat:@"this is a description: %d", i];
        todo.deadline = [[NSDate date] dateByAddingTimeInterval:arc4random() % 70000];
        todo.user = _lcUser;
        todo.isCompleted = false;
        todo.isHidden = false;
        todo.status = TodoStatusNormal;
        todo.syncVersion = 0;
        todo.identifier = [[NSUUID UUID] UUIDString];
        
        int random = (int) (arc4random() % 2500000 - 5000000);
        todo.localCreatedAt = [[NSDate date] dateByAddingTimeInterval:random];
        todo.localUpdatedAt = [todo.localCreatedAt copy];
        
        [array addObject:todo];
    }
    
    [LCTodo saveAll:[array copy]];
}

- (NSString *)sandboxUrl {
    NSArray *array = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return array[0];
}

#pragma mark - notifications

- (void)setupRemoteNotification {
    // iOS10 兼容，下使用UNUserNotificationCenter 管理通知
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 10.0) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center setDelegate:self];
        //iOS10 使用以下方法注册，才能得到授权
        [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionBadge + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError *_Nullable error) {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
            //TODO:授权状态改变
            NSLog(@"%@", granted ? @"授权成功" : @"授权失败");
        }];
        // 获取当前的通知授权状态, UNNotificationSettings
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings *_Nonnull settings) {
            NSLog(@"%s\nline:%@\n-----\n%@\n\n", __func__, @(__LINE__), settings);
            /*
             UNAuthorizationStatusNotDetermined : 没有做出选择
             UNAuthorizationStatusDenied : 用户未授权
             UNAuthorizationStatusAuthorized ：用户已授权
             */
            if (settings.authorizationStatus == UNAuthorizationStatusNotDetermined) {
                NSLog(@"未选择");
            } else if (settings.authorizationStatus == UNAuthorizationStatusDenied) {
                NSLog(@"未授权");
            } else if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                NSLog(@"已授权");
            }
        }];
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 8.0) {
        UIUserNotificationType types = UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
        
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    } else {
        UIRemoteNotificationType types = UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeSound;
        [[UIApplication sharedApplication] registerForRemoteNotificationTypes:types];
    }
#pragma clang diagnostic pop
}

- (void)application:(UIApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    [AVOSCloud handleRemoteNotificationsWithDeviceToken:deviceToken];
}

#pragma mark - public methods

- (void)logOut {
    [LCUser logOut];
    _cdUser = nil;
    
    [self setCenterViewController:[UIViewController new] key:nil];
    [_drawerViewController closeDrawerWithSide:JVFloatingDrawerSideLeft animated:YES completion:nil];
    [_stateHolder removeAllObjects];
    LoginViewController *loginViewController = [LoginViewController new];
    [self switchRootViewController:loginViewController isNavigation:NO key:nil];
}

- (void)clearStateHolder {
    [_stateHolder removeAllObjects];
    DDLogInfo(@"已清除视图控制器缓存");
}

- (void)logIn {
    [self setupUser];
    [self switchRootViewController:[HomeViewController new] isNavigation:YES key:[AppDelegate homeViewControllerKey]];
    [self synchronize:SyncModeAutomatically isForcing:YES];
}

#pragma mark - sync

- (void)synchronize:(SyncMode)syncType isForcing:(BOOL)isForcing {
    if (!isForcing) if (syncType == SyncModeAutomatically && (!_cdUser.enableAutoSync || !_cdUser.enableAutoSync.boolValue)) return;
    
    __weak typeof(self) weakSelf = self;
    [[GCDQueue globalQueueWithLevel:DISPATCH_QUEUE_PRIORITY_DEFAULT] sync:^{
        if ([SGSyncManager isSyncing]) return;
        if (![weakSelf.window.rootViewController isKindOfClass:[JVFloatingDrawerViewController class]]) return;
        DrawerTableViewController *drawer = (DrawerTableViewController *) _drawerViewController.leftViewController;
        
        drawer.isSyncing = YES;
        [[SGSyncManager sharedInstance] synchronize:syncType complete:^(BOOL succeed) {
            drawer.isSyncing = NO;
        }];
    }];
}

- (void)networkChanged {
    [self synchronize:SyncModeAutomatically isForcing:NO];
}

#pragma mark - switch root view controller

- (void)switchRootViewController:(UIViewController *)viewController isNavigation:(BOOL)isNavigation key:(NSString *)key {
    if (isNavigation) {
        [self setCenterViewController:viewController key:key];
    }
    UIView *snapShot = [self.window snapshotViewAfterScreenUpdates:true];
    [viewController.view addSubview:snapShot];
    
    self.window.rootViewController = isNavigation ? _drawerViewController : viewController;
    
    [UIView animateWithDuration:.5 animations:^{snapShot.layer.opacity = 0;} completion:^(BOOL finished) {[snapShot removeFromSuperview];}];
}

#pragma mark - drawer

- (void)toggleDrawer:(id)sender animated:(BOOL)animated {
    [_drawerViewController toggleDrawerWithSide:JVFloatingDrawerSideLeft animated:animated completion:nil];
}

- (void)setCenterViewController:(UIViewController *)viewController key:(NSString *)key {
    RTRootNavigationController *navigationController = nil;
    if (!key || !kEnableViewControllerStateHolder)
        navigationController = [[RTRootNavigationController alloc] initWithRootViewController:viewController];
    else if (!_stateHolder[key]) {
        navigationController = [[RTRootNavigationController alloc] initWithRootViewController:viewController];
        _stateHolder[key] = navigationController;
    } else
        navigationController = _stateHolder[key];
    
    _drawerViewController.centerViewController = navigationController;
}
@end
