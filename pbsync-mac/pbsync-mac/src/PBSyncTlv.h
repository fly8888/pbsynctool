//
//  PBSyncTlv.h
//  pbsync-mac
//
//  Created by zFly on 2022/7/22.
//

#import <Foundation/Foundation.h>

typedef enum Tlv_Tag {
    Tlv_online  = 9,
    Tlv_online_reply,
    Tlv_send_text
} Tlv_tag;

NS_ASSUME_NONNULL_BEGIN

@interface PBSyncTlv : NSObject
@property (nonatomic, assign)uint16_t tag;
@property (nonatomic, assign)uint32_t len;
@property (nonatomic, copy)NSData * data;

+(PBSyncTlv *)decode:(NSData *)data;
-(NSData *)encode;
+(PBSyncTlv *)onlineTlv;
+(PBSyncTlv *)replyOnlineTlv;

@end

NS_ASSUME_NONNULL_END
