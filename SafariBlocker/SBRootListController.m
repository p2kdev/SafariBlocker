#import <Preferences/Preferences.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSTextFieldSpecifier.h>
#include <objc/runtime.h>
#import <spawn.h>

@interface LSApplicationProxy
	+(id)applicationProxyForIdentifier:(NSString *)bundleId;
	-(NSURL *)containerURL;
@end

@interface TBRootListController : PSListController
@end

@interface TBGeneralListController : PSListController
	@property (nonatomic,retain) NSMutableArray *dataList;
	@property (nonatomic,assign) NSString *dataListKey;
 	@property (nonatomic,retain) UITextView *currentTextView;
	-(void)updateDataToPrefsFile;
	-(id)initForType:(int)type;
@end

NSString *prefFilePath;

@implementation TBRootListController

- (id)init
{
	self = [super init];
	//Get documents directory
	prefFilePath = [[[[objc_getClass("LSApplicationProxy") applicationProxyForIdentifier:@"com.apple.mobilesafari"] containerURL] path] stringByAppendingPathComponent:@"Library/Preferences/com.p2kdev.safariblocker.plist"];
	return self;
}

- (id)specifiers
{
	if(_specifiers == nil)
	{
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

- (void)launchAllowedDomainOptions {
	[self pushController:[[TBGeneralListController alloc] initForType:1] animate:YES];
}

- (void)launchBlockedDomainOptions {
	[self pushController:[[TBGeneralListController alloc] initForType:2] animate:YES];
}

- (void)launchBlockedURLOptions {
	[self pushController:[[TBGeneralListController alloc] initForType:3] animate:YES];
}

-(id)readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *tweakSettings = [NSDictionary dictionaryWithContentsOfFile:prefFilePath];

		NSString *key = [specifier propertyForKey:@"key"];
		id defaultValue = [specifier propertyForKey:@"default"];
		id plistValue = [tweakSettings objectForKey:key];

		if (!plistValue) plistValue = defaultValue;

    return plistValue;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {

		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefFilePath]];

		NSString *newKey = [specifier propertyForKey:@"key"];
		id specifierValue = value;
		[defaults setObject:specifierValue forKey:newKey];
		[defaults writeToFile:prefFilePath atomically:YES];

		CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
		if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

- (void)visitTwitter {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://twitter.com/p2kdev"]];
}

@end

@implementation TBGeneralListController

- (id)initForType:(int)type
{
	self = [super init];
	if (self) {

		self.dataList = [[NSMutableArray alloc] init];
		if (type == 1)
			self.dataListKey = @"allowedDomains";
		else if (type == 2)
			self.dataListKey = @"blockedDomains";
		else if (type == 3)
			self.dataListKey = @"blockedURLs";
	}
	return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {

		_specifiers = [[NSMutableArray alloc] init];

		NSMutableDictionary *tweakSettings = [[NSMutableDictionary alloc] initWithContentsOfFile:prefFilePath];
		id plistValue = [tweakSettings objectForKey:self.dataListKey];

		if (plistValue)
		{
			int index = 1;
			self.dataList = [[plistValue componentsSeparatedByString:@";"] mutableCopy];

			for (NSString *currData in self.dataList)
			{
				if ([currData length] == 0)
					continue;

				NSString *newDataLabel = [NSString stringWithFormat:@"#%d",index];
				PSTextFieldSpecifier  *newData = [PSTextFieldSpecifier preferenceSpecifierNamed:newDataLabel
																										target:self
																										set:@selector(setPreferenceValue:specifier:)
																										get:@selector(readPreferenceValue:)
																										detail:Nil
																										cell:PSEditTextCell
																										edit:Nil];
				[newData setProperty:newDataLabel forKey:@"key"];
				[newData setProperty:@"com.p2kdev.safariblocker.settingschanged" forKey:@"PostNotification"];
				[newData setProperty:@YES forKey:@"enabled"];
				[newData setPlaceholder:@"Enter the url/domain to block"];
				//[newNumber setKeyboardType:4 autoCaps:NO autoCorrection:UITextAutocorrectionTypeDefault];
				[_specifiers addObject:newData];

				index++;
			}
		}
	}

	return _specifiers;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

	// if the cell is an editable cell, it's either the apple id or password cell
	if ([cell isKindOfClass:objc_getClass("PSEditableTableCell")])
	{
		PSEditableTableCell *editableCell = (PSEditableTableCell *)cell;
		if (editableCell.textField)
		{
			UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
			[keyboardDoneButtonView sizeToFit];
			UIBarButtonItem *flexBarButton = [[UIBarButtonItem alloc]
			    initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
			    target:self action:nil];

			UIBarButtonItem *doneBarButton = [[UIBarButtonItem alloc]
			    initWithBarButtonSystemItem:UIBarButtonSystemItemDone
			    target:self action:@selector(doneClicked:)];

			keyboardDoneButtonView.items = [NSArray arrayWithObjects:flexBarButton,doneBarButton,nil];
			//[keyboardDoneButtonView setItems:[NSArray arrayWithObjects:doneButton, nil]];
	    ((UITextField *)editableCell.textField).inputAccessoryView = keyboardDoneButtonView;
		}
	}

	return cell;
}

- (IBAction)doneClicked:(id)sender
{
    //NSLog(@"Done Clicked.");
    [self.view endEditing:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return YES - we will be able to delete all rows
		if (indexPath.row <= [self.dataList count] - 1)
		{
			return YES;
		}
    return NO;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	[self.dataList removeObjectAtIndex:indexPath.row];
	[self updateDataToPrefsFile];
	[self reloadSpecifiers];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.p2kdev.safariblocker.settingschanged"), NULL, NULL, YES);
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {

	id plistValue = nil;
	NSString *key = [specifier propertyForKey:@"key"];
	if ([key hasPrefix:@"#"])
	{
		key = [key stringByReplacingOccurrencesOfString:@"#"	withString:@""];
		int objectIndex = [key integerValue]-1;
		if ([self.dataList count] > objectIndex)
			plistValue = [self.dataList objectAtIndex:[key integerValue]-1];
	}

	return plistValue;
}

-(void)updateDataToPrefsFile
{
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefFilePath]];
	[defaults setObject:[self.dataList componentsJoinedByString:@";"] forKey:self.dataListKey];
	[defaults writeToFile:prefFilePath atomically:YES];
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {

		NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
		[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:prefFilePath]];

		NSString *newKey = [specifier propertyForKey:@"key"];
		id specifierValue = value;
		if ([newKey hasPrefix:@"#"])
		{
			newKey = [newKey stringByReplacingOccurrencesOfString:@"#"	withString:@""];

			self.dataList[[newKey integerValue]-1] = specifierValue;
			specifierValue = [self.dataList componentsJoinedByString:@";"];
			newKey = self.dataListKey;
		}

		[defaults setObject:specifierValue forKey:newKey];
		[defaults writeToFile:prefFilePath atomically:YES];

		CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
		if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}

@end
