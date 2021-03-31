#import <Foundation/Foundation.h>
#import <libundirect/libundirect.h>
#import <libundirect/libundirect_hookoverwrite.h>
#import "Bagel/Bagel.h"

//Credits to MrChrisBarker for ToastMenu https://github.com/MrChrisBarker/bagel-objectivec-toast

@interface LoadingController : NSObject
- (NSURL*)URL;
@end

@interface TabDocument : NSObject
@end

@interface TabController : NSObject
  -(void)updateSafariBlockerPrefsForActionType:(int)action blockedData:(NSString*)content;
  -(void)showToastWithMessage:(NSString*)arg1;
@end

@interface SFBarRegistration : NSObject
- (BOOL)containsBarItem:(NSInteger)barItem;
@end

@interface _SFToolbar : NSObject
@property (nonatomic,weak) SFBarRegistration* barRegistration;
@end

@interface BrowserToolbar : _SFToolbar
@end

@interface NavigationBar : NSObject
- (id)_toolbarForBarItem:(NSInteger)barItem;
@end

@interface BrowserRootViewController : UIViewController
@property (readonly, nonatomic) BrowserToolbar* bottomToolbar;
@property (readonly, nonatomic) NavigationBar* navigationBar;
@end

static _SFToolbar* activeToolbarOrToolbarForBarItemForBrowserRootViewController(BrowserRootViewController* rootVC, NSInteger barItem)
{
	if(!rootVC) return nil;

  if([rootVC.bottomToolbar.barRegistration containsBarItem:barItem])
  {
    return rootVC.bottomToolbar;
  }
  else 
  {
    if([rootVC.navigationBar respondsToSelector:@selector(_toolbarForBarItem:)])
    {
      return [rootVC.navigationBar _toolbarForBarItem:barItem];
    }
    else //iOS 14
    {
      _SFToolbar* leadingToolbar = [rootVC.navigationBar valueForKey:@"_leadingToolbar"];
      _SFToolbar* trailingToolbar = [rootVC.navigationBar valueForKey:@"_trailingToolbar"];

      if([leadingToolbar.barRegistration containsBarItem:barItem])
      {
        return (BrowserToolbar*)leadingToolbar;
      }

      if([trailingToolbar.barRegistration containsBarItem:barItem])
      {
        return (BrowserToolbar*)trailingToolbar;
      }

      return nil;
    }
  }
}

//Store the preferences in Safari Home Directory to avoid sandbox issues
#define prefFilePath [NSString stringWithFormat:@"%@/Library/Preferences/com.p2kdev.safariblocker.plist", NSHomeDirectory()]

static BOOL skipNextTabOpen = NO;

static NSMutableArray * blockedURLs;
static NSMutableArray * blockedDomains;
static NSMutableArray * allowedDomains;
static bool showBagelMenu = YES;

static NSString* removeJunk(NSString* url)
{
  url = [url stringByReplacingOccurrencesOfString:@"//" withString:@""];
  url = [url stringByReplacingOccurrencesOfString:@"http://" withString:@""];
  url = [url stringByReplacingOccurrencesOfString:@"https://" withString:@""];
  url = [url stringByReplacingOccurrencesOfString:@"www." withString:@""];
  return url;
}

