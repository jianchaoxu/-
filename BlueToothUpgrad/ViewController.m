//
//  ViewController.m
//  BlueToothUpgrad
//
//  Created by 易骏 on 17/4/17.
//  Copyright © 2017年 xjc. All rights reserved.
//

#import "ViewController.h"
#import "PerpheralVC.h"
#import <MPBluetoothKit.h>
#import <MBProgressHUD.h>
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic , strong) UITableView *discoverlist;

@property (nonatomic, strong) MPCentralManager *centralManager;

@end

@implementation ViewController

-(UITableView *)discoverlist
{
    if (!_discoverlist) {
        self.discoverlist = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStylePlain];
        self.discoverlist.delegate = self;
        self.discoverlist.dataSource = self;
    }
    return _discoverlist;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"😄";
    [self.view addSubview:self.discoverlist];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"扫描" style:UIBarButtonItemStylePlain target:self action:@selector(initcenterManager)];
    
}

-(void)initcenterManager
{
    __weak typeof(self) weakSelf = self;
    _centralManager = [[MPCentralManager alloc] initWithQueue:nil];
    [_centralManager setUpdateStateBlock:^(MPCentralManager *centralManager){
        if(centralManager.state == CBCentralManagerStatePoweredOn){
            [weakSelf scanPeripehrals];
        }
        else{
            [weakSelf.discoverlist reloadData];
        }
    }];
}

-(void)scanPeripehrals
{
    
    if(_centralManager.state == CBCentralManagerStatePoweredOn){
        [_centralManager scanForPeripheralsWithServices:nil options:nil withBlock:^(MPCentralManager *centralManager, MPPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
            if ([peripheral.name containsString:@"Baby"]) {
           
            id manufacturerData = [advertisementData objectForKey:@"kCBAdvDataManufacturerData"];
            const char *scanResult =[[manufacturerData description] cStringUsingEncoding:NSUTF8StringEncoding];
            NSString *macstr = [self prassingMacFromBluetoothWith:scanResult];
            NSLog(@"扫描到:%@___=%@",peripheral.name,macstr);
                 [self.discoverlist reloadData];
            }
        }];
    }
}



#pragma mark - UITableViewDelegate, UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_centralManager.discoveredPeripherals count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellID = @"peripheralCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
    }
    MPPeripheral *peripheral = [_centralManager.discoveredPeripherals objectAtIndex:indexPath.row];
    cell.textLabel.text = peripheral.name;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld",[peripheral.RSSI integerValue]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    MPPeripheral *peripheral = [_centralManager.discoveredPeripherals objectAtIndex:indexPath.row];
    [self connectPeripheral:peripheral];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}



- (void)connectPeripheral:(MPPeripheral *)peripheral
{
    [_centralManager connectPeripheral:peripheral options:nil withSuccessBlock:^(MPCentralManager *centralManager, MPPeripheral *peripheral) {
        PerpheralVC *controller = [[PerpheralVC alloc] init];
        controller.peripheral = peripheral;
        NSLog(@"sss连接到---%@",peripheral.name);
        [_centralManager stopScan];
        [self.navigationController pushViewController:controller animated:YES];
    } withDisConnectBlock:^(MPCentralManager *centralManager, MPPeripheral *peripheral, NSError *error) {
        NSLog(@"disconnectd %@",peripheral.name);
        [self bluetoothDisconnectWithTitle:[NSString stringWithFormat:@"Disconnected %@",peripheral.name]];
        [self scanPeripehrals];
    }];
}


-(void)bluetoothDisconnectWithTitle:(NSString *)title
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:title preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *act = [UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:act];
    [self presentViewController:alert animated:YES completion:nil];
}






-(NSString*)prassingMacFromBluetoothWith:(const char *)macstring;
{
    NSString *macAddress = [NSString stringWithFormat:@"%s", macstring];
    macAddress = [macAddress stringByReplacingOccurrencesOfString:@"<" withString:@""];
    macAddress = [macAddress stringByReplacingOccurrencesOfString:@">" withString:@""];
    macAddress = [macAddress stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString *header=[macAddress substringWithRange:NSMakeRange(0, 4)];
    NSLog(@"header=%@",header);
    if(macAddress.length>=12){
        macAddress = [macAddress substringWithRange:NSMakeRange(macAddress.length-12, 12)];
    }else{
        NSLog(@"mac地址有误");
        return nil;
    }
    NSString *uper_mac=[macAddress uppercaseString];//变为大写字母
    NSMutableString *c_macstr=[NSMutableString stringWithString:uper_mac];
    //mac:  F4:5E:AB:0C:2E:05
    for (int a=0; a<5; a++) {//插入@“:”
        [c_macstr insertString:@":" atIndex:(3*a+2)];
    }
    //  NSLog(@"c_macstr=%@",c_macstr);
    return c_macstr;
}

@end
