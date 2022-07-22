//
//  PBSyncSocket.h
//  UdpEchoClient
//
//  Created by zFly on 2022/7/21.
//

#import <Foundation/Foundation.h>
#import "../PCH.h"
#import "PBSyncTlv.h"

NS_ASSUME_NONNULL_BEGIN

@interface PBSyncSocket : NSObject <GCDAsyncUdpSocketDelegate>

@property (nonatomic, strong)NSMutableArray * addresses;
@property (nonatomic, copy) void (^receivedBlock)(NSString *);

-(void)setUp;
-(void)sendData:(NSData *)data;
-(void)sendText:(NSString *)text;
@end

NS_ASSUME_NONNULL_END
