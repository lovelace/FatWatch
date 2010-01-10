//
//  EnergyViewController.h
//  EatWatch
//
//  Created by Benjamin Ragheb on 1/5/10.
//  Copyright 2010 Benjamin Ragheb. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EWEnergyFormatter;
@class NewEquivalentViewController;

@interface EnergyViewController : UITableViewController {
	float weight;
	float energy;
	NSArray *titleArray;
	NSArray *dataArray;
	NSMutableArray *deletedItemArray;
	EWEnergyFormatter *energyFormatter;
	BOOL dirty;
	NewEquivalentViewController *newEquivalentController;
}
- (id)initWithWeight:(float)weight andChangePerDay:(float)rate;
@end