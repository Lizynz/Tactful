#import <UIKit/UIKit.h>
#include <substrate.h>

static const NSBundle *tweakBundle = [NSBundle bundleWithPath:@"/Library/Application Support/Tactful/Localizations.bundle"];
#define LOCALIZED(str) [tweakBundle localizedStringForKey:str value:@"" table:nil]

@interface SBUIAppIconForceTouchControllerDataProvider : NSObject // iOS 10 -11
@property (nonatomic, readonly) NSString *applicationBundleIdentifier;
@property (nonatomic, readonly) NSArray *applicationShortcutItems;
@end

@interface SBApplication : NSObject
@property (nonatomic,copy) NSArray *dynamicShortcutItems;
-(NSString *)bundleIdentifier;
@end

@interface SBSApplicationShortcutIcon : NSObject
@end

@interface SBSApplicationShortcutSystemIcon : SBSApplicationShortcutIcon
-(instancetype)initWithType:(NSInteger)type;
@end

@interface SBSApplicationShortcutCustomImageIcon : SBSApplicationShortcutIcon
@property (nonatomic, readonly, retain) NSData *imagePNGData;
-(instancetype)initWithImagePNGData:(NSData *)imageData;
@end

@interface SBSApplicationShortcutItem : NSObject
- (void)setBundleIdentifierToLaunch:(id)arg1;
- (void)setIcon:(id)arg1;
- (void)setLocalizedSubtitle:(id)arg1;
- (void)setLocalizedTitle:(id)arg1;
- (void)setType:(id)arg1;
- (void)setUserInfo:(id)arg1;
- (void)setUserInfoData:(id)arg1;
@end

@interface CydiaTabBarController : UITabBarController
@end

@interface CYPackageController : UIViewController
-(void)setDelegate:(id)arg1 ;
-(id)initWithDatabase:(id)arg1 forPackage:(id)arg2 withReferrer:(id)arg3 ;
-(void)reloadData;
@end

@interface PackageListController : UIViewController <UIViewControllerPreviewingDelegate>
-(NSURL *)referrerURL;
@end

@interface Package : NSObject
-(id)id;
-(BOOL)uninstalled;
-(BOOL)isCommercial;
-(void)install;
-(void)remove;
@end

@interface Database : NSObject
+(id)sharedInstance;
@end

@interface Cydia : UIApplication
-(void)queue;
-(BOOL)requestUpdate;
-(void)handleShortcutItem:(UIApplicationShortcutItem *)item;
@end

%hook PackageListController

-(void)viewDidLoad {
  %orig;
  UITableView *tableView = MSHookIvar<UITableView *>(self,"list_");
  if (tableView) {
    [self registerForPreviewingWithDelegate:self sourceView:tableView];
  }
}

#pragma mark - UIViewControllerPreviewingDelegate
%new
- (UIViewController *)previewingContext:(id <UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
    if ([self.presentedViewController isKindOfClass:%c(CYPackageController)]) {
        return nil;
    }
    UITableView *tableView = MSHookIvar<UITableView *>(self,"list_");
    if (!tableView) {
      return nil;
    }
    NSIndexPath *indexPath = [tableView indexPathForRowAtPoint:location];
    if (indexPath) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        [previewingContext setSourceRect:cell.frame];
        if (cell) {
          NSInteger index = 0;
          for (int i = 0; i < indexPath.section; i++) {
              index += [tableView numberOfRowsInSection:i];
          }
          index += indexPath.row;
          NSArray *packages = MSHookIvar<NSArray *>(self,"packages_");
          if (packages && packages.count > index) {
            Package *package = [packages objectAtIndex:index];
            if (package) {
              CYPackageController *packageController = [[%c(CYPackageController) alloc] initWithDatabase:[%c(Database) sharedInstance] forPackage:[package id] withReferrer:[self referrerURL].absoluteString];
              [packageController setDelegate:[UIApplication sharedApplication]];
              return packageController;
            }
          }
        }
    }
    return nil;
}
%new
- (void)previewingContext:(id <UIViewControllerPreviewing>)previewingContext commitViewController:(CYPackageController *)viewControllerToCommit {
    [viewControllerToCommit reloadData];
    [self showViewController:viewControllerToCommit sender:self];
}

%end

%hook CYPackageController

%new
-(NSArray *)previewActionItems {
  Package *package = MSHookIvar<Package *>(self,"package_");
  if (package == nil) {
    return @[];
  }
  UIPreviewAction *packageAction = [%c(UIPreviewAction) actionWithTitle:([package uninstalled] ? ([package isCommercial] ? LOCALIZED(@"Purchase") : LOCALIZED(@"Install")) : LOCALIZED(@"Remove")) style:0 handler:^(UIPreviewAction *action, UIViewController *viewController) {
    if ([package uninstalled]) {
      [package install];
    } else if ([package isCommercial]) {

    } else {
      [package remove];
    }
    [(Cydia *)[UIApplication sharedApplication] queue];
  }];
  return @[packageAction];
}

%end

%hook Cydia

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  BOOL x = %orig;
  if ([launchOptions objectForKey:@"UIApplicationLaunchOptionsShortcutItemKey"]) {
      [self handleShortcutItem:[launchOptions objectForKey:@"UIApplicationLaunchOptionsShortcutItemKey"]];
  }
  return x;
}