%hook TabController

  - (void)_insertTabDocument:(id)tabDocument atIndex:(NSUInteger)index inBackground:(BOOL)inBackground animated:(BOOL)animated updateUI:(BOOL)updateUI
  {
    if(skipNextTabOpen)
    {
      %orig;
      skipNextTabOpen = NO;
      return;
    }

    TabDocument *originalTab;

    @try
    {
      //Attempt to fetch the parent tab for the new tab which is being opened
      originalTab = MSHookIvar<TabDocument*>(tabDocument,"_parentTabDocumentForBackClosesSpawnedTab");
    }
    @catch(NSException* ex)
    {
      NSLog(@"Error while fetching parentTab %@",ex.reason);
    }

    LoadingController* loadingController = [originalTab valueForKey:@"_loadingController"];
    NSURL *originalURL = [loadingController URL];

    if (originalTab && originalURL)
    {
        NSString *domainForURL = removeJunk([originalURL host]);
        NSString *URLWithoutJunk = removeJunk([originalURL resourceSpecifier]);

        //Check if the domain is whitelisted
        if ([allowedDomains containsObject:domainForURL])
        {
            %orig;
            return;
        }

        //Block the Tab if domain is blacklisted
        if ([blockedDomains containsObject:domainForURL])
        {
            if (showBagelMenu)
              [self showToastWithMessage:[NSString stringWithFormat:@"Blocked pop-up from Domain - \r %@",domainForURL]];
            return;
        }

        //Check for URL in blacklistedURLs
        for (id tempURL in blockedURLs)
        {
            NSString *tempURLWithoutJunk = removeJunk(tempURL);

            if ([tempURLWithoutJunk isEqualToString:URLWithoutJunk])
            {
                if (showBagelMenu)
                  [self showToastWithMessage:[NSString stringWithFormat:@"Blocked pop-up from URL - \r %@",URLWithoutJunk]];
                return;
            }
        }


        NSString *msg = [NSString stringWithFormat:@"What would you like to do with this Tab? \r\r Domain : %@ \r\r URL : %@",domainForURL,URLWithoutJunk];

        UIAlertController * alert = [UIAlertController
                    alertControllerWithTitle:@"SafariBlocker"
                    message:msg
                    preferredStyle:UIAlertControllerStyleActionSheet];

        UIAlertAction* allowOnce = [UIAlertAction
                                    actionWithTitle:@"Allow once"
                                    style:UIAlertActionStyleDefault
                                    handler:^(UIAlertAction * action) {
                                          %orig;
                  }];

          UIAlertAction* allowDomain = [UIAlertAction
                                      actionWithTitle:@"Whitelist Domain"
                                      style:UIAlertActionStyleDefault
                                      handler:^(UIAlertAction * action) {
                                            [self updateSafariBlockerPrefsForActionType:1 blockedData:domainForURL];
                                            %orig;
                    }];

          UIAlertAction* blockDomain = [UIAlertAction
                                      actionWithTitle:@"Block Domain"
                                      style:UIAlertActionStyleDestructive
                                      handler:^(UIAlertAction * action) {
                                            [self updateSafariBlockerPrefsForActionType:2 blockedData:domainForURL];

                    }];

          UIAlertAction* blockURL = [UIAlertAction
                                      actionWithTitle:@"Block URL"
                                      style:UIAlertActionStyleDestructive
                                      handler:^(UIAlertAction * action) {
                                            [self updateSafariBlockerPrefsForActionType:3 blockedData:URLWithoutJunk];
                    }];

          UIAlertAction* cancelAction = [UIAlertAction
                                      actionWithTitle:@"Cancel"
                                      style:UIAlertActionStyleCancel
                                      handler:^(UIAlertAction * action) {
                    }];

            [alert addAction:allowOnce];
            [alert addAction:allowDomain];
            [alert addAction:blockDomain];
            [alert addAction:blockURL];
            [alert addAction:cancelAction];

            BrowserRootViewController* rootVC = [[self valueForKey:@"_browserController"] valueForKey:@"_rootViewController"];
            _SFToolbar* activeToolbar = activeToolbarOrToolbarForBarItemForBrowserRootViewController(rootVC, 5);
            if(activeToolbar)
            {
              //set popover position to tab expose item in toolbar (looks better on iPad)
              UIView* sourceView = [[activeToolbar.barRegistration valueForKey:@"_tabExposeItem"] valueForKey:@"_view"];
              if(sourceView)
              {
                alert.popoverPresentationController.sourceView = sourceView;
                alert.popoverPresentationController.sourceRect = sourceView.bounds;
              }
            }

            [rootVC presentViewController:alert animated:YES completion:nil];
      }
      else
        %orig;
  }

  %new
    -(void)showToastWithMessage:(NSString*)message
    {
      UIViewController* rootVC = [[self valueForKey:@"_browserController"] valueForKey:@"_rootViewController"];
      [[Bagel shared] pop:rootVC.view withMessage:message];
    }

  %new
    -(void)updateSafariBlockerPrefsForActionType:(int)action blockedData:(NSString*)content
    {
      if (!content)
        return;

      NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefFilePath]];

      switch(action)
      {
        case 1://WhiteList
        {
          [allowedDomains addObject:content];
          [defaults setObject:[allowedDomains componentsJoinedByString:@";"] forKey:@"allowedDomains"];
          break;
        }
        case 2://Block Domain
        {
          [blockedDomains addObject:content];
          [defaults setObject:[blockedDomains componentsJoinedByString:@";"] forKey:@"blockedDomains"];
          break;
        }
        case 3://Block URL
        {
          [blockedURLs addObject:content];
          [defaults setObject:[blockedURLs componentsJoinedByString:@";"] forKey:@"blockedURLs"];
          break;
        }
      }

    	[defaults writeToFile:prefFilePath atomically:YES];
    }
