//
//  ViewController.m
//  GaoDeHelloAMap
//
//  Created by 王增迪 on 12/12/14.
//  Copyright (c) 2014 Wang Zengdi. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchAPI.h>

#import "ARView.h"
#import "PlaceOfInterest.h"
#define APIKey      @"292a7bf1d4b969e26508683f5447a9c0"


@interface ViewController ()<MAMapViewDelegate, AMapSearchDelegate,
UITableViewDataSource, UITableViewDelegate>
{
    MAMapView *_mapView;
    ARView *_arView;
    AMapSearchAPI *_search;
    CLLocation *_currentLocation;
    UIButton *_locationButton;
    
    UITableView *_tableView;
    NSArray *_pois;
    NSMutableArray *_annotations;
//    NSTimer *paintingTimer;
    
}
@property (nonatomic, strong) NSTimer *paintingTimer;
@property (nonatomic, strong) NSTimer *GeoTimer;
@end

@implementation ViewController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _pois.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"cellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
    }
    
    AMapPOI *poi = _pois[indexPath.row];
    
    cell.textLabel.text = poi.name;
    cell.detailTextLabel.text = poi.address;
    
    return cell;
}

#pragma mark - initialize

- (void)initAttributes
{
    _annotations = [NSMutableArray array];
    _pois = nil;
}

- (void)initTableView
{
//    NSLog(@"self.view: %@",self.view);
    CGFloat halfHeight = CGRectGetHeight(self.view.bounds) * 0.5;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, halfHeight, CGRectGetWidth(self.view.bounds), halfHeight) style:UITableViewStylePlain];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
//    [self.view addSubview:_tableView];
}

- (void)initControls
{
    _locationButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _locationButton.frame = CGRectMake(20, CGRectGetHeight(_mapView.bounds)-80, 40, 40);
    _locationButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    //    _locationButton.backgroundColor = [UIColor whiteColor];
    //set backgroundColor as transparent
    _locationButton.backgroundColor = nil;
    _locationButton.opaque = NO;
    _locationButton.layer.cornerRadius = 5;
    [_locationButton addTarget:self action:@selector(locateAction) forControlEvents:UIControlEventTouchUpInside];
    [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    [_mapView addSubview:_locationButton];
    
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    searchButton.frame = CGRectMake(80, CGRectGetHeight(_mapView.bounds) - 80, 40, 40);
    searchButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    searchButton.backgroundColor = nil;
    [searchButton setImage:[UIImage imageNamed:@"search"] forState:UIControlStateNormal];
    [searchButton addTarget:self action:@selector(searchAction) forControlEvents:UIControlEventTouchUpInside];
    [_mapView addSubview:searchButton];
    _mapView.showsUserLocation = YES;
}

- (void)initSearch
{
    _search = [[AMapSearchAPI alloc] initWithSearchKey:APIKey Delegate:self];
}

- (void)initMapView
{
    [MAMapServices sharedServices].apiKey = APIKey;
    _mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds))];
    _mapView.delegate = self;
    _mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 22);
    _mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, 22);
    
//    [self.view addSubview:_mapView];
//    NSLog(@"mapView: %@",_mapView);
}


#pragma mark - action


- (void)reGeoAction
{
    if (_currentLocation) {
        AMapReGeocodeSearchRequest *request = [[AMapReGeocodeSearchRequest alloc] init];
        
        request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
        
        [_search AMapReGoecodeSearch:request];
    }
}

- (void)locateAction
{
    if (_mapView.userTrackingMode != MAUserTrackingModeFollowWithHeading) {
        [_mapView setUserTrackingMode:MAUserTrackingModeFollowWithHeading animated:YES];
    }
}

- (void)searchAction
{
    if(_currentLocation == nil || _search == nil)
    {
        NSLog(@"search failed");
        return;
    }
    
    AMapPlaceSearchRequest *request = [[AMapPlaceSearchRequest alloc] init];
    request.searchType = AMapSearchType_PlaceAround;
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    
    request.keywords = @"餐饮";
    
    [_search AMapPlaceSearch:request];
}


#pragma mark - search delegate