%new
-(void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void (^)(BOOL))completionHandler {
    [self handleShortcutItem:shortcutItem];
}

%new
-(void)handleShortcutItem:(UIApplicationShortcutItem *)item {
  __block BOOL loaded = MSHookIvar<BOOL>(self,"loaded_");
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT,0),^{
    while (!loaded) {
      loaded = MSHookIvar<BOOL>(self,"loaded_");
    }
    dispatch_async(dispatch_get_main_queue(),^{
      CydiaTabBarController *tabBarController = MSHookIvar<CydiaTabBarController *>(self,"tabbar_");
      if ([item.type isEqualToString:@"tactful_search"]) {
        UINavigationController *searchViewController = [tabBarController.viewControllers lastObject];
        [tabBarController setSelectedIndex:[tabBarController.viewControllers indexOfObject:searchViewController]];
        if (searchViewController.view.subviews.count > 1) {
          UIView *subview = [searchViewController.view.subviews objectAtIndex:1];
          if ([subview isKindOfClass:[UINavigationBar class]]) {
            [((UINavigationBar *)subview).topItem.titleView becomeFirstResponder];
          }
        }
      } else if ([item.type isEqualToString:@"tactful_recent"]) {
        UINavigationController *installedViewController = [tabBarController.viewControllers objectAtIndex:3];
        [tabBarController setSelectedIndex:3];
        if (installedViewController.view.subviews.count > 1) {
          UIView *subview = [installedViewController.view.subviews objectAtIndex:1];
          if ([subview isKindOfClass:[UINavigationBar class]]) {
            UIView *titleView = ((UINavigationBar *)subview).topItem.titleView;
            if ([titleView isKindOfClass:[UISegmentedControl class]]) {
              [((UISegmentedControl *)titleView) setSelectedSegmentIndex:((UISegmentedControl *)titleView).numberOfSegments-1];
              [((UISegmentedControl *)titleView) sendActionsForControlEvents:UIControlEventValueChanged];
            }
          }
        }
      } else if ([item.type isEqualToString:@"tactful_addrepo"]) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"cydia://sources/add"] options:@{} completionHandler:nil];
      } else if ([item.type isEqualToString:@"tactful_refreshrepo"]) {
        [tabBarController setSelectedIndex:2];
        [self requestUpdate];
      }
    });
  });
}

%end

%hook SBUIAppIconForceTouchControllerDataProvider

- (id)applicationShortcutItems { //iOS 10 - 11

	NSArray *applicationShortcutItems = %orig;
	NSMutableArray *items = [NSMutableArray arrayWithArray:applicationShortcutItems];

  if ([self.applicationBundleIdentifier isEqualToString:@"com.saurik.Cydia"]) {

    SBSApplicationShortcutItem *refreshReposItem = [[%c(SBSApplicationShortcutItem) alloc] init];
    [refreshReposItem setType:@"tactful_refreshrepo"];
    [refreshReposItem setLocalizedTitle:LOCALIZED(@"Refresh Repos")];
    SBSApplicationShortcutSystemIcon *refreshReposIcon = [%c(SBSApplicationShortcutSystemIcon) alloc];
    refreshReposIcon = [refreshReposIcon initWithType:15]; //UIApplicationShortcutIconTypeConfirmation
    [refreshReposItem setIcon:refreshReposIcon];
    [items addObject:refreshReposItem];

    SBSApplicationShortcutItem *addRepoItem = [[%c(SBSApplicationShortcutItem) alloc] init];
    [addRepoItem setType:@"tactful_addrepo"];
    [addRepoItem setLocalizedTitle:LOCALIZED(@"Add Repo")];
    SBSApplicationShortcutSystemIcon *addRepoIcon = [%c(SBSApplicationShortcutSystemIcon) alloc];
    addRepoIcon = [addRepoIcon initWithType:3]; //UIApplicationShortcutIconTypeAdd
    [addRepoItem setIcon:addRepoIcon];
    [items addObject:addRepoItem];

    SBSApplicationShortcutItem *searchItem = [[%c(SBSApplicationShortcutItem) alloc] init];
    [searchItem setType:@"tactful_search"];
    [searchItem setLocalizedTitle:LOCALIZED(@"Search Cydia")];
    SBSApplicationShortcutSystemIcon *searchIcon = [%c(SBSApplicationShortcutSystemIcon) alloc];
    searchIcon = [searchIcon initWithType:5]; //UIApplicationShortcutIconTypeSearch
    [searchItem setIcon:searchIcon];
    [items addObject:searchItem];

    SBSApplicationShortcutItem *recentInstallationItem = [[%c(SBSApplicationShortcutItem) alloc] init];
    [recentInstallationItem setType:@"tactful_recent"];
    [recentInstallationItem setLocalizedTitle:LOCALIZED(@"Recent Installations")];
    SBSApplicationShortcutSystemIcon *installIcon = [%c(SBSApplicationShortcutSystemIcon) alloc];
    installIcon = [installIcon initWithType:14]; //UIApplicationShortcutIconTypeInvitation
    [recentInstallationItem setIcon:installIcon];
    [items addObject:recentInstallationItem];

  }
  return [items copy];
}

%end