%end

static void updatePrefs(){

    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:prefFilePath];
    NSString * whitelistdomain = [prefs objectForKey:@"allowedDomains"] ? [[prefs objectForKey:@"allowedDomains"] stringValue] : @"";
    NSString * blacklistdomain = [prefs objectForKey:@"blockedDomains"] ? [[prefs objectForKey:@"blockedDomains"] stringValue] : @"";
    NSString * blacklisturl = [prefs objectForKey:@"blockedURLs"] ? [[prefs objectForKey:@"blockedURLs"] stringValue] : @"";
    showBagelMenu = [prefs objectForKey:@"showBagelMenu"] ? [[prefs objectForKey:@"showBagelMenu"] boolValue] : YES;

    //Populate our array's
    blockedURLs = [[blacklisturl componentsSeparatedByString:@";"] mutableCopy];
    blockedDomains = [[blacklistdomain componentsSeparatedByString:@";"] mutableCopy];
    allowedDomains = [[whitelistdomain componentsSeparatedByString:@";"] mutableCopy];
    [blockedURLs removeObject:@""];
    [blockedDomains removeObject:@""];
    [allowedDomains removeObject:@""];
}

typedef void (^UIActionHandler)(__kindof UIAction *action);
@interface UIAction (Private)
@property (nonatomic) UIActionHandler handler;
@end

%hook _SFLinkPreviewHelper

- (UIAction*)openInNewTabActionForURL:(NSURL*)arg1 preActionHandler:(id)arg2
{
  UIAction* action = %orig;

  UIActionHandler prevHandler = action.handler;
  action.handler = ^(__kindof UIAction* action)
  {
    skipNextTabOpen = YES;
    prevHandler(action);
    skipNextTabOpen = NO;
  };

  return action;
}

%end

//Thanks to @opa334 for the below stuff
#ifdef __arm64e__
#define ifArm64eElse(a,b) (a)
#else
#define ifArm64eElse(a,b) (b)
#endif

%ctor
{
  CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)updatePrefs, CFSTR("com.p2kdev.safariblocker.settingschanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
  updatePrefs();

  //obj_direct magic
  void* insertTabDocumentPtr = libundirect_find(@"MobileSafari", (unsigned char[]){0xF8, 0x03, 0x06, 0xAA, 0xF5, 0x03, 0x05, 0xAA}, 8, ifArm64eElse(0x7F, 0xFC));
	libundirect_rebind(insertTabDocumentPtr, NSClassFromString(@"TabController"), @selector(_insertTabDocument:atIndex:inBackground:animated:updateUI:), "v@:@QBBB");
}
