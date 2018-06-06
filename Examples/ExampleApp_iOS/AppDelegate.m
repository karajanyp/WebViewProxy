//
//  AppDelegate.m
//  ExampleApp_iOS
//
//  Created by Marcus Westin on 6/13/13.
//  Copyright (c) 2013 WebViewProxy. All rights reserved.
//

#import "AppDelegate.h"
#import "WebViewProxy.h"

#pragma mark - TestBedViewController

@interface TestBedViewController : UIViewController <UIWebViewDelegate, NSURLSessionTaskDelegate, NSURLSessionDataDelegate, NSURLSessionDelegate>
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) NSString *chicken_proxy_host;
@property (nonatomic, strong) NSString *chicken_proxy_port;
@end

@implementation TestBedViewController
 
- (void)loadView
{
    self.view = [[UIView alloc] init];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self _setupProxy];
    [self _createWebView];
}

- (void) _createWebView {
    UIWebView* webView = [[UIWebView alloc] initWithFrame:self.window.bounds];
    [_window addSubview:webView];
    NSString* htmlPath = [[NSBundle mainBundle] pathForResource:@"WebViewContent" ofType:@"html"];
    NSString* html = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    [webView loadHTMLString:html baseURL:nil];
}

- (void) _setupProxy {
    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    [queue setMaxConcurrentOperationCount:5];
    
    #if 0
    //socks5 proxy
    [WebViewProxy handleRequestsWithHost:@".*" handler:^(NSURLRequest *req, WVPResponse *res) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        configuration.connectionProxyDictionary=@{(NSString *)kCFStreamPropertySOCKSProxyHost: @"104.233.252.165",
                                                  (NSString *)kCFStreamPropertySOCKSProxyPort: @31601,
                                                  (NSString *)kCFStreamPropertySOCKSUser: @"user1",
                                                  (NSString *)kCFStreamPropertySOCKSPassword: @"passwd1"
                                                  };
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
 
        NSURLRequest *request = [NSURLRequest requestWithURL:req.URL];
        
        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:
                                      ^(NSData *data, NSURLResponse *response, NSError *error) {
                                        NSLog(@"error = %@, response = %@", error, response);
                                        if (error) {
                                            return [res pipeError:error];
                                        } else if (((NSHTTPURLResponse*)error).statusCode >= 400) {
                                            return [res respondWithStatusCode:500 text:@"There was some sort of error :("];
                                        } else {
                                            [res respondWithData:data mimeType:response.MIMEType];
                                        }
                                      }];
        
        [task resume];
    }];
    #endif
    
    #if 0
    //https proxy
    [WebViewProxy handleRequestsWithHost:@".*" handler:^(NSURLRequest *req, WVPResponse *res) {
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        
        configuration.connectionProxyDictionary = @{
                                                    @"HTTPEnable" : [NSNumber numberWithInt:1],
                                                    (NSString *)kCFStreamPropertyHTTPProxyHost: @"98.126.23.24",
                                                    (NSString *)kCFStreamPropertyHTTPProxyPort: @30250,
                                                    
                                                    @"HTTPSEnable" : [NSNumber numberWithInt:1],
                                                    (NSString *)kCFStreamPropertyHTTPSProxyHost:@"98.126.23.24",
                                                    (NSString *)kCFStreamPropertyHTTPSProxyPort:@30250,
                                                    };

        NSString *username = @"user1";
        NSString *password = @"passwd1";
        NSString *authString = [NSString stringWithFormat:@"%@:%@",
                                username,
                                password];
        
        NSData *authData = [authString dataUsingEncoding:NSUTF8StringEncoding];
        
        NSString *authHeader = [NSString stringWithFormat: @"Basic %@",
                                [authData base64EncodedStringWithOptions:0]];
        
        [configuration setHTTPAdditionalHeaders:@{
                                                  @"Proxy-Authorization": authHeader
                                                  }
        ];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];

        NSURLRequest *request = [NSURLRequest requestWithURL:req.URL];

        NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:
                                      ^(NSData *data, NSURLResponse *response, NSError *error) {
                                        NSLog(@"error = %@, response = %@", error, response);
                                        if (error) {
                                            return [res pipeError:error];
                                        } else if (((NSHTTPURLResponse*)error).statusCode >= 400) {
                                            return [res respondWithStatusCode:500 text:@"There was some sort of error :("];
                                        } else {
                                            
                                            [res respondWithData:data mimeType:response.MIMEType];
                                        }
                                      }];
        
        [task resume];
    }];
    #endif
    
    [WebViewProxy handleRequestsWithHost:@"www.google.com" path:@"/images/srpr/logo3w.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:req.URL] queue:queue completionHandler:^(NSURLResponse *netRes, NSData *data, NSError *netErr) {
            if (netErr) {
                return [res pipeError:netErr];
            } else if (((NSHTTPURLResponse*)netRes).statusCode >= 400) {
                return [res respondWithStatusCode:500 text:@"There was some sort of error :("];
            } else {
                [res respondWithData:data mimeType:@"image/png"];
            }
        }];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"intercept" path:@"/Galaxy.png" handler:^(NSURLRequest* req, WVPResponse *res) {
        NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Galaxy" ofType:@"png"];
        UIImage* image = [UIImage imageWithContentsOfFile:filePath];
        [res respondWithImage:image];
    }];
    
    [WebViewProxy handleRequestsWithHost:@"example.proxy" handler:^(NSURLRequest *req, WVPResponse *res) {
        NSString* proxyUrl = [req.URL.absoluteString stringByReplacingOccurrencesOfString:@"example.proxy" withString:@"example.com"];
        NSURLRequest* proxyReq = [NSURLRequest requestWithURL:[NSURL URLWithString:proxyUrl]];
        [NSURLConnection connectionWithRequest:proxyReq delegate:res];
    }];
}

#pragma mark UIWebViewDelegate

// You can decide what to do with redirection by implementing the delegate method below if no proxy is used.
-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSLog(@"request url = %@, navigation type = %ld", request.URL.absoluteString, (long)navigationType);
//     if ([request.URL.absoluteString containsString:@"itunes.apple.com"]) {
//         [[UIApplication sharedApplication] openURL:request.URL];
//         return NO;
//     }
    return YES;
}

#pragma mark URLSessionDelegate

// You need to implement the delegate method below to deal with redirection if proxy is used.
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task willPerformHTTPRedirection:(NSHTTPURLResponse *)response newRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURLRequest * _Nullable))completionHandler
{
    NSLog(@"response = %@, request = %@", response, request.URL.absoluteString);
    
    //允许服务器重定向
    if (completionHandler)
    {
        completionHandler(request);
//         NSDictionary *responseHeaders = response.allHeaderFields;
//         if (responseHeaders && responseHeaders[@"Location"] && [responseHeaders[@"Location"] containsString:@"itunes.apple.com"]) {
//             completionHandler(nil);
//             [self.webView loadRequest:request];
//         } else {
//             completionHandler(request);
//         }
    }
}

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    TestBedViewController *tbvc = [[TestBedViewController alloc] init];
    tbvc.edgesForExtendedLayout = UIRectEdgeNone;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:tbvc];
    self.window.rootViewController = nav;
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    return YES;
}

@end
