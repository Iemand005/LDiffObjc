//
//  LUndiff.m
//  larchiver
//
//  Created by Lasse Lauwerys on 10/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDUndiffTool.h"

@implementation LDUndiffTool

- (BOOL)readHeaderFileWithURL:(NSURL *)url error:(NSError * __autoreleasing *)error
{
    UInt8 fileNameSizeLength = 2;
    
    LDFileStreamReader *reader;
    LDFile *baseFile;
    LDFile *layerFile;
    LDFile *outputFile;
    LDFile *headerFile;
    
    char magicBytes[4];
    UInt32 topLayerCount;
    
    UInt32 baseHeaderMetaSize;
    UInt32 baseFileNameSize;
    char *baseFileNameData;
    UInt32 baseChecksum;
    
    UInt32 layerHeaderMetaSize;
    UInt16 layerFileNameSize;
    char *layerFileNameBuffer;
    NSString *layerFileName;
    UInt16 outputFileNameSize;
    char *outputFileNameBuffer;
    NSString *outputFileName;
    UInt64 size;
    BOOL nanosecondTimestamps;
    UInt64 aTime;
    UInt64 bTime;
    UInt64 cTime;
    UInt64 mTime;
    UInt32 checksum;
    BOOL isHeader = NO;
    
    headerFile = [LDFile fileFromURL:url];
    NSError *fileError;
    [headerFile open:&fileError];

    if (!fileError) {
        reader = [LDFileStreamReader streamReaderWithFile:headerFile];
        
        [reader setLength:4];
        [reader readDataOfLength:4];
        [reader nextBytes:magicBytes];
        
        UInt8 headerFileNameLength = 0;
        char *headerFileNameBuffer;
        NSString *headerFileName;
        if (!strncmp(magicBytes, "LDIF", 4)) {
            [reader readDataOfLength:12 + fileNameSizeLength];
            [reader skipBytes:12];
            [reader setLength:fileNameSizeLength];
            [reader nextBytes:&headerFileNameLength];
            if (headerFileNameLength > 255) @throw @"Invalid header file or layer filr";
            headerFileNameBuffer = malloc(headerFileNameLength);
            [reader readDataOfLength:headerFileNameLength];
            [reader nextBytes:headerFileNameBuffer];
            headerFileName = [[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:headerFileNameBuffer length:headerFileNameLength] encoding:self.stringEncoding];
            headerFile = [LDFile fileWithPath:headerFileName];
            [headerFile open:&fileError];
            if (fileError) {
                if (error) *error = fileError;
                return false;
            }
            reader = [LDFileStreamReader streamReaderWithFile:headerFile];
            [reader readDataOfLength:4];
            [reader nextBytes:magicBytes];
        }
        
        isHeader = !strncmp(magicBytes, "LDIH", 4);
        
        if (isHeader) {
            [reader readDataOfLength:8];
            [reader nextBytes:&topLayerCount];
            
            [reader nextBytes:&baseHeaderMetaSize];
            [reader readDataOfLength:baseHeaderMetaSize];
            [reader nextBytes:&baseFileNameSize length:fileNameSizeLength];
            baseFileNameData = malloc(baseFileNameSize);
            [reader nextBytes:baseFileNameData length:baseFileNameSize];
            
            [reader setLength:8];
            [reader nextBytes:&size];
            [reader nextByte:&nanosecondTimestamps];
            if (!nanosecondTimestamps) [reader setLength:4];
            [reader nextBytes:&aTime];
            [reader nextBytes:&bTime];
            [reader nextBytes:&cTime];
            [reader nextBytes:&mTime];
            [reader setLength:4];
            [reader nextBytes:&baseChecksum];
            
            if (size < bufferSize) bufferSize = size;
            
            layerCount = topLayerCount + 1;
            self.layerFiles = [NSMutableArray arrayWithCapacity:layerCount];
            self.outputFiles = [NSMutableArray arrayWithCapacity:layerCount];
            
            NSString *baseFileName = [[NSString alloc] initWithBytesNoCopy:baseFileNameData length:baseFileNameSize encoding:self.stringEncoding freeWhenDone:YES];
            baseFile = [LDFile fileWithPath:baseFileName];
            [self setBaseFile:baseFile];
            [self setHeaderFile:[LDFile fileFromURL:url]];
            
            for (int i = 0; i < topLayerCount; ++i) {
                [reader readDataOfLength:4];
                [reader nextBytes:&layerHeaderMetaSize];

                [reader flushBufferAndReadDataOfLength:layerHeaderMetaSize];
                [reader nextBytes:&layer length:2];
                if (layer == i) {
                    [reader nextBytes:&layerFileNameSize length:2];
                    
                    [reader setLength:layerFileNameSize];
                    layerFileNameBuffer = malloc(layerFileNameSize);
                    [reader nextBytes:layerFileNameBuffer];
                    
                    [reader setLength:4];
                    [reader nextBytes:&outputFileNameSize length:2];
                    
                    [reader setLength:outputFileNameSize];
                    outputFileNameBuffer = malloc(outputFileNameSize);
                    [reader nextBytes:outputFileNameBuffer];
                    
                    [reader setLength:8];
                    [reader nextBytes:&size];
                    [reader nextByte:&nanosecondTimestamps];
                    if (!nanosecondTimestamps) [reader setLength:4];
                    [reader nextBytes:&aTime];
                    [reader nextBytes:&bTime];
                    [reader nextBytes:&cTime];
                    [reader nextBytes:&mTime];
                    [reader setLength:4];
                    [reader nextBytes:&checksum];
                    
                    layerFileName = [[NSString alloc] initWithBytesNoCopy:layerFileNameBuffer length:layerFileNameSize encoding:self.stringEncoding freeWhenDone:YES];
                    layerFile = [LDFile fileWithPath:layerFileName];
                    
                    outputFileName = [[NSString alloc] initWithBytesNoCopy:outputFileNameBuffer length:outputFileNameSize encoding:self.stringEncoding freeWhenDone:YES];
                    outputFile = [LDFile fileWithPath:outputFileName];
                    [self.layerFiles addObject:layerFile];
                    [self.outputFiles addObject:outputFile];
                    NSLog(@"%@", outputFile.path);
                }
            }
        }
    } else if (error) *error = fileError;
    return isHeader;
}

