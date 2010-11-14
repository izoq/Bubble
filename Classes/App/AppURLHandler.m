//
//  AppURLHandler.m
//  Bubble
//
//  Created by Luke on 10/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppURLHandler.h"


@implementation AppURLHandler
-(void)handleURL:(NSString*)urlString{
	NSURL *url=[NSURL URLWithString:urlString];
	if (!url) {
		return;
	}
	if (![[url resourceSpecifier] hasPrefix:@"//"]) {
		urlString = [NSString stringWithFormat:@"%@://%@", [url scheme], [url resourceSpecifier]];
		url = [NSURL URLWithString:urlString];
	}
	
	NSString *schema = [url scheme];
	NSString *host = [url host];
	if ([schema isEqualToString:@"weibo"]) {
		if ([host isEqualToString:@"load_older_home_timeline"]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:StartLoadOlderTimelineNotification object:nil];
		}
		if ([host isEqualToString:@"home_timeline_status_click"]) {
			NSString *statusId = [[url queryArgumentForKey:@"id"] 
								stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[[NSNotificationCenter defaultCenter] postNotificationName:DidClickTimelineNotification object:statusId];
		}
		if ([host isEqualToString:@"user"]) {
			NSMutableDictionary *data=[NSMutableDictionary dictionaryWithCapacity:0];
			[data setObject:[url queryArgumentForKey:@"fetch_with"] forKey:@"fetch_with"];
			[data setObject:[[url queryArgumentForKey:@"value"] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey:@"value"];
			[[NSNotificationCenter defaultCenter] postNotificationName:GetUserNotification object:data];
			
		}
	}
	
}
@end