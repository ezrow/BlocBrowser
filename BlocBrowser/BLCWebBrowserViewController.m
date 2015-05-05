//
//  BLCWebBrowserViewController.m
//  BlocBrowser
//
//  Created by Ryan Williams on 27/04/15.
//  Copyright (c) 2015 Ryan Williams. All rights reserved.
//

#import "BLCWebBrowserViewController.h"
#import "BLCAwesomeFloatingToolbar.h"

@interface BLCWebBrowserViewController () <UIWebViewDelegate, UITextFieldDelegate, BLCAwesomeFloatingToolbarDelegate>

@property (nonatomic, strong) UIWebView *webview;
@property (nonatomic, strong) UITextField *textField;


@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;
@property (nonatomic, strong) BLCAwesomeFloatingToolbar *awesomeToolbar;
@property (nonatomic, assign) NSUInteger frameCount;

#define kBLCWebBrowserBackString NSLocalizedString(@"Back", @"Back command")
#define kBLCWebBrowserForwardString NSLocalizedString(@"Forward", @"Forward command")
#define kBLCWebBrowserStopString NSLocalizedString(@"Stop", @"Stop command")
#define kBLCWebBrowserRefreshString NSLocalizedString(@"Refresh", @"Reload command")
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

    self.awesomeToolbar = [[BLCAwesomeFloatingToolbar alloc] initWithFourTitles:@[kBLCWebBrowserBackString, kBLCWebBrowserForwardString, kBLCWebBrowserStopString, kBLCWebBrowserRefreshString]];
    
    self.awesomeToolbar.delegate = self;
    
    for (UIView *viewToAdd in @[self.webview, self.textField, self.awesomeToolbar]) {
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
    CGFloat browserHeight = CGRectGetHeight(self.view.bounds) - itemHeight;
    
    // Now, assign the frames
    self.textField.frame = CGRectMake(0, 0, width, itemHeight);
    self.webview.frame = CGRectMake(0, CGRectGetMaxY(self.textField.frame), width, browserHeight);
    
    self.awesomeToolbar.frame = CGRectMake(20, 100, 280, 60);
}

#pragma mark - BLCAwesomeFloatingToolbarDelegate

- (void) floatingToolbar:(BLCAwesomeFloatingToolbar *)toolbar didSelectButtonWithTitle:(NSString *)title {
    if ([title isEqual:NSLocalizedString(kBLCWebBrowserBackString, @"Back command")]) {
        [self.webview goBack];
    } else if ([title isEqual:NSLocalizedString(kBLCWebBrowserForwardString, @"Forward command")]) {
        [self.webview goForward];
    } else if ([title isEqual:NSLocalizedString(kBLCWebBrowserStopString, @"Stop command")]) {
        [self.webview stopLoading];
    } else if ([title isEqual:NSLocalizedString(kBLCWebBrowserRefreshString, @"Reload command")]) {
        [self.webview reload];
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
    
    [self.awesomeToolbar setEnabled:[self.webview canGoBack] forButtonWithTitle:kBLCWebBrowserBackString];
    [self.awesomeToolbar setEnabled:[self.webview canGoForward] forButtonWithTitle:kBLCWebBrowserForwardString];
    [self.awesomeToolbar setEnabled:self.frameCount > 0 forButtonWithTitle:kBLCWebBrowserStopString];
    [self.awesomeToolbar setEnabled:self.webview.request.URL && self.frameCount == 0 forButtonWithTitle:kBLCWebBrowserRefreshString];

}

- (void) resetWebView {
    [self.webview removeFromSuperview];
    
    UIWebView *newWebView = [[UIWebView alloc] init];
    newWebView.delegate = self;
    [self.view addSubview:newWebView];
    
    self.webview = newWebView;
    
    self.textField.text = nil;
    [self updateButtonsAndTitle];
}

@end
