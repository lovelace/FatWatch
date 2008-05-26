//
//  WebServerDelegate.m
//  EatWatch
//
//  Created by Benjamin Ragheb on 5/17/08.
//  Copyright 2008 Benjamin Ragheb. All rights reserved.
//

#import "WebServerDelegate.h"
#import "MonthData.h"
#import "CSVWriter.h"
#import "CSVReader.h"
#import "MicroWebServer.h"
#import "Database.h"
#import "FormDataParser.h"


#define HTTP_STATUS_OK 200
#define HTTP_STATUS_NOT_FOUND 404

@interface WebServerDelegate ()
- (NSDateFormatter *)dateFormatter;
- (void)handleExport:(MicroWebConnection *)connection;
- (void)handleImport:(MicroWebConnection *)connection;
- (void)performImport;
- (void)sendResourceNamed:(NSString *)name withSubstitutions:(NSDictionary *)substitutions toConnection:(MicroWebConnection *)connection;
@end



@implementation WebServerDelegate


- (void)handleWebConnection:(MicroWebConnection *)connection {
	NSString *path = [[connection requestURL] path];
	
	printf("%s <%s>\n", [[connection requestMethod] UTF8String], [path UTF8String]);
	
	if ([path isEqualToString:@"/"]) {
		UIDevice *device = [UIDevice currentDevice];
		NSDictionary *subst = [NSDictionary dictionaryWithObjectsAndKeys:
							   [device localizedModel], @"__MODEL__",
							   [device name], @"__NAME__",
							   nil];
		[self sendResourceNamed:@"home" withSubstitutions:subst toConnection:connection];
		return;
	}
	
	if ([path hasPrefix:@"/export/"]) {
		[self handleExport:connection];
		return;
	}
	
	if ([path isEqualToString:@"/import"]) {
		[self handleImport:connection];
		return;
	}
	
	// handle robots.txt, favicon.ico
	
	[connection setResponseStatus:HTTP_STATUS_NOT_FOUND];
	[connection setValue:@"text/plain" forResponseHeader:@"Content-Type"];
	[connection setResponseBodyString:@"Not Found"];
}


- (void)sendResourceNamed:(NSString *)name withSubstitutions:(NSDictionary *)substitutions toConnection:(MicroWebConnection *)connection {
	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"html"];

	if (path == nil) {
		[connection setResponseStatus:HTTP_STATUS_NOT_FOUND];
		[connection setValue:@"text/plain" forResponseHeader:@"Content-Type"];
		[connection setResponseBodyString:[NSString stringWithFormat:@"Resource '%@' Not Found", name]];
		return;
	}
	
	NSMutableString *text = [[NSMutableString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];

	for (NSString *key in [substitutions allKeys]) {
		[text replaceOccurrencesOfString:key
							  withString:[substitutions objectForKey:key]
								 options:0
								   range:NSMakeRange(0, [text length])];
	}
	
	[connection setResponseStatus:HTTP_STATUS_OK];
	[connection setValue:@"text/html" forResponseHeader:@"Content-Type"];
	[connection setResponseBodyData:[text dataUsingEncoding:NSUTF8StringEncoding]];
	
	[text release];
}


- (NSDateFormatter *)dateFormatter {
	NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
	[formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
	[formatter setDateStyle:NSDateFormatterShortStyle];
	[formatter setTimeStyle:NSDateFormatterNoStyle];
	return [formatter autorelease];
}


- (void)handleExport:(MicroWebConnection *)connection {
	CSVWriter *writer = [[CSVWriter alloc] init];
	
	NSDateFormatter *formatter = [self dateFormatter];
	
	Database *db = [Database sharedDatabase];
	EWMonth month;
	for (month = db.earliestMonth; month <= db.latestMonth; month += 1) {
		MonthData *md = [db dataForMonth:month];
		EWDay day;
		for (day = 1; day <= 31; day++) {
			float measuredWeight = [md measuredWeightOnDay:day];
			NSString *note = [md noteOnDay:day];
			BOOL flag = [md isFlaggedOnDay:day];
			if (measuredWeight > 0 || note != nil || flag) {
				[writer addString:[formatter stringFromDate:[md dateOnDay:day]]];
				[writer addFloat:measuredWeight];
				[writer addFloat:[md trendWeightOnDay:day]];
				[writer addBoolean:flag];
				[writer addString:note];
				[writer endRow];
			}
		}
	}
	
	[connection setResponseStatus:HTTP_STATUS_OK];
	[connection setValue:@"text/csv" forResponseHeader:@"Content-Type"];
	[connection setResponseBodyData:[writer data]];
	[writer release];
	return;
}


- (void)handleImport:(MicroWebConnection *)connection {
	if (importData != nil) {
		[self sendResourceNamed:@"importPending" withSubstitutions:nil toConnection:connection];
		return;
	}
	
	FormDataParser *form = [[FormDataParser alloc] initWithConnection:connection];

	importData = [[form dataForKey:@"filedata"] retain];
	importReplace = [[form stringForKey:@"how"] isEqualToString:@"replace"];
	
	if (importData == nil) {
		[self sendResourceNamed:@"importNoData" withSubstitutions:nil toConnection:connection];
		return;
	}
	
	NSString *saveButtonTitle = importReplace ? @"Replace" : @"Merge";
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Data Received" message:@"Data was received, do you want to store it in this phone?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:saveButtonTitle, nil];
	[alert show];
	[alert release];
	
	[self sendResourceNamed:@"importAccepted" withSubstitutions:nil toConnection:connection];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[self performImport];
	}
	[importData release];
	importData = nil;
}


- (void)performImport {
	const Database *db = [Database sharedDatabase];

	if (importReplace) {
		[db deleteWeights];
	}
	
	NSUInteger count = 0;
	CSVReader *reader = [[CSVReader alloc] initWithData:importData];
	
	NSDateFormatter *formatter = [self dateFormatter];
	
	while ([reader nextRow]) {
		NSString *dateString = [reader readString];
		if (dateString == nil) continue;
		NSDate *date = [formatter dateFromString:dateString];
		if (date == nil) continue;
		
		float measuredWeight = [reader readFloat];
		[reader readFloat]; // skip trendWeight
		BOOL flag = [reader readBoolean];
		NSString *note = [reader readString];
		
		if (measuredWeight > 0 || note != nil || flag) {
			EWMonthDay monthday = EWMonthDayFromDate(date);
			MonthData *md = [db dataForMonth:EWMonthDayGetMonth(monthday)];
			[md setMeasuredWeight:measuredWeight flag:flag note:note onDay:EWMonthDayGetDay(monthday)];
			count++;
		}
	}
	
	[reader release];
	[db commitChanges];

	NSString *msg;
	
	if (count > 0) {
		msg = [NSString stringWithFormat:@"%d records imported.", count];
	} else {
		msg = @"No records imported.  The file may not be in the correct format.";
	}
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Import Complete" message:msg delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}


@end
