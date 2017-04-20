//
//  PerpheralVC.m
//  BlueToothUpgrad
//
//  Created by 易骏 on 17/4/18.
//  Copyright © 2017年 xjc. All rights reserved.
//

#import "PerpheralVC.h"
#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD+NJ.h"

#define SERVICE_UUID           @"0000FEE7-0000-1000-8000-00805F9B34FB"
#define CHARACTERISTIC_UUID    @"0000FEC8-0000-1000-8000-00805F9B34FB"
#define WRITE_UUID            @"0000FEC7-0000-1000-8000-00805F9B34FB"

#define BLE_OAD_SERVICE              @"F000FFC0-0451-4000-B000-000000000000"
#define BLE_OAD_IMAGE_NOTIFY         @"F000FFC1-0451-4000-B000-000000000000"
#define BLE_OAD_IMAGE_BLOCK_REQUEST  @"F000FFC2-0451-4000-B000-000000000000"

#define WIDTH self.view.frame.size.width
#define HEIGHT self.view.frame.size.height
static NSInteger x = 0;

@interface PerpheralVC ()
{
    NSTimer *updateTimer,*updateBtimer;
    MPPeripheral *writeper;
    MPCharacteristic *characteristic_notify;
    MPCharacteristic *characteristic_request;
    MPPeripheral *writePeripheral;
    UIButton *but;
    UILabel *logLabel;

}
@property(nonatomic,strong) MPCharacteristic *characteristic;


@end

@implementation PerpheralVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self discoverService];
    
    but = [UIButton buttonWithType:UIButtonTypeCustom];
    but.frame = CGRectMake((WIDTH-200)/2, (HEIGHT-50)/2-100, 200, 50);
    [but setTitle:@"升级" forState:UIControlStateNormal];
    but.backgroundColor = [UIColor cyanColor];
    [but setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [but addTarget:self action:@selector(upgradblue) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:but];
    
    logLabel = [[UILabel alloc]initWithFrame:CGRectMake(10, CGRectGetMaxY(but.frame)+20, WIDTH-40, 50)];
    logLabel.textColor = [UIColor blackColor];
    logLabel.textAlignment = NSTextAlignmentCenter;
    logLabel.numberOfLines = 0;
    [self.view addSubview:logLabel];
}

-(void)discoverService
{
    __weak typeof(self) weakSelf = self;
    [_peripheral discoverServices:nil withBlock:^(MPPeripheral *peripheral, NSError *error) {
        for(MPService *service in peripheral.services){
            NSLog(@"发现服务了.....%@",service.UUID);
            //数据服务通道
            if ([service.UUID isEqual:[CBUUID UUIDWithString:@"FEE7"]]) {
                [weakSelf discoverCharacteristicForService:service];
            }
            //升级的服务 --- F000FFC0-0451-4000-B000-000000000000
            if ([service.UUID isEqual:[CBUUID UUIDWithString:BLE_OAD_SERVICE]]) {
                [weakSelf forBleUpdateCharacteristicWithService:service];
            };
        }
    }];
}

