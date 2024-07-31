//
//  LDiff.m
//  larchiver
//
//  Created by Lasse Lauwerys on 30/03/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "LDDiffTool.h"

@implementation LDDiffTool

- (id)initWithBaseFile:(LDFile*)baseFile andHeaderFile:(LDFile *)headerFile
{
    self = [self init];
    self.baseFile = baseFile;
    self.headerFile = headerFile;
    return self;
}

- (void)setBaseFile:(LDFile *)baseFile
{
    if (layerFiles.count) [layerFiles replaceObjectAtIndex:0 withObject:baseFile];
    else [layerFiles addObject:baseFile];
}

- (LDFile *)baseFile
{
    return [layerFiles objectAtIndex:0];
}

- (void)setHeaderFile:(LDFile *)headerFile
{
    if (outputFiles.count) [outputFiles replaceObjectAtIndex:0 withObject:headerFile];
    else [outputFiles addObject:headerFile];
}

+ (LDDiffTool*)diffToolWithBaseFile:(LDFile *)baseFile andHeaderFile:(LDFile *)headerFile
{
    return [[LDDiffTool alloc] initWithBaseFile:baseFile andHeaderFile:headerFile];
}

- (NSDictionary *)layerFilesDict
{
    return [NSDictionary dictionaryWithObjects:outputFiles forKeys:layerFiles];
}

