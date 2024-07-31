//
//  FileTableViewController.m
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDFileTableViewController.h"
#import "LDFileTableView.h"

@implementation LDFileTableViewController

- (void)setBaseFile:(LDFile*)file
{
    [self.layerFiles replaceObjectAtIndex:0 withObject:file];
}

- (LDFile *)baseFile
{
    return [self.layerFiles objectAtIndex:0];
}

- (id)init
{
    self = [super init];
    self.layerFiles = [[NSMutableArray alloc] init];
    self.outputFiles = [[NSMutableArray alloc] init];
    return self;
}

- (void)awakeFromNib
{
    [self.tableView registerForDraggedTypes:@[NSFilenamesPboardType, NSStringPboardType]];
}

- (void)setBaseFileWithURL:(NSURL*)url
{
    [self setBaseFile:[LDFile fileFromURL:url]];
    [self.tableView reloadData];
}

- (void)removeSelectedItems
{
    [self removeItemsAtIndexes:[self getSelectedItemIndexes]];
}

- (NSIndexSet*)getSelectedItemIndexes
{
    return [self.tableView getSelectedItemIndexes];
}

- (void)removeItemsAtIndexes:(NSIndexSet*)indexes
{
    NSIndexSet *selectedIndexes = [[NSIndexSet alloc] initWithIndexSet:self.tableView.selectedRowIndexes];
    [self.tableView removeRowsAtIndexes:indexes withAnimation:NSTableViewAnimationEffectGap];
    [self.layerFiles removeObjectsAtIndexes: indexes];
    [self.outputFiles removeObjectsAtIndexes: indexes];
    if((![selectedIndexes containsIndex:self.tableView.clickedRow+1] || [selectedIndexes containsIndex:self.tableView.clickedRow]))
        [self.tableView deselectRow:self.tableView.clickedRow];
}

- (void)swapItemsInArray:(NSMutableArray*)array atIndexes:(NSIndexSet*)indexes withOffset:(NSInteger)offset
{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop){
        NSUInteger nextIndex = index + offset;
        if (nextIndex > 0 && nextIndex < array.count) {
            NSObject *previousItem = [array objectAtIndex:nextIndex];
            [array replaceObjectAtIndex:nextIndex withObject:[array objectAtIndex:index]];
            [array replaceObjectAtIndex:index withObject:previousItem];
        }
    }];
}

- (void)moveRowAtIndex:(NSUInteger)oldIndex toIndex:(NSUInteger)newIndex
{
    LDFile *newFile = [self.layerFiles objectAtIndex:newIndex];
    LDFile *oldFile = [self.layerFiles objectAtIndex:oldIndex];
    [[self layerFiles] replaceObjectAtIndex:newIndex withObject:oldFile];
    [[self layerFiles] replaceObjectAtIndex:oldIndex withObject:newFile];
    newFile = [self.outputFiles objectAtIndex:newIndex];
    oldFile = [self.outputFiles objectAtIndex:oldIndex];
    newFile.path = [[newFile.path stringByDeletingPathExtension] stringByAppendingPathExtension:[self pathExtensionForIndex:oldIndex]];
    oldFile.path = [[oldFile.path stringByDeletingPathExtension] stringByAppendingPathExtension:[self pathExtensionForIndex:newIndex]];
    [[self outputFiles] replaceObjectAtIndex:newIndex withObject:oldFile];
    [[self outputFiles] replaceObjectAtIndex:oldIndex withObject:newFile];
    
    [self.tableView moveRowAtIndex:oldIndex toIndex:newIndex];
}

- (NSString*)pathExtensionForIndex:(NSInteger)index
{
    return index > 0 ? [NSString stringWithFormat:@"diff%li", index] : @"diffh";
}

