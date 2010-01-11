//
//  EWWeightFormatter.h
//  EatWatch
//
//  Created by Benjamin Ragheb on 12/20/09.
//  Copyright 2009 Benjamin Ragheb. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSUserDefaults+EWAdditions.h"


typedef enum {
	EWWeightFormatterStyleDisplay,
	EWWeightFormatterStyleVariance,
	EWWeightFormatterStyleWhole,
	EWWeightFormatterStyleGraph,
	EWWeightFormatterStyleExport,
	EWWeightFormatterStyleBMI,
	EWWeightFormatterStyleBMILabeled
} EWWeightFormatterStyle;


@interface NSFormatter (EWAdditions)
- (NSString *)stringForFloat:(float)value;
@end


@interface EWWeightFormatter : NSFormatter {
}
+ (void)getBMIWeights:(float *)weightArray;
+ (UIColor *)colorForWeight:(float)weight;
+ (UIColor *)backgroundColorForWeight:(float)weight;
+ (id)weightFormatterWithStyle:(EWWeightFormatterStyle)style unit:(EWWeightUnit)unit;
+ (id)weightFormatterWithStyle:(EWWeightFormatterStyle)style;
@end
