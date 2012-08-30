//
//	ReaderMainPagebar.m
//	Reader v2.5.6
//
//	Created by Julius Oklamcak on 2011-09-01.
//	Copyright © 2011-2012 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderMainPagebar.h"
#import "ReaderThumbCache.h"
#import "ReaderDocument.h"
#import "ReaderConstants.h"

#import <QuartzCore/QuartzCore.h>

@implementation ReaderMainPagebar

#pragma mark Constants

#if (READER_SLIDER == TRUE)
#define THUMB_FRAC 1.7036688617121354f
#define THUMB_SMALL_GAP 3
#define THUMB_SMALL_WIDTH_PAD 212 //140
#define THUMB_SMALL_HEIGHT_PAD (THUMB_SMALL_WIDTH / THUMB_FRAC )

#define THUMB_SMALL_WIDTH_PHONE 80 //140
#define THUMB_SMALL_HEIGHT_PHONE (THUMB_SMALL_WIDTH / THUMB_FRAC )

#define THUMB_LARGE_WIDTH 150
#define THUMB_LARGE_HEIGHT (THUMB_LARGE_WIDTH / THUMB_FRAC)



#else

#define THUMB_SMALL_GAP 2
#define THUMB_SMALL_WIDTH 22
#define THUMB_SMALL_HEIGHT 28

#define THUMB_LARGE_WIDTH 32
#define THUMB_LARGE_HEIGHT 42

#endif

#define PAGE_NUMBER_WIDTH 96.0f
#define PAGE_NUMBER_HEIGHT 30.0f
#define PAGE_NUMBER_SPACE 20.0f

#pragma mark Properties

@synthesize delegate;

#pragma mark ReaderMainPagebar class methods

+ (Class)layerClass
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [CAGradientLayer class];
}

#pragma mark ReaderMainPagebar instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [self initWithFrame:frame document:nil];
}

- (void)updatePageThumbView:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
    
    NSInteger pages = [document.pageNumber intValue];
            
#if (READER_SLIDER == TRUE)
    ReaderPagebarThumb *tthumb = [miniThumbViews objectForKey:[NSNumber numberWithInteger:page]];
        
    CGPoint point = [tthumb center];
    point.y = 0; 
    point.x = point.x - (self.frame.size.width / 2);
    
    [scrollView setContentOffset:point animated:YES];
#endif


	if (pages > 1) // Only update frame if more than one page
	{
#if (READER_SLIDER == TRUE)
		CGFloat controlWidth = scrollView.bounds.size.width;
#else
        CGFloat controlWidth = trackControl.bounds.size.width;
#endif
		CGFloat useableWidth = (controlWidth - THUMB_LARGE_WIDTH);

		CGFloat stride = (useableWidth / (pages - 1)); // Page stride

		NSInteger X = (stride * (page - 1)); CGFloat pageThumbX = X;

		CGRect pageThumbRect = pageThumbView.frame; // Current frame

		if (pageThumbX != pageThumbRect.origin.x) // Only if different
		{
			pageThumbRect.origin.x = pageThumbX; // The new X position

			pageThumbView.frame = pageThumbRect; // Update the frame
		}
	}

#if (READER_SLIDER == TRUE)
    ReaderPagebarThumb *oldthumb = [miniThumbViews objectForKey:[NSNumber numberWithInteger:pageThumbView.tag]];
    [oldthumb makeTransparent];
    [tthumb makeOpaque];
#endif

	if (page != pageThumbView.tag) // Only if page number changed
	{        
		pageThumbView.tag = page; [pageThumbView reuse]; // Reuse the thumb view

		CGSize size = CGSizeMake(THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT); // Maximum thumb size

		NSURL *fileURL = document.fileURL; NSString *guid = document.guid; NSString *phrase = document.password;

		ReaderThumbRequest *request = [ReaderThumbRequest forView:pageThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];

		UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:request priority:YES]; // Request the thumb

		UIImage *thumb = ([image isKindOfClass:[UIImage class]] ? image : nil); [pageThumbView showImage:thumb];
        

	}
}

