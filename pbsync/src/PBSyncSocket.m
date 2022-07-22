//
//  PBSyncSocket.m
//  UdpEchoClient
//
//  Created by zFly on 2022/7/21.
//

#import "PBSyncSocket.h"
#define PORT  65534
#define BROADCAST_IP  @"255.255.255.255"
#define socket_queue (dispatch_get_main_queue())

#define DD_DEBUG YES
#define NSLogDebug(frmt, ...) if(DD_DEBUG)NSLog((frmt), ##__VA_ARGS__);
#define DDLogCError(frmt, ...) NSLog((frmt), ##__VA_ARGS__);

@implementation PBSyncSocket
{
    GCDAsyncUdpSocket * _udpSocket;
    NSString * _myIp;
    NSMutableArray * _addressArray;
}

-(void)setUp
{
    _myIp = [self deviceIPAdress];
    if(!_myIp)
    {
        DDLogCError(@"-error--_myIp:%@",_myIp);
        return;
    }
   
    _addressArray = [[NSMutableArray alloc] init];

    NSString * ip = _myIp;
    __weak PBSyncSocket * weakSelf = self;
    _udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:weakSelf delegateQueue:socket_queue];
    
    [_udpSocket setIPv4Enabled:YES];
    [_udpSocket setIPv6Enabled:NO];

    [_udpSocket setSendFilter:^BOOL(NSData *data, NSData *address, long tag){
        NSString * toHost = [GCDAsyncUdpSocket hostFromAddress:address];
//        NSLogDebug(@"发送过滤-toHost:%@ ip: %@",toHost,ip);
        if([toHost isEqualToString:ip]) return NO;
        return YES;
    } withQueue:socket_queue];

    [_udpSocket setReceiveFilter:^BOOL(NSData *data, NSData *address, id * context){
        NSString * fromHost = [GCDAsyncUdpSocket hostFromAddress:address];
//        NSLogDebug(@"接收过滤-fromHost:%@ ip: %@",fromHost,ip);
        if([fromHost isEqualToString:ip]) return NO;
        return YES;
    } withQueue:socket_queue];

    

    NSError *error = nil;
    if(![_udpSocket enableBroadcast:YES error:&error])
    {
        DDLogCError(@"Error broadcast: %@",error);
        return;
    }

    if (![_udpSocket bindToPort:PORT error:&error])
    {
        DDLogCError(@"Error binding: %@",error);
        return;
    }

    if (![_udpSocket beginReceiving:&error])
    {
        DDLogCError(@"Error binding: %@",error);
        return;
    }
    
    [self sendOnLineTlv];
}

//上线打招呼
-(void)sendOnLineTlv
{
    NSLogDebug(@"发起广播:我上线了");
    PBSyncTlv * tlv = [PBSyncTlv onlineTlv];
    [self sendTlv:tlv  toHost:BROADCAST_IP];
}

//在线回招呼
-(void)replyOnLineTlvToHost:(NSString *)host
{
    NSLogDebug(@"回复广播:%@", host);
    PBSyncTlv * tlv = [PBSyncTlv replyOnlineTlv];
    [self sendTlv:tlv  toHost:host];
}

-(void)sendText:(NSString *)text
{
    NSData * data = [text dataUsingEncoding:4];
    [self sendData:data];
}

-(void)sendData:(NSData *)data
{
    PBSyncTlv * tlv = [[PBSyncTlv alloc]init];
    tlv.tag=Tlv_send_text;
    tlv.len= (uint32_t)data.length;
    tlv.data = data;
    for(NSString * IP in _addressArray)
    {
        [self sendTlv:tlv toHost:IP ];
    }
}

-(void)sendTlv:(PBSyncTlv *)tlv toHost:(NSString *)host
{
    NSData * data = [tlv encode] ;
//    NSLogDebug(@"sendData:%@",data);
    [_udpSocket sendData:data.mutableCopy toHost:host port:PORT withTimeout:2 tag:0];
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    // You could add checks here
    // NSLogDebug(@"udpSocket didSendDataWithTag: %ld",tag);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    // You could add checks here
    DDLogCError(@"udpSocket didNotSendDataWithTag: %ld  dueToError:%@",tag,error);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSString * fromHost = [GCDAsyncUdpSocket hostFromAddress:address];
    NSLogDebug(@"fromHost:%@ ",fromHost);
   
    if(data)
    {
        PBSyncTlv * tlv = [PBSyncTlv decode:data];
        if(tlv && fromHost)
        {
            [self addAddress:fromHost];
        }
        
        if(tlv.tag==Tlv_online)
        {
            NSLogDebug(@"收到上线广播:%@ ",fromHost);
            [self replyOnLineTlvToHost:fromHost];
            
        }else if(tlv.tag==Tlv_online_reply)
        {
            NSLogDebug(@"收到广播回复:%@ ",fromHost);
        }else if(tlv.tag==Tlv_send_text && tlv.len>0)
        {
            NSString * string = [[NSString alloc]initWithData:tlv.data encoding:4];
//            NSLogDebug(@"客户端消息:%@ ,%@",string,fromHost);
            if(self.receivedBlock)self.receivedBlock(string);
        }
    }
    else
    {
        NSString *host = nil;
        uint16_t port = 0;
        [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
        DDLogCError(@"RECV: Unknown message from: %@:%hu", host, port);
    }
}

-(void)addAddress:(NSString *)fromHost
{
    if(![_addressArray containsObject:fromHost])
    {
        [_addressArray addObject:fromHost];
    }
}

-(NSString *)deviceIPAdress
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET)
            {
                
#if TARGET_OS_OSX
//                NSLog(@"TARGET_OS_OSX");
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en1"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
#elif TARGET_OS_IOS
//                NSLog(@"TARGET_OS_IOS");
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
#endif
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    freeifaddrs(interfaces);
    return address;
}
@end



