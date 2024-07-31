//
//  DiffchiverTests.m
//  DiffchiverTests
//
//  Created by Lasse Lauwerys on 10/04/24.
//  Copyright (c) 2024 Lasse Lauwerys. All rights reserved.
//

#import "DiffchiverTests.h"

@implementation DiffchiverTests

- (void)setUp
{
    [super setUp];
    diffTool = [LDDiffTool diffTool];
    undiffTool = [LDUndiffTool undiffTool];
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testCompressionDecompressionBasic
{
    NSDictionary *paths = @{@"testbsd.txt": @"testlayerone.diffh", @"testl1.txt": @"testlayerone.diff1"};
    NSString *text = @"AAAAAAAAAA";
    [text writeToFile:@"testbsd.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    text = @"BABABABAAB";
    [text writeToFile:@"testl1.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
    for (NSString *inputPath in paths) {
        [diffTool addLayerWithInputPath:inputPath outputPath:[paths objectForKey:inputPath]];
        [undiffTool addLayerWithInputPath:[inputPath stringByAppendingPathExtension:@".rec"] outputPath:[paths objectForKey:inputPath]];
    }
    [diffTool compress];
    
    [undiffTool extractAll];
    NSString *recovered = [NSString stringWithContentsOfFile:@"testl1.txt.rec" encoding:NSUTF8StringEncoding error:nil];
    STAssertEqualObjects(text, recovered, @" c");
}

@end