- (void)extractLayersAtIndexes:(NSIndexSet *)indexes
{
    indexes = [indexes indexesPassingTest:^BOOL(NSUInteger index, BOOL *stop){
        return index != 0 && index < self.outputFiles.count;
    }];
    
    LDFile *baseFile = self.baseFile;
    NSArray *restoredFiles = [self.layerFiles objectsAtIndexes:indexes];
    NSArray *inputFiles = [self.outputFiles objectsAtIndexes:indexes];
    UInt64 bytesToProcess;
    NSData *baseData;
    
    if (restoredFiles.count != inputFiles.count) {
        NSLog(@"Wtf gast");
        return;
    }
    
    layerCount = inputFiles.count;
    
    NSData *layerChecksumData;
    LDFile *layerFile;
    LDFile *outputFile;
    
    LDDifference differences[layerCount];
    layerMetaBuffers = [NSMutableArray arrayWithCapacity:layerCount];
    layerFileSizes = calloc(layerCount, 8);
    
    for (int layerIndex = 0; layerIndex < layerCount; ++layerIndex) {
        outputFile = [inputFiles objectAtIndex:layerIndex];
        layerFile = [restoredFiles objectAtIndex:layerIndex];
        [outputFile open];
        NSInteger layerInfoDataSize = 18;
        NSData *layerInfoData = [outputFile readDataOfLength:layerInfoDataSize];
        NSData *offsetDataLengthData;
        
        char magicBytes[4];
        UInt8 version;
        UInt8 indexingMethod;
        UInt64 size;
        UInt16 fileNameLength;
        UInt32 offsetDataCount;
        UInt32 checksum;
        
        LDDataStreamReader * infoReader = [LDDataStreamReader streamReaderWithData:layerInfoData];
        [infoReader nextDoubleWord:magicBytes];
        if (!strncmp(magicBytes, "LDIF", 4)) {
            [infoReader nextByte:&version];
            [infoReader nextByte:&indexingMethod];
            [infoReader nextWord:&layer];
            [infoReader nextQuadWord:&size];
            [infoReader nextWord:&fileNameLength];
            NSData *layerFileNameData = [outputFile readDataOfLength:fileNameLength];
            self.indexingMethod = indexingMethod;
            layerFileSizes[layerIndex] = size;
            NSString *fileName = [[NSString alloc] initWithData:layerFileNameData encoding:self.stringEncoding];
            
            NSLog(@"%@", fileName);
            
            UInt64 checksumOffset = [outputFile size] - 8;
            [outputFile seekToFileOffset:checksumOffset];
            layerChecksumData = [outputFile readDataOfLength:4];
            [layerChecksumData getBytes:&checksum length:4];
            offsetDataLengthData = [outputFile readDataOfLength:4];
            [offsetDataLengthData getBytes:&offsetDataCount length:4];

            UInt8 offsetDataSize = [self offsetDataSize];
            if (offsetDataCount) {
                UInt64 offsetsDataSize = offsetDataCount * offsetDataSize;
                if (self.indexingMethod == LDIndexingMethodOffsetsAndLengths) checksumOffset -= 4;
                [outputFile seekToFileOffset:checksumOffset - offsetsDataSize];
                NSData *layerMetaData = [outputFile readDataOfLength:offsetsDataSize];
                LDDataStreamReader *layerMetaReader = [LDDataStreamReader streamReaderWithData:layerMetaData];
                [layerMetaReader nextQuadWord:&differences[layerIndex].offset];
                if (self.indexingMethod == LDIndexingMethodOffsetsAndLengths) {
                    UInt32 length;
                    [layerMetaReader nextDoubleWord:&length];
                    differences[layerIndex].length = differences[layerIndex].offset + length;
                    LDDifference    difference = differences[layerIndex];
                } else [layerMetaReader nextQuadWord:&differences[layerIndex].length];
                [layerMetaBuffers addObject:layerMetaReader];
            }
            
            [outputFile seekToFileOffset:layerInfoDataSize + fileNameLength];
            
            [layerFile createAndOpenWithoutOverwriting];
        }
    }
    
    [baseFile open];
    
    UInt64 baseOffset = 0;
    
    char *baseBuffer = malloc(bufferSize);
    const char *layerBuffer;
    UInt32 layerBufferOffset = 0;
    bool notFinished;
    
    do @autoreleasepool {
        bytesToProcess = [baseData = [[baseFile handle] readDataOfLength:bufferSize] length];
        [baseData getBytes:baseBuffer length:bytesToProcess];
        
        for (int layerIndex = 0; layerIndex < layerCount; ++layerIndex) {
            layerFile = [restoredFiles objectAtIndex:layerIndex];
            outputFile = [inputFiles objectAtIndex:layerIndex];
            LDDataStreamReader *layerMetaReader;
            if (layerIndex < layerMetaBuffers.count) layerMetaReader = [layerMetaBuffers objectAtIndex:layerIndex];
            LDDifference difference = differences[layerIndex];
            
            UInt64 expectedToFind;
            if (baseOffset + bytesToProcess - 1 >= difference.offset) {
                UInt64 currentRangeEnd = baseOffset + bytesToProcess;
                expectedToFind = (difference.length < currentRangeEnd ? difference.length : currentRangeEnd) - (difference.offset > baseOffset ? difference.offset : baseOffset);
                layerBuffer = [[outputFile.handle readDataOfLength:expectedToFind] bytes];
                layerBufferOffset = 0;
            }
            
            for (int i = 0; i < bytesToProcess && (notFinished = (offset = baseOffset + i) < layerFileSizes[layerIndex]); i++) {
                if (offset >= difference.offset && offset < difference.length) {
                    if (layerBufferOffset == expectedToFind && baseOffset + bytesToProcess - 1 >= difference.offset) {
                        UInt64 currentRangeEnd = offset + bytesToProcess;
                        expectedToFind = (difference.length < currentRangeEnd ? difference.length : currentRangeEnd) - (difference.offset > offset ? difference.offset : offset);
                        layerBuffer = [[[outputFile handle] readDataOfLength:expectedToFind] bytes];
                        layerBufferOffset = 0;
                    }
                    baseBuffer[i] = layerBuffer[layerBufferOffset++];
                    if (offset == difference.length - 1 && ![layerMetaReader reachedEnd]) {
                        [layerMetaReader nextQuadWord:&differences[layerIndex].offset];
                        if (self.indexingMethod == LDIndexingMethodOffsetsAndLengths) {
                            UInt32 length;
                            [layerMetaReader nextDoubleWord:&length];
                            differences[layerIndex].length = differences[layerIndex].offset + length;
                        } else [layerMetaReader nextQuadWord:&differences[layerIndex].length];
                        difference = differences[layerIndex];
                    }
                }
            }
            if (notFinished) [layerFile writeBytes:baseBuffer length:bytesToProcess];
            else {
                if (layerFileSizes[layerIndex] > baseOffset) [layerFile writeBytes:baseBuffer length:layerFileSizes[layerIndex] - baseOffset];
                continue;
            }
        }
        baseOffset += bytesToProcess;
    } while (bytesToProcess);
    free(baseBuffer);
}

