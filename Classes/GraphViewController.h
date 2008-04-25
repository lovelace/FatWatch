//
//  GraphViewController.h
//  EatWatch
//
//  Created by Benjamin Ragheb on 3/29/08.
//  Copyright 2008 Benjamin Ragheb. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Database;

@interface GraphViewController : UIViewController {
	BOOL firstLoad;
	NSUInteger dbChangeCount;
	UILabel *warningLabel;
	UIScrollView *scrollView;
}
- (id)init;
@end