- (void)updatePageNumberText:(NSInteger)page
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (page != pageNumberLabel.tag) // Only if page number changed
	{
		NSInteger pages = [document.pageCount integerValue]; // Total pages

		NSString *format = NSLocalizedString(@"%d of %d", @"format"); // Format

		NSString *number = [NSString stringWithFormat:format, page, pages]; // Text

		pageNumberLabel.text = number; // Update the page number label text

		pageNumberLabel.tag = page; // Update the last page number tag
	}
}

- (id)initWithFrame:(CGRect)frame document:(ReaderDocument *)object
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	assert(object != nil); // Check

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = YES;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
		self.backgroundColor = [UIColor clearColor];

		CAGradientLayer *layer = (CAGradientLayer *)self.layer;
		UIColor *liteColor = [UIColor colorWithWhite:0.82f alpha:0.8f];
		UIColor *darkColor = [UIColor colorWithWhite:0.32f alpha:0.8f];
		layer.colors = [NSArray arrayWithObjects:(id)liteColor.CGColor, (id)darkColor.CGColor, nil];

		CGRect shadowRect = self.bounds; shadowRect.size.height = 4.0f; shadowRect.origin.y -= shadowRect.size.height;

		ReaderPagebarShadow *shadowView = [[ReaderPagebarShadow alloc] initWithFrame:shadowRect];

		[self addSubview:shadowView]; [shadowView release]; // Add the shadow to the view

		CGFloat numberY = (0.0f - (PAGE_NUMBER_HEIGHT + PAGE_NUMBER_SPACE));
		CGFloat numberX = ((self.bounds.size.width - PAGE_NUMBER_WIDTH) / 2.0f);
		CGRect numberRect = CGRectMake(numberX, numberY, PAGE_NUMBER_WIDTH, PAGE_NUMBER_HEIGHT);

		pageNumberView = [[UIView alloc] initWithFrame:numberRect]; // Page numbers view

		pageNumberView.autoresizesSubviews = NO;
		pageNumberView.userInteractionEnabled = NO;
		pageNumberView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		pageNumberView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];

		pageNumberView.layer.cornerRadius = 4.0f;
		pageNumberView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);
		pageNumberView.layer.shadowColor = [UIColor colorWithWhite:0.0f alpha:0.6f].CGColor;
		pageNumberView.layer.shadowPath = [UIBezierPath bezierPathWithRect:pageNumberView.bounds].CGPath;
		pageNumberView.layer.shadowRadius = 2.0f; pageNumberView.layer.shadowOpacity = 1.0f;

		CGRect textRect = CGRectInset(pageNumberView.bounds, 4.0f, 2.0f); // Inset the text a bit

		pageNumberLabel = [[UILabel alloc] initWithFrame:textRect]; // Page numbers label

		pageNumberLabel.autoresizesSubviews = NO;
		pageNumberLabel.autoresizingMask = UIViewAutoresizingNone;
		pageNumberLabel.textAlignment = UITextAlignmentCenter;
		pageNumberLabel.backgroundColor = [UIColor clearColor];
		pageNumberLabel.textColor = [UIColor whiteColor];
		pageNumberLabel.font = [UIFont systemFontOfSize:16.0f];
		pageNumberLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
		pageNumberLabel.shadowColor = [UIColor blackColor];
		pageNumberLabel.adjustsFontSizeToFitWidth = YES;
		pageNumberLabel.minimumFontSize = 12.0f;

		[pageNumberView addSubview:pageNumberLabel]; // Add label view

		[self addSubview:pageNumberView]; // Add page numbers display view

        
#if (READER_SLIDER == TRUE)
        scrollView = [[ReaderPreview alloc] initWithFrame:frame];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapGesture:)];
        //tapGesture.numberOfTouchesRequired = 1; tapGesture.numberOfTapsRequired = 1; tapGesture.delegate = self;
        [scrollView addGestureRecognizer:tapGesture]; [tapGesture release];
        [self addSubview:scrollView];
