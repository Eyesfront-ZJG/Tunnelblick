/*
 * Copyright 2011, 2012, 2013, 2014, 2015, 2016 Jonathan K. Bullard. All rights reserved.
 *
 *  This file is part of Tunnelblick.
 *
 *  Tunnelblick is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2
 *  as published by the Free Software Foundation.
 *
 *  Tunnelblick is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program (see the file COPYING included with this
 *  distribution); if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *  or see http://www.gnu.org/licenses/.
 */


#import "ConfigurationUpdater.h"

#import "defines.h"
#import "helper.h"
#import "sharedRoutines.h"
#import "NSString+TB.h"

#import "ConfigurationManager.h"
#import "ConfigurationMultiUpdater.h"
#import "MenuController.h"
#import "NSFileManager+TB.h"
#import "NSTimer+TB.h"
#import "TBUserDefaults.h"

extern NSFileManager  * gFileMgr;
extern MenuController * gMC;
extern BOOL             gShuttingDownWorkspace;
extern TBUserDefaults * gTbDefaults;

@implementation ConfigurationUpdater

TBSYNTHESIZE_OBJECT_GET(retain, NSString  *, cfgBundlePath)
TBSYNTHESIZE_OBJECT_GET(retain, NSString  *, cfgBundleId)
TBSYNTHESIZE_OBJECT_GET(retain, NSString  *, cfgName)
TBSYNTHESIZE_OBJECT(    retain, NSString *,  feedUrlStringForConfigurationUpdater, setFeedUrlStringForConfigurationUpdater)

-(NSString *) edition {
	
	return [[[self cfgBundlePath] stringByDeletingLastPathComponent] pathEdition];
}

-(ConfigurationUpdater *) initWithPath: (NSString *) path {
    
    // Returns nil if error
    
    if (  ! [path hasSuffix: @".tblk"]  ) {
        NSLog(@"%@ is not a .tblk", path);
        return nil;
    }
    
    NSBundle * bundle = [NSBundle bundleWithPath: path];
	if (  ! bundle  ) {
        NSLog(@"%@ is not a valid bundle", path);
        return nil;
    }
    
    NSDictionary * infoPlist = [ConfigurationManager plistInTblkAtPath: path];
    
    if (  ! infoPlist  ) {
        NSLog(@"The .tblk at %@ does not contain a valid Info.plist", path);
        return nil;
    }
    
    NSString * bundleId      = [infoPlist objectForKey: @"CFBundleIdentifier"];
    NSString * bundleVersion = [infoPlist objectForKey: @"CFBundleVersion"];
    NSString * feedURLString = [infoPlist objectForKey: @"SUFeedURL"];
    
    if (  ! (   bundleId
             && bundleVersion
             && feedURLString)  ) {
        NSLog(@"Missing CFBundleIdentifier, CFBundleVersion, or SUFeedURL in Info.plist for .tblk at %@", path);
        return nil;
    }
    
    NSURL * feedURL = [NSURL URLWithString: feedURLString];
    if (  ! feedURL  ) {
        NSLog(@"SUFeedURL in Info.plist for .tblk at %@ is not a valid URL", path);
        return nil;
    }
	
	[self setFeedUrlStringForConfigurationUpdater: feedURLString];
	
    NSTimeInterval interval = 60*60; // One hour (1 hour in seconds = 60 minutes * 60 seconds/minute)
    id checkInterval = [infoPlist objectForKey: @"SUScheduledCheckInterval"];
    if (  checkInterval  ) {
        if (  [checkInterval respondsToSelector: @selector(intValue)]  ) {
            NSTimeInterval i = (NSTimeInterval) [checkInterval intValue];
            if (  i <= 60.0  ) {
                NSLog(@"SUScheduledCheckInterval in Info.plist for the .tblk at %@ is less than 60 seconds; using 60 minutes.", path);
            } else {
                interval = i;
            }
        } else {
            NSLog(@"SUScheduledCheckInterval in Info.plist for the .tblk at %@ is invalid (does not respond to intValue); using 3600 seconds (60 minutes)", path);
        }
    }
    
    if (  (self = [super init])  ) {
        
        cfgBundlePath = [path retain];
        cfgBundleId   = [bundleId retain];
        cfgName       = [[path lastPathComponent] retain];
        
        return self;
    }

    return nil;
}

-(void) dealloc {
    
	[cfgBundlePath release]; cfgBundlePath = nil;
	[cfgBundleId   release]; cfgBundleId   = nil;
	[cfgName       release]; cfgName       = nil;
    
    [super dealloc];
}

//
// None of the rest of the delegate methods are used but they show the progress of the update checks
//
- (void)installerFinishedForHost:(id)host {
	
	(void) host;
	
    TBLog(@"DB-UC", @"installerFinishedForHost for '%@' (%@ %@)", [self cfgName], [self cfgBundleId], [self edition]);
}

@end