- (void)compress
{
    LDFile *baseFile = self.baseFile;
    LDFile *headerFile = [outputFiles objectAtIndex:0];
    
    NSData *baseData;
    UInt64 bytesToProcess;
    
    layerCount = layerFiles.count;
    NSUInteger topLayerCount = layerCount - 1;
    
    NSUInteger baseFileSize = [baseFile size];
    if (baseFileSize < bufferSize) bufferSize = baseFileSize;

    baseOffset = 0;
    
    if (layerFiles.count != outputFiles.count) {
        NSLog(@"Wtf gast");
        return;
    }
    
    layerMetaBuffers = [NSMutableArray array];
    
    char *headerMagicBytes = "LDIH";
    char *magicBytes = "LDIF";
    UInt8 version = 1;
    UInt8 indexingMethod = self.indexingMethod;
    UInt64 size;
    UInt8 fileNameSizeLength = 2;
    
    layerCRCs = [NSMutableArray arrayWithCapacity:layerCount];
    
    void(^layerIterator)(void(^)(LDFile *, LDFile *, NSMutableData *, LDCRC *)) = ^void(void(^callback)(LDFile *, LDFile *, NSMutableData *, LDCRC *)){
        for (layer = 0; layer < topLayerCount; ++layer)
            callback([layerFiles objectAtIndex:layer + 1], [outputFiles objectAtIndex:layer + 1], [layerMetaBuffers objectAtIndex:layer], [layerCRCs objectAtIndex:layer]);
    };
    
    NSString *headerFilePath = [headerFile path];
    NSData *headerFileNameData = [headerFilePath dataUsingEncoding:self.stringEncoding];
    NSUInteger headerFileNameSize = [headerFileNameData length];
    
    [baseFile open];
    [headerFile createAndOpenWithoutOverwriting];
    
    layerFileSizes = calloc(layerCount, 8);
    
    LDFile *file;
    for (layer = 1; layer < layerFiles.count; ++layer) {
        if ([file = [outputFiles objectAtIndex:layer] createAndOpenWithoutOverwriting]) {
            [layerMetaBuffers addObject:[NSMutableData data]];
            [layerCRCs addObject:[LDCRC crc]];
            LDFile *layerFile = [layerFiles objectAtIndex:layer];
            size = [layerFile size];
            layerFileSizes[layer - 1] = size;
            [layerFile open];
            NSMutableData *headerData = [NSMutableData dataWithBytes:magicBytes length:4];
            [headerData appendBytes:&version length:1];
            [headerData appendBytes:&indexingMethod length:1];
            [headerData appendBytes:&layer length:2];
            [headerData appendBytes:&size length:8];
            [headerData appendBytes:&headerFileNameSize length:fileNameSizeLength];
            [headerData appendData:headerFileNameData];
            [file writeData:headerData];
        } else {
            NSLog(@"A file with the given name (%@) already exists!", file.name);
            return;
        }
    }
    
    UInt offsetStartLength = indexingMethod == LDIndexingMethodPositionalOffsets ? 4 : 8;
    UInt offsetEndLength = indexingMethod == LDIndexingMethodTransitionOffsets ? 8 : 4;
    UInt offsetByteLength = offsetStartLength + offsetEndLength;
    int lengthLimit = UINT32_MAX;
    
    LDCRC *baseCRC = [LDCRC crc];
    
    differenceOffset = 0;
    
    baseBuffer = malloc(bufferSize);
    layerBuffer = malloc(bufferSize);
    outputTempBuffer = malloc(bufferSize);
    statuses = calloc(topLayerCount, 1);
    dispatch_queue_t priority_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    do @autoreleasepool {
        bytesToProcess = (baseData = [baseFile.handle readDataOfLength:bufferSize]).length;
        if (calculateChecksum) dispatch_async(priority_queue, ^{
            [baseCRC writeBytesSliceBy16:baseData.bytes length:bytesToProcess];
        });
        [baseData getBytes:baseBuffer length:bytesToProcess];
        layerIterator(^(LDFile *layerFile, LDFile *outputFile, NSMutableData *layerMetaBuffer, LDCRC *crc){
            [[layerFile.handle readDataOfLength:bufferSize] getBytes:layerBuffer length:bytesToProcess];
            outputTempBufferSize = 0;
            switch ([self indexingMethod]) {
                case LDIndexingMethodTransitionOffsets:
                    for (int i = 0; i < bytesToProcess && ((offset = baseOffset + i) < layerFileSizes[layer]); ++i) {
                        if (baseBuffer[i] == layerBuffer[i]) {
                            if (statuses[layer]) {
                                bool skip = false;
                                for (int nextIndex = 1; nextIndex <= 16 && nextIndex + i < bytesToProcess; ++nextIndex)
                                    if (baseBuffer[nextIndex + i] != layerBuffer[nextIndex + i]) {
                                        skip = true;
                                        break;
                                    }
                                if (!skip) {
                                    statuses[layer] = false;
                                    [layerMetaBuffer appendBytes:&offset length:8];
                                }
                            }
                        } else {
                            baseBuffer[i] = layerBuffer[i];
                            if (!statuses[layer]) {
                                statuses[layer] = true;
                                [layerMetaBuffer appendBytes:&offset length:8];
                            }
                            if (offset == layerFileSizes[layer] - 1) {
                                ++offset;
                                [layerMetaBuffer appendBytes:&offset length:8];
                            }
                        }
                        if (statuses[layer]) outputTempBuffer[outputTempBufferSize++] = layerBuffer[i];
                    }
                    break;
                case LDIndexingMethodOffsetsAndLengths:
                    for (int i = 0; i < bytesToProcess && ((offset = baseOffset + i) < layerFileSizes[layer]); ++i) {
                        differenceLength = offset - differenceOffset;
                        if (baseBuffer[i] == layerBuffer[i]) {
                            if (statuses[layer]) {
                                bool skip = false;
                                for (int nextIndex = 1; nextIndex <= 12 && nextIndex + i < bytesToProcess && !(differenceLength + nextIndex - 1 != lengthLimit); ++nextIndex)
                                    if (baseBuffer[nextIndex + i] != layerBuffer[nextIndex + i]) {
                                        skip = true;
                                        break;
                                    }
                                if (!skip) {
                                    statuses[layer] = false;
                                    [layerMetaBuffer appendBytes:&differenceLength length:4];
                                }
                            }
                        } else {
                            baseBuffer[i] = layerBuffer[i];
                            if (differenceLength == lengthLimit) {
                                differenceOffset = offset;
                                [layerMetaBuffer appendBytes:&differenceLength length:4];
                                [layerMetaBuffer appendBytes:&differenceOffset length:8];
                            }
                            if (!statuses[layer]) {
                                statuses[layer] = true;
                                differenceOffset = offset;
                                [layerMetaBuffer appendBytes:&differenceOffset length:8];
                            }
                            if (offset == layerFileSizes[layer] - 1) {
                                ++differenceLength;
                                [layerMetaBuffer appendBytes:&differenceLength length:4];
                            }
                        }
                        if (statuses[layer]) outputTempBuffer[outputTempBufferSize++] = layerBuffer[i];
                    }
                case LDIndexingMethodPositionalOffsets:
                    for (int i = 0; i < bytesToProcess && ((offset = baseOffset + i) < layerFileSizes[layer]); ++i) {
                        differenceLength = offset - differenceOffset;

                        if (baseBuffer[i] == layerBuffer[i]) {
                            if (statuses[layer]) {
                                bool skip = false;
                                for (int nextIndex = 1; nextIndex <= 8 && nextIndex + i < bytesToProcess && !(differenceLength + nextIndex - 1 != lengthLimit); ++nextIndex)
                                    if (baseBuffer[nextIndex + i] != layerBuffer[nextIndex + i]) {
                                        skip = true;
                                        break;
                                    }
                                if (!skip) {
                                    statuses[layer] = false;
                                    [layerMetaBuffer appendBytes:&differenceLength length:4];
                                }
                            }
                        } else {
                            baseBuffer[i] = layerBuffer[i];
                            if (differenceLength == lengthLimit) {
                                
                                [layerMetaBuffer appendBytes:&differenceLength length:4];
                                differenceOffset = offset - previousDifferenceOffset;
                                [layerMetaBuffer appendBytes:&differenceOffset length:4];
                            }
                            if (!statuses[layer]) {
                                statuses[layer] = true;
                                differenceOffset = offset - previousDifferenceOffset;
                                [layerMetaBuffer appendBytes:&differenceOffset length:4];
                                previousDifferenceOffset = offset;
                                differenceOffset = 0;
                            }
                            if (offset == layerFileSizes[layer] - 1) {
                                ++differenceLength;
                                [layerMetaBuffer appendBytes:&differenceLength length:4];
                            }
                            
                        }
                        if (statuses[layer]) outputTempBuffer[outputTempBufferSize++] = layerBuffer[i];
                        
                    }
                    break;
            }
            
            if (calculateChecksum) dispatch_async(priority_queue, ^{
                [crc writeBytesSliceBy16:layerBuffer length:bytesToProcess];
            });
            [outputFile writeBytes:outputTempBuffer length:outputTempBufferSize];
        });
        baseOffset += bytesToProcess;
    } while (bytesToProcess);
    free(baseBuffer);
    free(layerBuffer);
    free(outputTempBuffer);
    free(statuses);
    free(layerFileSizes);
    
    offset = [baseFile size];
    
    NSMutableData *headerData = [NSMutableData dataWithBytes:headerMagicBytes length:4];
    
    [headerData appendBytes:&topLayerCount length:4];
    
    NSMutableData *baseHeaderMeta = [NSMutableData data];
    NSData *baseFileName = [[baseFile path] dataUsingEncoding:self.stringEncoding];
    NSInteger baseFileNameSize = baseFileName.length;
    UInt32 baseChecksum = [baseCRC getChecksum];
    NSData *baseFileDetails = [self headerDetailsForFile:[baseFile path]];
    [baseHeaderMeta appendBytes:&baseFileNameSize length:fileNameSizeLength];
    [baseHeaderMeta appendData:baseFileName];
    [baseHeaderMeta appendData:baseFileDetails];
    [baseHeaderMeta appendBytes:&baseChecksum length:4];
    
    NSInteger baseHeaderMetaSize = baseHeaderMeta.length;
    [headerData appendBytes:&baseHeaderMetaSize length:4];
    [headerData appendData:baseHeaderMeta];
    
    [headerFile writeData:headerData];
    
    UInt8 offsetDataSize = [self offsetDataSize];
    
    layerIterator(^(LDFile *layerFile, LDFile *outputFile, NSData *layerMetaBuffer, LDCRC *crc){
        NSUInteger layerMetaSize = layerMetaBuffer.length / offsetDataSize;
        UInt32 checksum = [crc getChecksum];
        [outputFile writeData:layerMetaBuffer];
        [outputFile writeBytes:&checksum length:4];
        [outputFile writeBytes:&layerMetaSize length:4];
        [layerFile close];
        [outputFile close];
        
        NSData *layerFileName = [layerFile.path dataUsingEncoding:self.stringEncoding];
        NSInteger layerFileNameSize = layerFileName.length;
        NSData *outputFileName = [outputFile.path dataUsingEncoding:self.stringEncoding];
        NSInteger outputFileNameSize = outputFileName.length;

        NSData *fileDetails = [self headerDetailsForFile:layerFile.path];
        
        NSMutableData *layerHeaderMeta = [NSMutableData data];
        [layerHeaderMeta appendBytes:&layer length:2];
        [layerHeaderMeta appendBytes:&layerFileNameSize length:fileNameSizeLength];
        [layerHeaderMeta appendData:layerFileName];
        [layerHeaderMeta appendBytes:&outputFileNameSize length:fileNameSizeLength];
        [layerHeaderMeta appendData:outputFileName];
        [layerHeaderMeta appendData:fileDetails];
        [layerHeaderMeta appendBytes:&checksum length:4];
        
        NSInteger layerHeaderMetaSize = layerHeaderMeta.length;
        [headerFile writeData:[NSData dataWithBytes:&layerHeaderMetaSize length:4]];
        [headerFile writeData:layerHeaderMeta];
    });
    [headerFile close];
}