#else
		trackControl = [[ReaderTrackControl alloc] initWithFrame:self.bounds]; // Track control view

		[trackControl addTarget:self action:@selector(trackViewTouchDown:) forControlEvents:UIControlEventTouchDown];
		[trackControl addTarget:self action:@selector(trackViewValueChanged:) forControlEvents:UIControlEventValueChanged];
		[trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
		[trackControl addTarget:self action:@selector(trackViewTouchUp:) forControlEvents:UIControlEventTouchUpInside];

		[self addSubview:trackControl]; // Add the track control and thumbs view
#endif

		document = [object retain]; // Retain the document object for our use

		[self updatePageNumberText:[document.pageNumber integerValue]];

		miniThumbViews = [NSMutableDictionary new]; // Small thumbs
	}

	return self;
}

- (void)removeFromSuperview
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[trackTimer invalidate]; [enableTimer invalidate];

	[super removeFromSuperview];
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[trackTimer release], trackTimer = nil;

	[enableTimer release], enableTimer = nil;

#if (READER_SLIDER == TRUE)
    [scrollView release], scrollView = nil;
#else
	[trackControl release], trackControl = nil;
#endif
	[miniThumbViews release], miniThumbViews = nil;

	[pageNumberLabel release], pageNumberLabel = nil;

	[pageNumberView release], pageNumberView = nil;

	[pageThumbView release], pageThumbView = nil;

	[document release], document = nil;

	[super dealloc];
}

- (void)layoutSubviews
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
    
#if (READER_SLIDER == TRUE)
    float THUMB_SMALL_WIDTH = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? THUMB_SMALL_WIDTH_PHONE : THUMB_SMALL_WIDTH_PAD;
    float THUMB_SMALL_HEIGHT = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) ? THUMB_SMALL_HEIGHT_PHONE : THUMB_SMALL_HEIGHT_PAD;
#endif
    
	CGRect controlRect = CGRectInset(self.bounds, 4.0f, 0.0f);

	CGFloat thumbWidth = (THUMB_SMALL_WIDTH + THUMB_SMALL_GAP);
    
    NSInteger pages = [document.pageCount integerValue]; // Pages
    
#if (READER_SLIDER == TRUE)
    NSInteger thumbs = pages;
#else
    NSInteger thumbs = (controlRect.size.width / thumbWidth);
#endif
    
	if (thumbs > pages) thumbs = pages; // No more than total pages

	CGFloat controlWidth = ((thumbs * thumbWidth) - THUMB_SMALL_GAP);

	controlRect.size.width = controlWidth; // Update control width

	CGFloat widthDelta = (self.bounds.size.width - controlWidth);

	NSInteger X = (widthDelta / 2.0f); controlRect.origin.x = X;

#if (READER_SLIDER == TRUE)
    CGFloat width = (THUMB_SMALL_WIDTH + THUMB_SMALL_GAP) * pages;

    if (width < self.bounds.size.width) {
        width = self.bounds.size.width;
    }

    scrollView.contentSize = CGSizeMake(width, controlRect.size.height);
#else
	trackControl.frame = controlRect; // Update track control frame
#endif
    
    
	if (pageThumbView == nil) // Create the page thumb view when needed
	{        
		CGFloat heightDelta = (controlRect.size.height - THUMB_LARGE_HEIGHT);

		NSInteger thumbY = (heightDelta / 2.0f); NSInteger thumbX = 0; // Thumb X, Y

		CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_LARGE_WIDTH, THUMB_LARGE_HEIGHT);

		pageThumbView = [[ReaderPagebarThumb alloc] initWithFrame:thumbRect]; // Create the thumb view

		pageThumbView.layer.zPosition = 1.0f; // Z position so that it sits on top of the small thumbs

        NSInteger pageNum = [document.pageNumber integerValue];

#if (READER_SLIDER == TRUE)        
        if (pageThumbView.tag != pageNum)
        { 
            [self updatePageThumbView:pageNum]; // Update page thumb view
        }
#else
		[trackControl addSubview:pageThumbView]; // Add as the first subview of the track control
        [self updatePageThumbView:pageNum]; // Update page thumb view
#endif
	}

       
	NSInteger strideThumbs = (thumbs - 1); if (strideThumbs < 1) strideThumbs = 1;

	CGFloat stride = ((CGFloat)pages / (CGFloat)strideThumbs); // Page stride

	//CGFloat heightDelta = (controlRect.size.height - THUMB_SMALL_HEIGHT);

	//NSInteger thumbY = (heightDelta / 2.0f); NSInteger thumbX = 0; // Initial X, Y

