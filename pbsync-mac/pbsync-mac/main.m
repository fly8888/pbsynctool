//
//  main.m
//  pbsync-mac
//
//  Created by zFly on 2022/7/21.
//

#import "PCH.h"


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        
        NSPasteboard * pb = [NSPasteboard generalPasteboard];
        __block NSInteger changeCount = pb.changeCount;
        
        PBSyncSocket * socket = [[PBSyncSocket alloc] init];
        socket.receivedBlock = ^(NSString * str) {
            NSLog(@"收到消息:%@",str);
            if(str)
            {
                changeCount = 0;
                [pb clearContents];
                [pb setString:str forType:NSPasteboardTypeString];
                changeCount = 0;
            }
        };
            
        [socket setUp];

        [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
            if(changeCount == 0) changeCount = pb.changeCount;
            else if(changeCount != pb.changeCount)
            {
                changeCount = pb.changeCount;
                NSString * string = [pb stringForType:NSPasteboardTypeString];
                NSLog(@"string:%@",string);
                if(string && string.length<1024)[socket sendText:string];
            }
        }];
        
        [[NSRunLoop currentRunLoop] run];
    }
    return 0;
}