- (NSData *)headerDetailsForFile:(NSString *)path
{
    struct stat sb;
    stat(path.UTF8String, &sb);
    UInt64 size = sb.st_size;
    UInt64 aTime = sb.st_atimespec.tv_nsec, cTime = sb.st_ctimespec.tv_nsec, mTime = sb.st_mtimespec.tv_nsec, bTime = sb.st_birthtimespec.tv_nsec;
    
    BOOL nanosecondTimestamp = aTime || bTime || cTime || mTime;
    if (!nanosecondTimestamp)
        aTime = sb.st_atimespec.tv_sec,
        cTime = sb.st_ctimespec.tv_sec,
        mTime = sb.st_mtimespec.tv_sec,
        bTime = sb.st_birthtimespec.tv_sec;
    
    NSInteger timestampSize = nanosecondTimestamp ? 8 : 4;
    
    NSMutableData *fileHeaderMeta = [NSMutableData data];
    [fileHeaderMeta appendBytes:&size length:8];
    [fileHeaderMeta appendBytes:&nanosecondTimestamp length:1];
    [fileHeaderMeta appendBytes:&aTime length:timestampSize];
    [fileHeaderMeta appendBytes:&bTime length:timestampSize];
    [fileHeaderMeta appendBytes:&cTime length:timestampSize];
    [fileHeaderMeta appendBytes:&mTime length:timestampSize];
    return fileHeaderMeta;
}