-(void)discoverCharacteristicForService:(MPService*)service
{
    [service discoverCharacteristics:nil withBlock:^(MPPeripheral *peripheral, MPService *service, NSError *error) {
        for (MPCharacteristic *c in service.characteristics) {
            if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FEC7"]]){//FEC7
                _characteristic = c;
                writePeripheral = peripheral;
            }
            
            
//            if ([c.UUID isEqual:[CBUUID UUIDWithString:CHARACTERISTIC_UUID]]) {//FEC8
//                [peripheral setNotifyValue:YES forCharacteristic:c withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
//                    if (error) {
//                        NSLog(@"has error__%@",error.localizedDescription);
//                    } else {
//                        Byte *resultByte = (Byte*)[characteristic.value bytes];
//                        if (resultByte>0) {
//                            float header = (resultByte[0]<<8 | (resultByte[1] & 0xff));
//                            if (header == 0X1E05) {
//                                //实时温湿度 ____7685
//                                float temp_x10 = ( resultByte[4]<<8 | (resultByte[3] & 0xff));
//                                float humi_x10 = ( resultByte[6]<<8 | (resultByte[5] & 0xff));
//                                int capacity = resultByte[7]; //尿布的使用程度
//                                //DetectionViewController...
//                                [[NSNotificationCenter defaultCenter]postNotificationName:@"Capacity" object:[NSString stringWithFormat:@"%d",capacity]];
//                                float temperature = temp_x10/10;  //温度
//                                float humdata = humi_x10/10;     //湿度
//                                float  hum = round(humdata*100)/100;
//                                float  tem = round(temperature*100)/100;
//                               // NSLog(@"peripheral = %@",peripheral.identifier.UUIDString);
//                                NSLog(@"humidity = %.1f  temperture = %.1f",hum,tem);
//                            } else if (header == 0x1E08) {
//                                //睡眠
//                            }
//                            else if (header == 0X1E09){
//                                //电池电量—————7689
//                                float battery = (resultByte[3]&0xff);
//                                NSString *bstring = [NSString stringWithFormat:@"%.f",battery];
//                                NSLog(@"电池电量 = %@",bstring);
//                                [[NSUserDefaults standardUserDefaults] setObject:bstring forKey:@"batteryValue"];
//                            } else if (header == 0x1E10) {
//                                NSLog(@"result byte  = %s",resultByte);
//                                
//                            } else if (header == 0X1E0A) {
//                                //离线事件——————7690
//                                int even = (resultByte[3] & 0xff);
//                                if (even>0) {
//                                    float e_humi = (resultByte[5]<<8 | (resultByte[4] & 0xff));
//                                    float e_hum = ((e_humi/10)*100)/100;
//                                    NSInteger e_year = (resultByte[12]<<8 | (resultByte[11] & 0xff));
//                                    NSInteger e_second = (resultByte[6] & 0xff);
//                                    NSInteger e_minute = (resultByte[7] & 0xff);
//                                    NSInteger e_hours = (resultByte[8] & 0xff);
//                                    NSInteger e_daye = (resultByte[9] & 0xff) +1;
//                                    NSInteger e_month = (resultByte[10] & 0xff) +1;
//                                    NSString *uotline_time = [NSString stringWithFormat:@"%ld-%02ld-%02ld %02ld:%02ld:%02ld",(long)e_year,(long)e_month,(long)e_daye,(long)e_hours,(long)e_minute,(long)e_second];
//                                    NSLog(@"离线事件 时间 = %@ even = %d humidity = %.f",uotline_time,even,e_hum);
//                                }
//                            }
//                            else if (header == 0X1E0B) {
//                                int even = (resultByte[3] & 0xff);
//                                float e_humi = (resultByte[5]<<8 | (resultByte[4] & 0xff));
//                                float e_hum = ((e_humi/10)*100)/100;
//                                NSInteger e_year = (resultByte[12]<<8 | (resultByte[11] & 0xff));
//                                NSInteger e_mom = (resultByte[10] & 0xff) + 1;
//                                NSInteger e_day = (resultByte[9] & 0xff) + 1;
//                                NSInteger e_hour = (resultByte[8] & 0xff);
//                                NSInteger e_min = (resultByte[7] & 0xff);
//                                NSInteger e_sec = (resultByte[6] & 0xff);
//                                NSString *gettime = [NSString stringWithFormat:@"%ld-%02ld-%02ld %02ld:%02ld:%02ld",(long)e_year,(long)e_mom,(long)e_day,(long)e_hour,(long)e_min,(long)e_sec];
//                                NSString  *estring = [NSString stringWithFormat:@"%d/%.f/%@",even,e_hum,gettime];
//                                NSLog(@"estring = %@",estring);
//                                if (even == 11) {
//                                    [self showHUDWithText:@"宝宝尿尿了"];
//                                }
//                                if (even == 13) {
//                                    [self showHUDWithText:@"尿布更换了"];
//                                }
//                                
//                            }
//                            else if (header == 0x1E0C) {
//                                // 移动
//                                //  int sleep_even = resultByte[3];
//                                //  NSLog(@"0x1e0c_sleep_even = %d",sleep_even);
//                                //  NSString *sleep_state = [NSString stringWithFormat:@"%d",sleep_even];
//                                //  [[NSNotificationCenter defaultCenter] postNotificationName:@"BabySleepState" object:sleep_state];
//                            }
//                            else if (header == 0x1E0E) {
//                                //睡眠温度
//                                //                               float before_temp = (resultByte[4]<<8 | (resultByte[3] & 0xff));
//                                //                               float after_temp = (resultByte[6]<<8 | (resultByte[5] & 0xff));
//                                //                               NSString *temp_change = [NSString stringWithFormat:NSLocalizedString(@"TempChange" , nil),before_temp/10,after_temp/10];
//                                //                               NSLog(@"temp_change = %@",temp_change);
//                                //                               [[NSNotificationCenter defaultCenter]postNotificationName:@"TEMPERATURECHANGE" object:temp_change];
//                            } else if (header == 0x1E0F) {
//                                //睡眠开关状态
//                                //                               int sleepState = resultByte[4];
//                                //                               NSLog(@"sleepState = %d",sleepState);
//                                //                               [[NSNotificationCenter defaultCenter] postNotificationName:@"getstate" object:[NSString stringWithFormat:@"%d",sleepState]];
//                            }
//                        }
//                    }
//                }];
//                
//            }
        }
    }];
}


-(void)showHUDWithText:(NSString *)str
{
    [MBProgressHUD showSuccess:str];
}


