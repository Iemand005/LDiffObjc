//
//  LDDocument.m
//  Diffchiver
//
//  Created by Lasse Lauwerys on 10/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDDocument.h"


//?#import "LDiff.h"


@implementation LDDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"LDDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController
{
    [super windowControllerDidLoadNib:aController];
    
    goto fart;
    AuthorizationRef authref;
    OSStatus status;
    
    status = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagExtendRights | kAuthorizationFlagInteractionAllowed, &authref);
    AuthorizationItem items[1];
    items[0].name = kAuthorizationRightExecute;
    items[0].valueLength = 0;
    items[0].value = NULL;
    items[0].flags = 0;
    
    AuthorizationRights rights;
    rights.count = sizeof(items) / sizeof(items[0]);
    rights.items = items;
    
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagExtendRights;
    
    status = AuthorizationCopyRights(authref, &rights, kAuthorizationEmptyEnvironment, flags, NULL);
    
    if (status == errAuthorizationSuccess) {
        NSLog(@"successsssex");
        NSError *error;
        NSFileHandle *handlebar = [NSFileHandle fileHandleForReadingFromURL:[NSURL fileURLWithPath:@"/dev/disk0"] error:&error];
        NSLog(@"%@, %@", error.localizedDescription, error.localizedRecoverySuggestion);
    }
fart:
    
    [self setCalculateChecksum:YES];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:@"/dev/"];
    for (NSString *file in enumerator) {
        NSLog(@"%@", file);
        [(LDDiskTableController*)[[self diskTable] dataSource] addDisk:file];
        [[self diskTable] needsDisplay];
        [[self diskTable] reloadData];
    }
    [[self diskTable] needsDisplay];
    [[self diskTable] reloadData];
    
    NSLog(@"%li", undiffTool.outputFiles.count);
    if (undiffTool && undiffTool.layerFiles.count)
        for (int i = 0; i < undiffTool.layerFiles.count; ++i)
            [self.fileTableController addLayerFile:[undiffTool.layerFiles objectAtIndex:i] withOutputFile:[self->undiffTool.outputFiles objectAtIndex:i]];
    [self.fileTable reloadData];
}

