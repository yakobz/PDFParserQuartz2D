//
//  AppDelegate.m
//  CHIPDFParserQuartz2D
//
//  Created by Yakov on 8/5/16.
//  Copyright © 2016 CHISW. All rights reserved.
//

#import "AppDelegate.h"
#import "CHIPDFParser.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSString *downloadsPath = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES)[0];
    NSURL *pdfFileUrl = [[NSURL URLWithString:downloadsPath] URLByAppendingPathComponent:@"tests/0.499824966606488.html.pdf"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pdfFileUrl.path]) {
        [CHIPDFParser parcePDFWithURL:pdfFileUrl];
    }
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
