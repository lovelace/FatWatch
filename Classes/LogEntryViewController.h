//
//  LogEntryViewController.h
//  EatWatch
//
//  Created by Benjamin Ragheb on 3/30/08.
//  Copyright 2008 Benjamin Ragheb. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EWDate.h"

@class BRTextView;
@class EWDBMonth;

@interface LogEntryViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate> {
	EWDBMonth *monthData;
	EWDay day;
	BOOL weighIn;
	UISegmentedControl *weightControl;
	UIView *weightContainerView;
	UIPickerView *weightPickerView;
	UIView *noWeightView;
	BRTextView *noteView;
	UIView *annotationContainerView;
	UINavigationBar *navigationBar;
	UIButton *flag0Button;
	UIButton *flag1Button;
	UIButton *flag2Button;
	UIButton *flag3Button;
	UIButton *flagButtons[4];
	float scaleIncrement;
	NSInteger weightRow, fatRow;
	int weightMode;
	NSFormatter *weightFormatter;
}
+ (LogEntryViewController *)sharedController;
@property (nonatomic,retain) IBOutlet UISegmentedControl *weightControl;
@property (nonatomic,retain) IBOutlet UIView *weightContainerView;
@property (nonatomic,retain) IBOutlet UIPickerView *weightPickerView;
@property (nonatomic,retain) IBOutlet UIView *noWeightView;
@property (nonatomic,retain) IBOutlet BRTextView *noteView;
@property (nonatomic,retain) IBOutlet UIView *annotationContainerView;
@property (nonatomic,retain) IBOutlet UINavigationBar *navigationBar;
@property (nonatomic,retain) IBOutlet UIButton *flag0Button;
@property (nonatomic,retain) IBOutlet UIButton *flag1Button;
@property (nonatomic,retain) IBOutlet UIButton *flag2Button;
@property (nonatomic,retain) IBOutlet UIButton *flag3Button;
- (void)configureForDay:(EWDay)aDay dbMonth:(EWDBMonth *)aDBMonth isWeighIn:(BOOL)isWeighIn;
- (IBAction)toggleWeightAction:(id)sender;
- (IBAction)toggleFlagButton:(UIButton *)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;
@end