- (void)chooseSelectedDisk:(id)sender
{
    NSString *selectedDisk = [[self diskTableController] getSelectedDisk];
    NSURL *diskURL = [NSURL fileURLWithPathComponents:@[@"/dev", selectedDisk]];
    NSLog(@"%@", diskURL);
    LDFile *file = [LDFile fileFromURL:diskURL];
    NSError *error;
    [file open:&error];
    NSLog(@"%@", error.localizedDescription);
    [[self fileTableController] addLayerFileWithURL:diskURL];
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

- (void)changeIndexingMethod:(id)sender
{
    [self setIndexingMethodMenu:[sender menu]];
    [self setIndexingMethod:[sender tag]];
}

- (void)changeCalculateChecksum:(id)sender
{
    [self setCalculateChecksumMenuItem:sender];
    [self setCalculateChecksum:![(NSMenuItem *)sender state]];
}

- (void)setCalculateChecksum:(BOOL)calculateChecksum
{
    [[self calculateChecksumMenuItem] setState:calculateChecksum];
}

- (BOOL)calculateChecksum
{
    return [[self calculateChecksumMenuItem] state];
}

- (void)setIndexingMethod:(UInt8)method
{
    for (NSMenuItem *item in [[self indexingMethodMenu] itemArray])
        [item setState:NSOffState];
    [[[self indexingMethodMenu] itemWithTag:method] setState:NSOnState];
}

- (UInt8)indexingMethod
{
    for (NSMenuItem *item in [[self indexingMethodMenu] itemArray]) {
        if ([item state] == NSOnState) return [item tag];
    }
    return 1;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    NSException *exception = [NSException exceptionWithName:@"UnimplementedMethod" reason:[NSString stringWithFormat:@"%@ is unimplemented", NSStringFromSelector(_cmd)] userInfo:nil];
    @throw exception;
    return nil;
}

- (BOOL)readFromURL:(NSURL *)url ofType:(NSString *)typeName error:(NSError *__autoreleasing *)outError
{
    undiffTool = [LDUndiffTool undiffTool];
    NSError *error;
    BOOL result = [undiffTool readHeaderFileWithURL:url error:&error];
    [[self fileTableController] setLayerFiles:[undiffTool layerFiles]];
    [[self fileTableController] setOutputFiles:[undiffTool outputFiles]];
    if (error) {
        [self displayError:error];
    } else return result;
    return YES;
}

- (void)displayError:(NSError *)error
{
    [[self errorDescriptionTextView] setString:[error localizedDescription]];
    [[self errorRecoveryOptionsTextView] setString:[error localizedRecoverySuggestion]];
    [[self errorPanel] setDefaultButtonCell:[self errorTryAgainButtonCell]];
    [NSApp beginSheet:[self errorPanel] modalForWindow:[self documentWindow] modalDelegate:self didEndSelector:nil contextInfo:NULL];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
    return self.fileTableController.hasSelectedItems;
}

- (void)openLayerFiles:(id)sender
{
    NSOpenPanel *filePicker = [NSOpenPanel openPanel];
    filePicker.showsHiddenFiles = YES;
    filePicker.canChooseDirectories = NO;
    filePicker.canCreateDirectories = NO;
    filePicker.allowsMultipleSelection = YES;
    [filePicker beginSheetModalForWindow:self.documentWindow completionHandler:^(NSInteger result) {
        if (result == NSOKButton)
            for (NSURL *url in filePicker.URLs)
                [self.fileTableController addLayerFileWithURL:url];
    }];
}

- (void)addLayerFiles
{
    NSOpenPanel *filePicker = [NSOpenPanel openPanel];
    filePicker.showsHiddenFiles = YES;
    filePicker.canChooseDirectories = NO;
    filePicker.canCreateDirectories = NO;
    filePicker.allowsMultipleSelection = YES;
    [filePicker beginSheetModalForWindow:self.documentWindow completionHandler:^(NSInteger result) {
        if (result == NSOKButton)
            for (NSURL *url in filePicker.URLs)
                [self.fileTableController addLayerFileWithURL:url];
        [self updateCloseButtonStatus];
    }];
}

- (void)updateCloseButtonStatus
{
    [self.documentWindow setDocumentEdited:self.fileTableController.layerFiles.count > 0];
}

- (IBAction)removeSelectedFiles:(id)sender
{
    [self.fileTableController removeSelectedItems];
    [self updateCloseButtonStatus];
}

- (void)setOutputFiles:(id)sender
{
    [self.fileTableController.tableView.selectedRowIndexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        NSSavePanel *savePanel = [NSSavePanel savePanel];
        [savePanel beginSheetModalForWindow:self.documentWindow completionHandler:^(NSInteger result){
            if (result == NSOKButton)
                [self.fileTableController setOutputFileWithURL: savePanel.URL at: index - 1];
        }];
    }];
}

- (BOOL)acceptsPreviewPanelControl:(QLPreviewPanel *)panel
{
    return YES;
}

- (void)beginPreviewPanelControl:(QLPreviewPanel *)panel
{
    [panel setDataSource:(id)[self fileTableController]];
    [panel setDelegate:[self fileTableDelegate]];
}

- (void)endPreviewPanelControl:(QLPreviewPanel *)panel
{
    panel.dataSource = nil;
    panel.delegate = nil;
}

