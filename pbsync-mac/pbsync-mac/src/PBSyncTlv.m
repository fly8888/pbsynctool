//
//  PBSyncTlv.m
//  pbsync-mac
//
//  Created by zFly on 2022/7/22.
//

#import "PBSyncTlv.h"

static NSData * decryptX(NSData * data)
{
    NSMutableData * newData = [NSMutableData data];
    for (int i=0; i<data.length; i++) {
        char byte ;
        [data getBytes:&byte range:NSMakeRange(i, 1)];
        byte = byte ^0x66;
        [newData appendBytes:&byte length:1];
    }
    return newData;
}

static NSData * encryptX(NSData * data)
{
    NSMutableData * newData = [NSMutableData data];
    for (int i=0; i<data.length; i++) {
        char byte ;
        [data getBytes:&byte range:NSMakeRange(i, 1)];
        byte = byte ^ 0x66;
        [newData appendBytes:&byte length:1];
    }
    return newData;
}

@implementation PBSyncTlv

-(NSData *)encode
{
    NSMutableData * data = [NSMutableData data];
    uint16_t tag = CFSwapInt16HostToBig(self.tag);
    [data appendBytes:&tag length:sizeof(uint16_t)];
    uint32_t len = CFSwapInt32HostToBig(self.len);
    [data appendBytes:&len length:sizeof(uint32_t)];
    if(self.len>0)
    {
        NSData * encryptData = encryptX(self.data);
        [data appendData:encryptData];
    }
    return data;
}

+(PBSyncTlv *)decode:(NSData *)data
{
    PBSyncTlv * tlv = [[PBSyncTlv alloc]init];
    uint16_t tag = 0;
    [data getBytes:&tag length:sizeof(tlv.tag)];
    tlv.tag = CFSwapInt16BigToHost(tag);
    uint32_t len = 0;
    [data getBytes:&len range:NSMakeRange(sizeof(tlv.tag), sizeof(tlv.len))];
    tlv.len = CFSwapInt32BigToHost(len);
    if(tlv.len>0)
    {
        NSData * encryptData = [data subdataWithRange:NSMakeRange(sizeof(tlv.tag)+sizeof(tlv.len), tlv.len)];
        tlv.data = decryptX(encryptData);
    }
    return tlv;
}

+(PBSyncTlv *)onlineTlv
{
    PBSyncTlv * tlv = [[PBSyncTlv alloc]init];
    tlv.tag= Tlv_online;
    tlv.len=0;
    return tlv;
}

+(PBSyncTlv *)replyOnlineTlv
{
    PBSyncTlv * tlv = [[PBSyncTlv alloc]init];
    tlv.tag=Tlv_online_reply;
    tlv.len=0;
    return tlv;
}



@end