#if (READER_SLIDER == TRUE)
#else
	CGRect thumbRect = CGRectMake(thumbX, thumbY, THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT);
#endif
   
	NSMutableDictionary *thumbsToHide = [[miniThumbViews mutableCopy] autorelease];

	for (NSInteger thumb = 0; thumb < thumbs; thumb++) // Iterate through needed thumbs
	{
		NSInteger page = ((stride * thumb) + 1); if (page > pages) page = pages; // Page

		NSNumber *key = [NSNumber numberWithInteger:page]; // Page number key for thumb view

		ReaderPagebarThumb *smallThumbView = [miniThumbViews objectForKey:key]; // Thumb view
                
#if (READER_SLIDER == TRUE)
        CGFloat yOrigin = thumb * (THUMB_SMALL_WIDTH + THUMB_SMALL_GAP);
        CGRect thumbRect = CGRectMake(yOrigin, 0, THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT);
#else
#endif
		if (smallThumbView == nil) // We need to create a new small thumb view for the page number
		{
			CGSize size = CGSizeMake(THUMB_SMALL_WIDTH, THUMB_SMALL_HEIGHT); // Maximum thumb size

			NSURL *fileURL = document.fileURL; NSString *guid = document.guid; NSString *phrase = document.password;

			smallThumbView = [[ReaderPagebarThumb alloc] initWithFrame:thumbRect small:YES]; // Create a small thumb view

			ReaderThumbRequest *thumbRequest = [ReaderThumbRequest forView:smallThumbView fileURL:fileURL password:phrase guid:guid page:page size:size];

			UIImage *image = [[ReaderThumbCache sharedInstance] thumbRequest:thumbRequest priority:NO]; // Request the thumb

			if ([image isKindOfClass:[UIImage class]]) [smallThumbView showImage:image]; // Use thumb image from cache
            
#if (READER_SLIDER == TRUE)
            [scrollView addSubview:smallThumbView]; [miniThumbViews setObject:smallThumbView forKey:key];
            smallThumbView.tag = page;
#else
			[trackControl addSubview:smallThumbView]; [miniThumbViews setObject:smallThumbView forKey:key];
#endif
            
			[smallThumbView release], smallThumbView = nil; // Cleanup
		}
		else // Resue existing small thumb view for the page number
		{
			smallThumbView.hidden = NO; [thumbsToHide removeObjectForKey:key];

			if (CGRectEqualToRect(smallThumbView.frame, thumbRect) == false)
			{
				smallThumbView.frame = thumbRect; // Update thumb frame
			}
		}
        
		thumbRect.origin.x += thumbWidth; // Next thumb X position
	}

	[thumbsToHide enumerateKeysAndObjectsUsingBlock: // Hide unused thumbs
		^(id key, id object, BOOL *stop)
		{
			ReaderPagebarThumb *thumb = object; thumb.hidden = YES;
		}
	];
}

- (void)updatePagebarViews
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
    
	NSInteger page = [document.pageNumber integerValue]; // #
    
	[self updatePageNumberText:page]; // Update page number text

	[self updatePageThumbView:page]; // Update page thumb view
}

- (void)updatePagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == NO) // Only if visible
	{
		[self updatePagebarViews]; // Update views
	}
}

- (void)hidePagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == NO) // Only if visible
	{
		[UIView animateWithDuration:0.5 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.alpha = 0.0f;
			}
			completion:^(BOOL finished)
			{
				self.hidden = YES;
			}
		];
	}
}

- (void)showPagebar
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.hidden == YES) // Only if hidden
	{
		[self updatePagebarViews]; // Update views first

		[UIView animateWithDuration:0.5 delay:0.0
			options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
			animations:^(void)
			{
				self.hidden = NO;
				self.alpha = 1.0f;
			}
			completion:NULL
		];
	}
}

#pragma mark ReaderTrackControl action methods