- (void)searchRequest:(id)request didFailWithError:(NSError *)error
{
    NSLog(@"request :%@, error :%@", request, error);
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response
{
    NSLog(@"response :%@", response);
    
    NSString *title = response.regeocode.addressComponent.city;
    if (title.length == 0) {
        title = response.regeocode.addressComponent.province;
    }
    
    _mapView.userLocation.title = title;
    _mapView.userLocation.subtitle = response.regeocode.formattedAddress;
}

-(void)onPlaceSearchDone:(AMapPlaceSearchRequest *)request response:(AMapPlaceSearchResponse *)response
{
    NSLog(@"request: %@", request);
    NSLog(@"response: %@", response);
    ARView *arView = (ARView *)self.view;
    if (response.pois.count > 0) {
        
        _pois = response.pois;
        [_tableView reloadData];
        NSMutableArray *placesOfInterest = [NSMutableArray array];

        for (AMapPOI *poigd in _pois) {
            UILabel *label = [[UILabel alloc] init];
            label.adjustsFontSizeToFitWidth = NO;
            label.opaque = NO;
            label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
            label.center = CGPointMake(200.0f, 200.0f);
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            label.text = poigd.name;
//            CGSize size = [label.text sizeWithFont:label.font];
            CGSize size = [label.text sizeWithAttributes:@ {NSFontAttributeName: label.font}];
            label.bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
            
            PlaceOfInterest *poi = [PlaceOfInterest placeOfInterestWithView:label at:[[CLLocation alloc] initWithLatitude:poigd.location.latitude longitude:poigd.location.longitude]];
            [placesOfInterest addObject:poi];
        }
        [arView setPlacesOfInterest:placesOfInterest];
        
//        NSLog(@"_currentLocation: %@",_currentLocation);

        //清空标注
        [_mapView removeAnnotation:(id)_annotations];
        [_annotations removeAllObjects];
    }
}

#pragma mark - map delegate
- (void)mapView:(MAMapView *)mapView didChangeUserTrackingMode:(MAUserTrackingMode)mode animated:(BOOL)animated
{
    if (mode == MAUserTrackingModeNone) {
        [_locationButton setImage:[UIImage imageNamed:@"location_no"] forState:UIControlStateNormal];
    } else {
        [_locationButton setImage:[UIImage imageNamed:@"location_yes"] forState:UIControlStateNormal];
    }
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation
{
//    NSLog(@"userLocation: %@", userLocation.location);
    _currentLocation = [userLocation.location copy];
}

- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view
{
    if([view.annotation isKindOfClass:[MAUserLocation class]])
    {
        [self reGeoAction];
    }
}

#pragma mark - timer

// 开始定时器
- (void) startTimer{
    
    // 定义一个NSTimer
    self.paintingTimer = [NSTimer scheduledTimerWithTimeInterval:10.0
                                                          target:self
                                                        selector:@selector(searchAction)  userInfo:nil
                                                         repeats:YES];
    self.GeoTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
                                                          target:self
                                                        selector:@selector(reGeoAction)  userInfo:nil
                                                         repeats:YES];
}

// 停止定时器
- (void) stopTimer{
    if (self.paintingTimer != nil){
        // 定时器调用invalidate后，就会自动执行release方法。不需要在显示的调用release方法
        [self.paintingTimer invalidate];
    }
    if (self.GeoTimer != nil){
        // 定时器调用invalidate后，就会自动执行release方法。不需要在显示的调用release方法
        [self.GeoTimer invalidate];
    }
    
}


#pragma mark - life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self initMapView];
    [self initSearch];
    [self initControls];
    [self initTableView];
    [self initAttributes];
    
    [self reGeoAction];
    
    ARView *arView = (ARView *)self.view;
    
    // Create array of hard-coded places-of-interest, in this case some famous parks
    const char *poiNames[] = {"Jinan Railway Station JN",
        "QingDao Railway Station QD",
        "韩釜宫（济南店）",
        "Hyde Park UK",
        "Mont Royal QC",
        "Retiro Park ES"};
    
    CLLocationCoordinate2D poiCoords[] = {{36.6712, 116.99089000000004},
        {36.06547, 117.056056},
        {36.679906, 117.056056},
        {51.5068670, -0.1708030},
        {45.5126399, -73.6802448},
        {40.4152519, -3.6887466}};
    
    int numPois = sizeof(poiCoords) / sizeof(CLLocationCoordinate2D);
    
    NSMutableArray *placesOfInterest = [NSMutableArray arrayWithCapacity:numPois];
    for (int i = 0; i < numPois; i++) {
        UILabel *label = [[UILabel alloc] init];
        label.adjustsFontSizeToFitWidth = NO;
        label.opaque = NO;
        label.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.1f alpha:0.5f];
        label.center = CGPointMake(200.0f, 200.0f);
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor whiteColor];
        label.text = [NSString stringWithCString:poiNames[i] encoding:NSASCIIStringEncoding];
//        CGSize size = [label.text sizeWithFont:label.font];
        CGSize size = [label.text sizeWithAttributes:@ {NSFontAttributeName: label.font}];
        label.bounds = CGRectMake(0.0f, 0.0f, size.width, size.height);
        
        PlaceOfInterest *poi = [PlaceOfInterest placeOfInterestWithView:label at:[[CLLocation alloc] initWithLatitude:poiCoords[i].latitude longitude:poiCoords[i].longitude]];
        [placesOfInterest insertObject:poi atIndex:i];
    }
    [arView setPlacesOfInterest:placesOfInterest];
    
 //   NSLog(@"_currentLocation: %@",_currentLocation);

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    ARView *arView = (ARView *)self.view;
    [arView start];
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startTimer];// 开始定时器
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    ARView *arView = (ARView *)self.view;
    [arView stop];
    [self stopTimer];// 开始定时器
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end