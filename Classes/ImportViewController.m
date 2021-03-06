/*
 * ImportViewController.m
 * Created by Benjamin Ragheb on 5/1/11.
 * Copyright 2015 Heroic Software Inc
 *
 * This file is part of FatWatch.
 *
 * FatWatch is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FatWatch is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with FatWatch.  If not, see <http://www.gnu.org/licenses/>.
 */

#import "ImportViewController.h"
#import "EWImporter.h"
#import "EWDatabase.h"

@implementation ImportViewController
{
    UILabel *titleLabel;
    UIProgressView *importProgressView;
    UILabel *detailLabel;
    UIButton *okButton;
    EWImporter *importer;
    EWDatabase *database;
    BOOL promptBeforeImport;
}

@synthesize titleLabel;
@synthesize importProgressView;
@synthesize detailLabel;
@synthesize okButton;
@synthesize promptBeforeImport;

- (id)initWithImporter:(EWImporter *)theImporter database:(EWDatabase *)db
{
    if ((self = [super initWithNibName:@"ImportView" bundle:nil])) {
        importer = theImporter;
        importer.delegate = self;
        database = db;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}


- (void)viewDidUnload
{
    [self setTitleLabel:nil];
    [self setImportProgressView:nil];
    [self setDetailLabel:nil];
    [self setOkButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSMutableString *msg = [[NSMutableString alloc] init];
    if ([importer.columnDefaults count] > 0) {
        NSMutableIndexSet *idxs = [NSMutableIndexSet indexSet];
        [importer.columnDefaults enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [idxs addIndex:[obj unsignedIntegerValue]];
        }];
        NSMutableArray *names = [NSMutableArray array];
        [idxs enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            [names addObject:(importer.columnNames)[(idx - 1)]];
        }];
        [msg appendString:@"Found columns "];
        [msg appendString:[names componentsJoinedByString:@", "]];
        [msg appendString:@"."];
    } else {
        [msg appendString:@"No columns found."];
    }
    [msg appendString:@"\n\n"];
    self.titleLabel.text = @"Importing";
    self.importProgressView.progress = 0;
    self.detailLabel.text = msg;
    self.okButton.hidden = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (self.promptBeforeImport) {
        UIActionSheet *sheet = [[UIActionSheet alloc] init];
        sheet.destructiveButtonIndex = [sheet addButtonWithTitle:@"Delete & Import"];
        [sheet addButtonWithTitle:@"Merge Import"];
        sheet.cancelButtonIndex = [sheet addButtonWithTitle:@"Cancel"];
        sheet.delegate = self;
        [sheet showInView:self.view];
    } else {
        [importer performImportToDatabase:database];
    }
}

#pragma mark IB Actions

- (IBAction)okAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.cancelButtonIndex == buttonIndex) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    importer.deleteFirst = (actionSheet.destructiveButtonIndex == buttonIndex);
    [importer performImportToDatabase:database];
}

#pragma mark EWImporterDelegate

- (void)importer:(EWImporter *)anImporter importProgress:(float)progress {
    self.importProgressView.progress = progress;
}

- (void)importer:(EWImporter *)anImporter didImportNumberOfMeasurements:(unsigned int)importedCount outOfNumberOfRows:(unsigned int)rowCount {
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kEWLastImportKey];
	
	NSString *msg;
    
	// \xc2\xa0 : NO-BREAK SPACE
	if (importedCount > 0) {
		msg = [NSString stringWithFormat:NSLocalizedString(@"Imported %d\xc2\xa0measurements;\n%d\xc2\xa0lines ignored.", @"After import, count of lines read and ignored."), 
			   importedCount,
			   rowCount - importedCount];
	} else {
		msg = [NSString stringWithFormat:NSLocalizedString(@"Read %d\xc2\xa0rows but no measurements were found. The file may not be in the correct format.", @"After import, count of lines read, nothing imported."),
			   rowCount];
	}
    
    self.importProgressView.progress = 1.0f;
    self.titleLabel.text = @"Import Complete";
    self.detailLabel.text = [self.detailLabel.text stringByAppendingString:msg];
    self.okButton.hidden = NO;
}

@end