- (void)trackTimerFired:(NSTimer *)timer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[trackTimer invalidate]; [trackTimer release], trackTimer = nil; // Cleanup
#if (READER_SLIDER == TRUE)
#else
	if (trackControl.tag != [document.pageNumber integerValue]) // Only if different
	{
		[delegate pagebar:self gotoPage:trackControl.tag]; // Go to document page
	}
#endif
}

- (void)enableTimerFired:(NSTimer *)timer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[enableTimer invalidate]; [enableTimer release], enableTimer = nil; // Cleanup
#if (READER_SLIDER == TRUE)
#else
	trackControl.userInteractionEnabled = YES; // Enable track control interaction
#endif
}

- (void)restartTrackTimer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (trackTimer != nil) { [trackTimer invalidate]; [trackTimer release], trackTimer = nil; } // Invalidate and release previous timer

	trackTimer = [[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(trackTimerFired:) userInfo:nil repeats:NO] retain];
}

- (void)startEnableTimer
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (enableTimer != nil) { [enableTimer invalidate]; [enableTimer release], enableTimer = nil; } // Invalidate and release previous timer

	enableTimer = [[NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(enableTimerFired:) userInfo:nil repeats:NO] retain];
}

- (NSInteger)trackViewPageNumber:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGFloat controlWidth = trackView.bounds.size.width; // View width

	CGFloat stride = (controlWidth / [document.pageCount integerValue]);

	NSInteger page = (trackView.value / stride); // Integer page number

	return (page + 1); // + 1
}

- (void)trackViewTouchDown:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
    
	NSInteger page = [self trackViewPageNumber:trackView]; // Page

	if (page != [document.pageNumber integerValue]) // Only if different
	{
		[self updatePageNumberText:page]; // Update page number text

		[self updatePageThumbView:page]; // Update page thumb view

		[self restartTrackTimer]; // Start the track timer
	}

	trackView.tag = page; // Start page tracking
}

- (void)trackViewValueChanged:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	NSInteger page = [self trackViewPageNumber:trackView]; // Page

	if (page != trackView.tag) // Only if the page number has changed
	{
		[self updatePageNumberText:page]; // Update page number text

		[self updatePageThumbView:page]; // Update page thumb view

		trackView.tag = page; // Update the page tracking tag

		[self restartTrackTimer]; // Restart the track timer
	}
}

- (void)trackViewTouchUp:(ReaderTrackControl *)trackView
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[trackTimer invalidate]; [trackTimer release], trackTimer = nil; // Cleanup

	if (trackView.tag != [document.pageNumber integerValue]) // Only if different
	{
		trackView.userInteractionEnabled = NO; // Disable track control interaction

		[delegate pagebar:self gotoPage:trackView.tag]; // Go to document page

		[self startEnableTimer]; // Start track control enable timer
	}

	trackView.tag = 0; // Reset page tracking
}


- (ReaderPagebarThumb *)thumbCellContainingPoint:(CGPoint)point
{
#ifdef DEBUGX
    NSLog(@"%s %@", __FUNCTION__, NSStringFromCGPoint(point));
#endif
    
    ReaderPagebarThumb *theCell = nil;  
    
    for (ReaderPagebarThumb *tvCell in [miniThumbViews allValues])
    {
        if (CGRectContainsPoint(tvCell.frame, point) == true)
        {
            theCell = tvCell; break; // Found it                  
        }
    }
    return theCell;
}


- (void)handleTapGesture:(UITapGestureRecognizer *)recognizer
{
#ifdef DEBUGX
    NSLog(@"%s", __FUNCTION__);
#endif
   
    if (recognizer.state == UIGestureRecognizerStateRecognized) // Handle the tap
    {
        CGPoint point = [recognizer locationInView:recognizer.view]; // Tap location
        ReaderThumbView *tvCell = [self thumbCellContainingPoint:point]; // Look for cell
        
        if (tvCell != nil) //[delegate thumbsView:self didSelectThumbWithIndex:tvCell.tag];
        {   
            [delegate pagebar:self gotoPage:tvCell.tag];
        }
    }
}


@end

#pragma mark - 

//
//  ReaderPreview class implementation
//


@implementation ReaderPreview

#pragma mark Properties

#pragma mark ReaderPreview instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
    NSLog(@"%s", __FUNCTION__);