- (void)moveSelectedItems:(BOOL)downwards
{
    NSIndexSet *indexes = [self getSelectedItemIndexes];
    NSIndexSet *selectedIndexes = self.tableView.selectedRowIndexes;
    NSMutableIndexSet *newIndexes = [NSMutableIndexSet indexSet];

    __block NSUInteger lastIndex = 0;
    [self.tableView beginUpdates];
    NSInteger offset = downwards ? 1 : -1;
    NSInteger clickedRow = self.tableView.clickedRow;
    
    if (downwards)
        [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger oldIndex, BOOL *stop){
            NSUInteger newIndex = oldIndex + offset;
            if (newIndex < self.layerFiles.count && newIndex > lastIndex) {
                [self moveRowAtIndex:oldIndex toIndex:newIndex];
                if ([selectedIndexes containsIndex:oldIndex]) [newIndexes addIndex:newIndex];
            } else lastIndex = oldIndex;
        }];
    else
        [indexes enumerateIndexesUsingBlock:^(NSUInteger oldIndex, BOOL *stop){
            NSUInteger newIndex = oldIndex + offset;
            if (newIndex < self.layerFiles.count && (newIndex > lastIndex || [indexes firstIndex] == 1)) {
                [self moveRowAtIndex:oldIndex toIndex:newIndex];
                if ([selectedIndexes containsIndex:oldIndex]) [newIndexes addIndex:newIndex];
            } else lastIndex = oldIndex;
        }];
    
    if (newIndexes.count == 0) newIndexes = [newIndexes initWithIndexSet:indexes];
    
    BOOL invalidSelection = ((downwards && indexes.firstIndex == clickedRow) || (!downwards && indexes.lastIndex == clickedRow)) && ![self.tableView.selectedRowIndexes containsIndex:clickedRow];
    
    [self.tableView endUpdates];
    [self updateSelections];
    
    [newIndexes addIndexes:indexes];
    [self reloadOutputPathColumnAtIndexes:newIndexes];
    
    if (invalidSelection) [self.tableView deselectRow:clickedRow];
}

- (void)reloadOutputPathColumnAtIndexes:(NSIndexSet*)indexes
{
    [self.tableView reloadDataForRowIndexes:indexes columnIndexes:[NSIndexSet indexSetWithIndex:2]];
}

- (void)updateSelections
{
    [(LDFileTableViewDelegate*)self.tableView.delegate reloadControl];
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSLog(@"kankwe");
    return true;
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSLog(@"sort");
}

-(NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
    NSArray *urls = [[info draggingPasteboard] readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
    
    if ([[urls indexesOfObjectsPassingTest:^BOOL(NSURL *url, NSUInteger index, BOOL *stop){ return [self isUrlFile:url]; }] count] > 0)
        return NSDragOperationCopy;
    return NSDragOperationNone;
}

-(BOOL)isUrlFile:(NSURL*)url
{
    NSNumber *isFile;
    return [url getResourceValue:&isFile forKey:NSURLIsRegularFileKey error:nil] && isFile.boolValue;
}

-(BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)dropOperation
{
    NSPasteboard *pasteboard = [info draggingPasteboard];
    NSArray *urls = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]] options:nil];
    
    for (NSURL *url in urls) [self addLayerFileWithURL:url];
    return YES;
}

- (void)addLayerFile:(LDFile *)file
{
    NSUInteger layerFileCount = self.layerFiles.count;
    
    NSUInteger index = [self.layerFiles indexOfObject:file];
    BOOL newFile = index == NSNotFound;
    if (newFile) index = layerFileCount - 1;
    
    LDFile *outputFile = [LDFile fileWithPath:[file.path stringByAppendingPathExtension:[self pathExtensionForIndex:index+1]]];
    if (layerFileCount) [self setOutputDirectoryBasedOnFile:outputFile];
    if (newFile) [self addLayerFile:file withOutputFile:outputFile];
    else [self setOutputFile:outputFile atIndex:index];
    
}

- (void)addLayerFile:(LDFile *)layerFile withOutputFile:(LDFile*)outputFile
{
    NSLog(@"%@", outputFile.path);
    //if ([layerFile isRegularFile] || [outputFile isRegularFile]) {
        NSUInteger layerFileIndex = [self.layerFiles indexOfObject:layerFile];
        if (layerFileIndex == NSNotFound) {
            [self.layerFiles addObject:layerFile];
            [self.outputFiles addObject:outputFile];
            [self.tableView insertRowsAtIndexes:[NSIndexSet indexSetWithIndex:self.layerFiles.count] withAnimation:NSTableViewAnimationSlideRight];
        } else [self setOutputFile:outputFile atIndex:layerFileIndex];
    //}
}

- (void)setOutputDirectoryBasedOnFile:(LDFile*)file
{
    self.outputDirectory = [NSURL URLWithString:[file.path stringByDeletingLastPathComponent]];
    [self.tableView reloadData];
}

