//
//  TextEditViewController.m
//

#import "TextEditViewController.h"

@implementation TextEditViewController

@synthesize theTextView, accessoryView, viewTitle, viewSubtitle, theText, delegate, viewTag;

- (BOOL)textViewShouldBeginEditing:(UITextView *)aTextView 
{
    //[self.theTextView becomeFirstResponder];
    
	UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]
                                   initWithBarButtonSystemItem:UIBarButtonSystemItemDone 
                                   target:self 
                                   action:@selector(finishEdit)];
	
	self.navigationItem.rightBarButtonItem = doneButton;
	
	return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)aTextView 
{
    [aTextView resignFirstResponder];
    self.navigationItem.rightBarButtonItem = nil;
    return YES;
}

- (void)finishEdit 
{
    [theTextView resignFirstResponder];
}

#pragma mark - Responding to keyboard events

- (void)keyboardWillShow:(NSNotification *)notification 
{
    if (keyboardVisible)
    {
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    NSValue *aValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [aValue CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    
    CGFloat keyboardTop = keyboardRect.origin.y;
    CGRect newTextViewFrame = self.view.bounds;
    newTextViewFrame.size.height = keyboardTop - self.view.bounds.origin.y;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
	
    theTextView.frame = newTextViewFrame;
	
    [UIView commitAnimations];
    
    keyboardVisible = YES;
}

- (void)keyboardWillHide:(NSNotification *)notification 
{    
    if (!keyboardVisible)
    {
        return;
    }
    
    NSDictionary *userInfo = [notification userInfo];
    
    CGRect newTextViewFrame = self.view.bounds;
    
    // Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    // Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
	
    theTextView.frame = newTextViewFrame;
	
    [UIView commitAnimations];
    
    keyboardVisible = NO;
}

#pragma mark - View lifecycle

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    //METHOD_LOG;
    //NSLog(@"shouldAutorotateToInterfaceOrientation: %d", toInterfaceOrientation);
    
	return YES;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
	
    // Observe keyboard hide and show notifications to resize the text view appropriately.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    self.navigationItem.rightBarButtonItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self.navigationController setNavigationBarHidden:NO];
	[self.theTextView setHidden:NO];
	self.title = @"Notes";
    [self.theTextView setText:theText];
    
    self.navigationItem.title = viewTitle;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (delegate && [delegate respondsToSelector:@selector(textEditViewDone:tag:)])
    {
        [delegate textEditViewDone:theTextView.text tag:viewTag];
    }
}

#pragma mark - Memory management

- (void)didReceiveMemoryWarning 
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
	self.theTextView = nil;
	self.accessoryView = nil;
	self.accessoryView = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)dealloc 
{
    delegate = nil;
}

@end
