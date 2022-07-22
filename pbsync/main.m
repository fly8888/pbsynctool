#import "PCH.h"

int main(int argc, char *argv[], char *envp[]) {
	@autoreleasepool {
		
		UIPasteboard * pb = [UIPasteboard generalPasteboard];
        __block NSInteger changeCount = pb.changeCount;

		PBSyncSocket * socket = [[PBSyncSocket alloc] init];
		socket.receivedBlock = ^(NSString * str) {
            NSLog(@"收到消息:%@",str);
            changeCount = 0;
            if(str) [pb setString:str];
            changeCount = 0;
        };
		[socket setUp];

		[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
			if(changeCount == 0) changeCount = pb.changeCount;
            else if(changeCount != pb.changeCount)
			{
				changeCount = pb.changeCount;
				NSString * string = pb.string;
				if(string)[socket sendText:string];
			}
		}];

		[[NSRunLoop currentRunLoop] run];
		return 0;
	}
}