- (NSMutableArray *)layerFiles
{
    return layerFiles;
}

- (NSMutableArray *)outputFiles
{
    return outputFiles;
}

- (void)setOutputFiles:(NSMutableArray *)files
{
    outputFiles = files;
}

- (void)setLayerFiles:(NSMutableArray *)files
{
    layerFiles = files;
}

- (void)close
{
    for (LDFile *file in self.layerFiles) [file close];
    for (LDFile *file in self.outputFiles) [file close];
}

- (UInt64)currentOffset
{
    return offset;
}

- (void)extractAll
{
    [self extractLayersAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, self.outputFiles.count)]];
}

- (void)setBaseFile:(LDFile *)baseFile
{
    [self setFirstObjectInArray:self.layerFiles to:baseFile];
}

- (LDFile *)baseFile
{
    return [self.layerFiles objectAtIndex:0];
}

- (void)setHeaderFile:(LDFile *)headerFile
{
    [self setFirstObjectInArray:self.outputFiles to:headerFile];
}

- (LDFile *)headerFile
{
    return [self.outputFiles objectAtIndex:0];
}

- (void)setFirstObjectInArray:(NSMutableArray *)array to:(id)object
{
    if (array.count) [array replaceObjectAtIndex:0 withObject:object];
    else [array addObject:object];
}


+ (LDUndiffTool *)undiffTool
{
    return [[LDUndiffTool alloc] init];
}

@end