#endif
    
    CGRect newFrame = CGRectMake(0, THUMB_SMALL_GAP, frame.size.width, frame.size.height);
    
    if ((self = [super initWithFrame:newFrame]))
    {
        self.autoresizesSubviews = NO;
        self.pagingEnabled = NO;
        self.userInteractionEnabled = YES;
        self.contentMode = UIViewContentModeRedraw;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)dealloc
{
#ifdef DEBUGX
    NSLog(@"%s", __FUNCTION__);
#endif

    [super dealloc];
}

@end

#pragma mark -

//
//	ReaderTrackControl class implementation
//

@implementation ReaderTrackControl

#pragma mark Properties

@synthesize value = _value;

#pragma mark ReaderTrackControl instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = YES;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingNone;
		self.backgroundColor = [UIColor clearColor];
	}

	return self;
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[super dealloc];
}

- (CGFloat)limitValue:(CGFloat)valueX
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGFloat minX = self.bounds.origin.x; // 0.0f;
	CGFloat maxX = (self.bounds.size.width - 1.0f);

	if (valueX < minX) valueX = minX; // Minimum X
	if (valueX > maxX) valueX = maxX; // Maximum X

	return valueX;
}

#pragma mark UIControl subclass methods

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGPoint point = [touch locationInView:self]; // Touch point

	_value = [self limitValue:point.x]; // Limit control value

	return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if (self.touchInside == YES) // Only if inside the control
	{
		CGPoint point = [touch locationInView:touch.view]; // Touch point

		CGFloat x = [self limitValue:point.x]; // Potential new control value

		if (x != _value) // Only if the new value has changed since the last time
		{
			_value = x; [self sendActionsForControlEvents:UIControlEventValueChanged];
		}
	}

	return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	CGPoint point = [touch locationInView:self]; // Touch point

	_value = [self limitValue:point.x]; // Limit control value
}

@end

#pragma mark -

//
//	ReaderPagebarThumb class implementation
//

@implementation ReaderPagebarThumb

//#pragma mark Properties

//@synthesize ;

#pragma mark ReaderPagebarThumb instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [self initWithFrame:frame small:NO];
}

- (id)initWithFrame:(CGRect)frame small:(BOOL)small
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame])) // Superclass init
	{
        CGFloat value = (small ? 0.1f : 0.2f); // Size based alpha value

		UIColor *background = [UIColor colorWithWhite:0.8f alpha:value];

		self.backgroundColor = background; imageView.backgroundColor = background;

		imageView.layer.borderColor = [UIColor colorWithWhite:0.4f alpha:0.6f].CGColor;

		imageView.layer.borderWidth = 1.0f; // Give the thumb image view a border
        
        imageView.alpha = 0.5f;
	}

	return self;
}

- (void)makeTransparent;
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

    imageView.alpha = 0.5f;
}

- (void)makeOpaque
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif
    
    imageView.alpha = 1.0f;

}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[super dealloc];
}

@end

#pragma mark -

//
//	ReaderPagebarShadow class implementation
//

@implementation ReaderPagebarShadow

//#pragma mark Properties

//@synthesize ;

#pragma mark ReaderPagebarShadow class methods

+ (Class)layerClass
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	return [CAGradientLayer class];
}

#pragma mark ReaderPagebarShadow instance methods

- (id)initWithFrame:(CGRect)frame
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	if ((self = [super initWithFrame:frame]))
	{
		self.autoresizesSubviews = NO;
		self.userInteractionEnabled = NO;
		self.contentMode = UIViewContentModeRedraw;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.backgroundColor = [UIColor clearColor];

		CAGradientLayer *layer = (CAGradientLayer *)self.layer;
		UIColor *blackColor = [UIColor colorWithWhite:0.42f alpha:1.0f];
		UIColor *clearColor = [UIColor colorWithWhite:0.42f alpha:0.0f];
		layer.colors = [NSArray arrayWithObjects:(id)clearColor.CGColor, (id)blackColor.CGColor, nil];
	}

	return self;
}

- (void)dealloc
{
#ifdef DEBUGX
	NSLog(@"%s", __FUNCTION__);
#endif

	[super dealloc];
}

@end