- (void)setOutputDirectory:(NSURL*)directory atIndexes:(NSIndexSet*)indexes
{
    [indexes enumerateIndexesInRange:NSMakeRange(0, self.layerFiles.count - 1) options:0 usingBlock:^(NSUInteger index, BOOL *stop){
        [((LDFile*)[self.layerFiles objectAtIndex:index]) changeDirectory:directory];
    }];
    [self reloadOutputPathColumnAtIndexes:indexes];
}

- (void)setOutputDirectoryForSelectedItems:(NSURL*)directory
{
    NSIndexSet *indexes = [self getSelectedItemIndexes];
    [self setOutputDirectory:directory atIndexes:indexes];
    [self reloadOutputPathColumnAtIndexes:indexes];
}

- (NSURL*)outputDirectory
{
    return outputDirectory;
}

- (void)setOutputDirectory:(NSURL *)directory
{
    NSArray *files = [self.outputFiles objectsAtIndexes:[self getSelectedItemIndexes]];
    for (LDFile *file in files) [file changeDirectory:directory];
    [self.tableView reloadData];
}

- (void)setOutputFile:(LDFile*)file atIndex:(NSUInteger)index
{
    [[self outputFiles] replaceObjectAtIndex:index withObject:file];
    [self.tableView reloadData];
}

- (void)setOutputFileWithURL:(NSURL*)url at:(NSUInteger)index
{
    [self setOutputFile:[LDFile fileFromURL:url] atIndex:index];
}

- (void)addLayerFileWithURL:(NSURL*)url
{
    [self addLayerFile: [LDFile fileFromURL:url]];
}

- (void)addLayerFileWithURL:(NSURL*)url andOutputFileURL:(NSURL *)outputFileURL
{
    [self addLayerFile: [LDFile fileFromURL:url] withOutputFile:[LDFile fileFromURL:outputFileURL]];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.layerFiles.count;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSString *identifier = [tableColumn identifier];
    NSString *cellText;
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:identifier owner:self];
    if (row < self.layerFiles.count && row < self.outputFiles.count) {
        LDFile *file = [self.layerFiles objectAtIndex: row];
        LDFile *outFile = [self.outputFiles objectAtIndex: row];
        
        if ([identifier isEqualToString: @"name"]) {
            cellText = file.name;
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
                NSImage *cellIcon = [file imageWithSize:cellView.imageView.frame.size asIcon:YES];
                if (cellIcon)
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [cellView.imageView setImage:cellIcon];
                        [cellView setNeedsDisplay:YES];
                    });
            });
        }
        else if ([identifier isEqualToString: @"inPath"]) cellText = file.path;
        else if ([identifier isEqualToString: @"outPath"]) cellText = outFile.path;
        if(cellText) [cellView.textField setStringValue:cellText];
    }
    return cellView;
}

- (IBAction)deleteSelectedItems:(id)sender
{
    [self removeSelectedItems];
}

- (void)deleteItemAtIndex:(NSUInteger)index
{
    [self.layerFiles removeObjectAtIndex:index];
    [self.outputFiles removeObjectAtIndex:index];
    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:index] withAnimation:NSTableViewAnimationEffectGap];
}

- (BOOL)hasSelectedItems
{
    return self.tableView.selectedRow != NSNotFound || self.tableView.clickedRow != NSNotFound;
}

- (IBAction)moveSelectedItemsUp:(id)sender
{
    [self moveSelectedItems:NO];
}

- (void)keyDown:(NSEvent *)theEvent 
{
    if ([theEvent keyCode] == 20) [self showQuickLook];
}

- (void)showQuickLook
{
    QLPreviewPanel *panel = [QLPreviewPanel sharedPreviewPanel];
    [panel makeKeyAndOrderFront:nil];
    [panel reloadData];
}

- (IBAction)moveSelectedItemsDown:(id)sender
{
    [self moveSelectedItems:YES];
}

- (NSInteger)numberOfPreviewItemsInPreviewPanel:(QLPreviewPanel *)panel
{
    return [[[self tableView] selectedRowIndexes] count];
}

- (id<QLPreviewItem>)previewPanel:(QLPreviewPanel *)panel previewItemAtIndex:(NSInteger)index
{
    __block NSUInteger currentIndex = 0;
    NSUInteger itemIndex = [self.tableView.selectedRowIndexes indexPassingTest:^BOOL(NSUInteger newIndex, BOOL *stop){
        return currentIndex++ == index;
    }];
    if (itemIndex != NSNotFound) return [[self layerFiles] objectAtIndex:itemIndex];
    return nil;
}

@end