//升级通道。
- (void) forBleUpdateCharacteristicWithService:(MPService*)ser
{
    [ser discoverCharacteristics:nil withBlock:^(MPPeripheral *peripheral, MPService *service, NSError *error) {
        for (MPCharacteristic *c in ser.characteristics) {
            if ([c.UUID isEqual:[CBUUID UUIDWithString:BLE_OAD_IMAGE_NOTIFY]]) {
                characteristic_notify = c;
                [peripheral setNotifyValue:YES forCharacteristic:c withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
                }];
            }
            if ([c.UUID isEqual:[CBUUID UUIDWithString:BLE_OAD_IMAGE_BLOCK_REQUEST]]) {
                characteristic_request = c;
                [peripheral setNotifyValue:YES forCharacteristic:c withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
                }];
            }
        }
    }];
}



-(void)upgradblue
{

    if (writePeripheral == nil || characteristic_notify == nil || characteristic_request == nil) {
        return;
    }
    [but setTitle:@"升级中请稍候..." forState:UIControlStateNormal];
    [but setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    but.enabled = NO;
    NSLog(@"characteristic_notify = %@",characteristic_notify);
    [writePeripheral writeValue:[self getCoustomVersion] forCharacteristic:characteristic_notify type:CBCharacteristicWriteWithResponse withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
        if (!error) {
            Byte *resultByte = (Byte*)[characteristic.value bytes];
            NSInteger version = ((resultByte[0] & 0xff) | (resultByte[1] & 0xff)<<8)>>1;  //当前蓝牙的版本号
            int kind = version >>12 & 0x01;
            NSString *pf = [NSString stringWithFormat:@"%d",kind];
            int file_kind = resultByte[0] & 0x01; //当前的版本文件是A or B ?
            NSLog(@"返回的版本号:%d version:%ld,,kind = %@",file_kind,(long)version,pf);  //文件返回的类型  0/1（A/B）
            [self showSheetViewWithKind:file_kind];
        } else {
            NSLog(@"1111111---failure");
        }
    }];
}

-(void)showSheetViewWithKind:(int)k
{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请选择升级文件" message:(k==0)? @"当前文件为A，请升级B" : @"当前文件为B，请升级A" preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *imagea = [UIAlertAction actionWithTitle:@"ImageA" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self upgradPratmerWithKind:0];

    }];
    UIAlertAction *imageb = [UIAlertAction actionWithTitle:@"ImageB" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self upgradPratmerWithKind:1];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        but.enabled = YES;
        [but setTitle:@"升级" forState:UIControlStateNormal];
        [but setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    }];
    [alert addAction:imagea];
    [alert addAction:imageb];
    [alert addAction:cancel];
    [self presentViewController:alert animated:YES completion:nil];
}





-(void)upgradPratmerWithKind:(int)kind
{
    if (writePeripheral==nil || _characteristic ==nil) {
        return;
    }
    [writePeripheral writeValue:[self UpdateParameter] forCharacteristic:_characteristic type:CBCharacteristicWriteWithResponse withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
        if (!error) {
            NSLog(@"发送升级时的连接参数成功");
        } else {
            NSLog(@"发送升级时的连接参数失败");
        }
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0* NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendFileHeaderwithKind:kind];
    });
}

-(void)sendFileHeaderwithKind:(int)kind
{
    [writePeripheral writeValue:[self imageBin_notifityHeaderWithKind:kind] forCharacteristic:characteristic_notify type:CBCharacteristicWriteWithResponse withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
        if (!error) {
            NSLog (@"发送文件头success");
            //4.发送文件
            if (kind == 0)
                    [self performSelector:@selector(sendImageA_BinFile) withObject:nil afterDelay:3.0];
                else
                    [self performSelector:@selector(sendImageb_BinFile) withObject:nil afterDelay:3.0];
            
        } else {
            NSLog (@"发送文件头failure");
        }
    }];
}

-(void)sendImageA_BinFile
{
    NSLog(@"升级A");
    updateTimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(sengdate) userInfo:nil repeats:YES];
}

-(void)sendImageb_BinFile
{
    NSLog(@"升级B");
    updateBtimer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(sengBBdate) userInfo:nil repeats:YES];
}

- (void) sengdate
{
    //MARK: ---  withResponse or withoutResponse
    [writePeripheral writeValue:[self sendingImageBinFile] forCharacteristic:characteristic_request type:CBCharacteristicWriteWithoutResponse withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
       
    }];
}

-(void)sengBBdate
{
    [writePeripheral writeValue:[self sendingImage_b_BinFile] forCharacteristic:characteristic_request type:CBCharacteristicWriteWithoutResponse withBlock:^(MPPeripheral *peripheral, MPCharacteristic *characteristic, NSError *error) {
       
    }];
}