- (BOOL)windowShouldClose:(id)sender
{
    BOOL requestConfirmation = self.fileTableController.layerFiles.count > 0;
    if(requestConfirmation) [NSApp beginSheet:self.confirmationPanel modalForWindow:self.documentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
    return !requestConfirmation;
}

- (IBAction)confirmCloseApplication:(id)sender
{
    [NSApp endSheet:self.confirmationPanel];
    [self.documentWindow close];
}

- (IBAction)moveUp:(id)sender
{
    [[self fileTableController] moveSelectedItemsUp:sender];
}

- (IBAction)moveDown:(id)sender
{
    [[self fileTableController] moveSelectedItemsDown:sender];
}

- (IBAction)compress:(id)sender
{
    [[self progressIndicator] setIndeterminate:YES];
    [[self progressIndicator] startAnimation:sender];
    [[self statusWindow] makeKeyAndOrderFront:self.documentWindow];
    NSLog(@"Compressing");
    LDFileTableViewController *fileTableController = self.fileTableController;
    NSArray *layerFiles = fileTableController.layerFiles;
    NSArray *outputFiles = fileTableController.outputFiles;
    if (layerFiles.count > 1) {
        NSLog(@"%li files", layerFiles.count-1);
        diffTool = [LDDiffTool diffTool];
        [diffTool setIndexingMethod:[self indexingMethod]];
        [diffTool setCalculateChecksum:[self calculateChecksum]];
        [diffTool setLayerFiles:layerFiles withOutputFiles:outputFiles];
        
        [self initProgressForTool:YES withAction:^{
            [diffTool compress];
        }];
        
    } else [NSApp beginSheet:self.compressionWarningPanel modalForWindow:self.documentWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (void)initProgressForTool:(BOOL)isCompressing withAction:(dispatch_block_t)action
{
    NSWindow *statusWindow = [self statusWindow];
    NSUInteger maxSize;
    
    NSWindow *thatusWindow = [self statusWindow];
    NSProgressIndicator *progressIndicator = [self progressIndicator];
    [thatusWindow makeKeyAndOrderFront:self.documentWindow];

    SEL command;
    if (isCompressing) {
        [[self statusWindow] setTitle:@"Compressing"];
        maxSize = [diffTool maxOffset];
        command = @selector(updateDisplayForDiffTool);
        
    } else {
        [[self statusWindow] setTitle:@"Extracting"];
         maxSize = [undiffTool maxOffset];
        command = @selector(updateDisplayForUndiffTool);
    }
    [self.progressIndicator setMaxValue:maxSize];
    
    [statusWindow setDocumentEdited:YES];
    [self.progressIndicator setIndeterminate:NO];
    [[self progressIndicator] stopAnimation:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        action();
        [timer invalidate];
        [self performSelector:command onThread:[NSThread mainThread] withObject:nil waitUntilDone:NO];
        dispatch_async(dispatch_get_main_queue(), ^{
            [statusWindow setTitle:[[statusWindow title] stringByAppendingString:@" - Done!"]];
            [self.progressIndicator setMaxValue:[diffTool maxOffset]];
            [progressIndicator setDoubleValue:[progressIndicator maxValue]];
            [statusWindow setDocumentEdited:NO];
        });
    });

    timer = [NSTimer timerWithTimeInterval:0.5 target:self selector:command userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)updateDisplayForDiffTool
{
    [self updateDisplay:[diffTool currentOffset]];
    [self.progressIndicator setMaxValue:[diffTool maxOffset]];
}

- (void)updateDisplayForUndiffTool
{
    [self updateDisplay:[undiffTool currentOffset]];
    [self.progressIndicator setMaxValue:[undiffTool maxOffset]];
}

- (void)updateDisplay:(double)progress
{
    [[self progressIndicator] setDoubleValue:progress];
    NSString *percentage = [NSString stringWithFormat:@"%f%%", self.progressIndicator.maxValue / progress * 100];
    [[self progressPercentageLabel] setStringValue:percentage];
    startTime = [[NSDate date] timeIntervalSince1970];
}

- (IBAction)extract:(id)sender
{
    [self initProgressForTool:NO withAction:^{
        [undiffTool extractAll];
    }];
}

- (IBAction)requestOutputDirectory:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowsMultipleSelection = NO;
    openPanel.canChooseDirectories = YES;
    openPanel.canChooseFiles = NO;
    openPanel.canCreateDirectories = YES;
    [openPanel beginSheetModalForWindow:self.documentWindow completionHandler:^(NSInteger result){
        if (result == NSOKButton) [self.fileTableController setOutputDirectory:openPanel.URL];
    }];
}

- (void)openDisk:(id)sender
{
    
}

- (void)extractFileAs:(id)sender
{
    NSIndexSet *indexes = [[self fileTableController] selectedItemIndexes];
    [self initProgressForTool:NO withAction:^{
        [undiffTool extractLayersAtIndexes:indexes];
    }];
}

- (void)cancelCompression:(id)sender
{
    [NSApp beginSheet:self.confirmationPanel modalForWindow:self.statusWindow modalDelegate:self didEndSelector:nil contextInfo:nil];
}

- (IBAction)closeSheet:(id)sender
{
    NSWindow *panel = ((NSButton*)sender).window;
    [NSApp endSheet:panel];
    [panel orderOut:sender];
}

- (IBAction)modifyTable:(NSSegmentedControl*)sender
{
    switch (sender.selectedSegment) {
        case 0:
            [self addLayerFiles];
            break;
        case 1:
            [self removeSelectedFiles:sender];
            break;
        case 2:
            [self.fileTableController moveSelectedItems:NO];
            break;
        case 3:
            [self.fileTableController moveSelectedItems:YES];
            break;
        case 4:
            [self.itemMenu popUpMenuPositioningItem:[self.itemMenu itemAtIndex:0] atLocation:sender.frame.origin inView:self.documentWindow.contentView];
            break;
        case 5:
            [[self fileTableController] showQuickLook];
            break;
    }
}

@end
