//
//  ComposeController.m
//  Rainbow
//
//  Created by Luke on 9/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ComposeController.h"
#import "NSWindowAdditions.h"

@implementation ComposeController
@synthesize data,postType;
- (id)init {
	self = [super initWithWindowNibName:@"Compose"];
	weiboAccount=[AccountController instance];
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc addObserver:self selector:@selector(didPost:) 
			   name:DidPostStatusNotification
			 object:nil];
	
	[nc addObserver:self selector:@selector(handleReply:) 
			   name:ReplyNotification
			 object:nil];
	
	[nc addObserver:self selector:@selector(handleRePost:) 
			   name:RepostNotification
			 object:nil];
	[nc addObserver:self selector:@selector(handleSendMessage:) 
			   name:SendMessageNotification
			 object:nil];	
	return self;
}

-(void)awakeFromNib{
	[textView setImportsGraphics:TRUE];
	[textView setFont:[NSFont fontWithName:@"Menlo" size:14]];
	CGFloat linespace=3.0f;
	NSMutableParagraphStyle *paragraphStyle=[[[NSMutableParagraphStyle alloc] init] autorelease];
	[paragraphStyle setLineSpacing:linespace];
	[textView setDefaultParagraphStyle:paragraphStyle];
}

- (void)textDidChange:(NSNotification *)aNotification {
	NSString * string=[textView string];
	int remaining=140-[[string precomposedStringWithCanonicalMapping] length];
	[charactersRemaining setStringValue:[NSString stringWithFormat:@"%d",remaining]];
}
-(void)composeNew{
	self.postType=NormalPost;
	[self popUp];
	[[self window] setTitle:@"发微博"];

}

-(void)handleSendMessage:(NSNotification*)notification{
	self.postType=MessagePost;
	self.data=[notification object];
	[[self window] setTitle:[NSString stringWithFormat:@"Send Message To @%@",[data objectForKey:@"screen_name"]]];
	[self popUp];
}
-(void)handleReply:(NSNotification*)notification{
	self.postType=ReplyPost;
	self.data =[notification object];
	[[self window] setTitle:[NSString stringWithFormat:@"Reply@%@:%@",[data objectForKey:@"user"],[data objectForKey:@"content"]]];
	[self popUp];
}

-(void)handleRePost:(NSNotification*)notification{
	self.postType=Repost;
	self.data = [notification object];
	NSString *content=[data objectForKey:@"content"];
	NSString *user=[data objectForKey:@"user"];
	NSString *rtContent=[data objectForKey:@"rt_content"];
	NSString *rtUser =[data objectForKey:@"rt_user"];
	if (rtContent) {
		[[self window] setTitle:[NSString stringWithFormat:@"Repost @%@:%@",rtUser,rtContent]];
		[textView setString:[NSString stringWithFormat:@"//@%@:%@",user,content]];
		[textView setSelectedRange:NSMakeRange(0, 0)];
	}else {
		[[self window] setTitle:[NSString stringWithFormat:@"Repost @%@:%@",user,content]];
	}
	[self popUp];
}

-(IBAction)post:(id)sender{
	NSAttributedString *attributedString=[textView attributedString];
	NSUInteger length= attributedString.length;
	NSData *imageData=nil;
	BOOL upload=NO;
	if (length) {
		NSRange searchRange = NSMakeRange(0,0);
		while (searchRange.location<length) {
			NSTextAttachment *textAttachment=[attributedString attribute:NSAttachmentAttributeName
																		atIndex:searchRange.location
																 effectiveRange:&searchRange];
			if (textAttachment) {
				NSFileWrapper *image=[textAttachment fileWrapper];
				imageData=[image regularFileContents];
				[weiboAccount postWithStatus:[textView string] image:imageData imageName:[image preferredFilename]];
				upload=YES;
				//break;
			}
			searchRange.location+=searchRange.length;
		}
	}
	if (!upload) {
		switch (postType) {
			case NormalPost:
				[weiboAccount postWithStatus:[textView string]];
				break;
			case ReplyPost:
				[self.data setObject:[textView string] forKey:@"comment"];
				[weiboAccount reply:self.data];
				break;
			case Repost:
				[self.data setObject:[textView string] forKey:@"status"];
				[weiboAccount repost:self.data];
				break;
			case MessagePost:
				[self.data setObject:[textView string] forKey:@"text"];
				[weiboAccount sendMessage:self.data];
				break;
			default:
				break;
		}
	}
	[postProgressIndicator setHidden:NO];
	[postProgressIndicator startAnimation:self];
	
}
-(void)didPost:(NSNotification*)notification{
	[postProgressIndicator setHidden:YES];
	[postProgressIndicator stopAnimation:self];

	[self close];
}

-(void)popUp{
	NSWindow *window=[self window];
	NSPoint mouseLoc = [NSEvent mouseLocation];
	fromRect.origin=mouseLoc;
	fromRect.size.width=1;
	fromRect.size.height=1;
	if (![window isVisible]) {
		[window zoomOnFromRect:fromRect];
	}
	[window display];
	[window orderFront:self];
	[window makeKeyWindow];
}

- (BOOL)windowShouldClose:(id)sender{
	[[self window] zoomOffToRect:fromRect];
	[textView setString:@""];
	self.data=nil;
	[[self window] setTitle:@""];
	[charactersRemaining setStringValue:[NSString stringWithFormat:@"%d",140]];
	return YES;
}
- (NSArray *)supportedImageTypes {
	return [NSArray arrayWithObjects:@"jpg", @"jpeg", @"png", @"gif", nil];
}
- (IBAction)addPicture:(id)sender {
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel beginSheetForDirectory:nil file:nil types:[self supportedImageTypes] modalForWindow:[self window] modalDelegate:self didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)panel returnCode:(int)returnCode  contextInfo:(void  *)contextInfo {
	if (returnCode == NSOKButton) {
		NSArray *files = [panel URLs];
		if ([files count] > 0) {
			NSLog(@"%@",files);
			// Only open first file selected.
			//[self uploadPictureFile:[files objectAtIndex:0]];
		}
	}
}

@end
