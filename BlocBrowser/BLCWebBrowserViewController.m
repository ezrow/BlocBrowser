//
//  BLCWebBrowserViewController.m
//  BlocBrowser
//
//  Created by Ryan Williams on 27/04/15.
//  Copyright (c) 2015 Ryan Williams. All rights reserved.
//

#import "BLCWebBrowserViewController.h"

@interface BLCWebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIButton *stopButton;
@property (nonatomic, strong) UIButton *reloadButton;

@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, assign) NSUInteger frameCount;

@end

@implementation BLCWebBrowserViewController

#pragma mark - UIViewController


- (void)loadView {
    UIView *mainView = [UIView new];
    
    self.webview = [[UIWebView alloc] init];
    self.webview.delegate = self;
    
    self.textField = [[UITextField alloc] init];
    self.textField.keyboardType = UIKeyboardTypeURL;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.placeholder = NSLocalizedString(@"Website URL or text to search for", @"Placehorlder for URL or text to search for");
    self.textField.backgroundColor = [UIColor colorWithWhite:220/255.0f alpha:1];
    self.textField.delegate = self;

    self.backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.backButton setEnabled:NO];
    
    self.forwardButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.forwardButton setEnabled:NO];
    
    self.stopButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.stopButton setEnabled:NO];
    
    self.reloadButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.reloadButton setEnabled:NO];
    
    [self.backButton setTitle:NSLocalizedString(@"Back", @"Back comnmand") forState:UIControlStateNormal];
    
    [self.forwardButton setTitle:NSLocalizedString(@"Forward", @"Forward comnmand") forState:UIControlStateNormal];
    
    [self.stopButton setTitle:NSLocalizedString(@"Stop", @"Stop comnmand") forState:UIControlStateNormal];
    
    [self.reloadButton setTitle:NSLocalizedString(@"Refresh", @"Reload comnmand") forState:UIControlStateNormal];
    
    [self addButtonTargets];
    
    for (UIView *viewToAdd in @[self.webview, self.textField, self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        [mainView addSubview:viewToAdd];
    }
    
    self.view = mainView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.activityIndicator];
    [self.activityIndicator startAnimating];
    // Do any additional setup after loading the view.
}

- (void) viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    //make the webview fill the main view
    // First, calculate some dimensions.
    static const CGFloat itemHeight = 50;
    CGFloat width = CGRectGetWidth(self.view.bounds);
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight - itemHeight;
    CGFloat buttonWidth = CGRectGetWidth(self.view.bounds) / 4;
    
    
    // Now, assign the frames
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webview.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    CGFloat currentButtonX = 0;
    
    for (UIButton *thisButton in @[self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        thisButton.frame = CGRectMake(currentButtonX, CGRectGetMaxY(self.webview.frame), buttonWidth, itemHeight);
        currentButtonX += buttonWidth;
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    
    NSString *URLString = textField.text;
    
    NSURL *URL = [NSURL URLWithString:URLString];
    NSArray *componentsSeparatedByWhiteSpace = [URLString componentsSeparatedByString:@" "];
    
    if([componentsSeparatedByWhiteSpace count] > 1){
        NSLog(@"Found whitespace");
        
        NSCharacterSet *doNotWant = [NSCharacterSet characterSetWithCharactersInString:@"/: "];
        NSString *queryString = [[URLString componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @"+"];

        URLString =[NSString stringWithFormat:@"%@/%@", @"http://google.com/search?q=", queryString];
        URL = [NSURL URLWithString:[NSString stringWithFormat:@"%@", URLString]];
        
    }else{
        
        if (!URL.scheme) {
        // The user didn't type http: or https:
            URL = [NSURL URLWithString:[NSString stringWithFormat:@"http://%@", URLString]];
        }

    }
    
    
    if (URL) {
        NSURLRequest *request = [NSURLRequest requestWithURL:URL];
        [self.webview loadRequest:request];
    }
    return NO;
}

#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
     self.isLoading = YES;
    self.frameCount++;
    [self updateButtonsAndTitle];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
     self.isLoading = NO;
    self.frameCount--;
    [self updateButtonsAndTitle];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (error.code != -999) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error")
                                                        message:[error localizedDescription]
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                              otherButtonTitles:nil];
        [alert show];
    }
    self.frameCount--;
[self updateButtonsAndTitle];
}

#pragma mark - Miscellaneous

- (void) updateButtonsAndTitle {
    NSString *webpageTitle = [self.webview stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    if (webpageTitle) {
        self.title = webpageTitle;
    } else {
        self.title = self.webview.request.URL.absoluteString;
    }
    
    if (self.frameCount > 0) {
        [self.activityIndicator startAnimating];
    } else {
        [self.activityIndicator stopAnimating];
    }
    
    self.backButton.enabled = [self.webview canGoBack];
    self.forwardButton.enabled = [self.webview canGoForward];
    self.stopButton.enabled = self.frameCount > 0;
    self.reloadButton.enabled = self.frameCount == 0;
    
    self.reloadButton.enabled = self.webview.request.URL && self.frameCount == 0;
}

- (void) resetWebView {
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    
    [self addButtonTargets];
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}

- (void) addButtonTargets {
    for (UIButton *button in @[self.backButton, self.forwardButton, self.stopButton, self.reloadButton]) {
        [button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self.backButton addTarget:self.webview action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.forwardButton addTarget:self.webview action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
    [self.stopButton addTarget:self.webview action:@selector(stopLoading) forControlEvents:UIControlEventTouchUpInside];
    [self.reloadButton addTarget:self.webview action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
}

@end