- (void)addLayerWithInputPath:(NSString *)layerFilePath outputPath:(NSString *)outputFilePath
{
    [self addLayerFile:[LDFile fileWithPath:layerFilePath] withOutputFile:[LDFile fileWithPath:outputFilePath]];
}

- (void)addLayerWithInputName:(NSString *)layerPath outputName:(NSString *)outputPath relativeTo:(NSString *)directory
{
    [self addLayerWithInputPath:[directory stringByAppendingPathComponent:layerPath] outputPath:[directory stringByAppendingPathComponent:outputPath]];
}

- (void)setLayerFiles:(NSArray *)newLayerFiles withOutputFiles:(NSArray *)newOutputFiles
{
    if (newLayerFiles.count == newOutputFiles.count) {
        layerFiles = [NSMutableArray arrayWithArray:newLayerFiles];
        outputFiles = [NSMutableArray arrayWithArray:newOutputFiles];
    }
}

- (id)initWithBaseFileName:(NSString *)baseFileName andHeaderFileName:(NSString *)headerFileName relativeTo:(NSString *)directory
{
    return [self initWithBaseFile:[LDFile fileWithName:baseFileName relativeTo:directory] andHeaderFile:[LDFile fileWithName:headerFileName relativeTo:directory]];
}

- (NSMutableArray*) layerFiles
{
    return layerFiles;
}

- (NSMutableArray*) outputFiles
{
    return outputFiles;
}

+ (LDDiffTool *)diffTool
{
    return [[LDDiffTool alloc] init];
}

+ (LDDiffTool *)diffToolWithBaseFileName:(NSString *)baseFileName andHeaderFileName:(NSString *)headerFileName relativeTo:(NSString *)directory
{
    return [[LDDiffTool alloc] initWithBaseFileName:baseFileName andHeaderFileName:headerFileName relativeTo:directory];
}

@end