-(NSData *) sendingImageBinFile
{
    NSString *imageBin_path = [[NSBundle mainBundle] pathForResource: @"ImageA" ofType:@"bin"];
    NSData *oad_data = [NSData dataWithContentsOfFile:imageBin_path];
    Byte *Dvalue = (Byte *)[oad_data bytes];
    Byte byte[18];
    for (int i = 0; i < 18; i++) {
        if (i <= 1 ) {
            byte[0] = x%256;
            byte[1] = x/256;
        } else {
            if (i - 2 + x*16 < oad_data.length) {
                byte[i] = Dvalue[i - 2 + x*16];
            } else {
                byte[i] = 0xFF;
            }
        }
    }
    x++;
    NSData *sendData = [NSData dataWithBytes:byte length:sizeof(byte)];
    NSLog(@"x =%ld------senddata = %@",(long)x,sendData);
    logLabel.text = [NSString stringWithFormat:@"x =%ld------senddata = %@",(long)x,sendData];
    if (x*16 >= oad_data.length)
    {
        NSLog(@"升级完毕--------");
        x = 0;
        [updateTimer invalidate];
        updateTimer = nil;
        [self finishUpgrad];
    }
    return sendData;
}


-(NSData*)sendingImage_b_BinFile
{
    
    NSString *imageBin_path = [[NSBundle mainBundle] pathForResource: @"ImageB" ofType:@"bin"];
    NSData *oad_data = [NSData dataWithContentsOfFile:imageBin_path];
    Byte *Dvalue = (Byte *)[oad_data bytes];
    Byte byte[18];
    for (int i = 0; i < 18; i++) {
        if (i <= 1 ) {
            byte[0] = x%256;
            byte[1] = x/256;
        } else {
            if (i - 2 + x*16 < oad_data.length) {
                byte[i] = Dvalue[i - 2 + x*16];
            } else {
                byte[i] = 0xFF;
            }
        }
    }
    x++;
    NSData *sendData = [NSData dataWithBytes:byte length:sizeof(byte)];
    NSLog(@"x =%ld------senddata = %@",(long)x,sendData);
    logLabel.text = [NSString stringWithFormat:@"x =%ld------senddata = %@",(long)x,sendData];
    if (x*16 >= oad_data.length)
    {
        NSLog(@"升级完毕--------");
        x = 0;
        [updateBtimer invalidate];
        updateBtimer = nil;
        [self finishUpgrad];
    }
    return sendData;
}

-(void)finishUpgrad
{
    but.enabled = YES;
    [but setTitle:@"升级" forState:UIControlStateNormal];
    [but setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [MBProgressHUD showSuccess:@"升级成功"];
//    UIAlertController *ale = [UIAlertController alertControllerWithTitle:@"提示" message:@"升级成功" preferredStyle:UIAlertControllerStyleAlert];
//    UIAlertAction *act = [UIAlertAction actionWithTitle:@"好的" style:UIAlertActionStyleCancel handler:nil];
//    [ale addAction:act];
//    [self presentViewController:ale animated:YES completion:nil];
}

- (NSData *) getCoustomVersion //获取当前固件版本号
{
    Byte b[] = {0X00,0X00,0X7C,0X7C,0X00,0X00,0X00,0X00};
    NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
    return data;
}


- (NSData *) UpdateParameter //升级连接参数
{
    Byte b[] = {0XFE,0X08,0X01,0X03};
    NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
    return data;
}

- (NSInteger) pathOfImageBin_kindsWitkind
{
    NSString *imageBin_path = [[NSBundle mainBundle] pathForResource: @"ImageA" ofType:@"bin"];
    NSData *source_data = [NSData dataWithContentsOfFile:imageBin_path];
    Byte *sourceBytes = (Byte*)[source_data bytes];
    int fileVersion = ((sourceBytes[4] & 0xff) | (sourceBytes[5] & 0xff)<<8)>>1;
    NSLog(@"文件的版本号fileVersion = %d",fileVersion);
    return (sourceBytes[4] & 0x01);
}

- (NSData *) imageBin_notifityHeaderWithKind:(int)kind; //bendi文件头
{
    NSLog(@"bendi文件头 kind = %d",kind);
    NSString *filePathB = [[NSBundle mainBundle] pathForResource: (kind == 0) ? @"ImageA" : @"ImageB" ofType:@"bin"];
    NSData *oad_data = [NSData dataWithContentsOfFile:filePathB];
    Byte *bytes = (Byte*)[oad_data bytes];
    Byte b[] = {bytes[4],bytes[5],bytes[6],bytes[7],bytes[8],bytes[9],bytes[10],bytes[11]};
    NSData *data = [NSData dataWithBytes:&b length:sizeof(b)];
    NSLog(@"data = %@",data);
    return data;
}
@end
