//
//  ViewController.h
//  GaoDeHelloAMap
//
//  Created by 王增迪 on 12/12/14.
//  Copyright (c) 2014 Wang Zengdi. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController : UIViewController

//@property (nonatomic, strong) CLLocation *currentLocation;
- (void)beforeApplicationResignActive;
- (void)afterApplicationDidBecomeActive;

@end
