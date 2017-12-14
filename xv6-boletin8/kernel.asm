
kernel:     formato del fichero elf32-i386


Desensamblado de la sección .text:

80100000 <multiboot_header>:
80100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
80100006:	00 00                	add    %al,(%eax)
80100008:	fe 4f 52             	decb   0x52(%edi)
8010000b:	e4                   	.byte 0xe4

8010000c <entry>:

# Entering xv6 on boot processor, with paging off.
.globl entry
entry:
  # Turn on page size extension for 4Mbyte pages
  movl    %cr4, %eax
8010000c:	0f 20 e0             	mov    %cr4,%eax
  orl     $(CR4_PSE), %eax
8010000f:	83 c8 10             	or     $0x10,%eax
  movl    %eax, %cr4
80100012:	0f 22 e0             	mov    %eax,%cr4
  # Set page directory
  movl    $(V2P_WO(entrypgdir)), %eax
80100015:	b8 00 a0 10 00       	mov    $0x10a000,%eax
  movl    %eax, %cr3
8010001a:	0f 22 d8             	mov    %eax,%cr3
  # Turn on paging.
  movl    %cr0, %eax
8010001d:	0f 20 c0             	mov    %cr0,%eax
  orl     $(CR0_PG|CR0_WP), %eax
80100020:	0d 00 00 01 80       	or     $0x80010000,%eax
  movl    %eax, %cr0
80100025:	0f 22 c0             	mov    %eax,%cr0

  # Set up the stack pointer.
  movl $(stack + KSTACKSIZE), %esp
80100028:	bc 30 c6 10 80       	mov    $0x8010c630,%esp

  # Jump to main(), and switch to executing at
  # high addresses. The indirect call is needed because
  # the assembler produces a PC-relative instruction
  # for a direct jump.
  mov $main, %eax
8010002d:	b8 5d 38 10 80       	mov    $0x8010385d,%eax
  jmp *%eax
80100032:	ff e0                	jmp    *%eax

80100034 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
80100034:	55                   	push   %ebp
80100035:	89 e5                	mov    %esp,%ebp
80100037:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  initlock(&bcache.lock, "bcache");
8010003a:	83 ec 08             	sub    $0x8,%esp
8010003d:	68 84 84 10 80       	push   $0x80108484
80100042:	68 40 c6 10 80       	push   $0x8010c640
80100047:	e8 e8 4e 00 00       	call   80104f34 <initlock>
8010004c:	83 c4 10             	add    $0x10,%esp

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
8010004f:	c7 05 8c 0d 11 80 3c 	movl   $0x80110d3c,0x80110d8c
80100056:	0d 11 80 
  bcache.head.next = &bcache.head;
80100059:	c7 05 90 0d 11 80 3c 	movl   $0x80110d3c,0x80110d90
80100060:	0d 11 80 
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
80100063:	c7 45 f4 74 c6 10 80 	movl   $0x8010c674,-0xc(%ebp)
8010006a:	eb 47                	jmp    801000b3 <binit+0x7f>
    b->next = bcache.head.next;
8010006c:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
80100072:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100075:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
80100078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010007b:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    initsleeplock(&b->lock, "buffer");
80100082:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100085:	83 c0 0c             	add    $0xc,%eax
80100088:	83 ec 08             	sub    $0x8,%esp
8010008b:	68 8b 84 10 80       	push   $0x8010848b
80100090:	50                   	push   %eax
80100091:	e8 41 4d 00 00       	call   80104dd7 <initsleeplock>
80100096:	83 c4 10             	add    $0x10,%esp
    bcache.head.next->prev = b;
80100099:	a1 90 0d 11 80       	mov    0x80110d90,%eax
8010009e:	8b 55 f4             	mov    -0xc(%ebp),%edx
801000a1:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801000a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000a7:	a3 90 0d 11 80       	mov    %eax,0x80110d90

//PAGEBREAK!
  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
  bcache.head.next = &bcache.head;
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
801000ac:	81 45 f4 5c 02 00 00 	addl   $0x25c,-0xc(%ebp)
801000b3:	b8 3c 0d 11 80       	mov    $0x80110d3c,%eax
801000b8:	39 45 f4             	cmp    %eax,-0xc(%ebp)
801000bb:	72 af                	jb     8010006c <binit+0x38>
    b->prev = &bcache.head;
    initsleeplock(&b->lock, "buffer");
    bcache.head.next->prev = b;
    bcache.head.next = b;
  }
}
801000bd:	90                   	nop
801000be:	c9                   	leave  
801000bf:	c3                   	ret    

801000c0 <bget>:
// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
801000c0:	55                   	push   %ebp
801000c1:	89 e5                	mov    %esp,%ebp
801000c3:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  acquire(&bcache.lock);
801000c6:	83 ec 0c             	sub    $0xc,%esp
801000c9:	68 40 c6 10 80       	push   $0x8010c640
801000ce:	e8 83 4e 00 00       	call   80104f56 <acquire>
801000d3:	83 c4 10             	add    $0x10,%esp

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
801000d6:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801000db:	89 45 f4             	mov    %eax,-0xc(%ebp)
801000de:	eb 58                	jmp    80100138 <bget+0x78>
    if(b->dev == dev && b->blockno == blockno){
801000e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000e3:	8b 40 04             	mov    0x4(%eax),%eax
801000e6:	3b 45 08             	cmp    0x8(%ebp),%eax
801000e9:	75 44                	jne    8010012f <bget+0x6f>
801000eb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000ee:	8b 40 08             	mov    0x8(%eax),%eax
801000f1:	3b 45 0c             	cmp    0xc(%ebp),%eax
801000f4:	75 39                	jne    8010012f <bget+0x6f>
      b->refcnt++;
801000f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801000f9:	8b 40 4c             	mov    0x4c(%eax),%eax
801000fc:	8d 50 01             	lea    0x1(%eax),%edx
801000ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100102:	89 50 4c             	mov    %edx,0x4c(%eax)
      release(&bcache.lock);
80100105:	83 ec 0c             	sub    $0xc,%esp
80100108:	68 40 c6 10 80       	push   $0x8010c640
8010010d:	e8 b2 4e 00 00       	call   80104fc4 <release>
80100112:	83 c4 10             	add    $0x10,%esp
      acquiresleep(&b->lock);
80100115:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100118:	83 c0 0c             	add    $0xc,%eax
8010011b:	83 ec 0c             	sub    $0xc,%esp
8010011e:	50                   	push   %eax
8010011f:	e8 ef 4c 00 00       	call   80104e13 <acquiresleep>
80100124:	83 c4 10             	add    $0x10,%esp
      return b;
80100127:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010012a:	e9 9d 00 00 00       	jmp    801001cc <bget+0x10c>
  struct buf *b;

  acquire(&bcache.lock);

  // Is the block already cached?
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
8010012f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100132:	8b 40 54             	mov    0x54(%eax),%eax
80100135:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100138:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
8010013f:	75 9f                	jne    801000e0 <bget+0x20>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
80100141:	a1 8c 0d 11 80       	mov    0x80110d8c,%eax
80100146:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100149:	eb 6b                	jmp    801001b6 <bget+0xf6>
    if(b->refcnt == 0 && (b->flags & B_DIRTY) == 0) {
8010014b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010014e:	8b 40 4c             	mov    0x4c(%eax),%eax
80100151:	85 c0                	test   %eax,%eax
80100153:	75 58                	jne    801001ad <bget+0xed>
80100155:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100158:	8b 00                	mov    (%eax),%eax
8010015a:	83 e0 04             	and    $0x4,%eax
8010015d:	85 c0                	test   %eax,%eax
8010015f:	75 4c                	jne    801001ad <bget+0xed>
      b->dev = dev;
80100161:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100164:	8b 55 08             	mov    0x8(%ebp),%edx
80100167:	89 50 04             	mov    %edx,0x4(%eax)
      b->blockno = blockno;
8010016a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010016d:	8b 55 0c             	mov    0xc(%ebp),%edx
80100170:	89 50 08             	mov    %edx,0x8(%eax)
      b->flags = 0;
80100173:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100176:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
      b->refcnt = 1;
8010017c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010017f:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
      release(&bcache.lock);
80100186:	83 ec 0c             	sub    $0xc,%esp
80100189:	68 40 c6 10 80       	push   $0x8010c640
8010018e:	e8 31 4e 00 00       	call   80104fc4 <release>
80100193:	83 c4 10             	add    $0x10,%esp
      acquiresleep(&b->lock);
80100196:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100199:	83 c0 0c             	add    $0xc,%eax
8010019c:	83 ec 0c             	sub    $0xc,%esp
8010019f:	50                   	push   %eax
801001a0:	e8 6e 4c 00 00       	call   80104e13 <acquiresleep>
801001a5:	83 c4 10             	add    $0x10,%esp
      return b;
801001a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001ab:	eb 1f                	jmp    801001cc <bget+0x10c>
  }

  // Not cached; recycle an unused buffer.
  // Even if refcnt==0, B_DIRTY indicates a buffer is in use
  // because log.c has modified it but not yet committed it.
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
801001ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001b0:	8b 40 50             	mov    0x50(%eax),%eax
801001b3:	89 45 f4             	mov    %eax,-0xc(%ebp)
801001b6:	81 7d f4 3c 0d 11 80 	cmpl   $0x80110d3c,-0xc(%ebp)
801001bd:	75 8c                	jne    8010014b <bget+0x8b>
      release(&bcache.lock);
      acquiresleep(&b->lock);
      return b;
    }
  }
  panic("bget: no buffers");
801001bf:	83 ec 0c             	sub    $0xc,%esp
801001c2:	68 92 84 10 80       	push   $0x80108492
801001c7:	e8 d4 03 00 00       	call   801005a0 <panic>
}
801001cc:	c9                   	leave  
801001cd:	c3                   	ret    

801001ce <bread>:

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
801001ce:	55                   	push   %ebp
801001cf:	89 e5                	mov    %esp,%ebp
801001d1:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  b = bget(dev, blockno);
801001d4:	83 ec 08             	sub    $0x8,%esp
801001d7:	ff 75 0c             	pushl  0xc(%ebp)
801001da:	ff 75 08             	pushl  0x8(%ebp)
801001dd:	e8 de fe ff ff       	call   801000c0 <bget>
801001e2:	83 c4 10             	add    $0x10,%esp
801001e5:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((b->flags & B_VALID) == 0) {
801001e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801001eb:	8b 00                	mov    (%eax),%eax
801001ed:	83 e0 02             	and    $0x2,%eax
801001f0:	85 c0                	test   %eax,%eax
801001f2:	75 0e                	jne    80100202 <bread+0x34>
    iderw(b);
801001f4:	83 ec 0c             	sub    $0xc,%esp
801001f7:	ff 75 f4             	pushl  -0xc(%ebp)
801001fa:	e8 5d 27 00 00       	call   8010295c <iderw>
801001ff:	83 c4 10             	add    $0x10,%esp
  }
  return b;
80100202:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80100205:	c9                   	leave  
80100206:	c3                   	ret    

80100207 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
80100207:	55                   	push   %ebp
80100208:	89 e5                	mov    %esp,%ebp
8010020a:	83 ec 08             	sub    $0x8,%esp
  if(!holdingsleep(&b->lock))
8010020d:	8b 45 08             	mov    0x8(%ebp),%eax
80100210:	83 c0 0c             	add    $0xc,%eax
80100213:	83 ec 0c             	sub    $0xc,%esp
80100216:	50                   	push   %eax
80100217:	e8 a9 4c 00 00       	call   80104ec5 <holdingsleep>
8010021c:	83 c4 10             	add    $0x10,%esp
8010021f:	85 c0                	test   %eax,%eax
80100221:	75 0d                	jne    80100230 <bwrite+0x29>
    panic("bwrite");
80100223:	83 ec 0c             	sub    $0xc,%esp
80100226:	68 a3 84 10 80       	push   $0x801084a3
8010022b:	e8 70 03 00 00       	call   801005a0 <panic>
  b->flags |= B_DIRTY;
80100230:	8b 45 08             	mov    0x8(%ebp),%eax
80100233:	8b 00                	mov    (%eax),%eax
80100235:	83 c8 04             	or     $0x4,%eax
80100238:	89 c2                	mov    %eax,%edx
8010023a:	8b 45 08             	mov    0x8(%ebp),%eax
8010023d:	89 10                	mov    %edx,(%eax)
  iderw(b);
8010023f:	83 ec 0c             	sub    $0xc,%esp
80100242:	ff 75 08             	pushl  0x8(%ebp)
80100245:	e8 12 27 00 00       	call   8010295c <iderw>
8010024a:	83 c4 10             	add    $0x10,%esp
}
8010024d:	90                   	nop
8010024e:	c9                   	leave  
8010024f:	c3                   	ret    

80100250 <brelse>:

// Release a locked buffer.
// Move to the head of the MRU list.
void
brelse(struct buf *b)
{
80100250:	55                   	push   %ebp
80100251:	89 e5                	mov    %esp,%ebp
80100253:	83 ec 08             	sub    $0x8,%esp
  if(!holdingsleep(&b->lock))
80100256:	8b 45 08             	mov    0x8(%ebp),%eax
80100259:	83 c0 0c             	add    $0xc,%eax
8010025c:	83 ec 0c             	sub    $0xc,%esp
8010025f:	50                   	push   %eax
80100260:	e8 60 4c 00 00       	call   80104ec5 <holdingsleep>
80100265:	83 c4 10             	add    $0x10,%esp
80100268:	85 c0                	test   %eax,%eax
8010026a:	75 0d                	jne    80100279 <brelse+0x29>
    panic("brelse");
8010026c:	83 ec 0c             	sub    $0xc,%esp
8010026f:	68 aa 84 10 80       	push   $0x801084aa
80100274:	e8 27 03 00 00       	call   801005a0 <panic>

  releasesleep(&b->lock);
80100279:	8b 45 08             	mov    0x8(%ebp),%eax
8010027c:	83 c0 0c             	add    $0xc,%eax
8010027f:	83 ec 0c             	sub    $0xc,%esp
80100282:	50                   	push   %eax
80100283:	e8 ef 4b 00 00       	call   80104e77 <releasesleep>
80100288:	83 c4 10             	add    $0x10,%esp

  acquire(&bcache.lock);
8010028b:	83 ec 0c             	sub    $0xc,%esp
8010028e:	68 40 c6 10 80       	push   $0x8010c640
80100293:	e8 be 4c 00 00       	call   80104f56 <acquire>
80100298:	83 c4 10             	add    $0x10,%esp
  b->refcnt--;
8010029b:	8b 45 08             	mov    0x8(%ebp),%eax
8010029e:	8b 40 4c             	mov    0x4c(%eax),%eax
801002a1:	8d 50 ff             	lea    -0x1(%eax),%edx
801002a4:	8b 45 08             	mov    0x8(%ebp),%eax
801002a7:	89 50 4c             	mov    %edx,0x4c(%eax)
  if (b->refcnt == 0) {
801002aa:	8b 45 08             	mov    0x8(%ebp),%eax
801002ad:	8b 40 4c             	mov    0x4c(%eax),%eax
801002b0:	85 c0                	test   %eax,%eax
801002b2:	75 47                	jne    801002fb <brelse+0xab>
    // no one is waiting for it.
    b->next->prev = b->prev;
801002b4:	8b 45 08             	mov    0x8(%ebp),%eax
801002b7:	8b 40 54             	mov    0x54(%eax),%eax
801002ba:	8b 55 08             	mov    0x8(%ebp),%edx
801002bd:	8b 52 50             	mov    0x50(%edx),%edx
801002c0:	89 50 50             	mov    %edx,0x50(%eax)
    b->prev->next = b->next;
801002c3:	8b 45 08             	mov    0x8(%ebp),%eax
801002c6:	8b 40 50             	mov    0x50(%eax),%eax
801002c9:	8b 55 08             	mov    0x8(%ebp),%edx
801002cc:	8b 52 54             	mov    0x54(%edx),%edx
801002cf:	89 50 54             	mov    %edx,0x54(%eax)
    b->next = bcache.head.next;
801002d2:	8b 15 90 0d 11 80    	mov    0x80110d90,%edx
801002d8:	8b 45 08             	mov    0x8(%ebp),%eax
801002db:	89 50 54             	mov    %edx,0x54(%eax)
    b->prev = &bcache.head;
801002de:	8b 45 08             	mov    0x8(%ebp),%eax
801002e1:	c7 40 50 3c 0d 11 80 	movl   $0x80110d3c,0x50(%eax)
    bcache.head.next->prev = b;
801002e8:	a1 90 0d 11 80       	mov    0x80110d90,%eax
801002ed:	8b 55 08             	mov    0x8(%ebp),%edx
801002f0:	89 50 50             	mov    %edx,0x50(%eax)
    bcache.head.next = b;
801002f3:	8b 45 08             	mov    0x8(%ebp),%eax
801002f6:	a3 90 0d 11 80       	mov    %eax,0x80110d90
  }
  
  release(&bcache.lock);
801002fb:	83 ec 0c             	sub    $0xc,%esp
801002fe:	68 40 c6 10 80       	push   $0x8010c640
80100303:	e8 bc 4c 00 00       	call   80104fc4 <release>
80100308:	83 c4 10             	add    $0x10,%esp
}
8010030b:	90                   	nop
8010030c:	c9                   	leave  
8010030d:	c3                   	ret    

8010030e <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
8010030e:	55                   	push   %ebp
8010030f:	89 e5                	mov    %esp,%ebp
80100311:	83 ec 14             	sub    $0x14,%esp
80100314:	8b 45 08             	mov    0x8(%ebp),%eax
80100317:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
8010031b:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
8010031f:	89 c2                	mov    %eax,%edx
80100321:	ec                   	in     (%dx),%al
80100322:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80100325:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80100329:	c9                   	leave  
8010032a:	c3                   	ret    

8010032b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
8010032b:	55                   	push   %ebp
8010032c:	89 e5                	mov    %esp,%ebp
8010032e:	83 ec 08             	sub    $0x8,%esp
80100331:	8b 55 08             	mov    0x8(%ebp),%edx
80100334:	8b 45 0c             	mov    0xc(%ebp),%eax
80100337:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
8010033b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
8010033e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80100342:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80100346:	ee                   	out    %al,(%dx)
}
80100347:	90                   	nop
80100348:	c9                   	leave  
80100349:	c3                   	ret    

8010034a <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
8010034a:	55                   	push   %ebp
8010034b:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
8010034d:	fa                   	cli    
}
8010034e:	90                   	nop
8010034f:	5d                   	pop    %ebp
80100350:	c3                   	ret    

80100351 <printint>:
  int locking;
} cons;

static void
printint(int xx, int base, int sign)
{
80100351:	55                   	push   %ebp
80100352:	89 e5                	mov    %esp,%ebp
80100354:	53                   	push   %ebx
80100355:	83 ec 24             	sub    $0x24,%esp
  static char digits[] = "0123456789abcdef";
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
80100358:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010035c:	74 1c                	je     8010037a <printint+0x29>
8010035e:	8b 45 08             	mov    0x8(%ebp),%eax
80100361:	c1 e8 1f             	shr    $0x1f,%eax
80100364:	0f b6 c0             	movzbl %al,%eax
80100367:	89 45 10             	mov    %eax,0x10(%ebp)
8010036a:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
8010036e:	74 0a                	je     8010037a <printint+0x29>
    x = -xx;
80100370:	8b 45 08             	mov    0x8(%ebp),%eax
80100373:	f7 d8                	neg    %eax
80100375:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100378:	eb 06                	jmp    80100380 <printint+0x2f>
  else
    x = xx;
8010037a:	8b 45 08             	mov    0x8(%ebp),%eax
8010037d:	89 45 f0             	mov    %eax,-0x10(%ebp)

  i = 0;
80100380:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
80100387:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010038a:	8d 41 01             	lea    0x1(%ecx),%eax
8010038d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100390:	8b 5d 0c             	mov    0xc(%ebp),%ebx
80100393:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100396:	ba 00 00 00 00       	mov    $0x0,%edx
8010039b:	f7 f3                	div    %ebx
8010039d:	89 d0                	mov    %edx,%eax
8010039f:	0f b6 80 04 90 10 80 	movzbl -0x7fef6ffc(%eax),%eax
801003a6:	88 44 0d e0          	mov    %al,-0x20(%ebp,%ecx,1)
  }while((x /= base) != 0);
801003aa:	8b 5d 0c             	mov    0xc(%ebp),%ebx
801003ad:	8b 45 f0             	mov    -0x10(%ebp),%eax
801003b0:	ba 00 00 00 00       	mov    $0x0,%edx
801003b5:	f7 f3                	div    %ebx
801003b7:	89 45 f0             	mov    %eax,-0x10(%ebp)
801003ba:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801003be:	75 c7                	jne    80100387 <printint+0x36>

  if(sign)
801003c0:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801003c4:	74 2a                	je     801003f0 <printint+0x9f>
    buf[i++] = '-';
801003c6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801003c9:	8d 50 01             	lea    0x1(%eax),%edx
801003cc:	89 55 f4             	mov    %edx,-0xc(%ebp)
801003cf:	c6 44 05 e0 2d       	movb   $0x2d,-0x20(%ebp,%eax,1)

  while(--i >= 0)
801003d4:	eb 1a                	jmp    801003f0 <printint+0x9f>
    consputc(buf[i]);
801003d6:	8d 55 e0             	lea    -0x20(%ebp),%edx
801003d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
801003dc:	01 d0                	add    %edx,%eax
801003de:	0f b6 00             	movzbl (%eax),%eax
801003e1:	0f be c0             	movsbl %al,%eax
801003e4:	83 ec 0c             	sub    $0xc,%esp
801003e7:	50                   	push   %eax
801003e8:	e8 d8 03 00 00       	call   801007c5 <consputc>
801003ed:	83 c4 10             	add    $0x10,%esp
  }while((x /= base) != 0);

  if(sign)
    buf[i++] = '-';

  while(--i >= 0)
801003f0:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801003f4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801003f8:	79 dc                	jns    801003d6 <printint+0x85>
    consputc(buf[i]);
}
801003fa:	90                   	nop
801003fb:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801003fe:	c9                   	leave  
801003ff:	c3                   	ret    

80100400 <cprintf>:
//PAGEBREAK: 50

// Print to the console. only understands %d, %x, %p, %s.
void
cprintf(char *fmt, ...)
{
80100400:	55                   	push   %ebp
80100401:	89 e5                	mov    %esp,%ebp
80100403:	83 ec 28             	sub    $0x28,%esp
  int i, c, locking;
  uint *argp;
  char *s;

  locking = cons.locking;
80100406:	a1 d4 b5 10 80       	mov    0x8010b5d4,%eax
8010040b:	89 45 e8             	mov    %eax,-0x18(%ebp)
  if(locking)
8010040e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80100412:	74 10                	je     80100424 <cprintf+0x24>
    acquire(&cons.lock);
80100414:	83 ec 0c             	sub    $0xc,%esp
80100417:	68 a0 b5 10 80       	push   $0x8010b5a0
8010041c:	e8 35 4b 00 00       	call   80104f56 <acquire>
80100421:	83 c4 10             	add    $0x10,%esp

  if (fmt == 0)
80100424:	8b 45 08             	mov    0x8(%ebp),%eax
80100427:	85 c0                	test   %eax,%eax
80100429:	75 0d                	jne    80100438 <cprintf+0x38>
    panic("null fmt");
8010042b:	83 ec 0c             	sub    $0xc,%esp
8010042e:	68 b1 84 10 80       	push   $0x801084b1
80100433:	e8 68 01 00 00       	call   801005a0 <panic>

  argp = (uint*)(void*)(&fmt + 1);
80100438:	8d 45 0c             	lea    0xc(%ebp),%eax
8010043b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
8010043e:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100445:	e9 1a 01 00 00       	jmp    80100564 <cprintf+0x164>
    if(c != '%'){
8010044a:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
8010044e:	74 13                	je     80100463 <cprintf+0x63>
      consputc(c);
80100450:	83 ec 0c             	sub    $0xc,%esp
80100453:	ff 75 e4             	pushl  -0x1c(%ebp)
80100456:	e8 6a 03 00 00       	call   801007c5 <consputc>
8010045b:	83 c4 10             	add    $0x10,%esp
      continue;
8010045e:	e9 fd 00 00 00       	jmp    80100560 <cprintf+0x160>
    }
    c = fmt[++i] & 0xff;
80100463:	8b 55 08             	mov    0x8(%ebp),%edx
80100466:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010046a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010046d:	01 d0                	add    %edx,%eax
8010046f:	0f b6 00             	movzbl (%eax),%eax
80100472:	0f be c0             	movsbl %al,%eax
80100475:	25 ff 00 00 00       	and    $0xff,%eax
8010047a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(c == 0)
8010047d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
80100481:	0f 84 ff 00 00 00    	je     80100586 <cprintf+0x186>
      break;
    switch(c){
80100487:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010048a:	83 f8 70             	cmp    $0x70,%eax
8010048d:	74 47                	je     801004d6 <cprintf+0xd6>
8010048f:	83 f8 70             	cmp    $0x70,%eax
80100492:	7f 13                	jg     801004a7 <cprintf+0xa7>
80100494:	83 f8 25             	cmp    $0x25,%eax
80100497:	0f 84 98 00 00 00    	je     80100535 <cprintf+0x135>
8010049d:	83 f8 64             	cmp    $0x64,%eax
801004a0:	74 14                	je     801004b6 <cprintf+0xb6>
801004a2:	e9 9d 00 00 00       	jmp    80100544 <cprintf+0x144>
801004a7:	83 f8 73             	cmp    $0x73,%eax
801004aa:	74 47                	je     801004f3 <cprintf+0xf3>
801004ac:	83 f8 78             	cmp    $0x78,%eax
801004af:	74 25                	je     801004d6 <cprintf+0xd6>
801004b1:	e9 8e 00 00 00       	jmp    80100544 <cprintf+0x144>
    case 'd':
      printint(*argp++, 10, 1);
801004b6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004b9:	8d 50 04             	lea    0x4(%eax),%edx
801004bc:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004bf:	8b 00                	mov    (%eax),%eax
801004c1:	83 ec 04             	sub    $0x4,%esp
801004c4:	6a 01                	push   $0x1
801004c6:	6a 0a                	push   $0xa
801004c8:	50                   	push   %eax
801004c9:	e8 83 fe ff ff       	call   80100351 <printint>
801004ce:	83 c4 10             	add    $0x10,%esp
      break;
801004d1:	e9 8a 00 00 00       	jmp    80100560 <cprintf+0x160>
    case 'x':
    case 'p':
      printint(*argp++, 16, 0);
801004d6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004d9:	8d 50 04             	lea    0x4(%eax),%edx
801004dc:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004df:	8b 00                	mov    (%eax),%eax
801004e1:	83 ec 04             	sub    $0x4,%esp
801004e4:	6a 00                	push   $0x0
801004e6:	6a 10                	push   $0x10
801004e8:	50                   	push   %eax
801004e9:	e8 63 fe ff ff       	call   80100351 <printint>
801004ee:	83 c4 10             	add    $0x10,%esp
      break;
801004f1:	eb 6d                	jmp    80100560 <cprintf+0x160>
    case 's':
      if((s = (char*)*argp++) == 0)
801004f3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801004f6:	8d 50 04             	lea    0x4(%eax),%edx
801004f9:	89 55 f0             	mov    %edx,-0x10(%ebp)
801004fc:	8b 00                	mov    (%eax),%eax
801004fe:	89 45 ec             	mov    %eax,-0x14(%ebp)
80100501:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80100505:	75 22                	jne    80100529 <cprintf+0x129>
        s = "(null)";
80100507:	c7 45 ec ba 84 10 80 	movl   $0x801084ba,-0x14(%ebp)
      for(; *s; s++)
8010050e:	eb 19                	jmp    80100529 <cprintf+0x129>
        consputc(*s);
80100510:	8b 45 ec             	mov    -0x14(%ebp),%eax
80100513:	0f b6 00             	movzbl (%eax),%eax
80100516:	0f be c0             	movsbl %al,%eax
80100519:	83 ec 0c             	sub    $0xc,%esp
8010051c:	50                   	push   %eax
8010051d:	e8 a3 02 00 00       	call   801007c5 <consputc>
80100522:	83 c4 10             	add    $0x10,%esp
      printint(*argp++, 16, 0);
      break;
    case 's':
      if((s = (char*)*argp++) == 0)
        s = "(null)";
      for(; *s; s++)
80100525:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100529:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010052c:	0f b6 00             	movzbl (%eax),%eax
8010052f:	84 c0                	test   %al,%al
80100531:	75 dd                	jne    80100510 <cprintf+0x110>
        consputc(*s);
      break;
80100533:	eb 2b                	jmp    80100560 <cprintf+0x160>
    case '%':
      consputc('%');
80100535:	83 ec 0c             	sub    $0xc,%esp
80100538:	6a 25                	push   $0x25
8010053a:	e8 86 02 00 00       	call   801007c5 <consputc>
8010053f:	83 c4 10             	add    $0x10,%esp
      break;
80100542:	eb 1c                	jmp    80100560 <cprintf+0x160>
    default:
      // Print unknown % sequence to draw attention.
      consputc('%');
80100544:	83 ec 0c             	sub    $0xc,%esp
80100547:	6a 25                	push   $0x25
80100549:	e8 77 02 00 00       	call   801007c5 <consputc>
8010054e:	83 c4 10             	add    $0x10,%esp
      consputc(c);
80100551:	83 ec 0c             	sub    $0xc,%esp
80100554:	ff 75 e4             	pushl  -0x1c(%ebp)
80100557:	e8 69 02 00 00       	call   801007c5 <consputc>
8010055c:	83 c4 10             	add    $0x10,%esp
      break;
8010055f:	90                   	nop

  if (fmt == 0)
    panic("null fmt");

  argp = (uint*)(void*)(&fmt + 1);
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
80100560:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100564:	8b 55 08             	mov    0x8(%ebp),%edx
80100567:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010056a:	01 d0                	add    %edx,%eax
8010056c:	0f b6 00             	movzbl (%eax),%eax
8010056f:	0f be c0             	movsbl %al,%eax
80100572:	25 ff 00 00 00       	and    $0xff,%eax
80100577:	89 45 e4             	mov    %eax,-0x1c(%ebp)
8010057a:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010057e:	0f 85 c6 fe ff ff    	jne    8010044a <cprintf+0x4a>
80100584:	eb 01                	jmp    80100587 <cprintf+0x187>
      consputc(c);
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
80100586:	90                   	nop
      consputc(c);
      break;
    }
  }

  if(locking)
80100587:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
8010058b:	74 10                	je     8010059d <cprintf+0x19d>
    release(&cons.lock);
8010058d:	83 ec 0c             	sub    $0xc,%esp
80100590:	68 a0 b5 10 80       	push   $0x8010b5a0
80100595:	e8 2a 4a 00 00       	call   80104fc4 <release>
8010059a:	83 c4 10             	add    $0x10,%esp
}
8010059d:	90                   	nop
8010059e:	c9                   	leave  
8010059f:	c3                   	ret    

801005a0 <panic>:

void
panic(char *s)
{
801005a0:	55                   	push   %ebp
801005a1:	89 e5                	mov    %esp,%ebp
801005a3:	83 ec 38             	sub    $0x38,%esp
  int i;
  uint pcs[10];

  cli();
801005a6:	e8 9f fd ff ff       	call   8010034a <cli>
  cons.locking = 0;
801005ab:	c7 05 d4 b5 10 80 00 	movl   $0x0,0x8010b5d4
801005b2:	00 00 00 
  // use lapiccpunum so that we can call panic from mycpu()
  cprintf("lapicid %d: panic: ", lapicid());
801005b5:	e8 31 2a 00 00       	call   80102feb <lapicid>
801005ba:	83 ec 08             	sub    $0x8,%esp
801005bd:	50                   	push   %eax
801005be:	68 c1 84 10 80       	push   $0x801084c1
801005c3:	e8 38 fe ff ff       	call   80100400 <cprintf>
801005c8:	83 c4 10             	add    $0x10,%esp
  cprintf(s);
801005cb:	8b 45 08             	mov    0x8(%ebp),%eax
801005ce:	83 ec 0c             	sub    $0xc,%esp
801005d1:	50                   	push   %eax
801005d2:	e8 29 fe ff ff       	call   80100400 <cprintf>
801005d7:	83 c4 10             	add    $0x10,%esp
  cprintf("\n");
801005da:	83 ec 0c             	sub    $0xc,%esp
801005dd:	68 d5 84 10 80       	push   $0x801084d5
801005e2:	e8 19 fe ff ff       	call   80100400 <cprintf>
801005e7:	83 c4 10             	add    $0x10,%esp
  getcallerpcs(&s, pcs);
801005ea:	83 ec 08             	sub    $0x8,%esp
801005ed:	8d 45 cc             	lea    -0x34(%ebp),%eax
801005f0:	50                   	push   %eax
801005f1:	8d 45 08             	lea    0x8(%ebp),%eax
801005f4:	50                   	push   %eax
801005f5:	e8 1c 4a 00 00       	call   80105016 <getcallerpcs>
801005fa:	83 c4 10             	add    $0x10,%esp
  for(i=0; i<10; i++)
801005fd:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100604:	eb 1c                	jmp    80100622 <panic+0x82>
    cprintf(" %p", pcs[i]);
80100606:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100609:	8b 44 85 cc          	mov    -0x34(%ebp,%eax,4),%eax
8010060d:	83 ec 08             	sub    $0x8,%esp
80100610:	50                   	push   %eax
80100611:	68 d7 84 10 80       	push   $0x801084d7
80100616:	e8 e5 fd ff ff       	call   80100400 <cprintf>
8010061b:	83 c4 10             	add    $0x10,%esp
  // use lapiccpunum so that we can call panic from mycpu()
  cprintf("lapicid %d: panic: ", lapicid());
  cprintf(s);
  cprintf("\n");
  getcallerpcs(&s, pcs);
  for(i=0; i<10; i++)
8010061e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100622:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80100626:	7e de                	jle    80100606 <panic+0x66>
    cprintf(" %p", pcs[i]);
  panicked = 1; // freeze other CPU
80100628:	c7 05 80 b5 10 80 01 	movl   $0x1,0x8010b580
8010062f:	00 00 00 
  for(;;)
    ;
80100632:	eb fe                	jmp    80100632 <panic+0x92>

80100634 <cgaputc>:
#define CRTPORT 0x3d4
static ushort *crt = (ushort*)P2V(0xb8000);  // CGA memory

static void
cgaputc(int c)
{
80100634:	55                   	push   %ebp
80100635:	89 e5                	mov    %esp,%ebp
80100637:	83 ec 18             	sub    $0x18,%esp
  int pos;

  // Cursor position: col + 80*row.
  outb(CRTPORT, 14);
8010063a:	6a 0e                	push   $0xe
8010063c:	68 d4 03 00 00       	push   $0x3d4
80100641:	e8 e5 fc ff ff       	call   8010032b <outb>
80100646:	83 c4 08             	add    $0x8,%esp
  pos = inb(CRTPORT+1) << 8;
80100649:	68 d5 03 00 00       	push   $0x3d5
8010064e:	e8 bb fc ff ff       	call   8010030e <inb>
80100653:	83 c4 04             	add    $0x4,%esp
80100656:	0f b6 c0             	movzbl %al,%eax
80100659:	c1 e0 08             	shl    $0x8,%eax
8010065c:	89 45 f4             	mov    %eax,-0xc(%ebp)
  outb(CRTPORT, 15);
8010065f:	6a 0f                	push   $0xf
80100661:	68 d4 03 00 00       	push   $0x3d4
80100666:	e8 c0 fc ff ff       	call   8010032b <outb>
8010066b:	83 c4 08             	add    $0x8,%esp
  pos |= inb(CRTPORT+1);
8010066e:	68 d5 03 00 00       	push   $0x3d5
80100673:	e8 96 fc ff ff       	call   8010030e <inb>
80100678:	83 c4 04             	add    $0x4,%esp
8010067b:	0f b6 c0             	movzbl %al,%eax
8010067e:	09 45 f4             	or     %eax,-0xc(%ebp)

  if(c == '\n')
80100681:	83 7d 08 0a          	cmpl   $0xa,0x8(%ebp)
80100685:	75 30                	jne    801006b7 <cgaputc+0x83>
    pos += 80 - pos%80;
80100687:	8b 4d f4             	mov    -0xc(%ebp),%ecx
8010068a:	ba 67 66 66 66       	mov    $0x66666667,%edx
8010068f:	89 c8                	mov    %ecx,%eax
80100691:	f7 ea                	imul   %edx
80100693:	c1 fa 05             	sar    $0x5,%edx
80100696:	89 c8                	mov    %ecx,%eax
80100698:	c1 f8 1f             	sar    $0x1f,%eax
8010069b:	29 c2                	sub    %eax,%edx
8010069d:	89 d0                	mov    %edx,%eax
8010069f:	c1 e0 02             	shl    $0x2,%eax
801006a2:	01 d0                	add    %edx,%eax
801006a4:	c1 e0 04             	shl    $0x4,%eax
801006a7:	29 c1                	sub    %eax,%ecx
801006a9:	89 ca                	mov    %ecx,%edx
801006ab:	b8 50 00 00 00       	mov    $0x50,%eax
801006b0:	29 d0                	sub    %edx,%eax
801006b2:	01 45 f4             	add    %eax,-0xc(%ebp)
801006b5:	eb 34                	jmp    801006eb <cgaputc+0xb7>
  else if(c == BACKSPACE){
801006b7:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801006be:	75 0c                	jne    801006cc <cgaputc+0x98>
    if(pos > 0) --pos;
801006c0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006c4:	7e 25                	jle    801006eb <cgaputc+0xb7>
801006c6:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
801006ca:	eb 1f                	jmp    801006eb <cgaputc+0xb7>
  } else
    crt[pos++] = (c&0xff) | 0x0700;  // black on white
801006cc:	8b 0d 00 90 10 80    	mov    0x80109000,%ecx
801006d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801006d5:	8d 50 01             	lea    0x1(%eax),%edx
801006d8:	89 55 f4             	mov    %edx,-0xc(%ebp)
801006db:	01 c0                	add    %eax,%eax
801006dd:	01 c8                	add    %ecx,%eax
801006df:	8b 55 08             	mov    0x8(%ebp),%edx
801006e2:	0f b6 d2             	movzbl %dl,%edx
801006e5:	80 ce 07             	or     $0x7,%dh
801006e8:	66 89 10             	mov    %dx,(%eax)

  if(pos < 0 || pos > 25*80)
801006eb:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801006ef:	78 09                	js     801006fa <cgaputc+0xc6>
801006f1:	81 7d f4 d0 07 00 00 	cmpl   $0x7d0,-0xc(%ebp)
801006f8:	7e 0d                	jle    80100707 <cgaputc+0xd3>
    panic("pos under/overflow");
801006fa:	83 ec 0c             	sub    $0xc,%esp
801006fd:	68 db 84 10 80       	push   $0x801084db
80100702:	e8 99 fe ff ff       	call   801005a0 <panic>

  if((pos/80) >= 24){  // Scroll up.
80100707:	81 7d f4 7f 07 00 00 	cmpl   $0x77f,-0xc(%ebp)
8010070e:	7e 4c                	jle    8010075c <cgaputc+0x128>
    memmove(crt, crt+80, sizeof(crt[0])*23*80);
80100710:	a1 00 90 10 80       	mov    0x80109000,%eax
80100715:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
8010071b:	a1 00 90 10 80       	mov    0x80109000,%eax
80100720:	83 ec 04             	sub    $0x4,%esp
80100723:	68 60 0e 00 00       	push   $0xe60
80100728:	52                   	push   %edx
80100729:	50                   	push   %eax
8010072a:	e8 5d 4b 00 00       	call   8010528c <memmove>
8010072f:	83 c4 10             	add    $0x10,%esp
    pos -= 80;
80100732:	83 6d f4 50          	subl   $0x50,-0xc(%ebp)
    memset(crt+pos, 0, sizeof(crt[0])*(24*80 - pos));
80100736:	b8 80 07 00 00       	mov    $0x780,%eax
8010073b:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010073e:	8d 14 00             	lea    (%eax,%eax,1),%edx
80100741:	a1 00 90 10 80       	mov    0x80109000,%eax
80100746:	8b 4d f4             	mov    -0xc(%ebp),%ecx
80100749:	01 c9                	add    %ecx,%ecx
8010074b:	01 c8                	add    %ecx,%eax
8010074d:	83 ec 04             	sub    $0x4,%esp
80100750:	52                   	push   %edx
80100751:	6a 00                	push   $0x0
80100753:	50                   	push   %eax
80100754:	e8 74 4a 00 00       	call   801051cd <memset>
80100759:	83 c4 10             	add    $0x10,%esp
  }

  outb(CRTPORT, 14);
8010075c:	83 ec 08             	sub    $0x8,%esp
8010075f:	6a 0e                	push   $0xe
80100761:	68 d4 03 00 00       	push   $0x3d4
80100766:	e8 c0 fb ff ff       	call   8010032b <outb>
8010076b:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT+1, pos>>8);
8010076e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100771:	c1 f8 08             	sar    $0x8,%eax
80100774:	0f b6 c0             	movzbl %al,%eax
80100777:	83 ec 08             	sub    $0x8,%esp
8010077a:	50                   	push   %eax
8010077b:	68 d5 03 00 00       	push   $0x3d5
80100780:	e8 a6 fb ff ff       	call   8010032b <outb>
80100785:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT, 15);
80100788:	83 ec 08             	sub    $0x8,%esp
8010078b:	6a 0f                	push   $0xf
8010078d:	68 d4 03 00 00       	push   $0x3d4
80100792:	e8 94 fb ff ff       	call   8010032b <outb>
80100797:	83 c4 10             	add    $0x10,%esp
  outb(CRTPORT+1, pos);
8010079a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010079d:	0f b6 c0             	movzbl %al,%eax
801007a0:	83 ec 08             	sub    $0x8,%esp
801007a3:	50                   	push   %eax
801007a4:	68 d5 03 00 00       	push   $0x3d5
801007a9:	e8 7d fb ff ff       	call   8010032b <outb>
801007ae:	83 c4 10             	add    $0x10,%esp
  crt[pos] = ' ' | 0x0700;
801007b1:	a1 00 90 10 80       	mov    0x80109000,%eax
801007b6:	8b 55 f4             	mov    -0xc(%ebp),%edx
801007b9:	01 d2                	add    %edx,%edx
801007bb:	01 d0                	add    %edx,%eax
801007bd:	66 c7 00 20 07       	movw   $0x720,(%eax)
}
801007c2:	90                   	nop
801007c3:	c9                   	leave  
801007c4:	c3                   	ret    

801007c5 <consputc>:

void
consputc(int c)
{
801007c5:	55                   	push   %ebp
801007c6:	89 e5                	mov    %esp,%ebp
801007c8:	83 ec 08             	sub    $0x8,%esp
  if(panicked){
801007cb:	a1 80 b5 10 80       	mov    0x8010b580,%eax
801007d0:	85 c0                	test   %eax,%eax
801007d2:	74 07                	je     801007db <consputc+0x16>
    cli();
801007d4:	e8 71 fb ff ff       	call   8010034a <cli>
    for(;;)
      ;
801007d9:	eb fe                	jmp    801007d9 <consputc+0x14>
  }

  if(c == BACKSPACE){
801007db:	81 7d 08 00 01 00 00 	cmpl   $0x100,0x8(%ebp)
801007e2:	75 29                	jne    8010080d <consputc+0x48>
    uartputc('\b'); uartputc(' '); uartputc('\b');
801007e4:	83 ec 0c             	sub    $0xc,%esp
801007e7:	6a 08                	push   $0x8
801007e9:	e8 53 64 00 00       	call   80106c41 <uartputc>
801007ee:	83 c4 10             	add    $0x10,%esp
801007f1:	83 ec 0c             	sub    $0xc,%esp
801007f4:	6a 20                	push   $0x20
801007f6:	e8 46 64 00 00       	call   80106c41 <uartputc>
801007fb:	83 c4 10             	add    $0x10,%esp
801007fe:	83 ec 0c             	sub    $0xc,%esp
80100801:	6a 08                	push   $0x8
80100803:	e8 39 64 00 00       	call   80106c41 <uartputc>
80100808:	83 c4 10             	add    $0x10,%esp
8010080b:	eb 0e                	jmp    8010081b <consputc+0x56>
  } else
    uartputc(c);
8010080d:	83 ec 0c             	sub    $0xc,%esp
80100810:	ff 75 08             	pushl  0x8(%ebp)
80100813:	e8 29 64 00 00       	call   80106c41 <uartputc>
80100818:	83 c4 10             	add    $0x10,%esp
  cgaputc(c);
8010081b:	83 ec 0c             	sub    $0xc,%esp
8010081e:	ff 75 08             	pushl  0x8(%ebp)
80100821:	e8 0e fe ff ff       	call   80100634 <cgaputc>
80100826:	83 c4 10             	add    $0x10,%esp
}
80100829:	90                   	nop
8010082a:	c9                   	leave  
8010082b:	c3                   	ret    

8010082c <consoleintr>:

#define C(x)  ((x)-'@')  // Control-x

void
consoleintr(int (*getc)(void))
{
8010082c:	55                   	push   %ebp
8010082d:	89 e5                	mov    %esp,%ebp
8010082f:	83 ec 18             	sub    $0x18,%esp
  int c, doprocdump = 0;
80100832:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&cons.lock);
80100839:	83 ec 0c             	sub    $0xc,%esp
8010083c:	68 a0 b5 10 80       	push   $0x8010b5a0
80100841:	e8 10 47 00 00       	call   80104f56 <acquire>
80100846:	83 c4 10             	add    $0x10,%esp
  while((c = getc()) >= 0){
80100849:	e9 44 01 00 00       	jmp    80100992 <consoleintr+0x166>
    switch(c){
8010084e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100851:	83 f8 10             	cmp    $0x10,%eax
80100854:	74 1e                	je     80100874 <consoleintr+0x48>
80100856:	83 f8 10             	cmp    $0x10,%eax
80100859:	7f 0a                	jg     80100865 <consoleintr+0x39>
8010085b:	83 f8 08             	cmp    $0x8,%eax
8010085e:	74 6b                	je     801008cb <consoleintr+0x9f>
80100860:	e9 9b 00 00 00       	jmp    80100900 <consoleintr+0xd4>
80100865:	83 f8 15             	cmp    $0x15,%eax
80100868:	74 33                	je     8010089d <consoleintr+0x71>
8010086a:	83 f8 7f             	cmp    $0x7f,%eax
8010086d:	74 5c                	je     801008cb <consoleintr+0x9f>
8010086f:	e9 8c 00 00 00       	jmp    80100900 <consoleintr+0xd4>
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
80100874:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
      break;
8010087b:	e9 12 01 00 00       	jmp    80100992 <consoleintr+0x166>
    case C('U'):  // Kill line.
      while(input.e != input.w &&
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
80100880:	a1 28 10 11 80       	mov    0x80111028,%eax
80100885:	83 e8 01             	sub    $0x1,%eax
80100888:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
8010088d:	83 ec 0c             	sub    $0xc,%esp
80100890:	68 00 01 00 00       	push   $0x100
80100895:	e8 2b ff ff ff       	call   801007c5 <consputc>
8010089a:	83 c4 10             	add    $0x10,%esp
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
8010089d:	8b 15 28 10 11 80    	mov    0x80111028,%edx
801008a3:	a1 24 10 11 80       	mov    0x80111024,%eax
801008a8:	39 c2                	cmp    %eax,%edx
801008aa:	0f 84 e2 00 00 00    	je     80100992 <consoleintr+0x166>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
801008b0:	a1 28 10 11 80       	mov    0x80111028,%eax
801008b5:	83 e8 01             	sub    $0x1,%eax
801008b8:	83 e0 7f             	and    $0x7f,%eax
801008bb:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
    case C('P'):  // Process listing.
      // procdump() locks cons.lock indirectly; invoke later
      doprocdump = 1;
      break;
    case C('U'):  // Kill line.
      while(input.e != input.w &&
801008c2:	3c 0a                	cmp    $0xa,%al
801008c4:	75 ba                	jne    80100880 <consoleintr+0x54>
            input.buf[(input.e-1) % INPUT_BUF] != '\n'){
        input.e--;
        consputc(BACKSPACE);
      }
      break;
801008c6:	e9 c7 00 00 00       	jmp    80100992 <consoleintr+0x166>
    case C('H'): case '\x7f':  // Backspace
      if(input.e != input.w){
801008cb:	8b 15 28 10 11 80    	mov    0x80111028,%edx
801008d1:	a1 24 10 11 80       	mov    0x80111024,%eax
801008d6:	39 c2                	cmp    %eax,%edx
801008d8:	0f 84 b4 00 00 00    	je     80100992 <consoleintr+0x166>
        input.e--;
801008de:	a1 28 10 11 80       	mov    0x80111028,%eax
801008e3:	83 e8 01             	sub    $0x1,%eax
801008e6:	a3 28 10 11 80       	mov    %eax,0x80111028
        consputc(BACKSPACE);
801008eb:	83 ec 0c             	sub    $0xc,%esp
801008ee:	68 00 01 00 00       	push   $0x100
801008f3:	e8 cd fe ff ff       	call   801007c5 <consputc>
801008f8:	83 c4 10             	add    $0x10,%esp
      }
      break;
801008fb:	e9 92 00 00 00       	jmp    80100992 <consoleintr+0x166>
    default:
      if(c != 0 && input.e-input.r < INPUT_BUF){
80100900:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80100904:	0f 84 87 00 00 00    	je     80100991 <consoleintr+0x165>
8010090a:	8b 15 28 10 11 80    	mov    0x80111028,%edx
80100910:	a1 20 10 11 80       	mov    0x80111020,%eax
80100915:	29 c2                	sub    %eax,%edx
80100917:	89 d0                	mov    %edx,%eax
80100919:	83 f8 7f             	cmp    $0x7f,%eax
8010091c:	77 73                	ja     80100991 <consoleintr+0x165>
        c = (c == '\r') ? '\n' : c;
8010091e:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
80100922:	74 05                	je     80100929 <consoleintr+0xfd>
80100924:	8b 45 f0             	mov    -0x10(%ebp),%eax
80100927:	eb 05                	jmp    8010092e <consoleintr+0x102>
80100929:	b8 0a 00 00 00       	mov    $0xa,%eax
8010092e:	89 45 f0             	mov    %eax,-0x10(%ebp)
        input.buf[input.e++ % INPUT_BUF] = c;
80100931:	a1 28 10 11 80       	mov    0x80111028,%eax
80100936:	8d 50 01             	lea    0x1(%eax),%edx
80100939:	89 15 28 10 11 80    	mov    %edx,0x80111028
8010093f:	83 e0 7f             	and    $0x7f,%eax
80100942:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100945:	88 90 a0 0f 11 80    	mov    %dl,-0x7feef060(%eax)
        consputc(c);
8010094b:	83 ec 0c             	sub    $0xc,%esp
8010094e:	ff 75 f0             	pushl  -0x10(%ebp)
80100951:	e8 6f fe ff ff       	call   801007c5 <consputc>
80100956:	83 c4 10             	add    $0x10,%esp
        if(c == '\n' || c == C('D') || input.e == input.r+INPUT_BUF){
80100959:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
8010095d:	74 18                	je     80100977 <consoleintr+0x14b>
8010095f:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100963:	74 12                	je     80100977 <consoleintr+0x14b>
80100965:	a1 28 10 11 80       	mov    0x80111028,%eax
8010096a:	8b 15 20 10 11 80    	mov    0x80111020,%edx
80100970:	83 ea 80             	sub    $0xffffff80,%edx
80100973:	39 d0                	cmp    %edx,%eax
80100975:	75 1a                	jne    80100991 <consoleintr+0x165>
          input.w = input.e;
80100977:	a1 28 10 11 80       	mov    0x80111028,%eax
8010097c:	a3 24 10 11 80       	mov    %eax,0x80111024
          wakeup(&input.r);
80100981:	83 ec 0c             	sub    $0xc,%esp
80100984:	68 20 10 11 80       	push   $0x80111020
80100989:	e8 95 42 00 00       	call   80104c23 <wakeup>
8010098e:	83 c4 10             	add    $0x10,%esp
        }
      }
      break;
80100991:	90                   	nop
consoleintr(int (*getc)(void))
{
  int c, doprocdump = 0;

  acquire(&cons.lock);
  while((c = getc()) >= 0){
80100992:	8b 45 08             	mov    0x8(%ebp),%eax
80100995:	ff d0                	call   *%eax
80100997:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010099a:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010099e:	0f 89 aa fe ff ff    	jns    8010084e <consoleintr+0x22>
        }
      }
      break;
    }
  }
  release(&cons.lock);
801009a4:	83 ec 0c             	sub    $0xc,%esp
801009a7:	68 a0 b5 10 80       	push   $0x8010b5a0
801009ac:	e8 13 46 00 00       	call   80104fc4 <release>
801009b1:	83 c4 10             	add    $0x10,%esp
  if(doprocdump) {
801009b4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801009b8:	74 05                	je     801009bf <consoleintr+0x193>
    procdump();  // now call procdump() wo. cons.lock held
801009ba:	e8 1f 43 00 00       	call   80104cde <procdump>
  }
}
801009bf:	90                   	nop
801009c0:	c9                   	leave  
801009c1:	c3                   	ret    

801009c2 <consoleread>:

int
consoleread(struct inode *ip, char *dst, int n)
{
801009c2:	55                   	push   %ebp
801009c3:	89 e5                	mov    %esp,%ebp
801009c5:	83 ec 18             	sub    $0x18,%esp
  uint target;
  int c;

  iunlock(ip);
801009c8:	83 ec 0c             	sub    $0xc,%esp
801009cb:	ff 75 08             	pushl  0x8(%ebp)
801009ce:	e8 50 11 00 00       	call   80101b23 <iunlock>
801009d3:	83 c4 10             	add    $0x10,%esp
  target = n;
801009d6:	8b 45 10             	mov    0x10(%ebp),%eax
801009d9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  acquire(&cons.lock);
801009dc:	83 ec 0c             	sub    $0xc,%esp
801009df:	68 a0 b5 10 80       	push   $0x8010b5a0
801009e4:	e8 6d 45 00 00       	call   80104f56 <acquire>
801009e9:	83 c4 10             	add    $0x10,%esp
  while(n > 0){
801009ec:	e9 ab 00 00 00       	jmp    80100a9c <consoleread+0xda>
    while(input.r == input.w){
      if(myproc()->killed){
801009f1:	e8 92 38 00 00       	call   80104288 <myproc>
801009f6:	8b 40 24             	mov    0x24(%eax),%eax
801009f9:	85 c0                	test   %eax,%eax
801009fb:	74 28                	je     80100a25 <consoleread+0x63>
        release(&cons.lock);
801009fd:	83 ec 0c             	sub    $0xc,%esp
80100a00:	68 a0 b5 10 80       	push   $0x8010b5a0
80100a05:	e8 ba 45 00 00       	call   80104fc4 <release>
80100a0a:	83 c4 10             	add    $0x10,%esp
        ilock(ip);
80100a0d:	83 ec 0c             	sub    $0xc,%esp
80100a10:	ff 75 08             	pushl  0x8(%ebp)
80100a13:	e8 f8 0f 00 00       	call   80101a10 <ilock>
80100a18:	83 c4 10             	add    $0x10,%esp
        return -1;
80100a1b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100a20:	e9 ab 00 00 00       	jmp    80100ad0 <consoleread+0x10e>
      }
      sleep(&input.r, &cons.lock);
80100a25:	83 ec 08             	sub    $0x8,%esp
80100a28:	68 a0 b5 10 80       	push   $0x8010b5a0
80100a2d:	68 20 10 11 80       	push   $0x80111020
80100a32:	e8 06 41 00 00       	call   80104b3d <sleep>
80100a37:	83 c4 10             	add    $0x10,%esp

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
    while(input.r == input.w){
80100a3a:	8b 15 20 10 11 80    	mov    0x80111020,%edx
80100a40:	a1 24 10 11 80       	mov    0x80111024,%eax
80100a45:	39 c2                	cmp    %eax,%edx
80100a47:	74 a8                	je     801009f1 <consoleread+0x2f>
        ilock(ip);
        return -1;
      }
      sleep(&input.r, &cons.lock);
    }
    c = input.buf[input.r++ % INPUT_BUF];
80100a49:	a1 20 10 11 80       	mov    0x80111020,%eax
80100a4e:	8d 50 01             	lea    0x1(%eax),%edx
80100a51:	89 15 20 10 11 80    	mov    %edx,0x80111020
80100a57:	83 e0 7f             	and    $0x7f,%eax
80100a5a:	0f b6 80 a0 0f 11 80 	movzbl -0x7feef060(%eax),%eax
80100a61:	0f be c0             	movsbl %al,%eax
80100a64:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(c == C('D')){  // EOF
80100a67:	83 7d f0 04          	cmpl   $0x4,-0x10(%ebp)
80100a6b:	75 17                	jne    80100a84 <consoleread+0xc2>
      if(n < target){
80100a6d:	8b 45 10             	mov    0x10(%ebp),%eax
80100a70:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80100a73:	73 2f                	jae    80100aa4 <consoleread+0xe2>
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
80100a75:	a1 20 10 11 80       	mov    0x80111020,%eax
80100a7a:	83 e8 01             	sub    $0x1,%eax
80100a7d:	a3 20 10 11 80       	mov    %eax,0x80111020
      }
      break;
80100a82:	eb 20                	jmp    80100aa4 <consoleread+0xe2>
    }
    *dst++ = c;
80100a84:	8b 45 0c             	mov    0xc(%ebp),%eax
80100a87:	8d 50 01             	lea    0x1(%eax),%edx
80100a8a:	89 55 0c             	mov    %edx,0xc(%ebp)
80100a8d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80100a90:	88 10                	mov    %dl,(%eax)
    --n;
80100a92:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
    if(c == '\n')
80100a96:	83 7d f0 0a          	cmpl   $0xa,-0x10(%ebp)
80100a9a:	74 0b                	je     80100aa7 <consoleread+0xe5>
  int c;

  iunlock(ip);
  target = n;
  acquire(&cons.lock);
  while(n > 0){
80100a9c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80100aa0:	7f 98                	jg     80100a3a <consoleread+0x78>
80100aa2:	eb 04                	jmp    80100aa8 <consoleread+0xe6>
      if(n < target){
        // Save ^D for next time, to make sure
        // caller gets a 0-byte result.
        input.r--;
      }
      break;
80100aa4:	90                   	nop
80100aa5:	eb 01                	jmp    80100aa8 <consoleread+0xe6>
    }
    *dst++ = c;
    --n;
    if(c == '\n')
      break;
80100aa7:	90                   	nop
  }
  release(&cons.lock);
80100aa8:	83 ec 0c             	sub    $0xc,%esp
80100aab:	68 a0 b5 10 80       	push   $0x8010b5a0
80100ab0:	e8 0f 45 00 00       	call   80104fc4 <release>
80100ab5:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80100ab8:	83 ec 0c             	sub    $0xc,%esp
80100abb:	ff 75 08             	pushl  0x8(%ebp)
80100abe:	e8 4d 0f 00 00       	call   80101a10 <ilock>
80100ac3:	83 c4 10             	add    $0x10,%esp

  return target - n;
80100ac6:	8b 45 10             	mov    0x10(%ebp),%eax
80100ac9:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100acc:	29 c2                	sub    %eax,%edx
80100ace:	89 d0                	mov    %edx,%eax
}
80100ad0:	c9                   	leave  
80100ad1:	c3                   	ret    

80100ad2 <consolewrite>:

int
consolewrite(struct inode *ip, char *buf, int n)
{
80100ad2:	55                   	push   %ebp
80100ad3:	89 e5                	mov    %esp,%ebp
80100ad5:	83 ec 18             	sub    $0x18,%esp
  int i;

  iunlock(ip);
80100ad8:	83 ec 0c             	sub    $0xc,%esp
80100adb:	ff 75 08             	pushl  0x8(%ebp)
80100ade:	e8 40 10 00 00       	call   80101b23 <iunlock>
80100ae3:	83 c4 10             	add    $0x10,%esp
  acquire(&cons.lock);
80100ae6:	83 ec 0c             	sub    $0xc,%esp
80100ae9:	68 a0 b5 10 80       	push   $0x8010b5a0
80100aee:	e8 63 44 00 00       	call   80104f56 <acquire>
80100af3:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < n; i++)
80100af6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80100afd:	eb 21                	jmp    80100b20 <consolewrite+0x4e>
    consputc(buf[i] & 0xff);
80100aff:	8b 55 f4             	mov    -0xc(%ebp),%edx
80100b02:	8b 45 0c             	mov    0xc(%ebp),%eax
80100b05:	01 d0                	add    %edx,%eax
80100b07:	0f b6 00             	movzbl (%eax),%eax
80100b0a:	0f be c0             	movsbl %al,%eax
80100b0d:	0f b6 c0             	movzbl %al,%eax
80100b10:	83 ec 0c             	sub    $0xc,%esp
80100b13:	50                   	push   %eax
80100b14:	e8 ac fc ff ff       	call   801007c5 <consputc>
80100b19:	83 c4 10             	add    $0x10,%esp
{
  int i;

  iunlock(ip);
  acquire(&cons.lock);
  for(i = 0; i < n; i++)
80100b1c:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100b20:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100b23:	3b 45 10             	cmp    0x10(%ebp),%eax
80100b26:	7c d7                	jl     80100aff <consolewrite+0x2d>
    consputc(buf[i] & 0xff);
  release(&cons.lock);
80100b28:	83 ec 0c             	sub    $0xc,%esp
80100b2b:	68 a0 b5 10 80       	push   $0x8010b5a0
80100b30:	e8 8f 44 00 00       	call   80104fc4 <release>
80100b35:	83 c4 10             	add    $0x10,%esp
  ilock(ip);
80100b38:	83 ec 0c             	sub    $0xc,%esp
80100b3b:	ff 75 08             	pushl  0x8(%ebp)
80100b3e:	e8 cd 0e 00 00       	call   80101a10 <ilock>
80100b43:	83 c4 10             	add    $0x10,%esp

  return n;
80100b46:	8b 45 10             	mov    0x10(%ebp),%eax
}
80100b49:	c9                   	leave  
80100b4a:	c3                   	ret    

80100b4b <consoleinit>:

void
consoleinit(void)
{
80100b4b:	55                   	push   %ebp
80100b4c:	89 e5                	mov    %esp,%ebp
80100b4e:	83 ec 08             	sub    $0x8,%esp
  initlock(&cons.lock, "console");
80100b51:	83 ec 08             	sub    $0x8,%esp
80100b54:	68 ee 84 10 80       	push   $0x801084ee
80100b59:	68 a0 b5 10 80       	push   $0x8010b5a0
80100b5e:	e8 d1 43 00 00       	call   80104f34 <initlock>
80100b63:	83 c4 10             	add    $0x10,%esp

  devsw[CONSOLE].write = consolewrite;
80100b66:	c7 05 ec 19 11 80 d2 	movl   $0x80100ad2,0x801119ec
80100b6d:	0a 10 80 
  devsw[CONSOLE].read = consoleread;
80100b70:	c7 05 e8 19 11 80 c2 	movl   $0x801009c2,0x801119e8
80100b77:	09 10 80 
  cons.locking = 1;
80100b7a:	c7 05 d4 b5 10 80 01 	movl   $0x1,0x8010b5d4
80100b81:	00 00 00 

  ioapicenable(IRQ_KBD, 0);
80100b84:	83 ec 08             	sub    $0x8,%esp
80100b87:	6a 00                	push   $0x0
80100b89:	6a 01                	push   $0x1
80100b8b:	e8 94 1f 00 00       	call   80102b24 <ioapicenable>
80100b90:	83 c4 10             	add    $0x10,%esp
}
80100b93:	90                   	nop
80100b94:	c9                   	leave  
80100b95:	c3                   	ret    

80100b96 <exec>:
#include "x86.h"
#include "elf.h"

int
exec(char *path, char **argv)
{
80100b96:	55                   	push   %ebp
80100b97:	89 e5                	mov    %esp,%ebp
80100b99:	81 ec 18 01 00 00    	sub    $0x118,%esp
  uint argc, sz, sp, ustack[3+MAXARG+1];
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pde_t *pgdir, *oldpgdir;
  struct proc *curproc = myproc();
80100b9f:	e8 e4 36 00 00       	call   80104288 <myproc>
80100ba4:	89 45 d0             	mov    %eax,-0x30(%ebp)

  begin_op();
80100ba7:	e8 89 29 00 00       	call   80103535 <begin_op>

  if((ip = namei(path)) == 0){
80100bac:	83 ec 0c             	sub    $0xc,%esp
80100baf:	ff 75 08             	pushl  0x8(%ebp)
80100bb2:	e8 99 19 00 00       	call   80102550 <namei>
80100bb7:	83 c4 10             	add    $0x10,%esp
80100bba:	89 45 d8             	mov    %eax,-0x28(%ebp)
80100bbd:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100bc1:	75 1f                	jne    80100be2 <exec+0x4c>
    end_op();
80100bc3:	e8 f9 29 00 00       	call   801035c1 <end_op>
    cprintf("exec: fail\n");
80100bc8:	83 ec 0c             	sub    $0xc,%esp
80100bcb:	68 f6 84 10 80       	push   $0x801084f6
80100bd0:	e8 2b f8 ff ff       	call   80100400 <cprintf>
80100bd5:	83 c4 10             	add    $0x10,%esp
    return -1;
80100bd8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80100bdd:	e9 f1 03 00 00       	jmp    80100fd3 <exec+0x43d>
  }
  ilock(ip);
80100be2:	83 ec 0c             	sub    $0xc,%esp
80100be5:	ff 75 d8             	pushl  -0x28(%ebp)
80100be8:	e8 23 0e 00 00       	call   80101a10 <ilock>
80100bed:	83 c4 10             	add    $0x10,%esp
  pgdir = 0;
80100bf0:	c7 45 d4 00 00 00 00 	movl   $0x0,-0x2c(%ebp)

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
80100bf7:	6a 34                	push   $0x34
80100bf9:	6a 00                	push   $0x0
80100bfb:	8d 85 08 ff ff ff    	lea    -0xf8(%ebp),%eax
80100c01:	50                   	push   %eax
80100c02:	ff 75 d8             	pushl  -0x28(%ebp)
80100c05:	e8 f7 12 00 00       	call   80101f01 <readi>
80100c0a:	83 c4 10             	add    $0x10,%esp
80100c0d:	83 f8 34             	cmp    $0x34,%eax
80100c10:	0f 85 66 03 00 00    	jne    80100f7c <exec+0x3e6>
    goto bad;
  if(elf.magic != ELF_MAGIC)
80100c16:	8b 85 08 ff ff ff    	mov    -0xf8(%ebp),%eax
80100c1c:	3d 7f 45 4c 46       	cmp    $0x464c457f,%eax
80100c21:	0f 85 58 03 00 00    	jne    80100f7f <exec+0x3e9>
    goto bad;

  if((pgdir = setupkvm()) == 0)
80100c27:	e8 11 70 00 00       	call   80107c3d <setupkvm>
80100c2c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80100c2f:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100c33:	0f 84 49 03 00 00    	je     80100f82 <exec+0x3ec>
    goto bad;

  // Load program into memory.
  sz = 0;
80100c39:	c7 45 e0 00 00 00 00 	movl   $0x0,-0x20(%ebp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100c40:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
80100c47:	8b 85 24 ff ff ff    	mov    -0xdc(%ebp),%eax
80100c4d:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100c50:	e9 de 00 00 00       	jmp    80100d33 <exec+0x19d>
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
80100c55:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100c58:	6a 20                	push   $0x20
80100c5a:	50                   	push   %eax
80100c5b:	8d 85 e8 fe ff ff    	lea    -0x118(%ebp),%eax
80100c61:	50                   	push   %eax
80100c62:	ff 75 d8             	pushl  -0x28(%ebp)
80100c65:	e8 97 12 00 00       	call   80101f01 <readi>
80100c6a:	83 c4 10             	add    $0x10,%esp
80100c6d:	83 f8 20             	cmp    $0x20,%eax
80100c70:	0f 85 0f 03 00 00    	jne    80100f85 <exec+0x3ef>
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
80100c76:	8b 85 e8 fe ff ff    	mov    -0x118(%ebp),%eax
80100c7c:	83 f8 01             	cmp    $0x1,%eax
80100c7f:	0f 85 a0 00 00 00    	jne    80100d25 <exec+0x18f>
      continue;
    if(ph.memsz < ph.filesz)
80100c85:	8b 95 fc fe ff ff    	mov    -0x104(%ebp),%edx
80100c8b:	8b 85 f8 fe ff ff    	mov    -0x108(%ebp),%eax
80100c91:	39 c2                	cmp    %eax,%edx
80100c93:	0f 82 ef 02 00 00    	jb     80100f88 <exec+0x3f2>
      goto bad;
    if(ph.vaddr + ph.memsz < ph.vaddr)
80100c99:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100c9f:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100ca5:	01 c2                	add    %eax,%edx
80100ca7:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100cad:	39 c2                	cmp    %eax,%edx
80100caf:	0f 82 d6 02 00 00    	jb     80100f8b <exec+0x3f5>
      goto bad;
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
80100cb5:	8b 95 f0 fe ff ff    	mov    -0x110(%ebp),%edx
80100cbb:	8b 85 fc fe ff ff    	mov    -0x104(%ebp),%eax
80100cc1:	01 d0                	add    %edx,%eax
80100cc3:	83 ec 04             	sub    $0x4,%esp
80100cc6:	50                   	push   %eax
80100cc7:	ff 75 e0             	pushl  -0x20(%ebp)
80100cca:	ff 75 d4             	pushl  -0x2c(%ebp)
80100ccd:	e8 10 73 00 00       	call   80107fe2 <allocuvm>
80100cd2:	83 c4 10             	add    $0x10,%esp
80100cd5:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100cd8:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100cdc:	0f 84 ac 02 00 00    	je     80100f8e <exec+0x3f8>
      goto bad;
    if(ph.vaddr % PGSIZE != 0)
80100ce2:	8b 85 f0 fe ff ff    	mov    -0x110(%ebp),%eax
80100ce8:	25 ff 0f 00 00       	and    $0xfff,%eax
80100ced:	85 c0                	test   %eax,%eax
80100cef:	0f 85 9c 02 00 00    	jne    80100f91 <exec+0x3fb>
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
80100cf5:	8b 95 f8 fe ff ff    	mov    -0x108(%ebp),%edx
80100cfb:	8b 85 ec fe ff ff    	mov    -0x114(%ebp),%eax
80100d01:	8b 8d f0 fe ff ff    	mov    -0x110(%ebp),%ecx
80100d07:	83 ec 0c             	sub    $0xc,%esp
80100d0a:	52                   	push   %edx
80100d0b:	50                   	push   %eax
80100d0c:	ff 75 d8             	pushl  -0x28(%ebp)
80100d0f:	51                   	push   %ecx
80100d10:	ff 75 d4             	pushl  -0x2c(%ebp)
80100d13:	e8 fd 71 00 00       	call   80107f15 <loaduvm>
80100d18:	83 c4 20             	add    $0x20,%esp
80100d1b:	85 c0                	test   %eax,%eax
80100d1d:	0f 88 71 02 00 00    	js     80100f94 <exec+0x3fe>
80100d23:	eb 01                	jmp    80100d26 <exec+0x190>
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
    if(ph.type != ELF_PROG_LOAD)
      continue;
80100d25:	90                   	nop
  if((pgdir = setupkvm()) == 0)
    goto bad;

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
80100d26:	83 45 ec 01          	addl   $0x1,-0x14(%ebp)
80100d2a:	8b 45 e8             	mov    -0x18(%ebp),%eax
80100d2d:	83 c0 20             	add    $0x20,%eax
80100d30:	89 45 e8             	mov    %eax,-0x18(%ebp)
80100d33:	0f b7 85 34 ff ff ff 	movzwl -0xcc(%ebp),%eax
80100d3a:	0f b7 c0             	movzwl %ax,%eax
80100d3d:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80100d40:	0f 8f 0f ff ff ff    	jg     80100c55 <exec+0xbf>
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
  }
  iunlockput(ip);
80100d46:	83 ec 0c             	sub    $0xc,%esp
80100d49:	ff 75 d8             	pushl  -0x28(%ebp)
80100d4c:	e8 f0 0e 00 00       	call   80101c41 <iunlockput>
80100d51:	83 c4 10             	add    $0x10,%esp
  end_op();
80100d54:	e8 68 28 00 00       	call   801035c1 <end_op>
  ip = 0;
80100d59:	c7 45 d8 00 00 00 00 	movl   $0x0,-0x28(%ebp)

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
80100d60:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d63:	05 ff 0f 00 00       	add    $0xfff,%eax
80100d68:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80100d6d:	89 45 e0             	mov    %eax,-0x20(%ebp)
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
80100d70:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d73:	05 00 20 00 00       	add    $0x2000,%eax
80100d78:	83 ec 04             	sub    $0x4,%esp
80100d7b:	50                   	push   %eax
80100d7c:	ff 75 e0             	pushl  -0x20(%ebp)
80100d7f:	ff 75 d4             	pushl  -0x2c(%ebp)
80100d82:	e8 5b 72 00 00       	call   80107fe2 <allocuvm>
80100d87:	83 c4 10             	add    $0x10,%esp
80100d8a:	89 45 e0             	mov    %eax,-0x20(%ebp)
80100d8d:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80100d91:	0f 84 00 02 00 00    	je     80100f97 <exec+0x401>
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
80100d97:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100d9a:	2d 00 20 00 00       	sub    $0x2000,%eax
80100d9f:	83 ec 08             	sub    $0x8,%esp
80100da2:	50                   	push   %eax
80100da3:	ff 75 d4             	pushl  -0x2c(%ebp)
80100da6:	e8 99 74 00 00       	call   80108244 <clearpteu>
80100dab:	83 c4 10             	add    $0x10,%esp
  sp = sz;
80100dae:	8b 45 e0             	mov    -0x20(%ebp),%eax
80100db1:	89 45 dc             	mov    %eax,-0x24(%ebp)

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100db4:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80100dbb:	e9 96 00 00 00       	jmp    80100e56 <exec+0x2c0>
    if(argc >= MAXARG)
80100dc0:	83 7d e4 1f          	cmpl   $0x1f,-0x1c(%ebp)
80100dc4:	0f 87 d0 01 00 00    	ja     80100f9a <exec+0x404>
      goto bad;
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
80100dca:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dcd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100dd4:	8b 45 0c             	mov    0xc(%ebp),%eax
80100dd7:	01 d0                	add    %edx,%eax
80100dd9:	8b 00                	mov    (%eax),%eax
80100ddb:	83 ec 0c             	sub    $0xc,%esp
80100dde:	50                   	push   %eax
80100ddf:	e8 36 46 00 00       	call   8010541a <strlen>
80100de4:	83 c4 10             	add    $0x10,%esp
80100de7:	89 c2                	mov    %eax,%edx
80100de9:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100dec:	29 d0                	sub    %edx,%eax
80100dee:	83 e8 01             	sub    $0x1,%eax
80100df1:	83 e0 fc             	and    $0xfffffffc,%eax
80100df4:	89 45 dc             	mov    %eax,-0x24(%ebp)
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
80100df7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100dfa:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e01:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e04:	01 d0                	add    %edx,%eax
80100e06:	8b 00                	mov    (%eax),%eax
80100e08:	83 ec 0c             	sub    $0xc,%esp
80100e0b:	50                   	push   %eax
80100e0c:	e8 09 46 00 00       	call   8010541a <strlen>
80100e11:	83 c4 10             	add    $0x10,%esp
80100e14:	83 c0 01             	add    $0x1,%eax
80100e17:	89 c1                	mov    %eax,%ecx
80100e19:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e1c:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e23:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e26:	01 d0                	add    %edx,%eax
80100e28:	8b 00                	mov    (%eax),%eax
80100e2a:	51                   	push   %ecx
80100e2b:	50                   	push   %eax
80100e2c:	ff 75 dc             	pushl  -0x24(%ebp)
80100e2f:	ff 75 d4             	pushl  -0x2c(%ebp)
80100e32:	e8 ac 75 00 00       	call   801083e3 <copyout>
80100e37:	83 c4 10             	add    $0x10,%esp
80100e3a:	85 c0                	test   %eax,%eax
80100e3c:	0f 88 5b 01 00 00    	js     80100f9d <exec+0x407>
      goto bad;
    ustack[3+argc] = sp;
80100e42:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e45:	8d 50 03             	lea    0x3(%eax),%edx
80100e48:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100e4b:	89 84 95 3c ff ff ff 	mov    %eax,-0xc4(%ebp,%edx,4)
    goto bad;
  clearpteu(pgdir, (char*)(sz - 2*PGSIZE));
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
80100e52:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80100e56:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e59:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100e60:	8b 45 0c             	mov    0xc(%ebp),%eax
80100e63:	01 d0                	add    %edx,%eax
80100e65:	8b 00                	mov    (%eax),%eax
80100e67:	85 c0                	test   %eax,%eax
80100e69:	0f 85 51 ff ff ff    	jne    80100dc0 <exec+0x22a>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
    ustack[3+argc] = sp;
  }
  ustack[3+argc] = 0;
80100e6f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e72:	83 c0 03             	add    $0x3,%eax
80100e75:	c7 84 85 3c ff ff ff 	movl   $0x0,-0xc4(%ebp,%eax,4)
80100e7c:	00 00 00 00 

  ustack[0] = 0xffffffff;  // fake return PC
80100e80:	c7 85 3c ff ff ff ff 	movl   $0xffffffff,-0xc4(%ebp)
80100e87:	ff ff ff 
  ustack[1] = argc;
80100e8a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e8d:	89 85 40 ff ff ff    	mov    %eax,-0xc0(%ebp)
  ustack[2] = sp - (argc+1)*4;  // argv pointer
80100e93:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100e96:	83 c0 01             	add    $0x1,%eax
80100e99:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80100ea0:	8b 45 dc             	mov    -0x24(%ebp),%eax
80100ea3:	29 d0                	sub    %edx,%eax
80100ea5:	89 85 44 ff ff ff    	mov    %eax,-0xbc(%ebp)

  sp -= (3+argc+1) * 4;
80100eab:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eae:	83 c0 04             	add    $0x4,%eax
80100eb1:	c1 e0 02             	shl    $0x2,%eax
80100eb4:	29 45 dc             	sub    %eax,-0x24(%ebp)
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
80100eb7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80100eba:	83 c0 04             	add    $0x4,%eax
80100ebd:	c1 e0 02             	shl    $0x2,%eax
80100ec0:	50                   	push   %eax
80100ec1:	8d 85 3c ff ff ff    	lea    -0xc4(%ebp),%eax
80100ec7:	50                   	push   %eax
80100ec8:	ff 75 dc             	pushl  -0x24(%ebp)
80100ecb:	ff 75 d4             	pushl  -0x2c(%ebp)
80100ece:	e8 10 75 00 00       	call   801083e3 <copyout>
80100ed3:	83 c4 10             	add    $0x10,%esp
80100ed6:	85 c0                	test   %eax,%eax
80100ed8:	0f 88 c2 00 00 00    	js     80100fa0 <exec+0x40a>
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100ede:	8b 45 08             	mov    0x8(%ebp),%eax
80100ee1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80100ee4:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ee7:	89 45 f0             	mov    %eax,-0x10(%ebp)
80100eea:	eb 17                	jmp    80100f03 <exec+0x36d>
    if(*s == '/')
80100eec:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100eef:	0f b6 00             	movzbl (%eax),%eax
80100ef2:	3c 2f                	cmp    $0x2f,%al
80100ef4:	75 09                	jne    80100eff <exec+0x369>
      last = s+1;
80100ef6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100ef9:	83 c0 01             	add    $0x1,%eax
80100efc:	89 45 f0             	mov    %eax,-0x10(%ebp)
  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;

  // Save program name for debugging.
  for(last=s=path; *s; s++)
80100eff:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80100f03:	8b 45 f4             	mov    -0xc(%ebp),%eax
80100f06:	0f b6 00             	movzbl (%eax),%eax
80100f09:	84 c0                	test   %al,%al
80100f0b:	75 df                	jne    80100eec <exec+0x356>
    if(*s == '/')
      last = s+1;
  safestrcpy(curproc->name, last, sizeof(curproc->name));
80100f0d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f10:	83 c0 6c             	add    $0x6c,%eax
80100f13:	83 ec 04             	sub    $0x4,%esp
80100f16:	6a 10                	push   $0x10
80100f18:	ff 75 f0             	pushl  -0x10(%ebp)
80100f1b:	50                   	push   %eax
80100f1c:	e8 af 44 00 00       	call   801053d0 <safestrcpy>
80100f21:	83 c4 10             	add    $0x10,%esp

  // Commit to the user image.
  oldpgdir = curproc->pgdir;
80100f24:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f27:	8b 40 04             	mov    0x4(%eax),%eax
80100f2a:	89 45 cc             	mov    %eax,-0x34(%ebp)
  curproc->pgdir = pgdir;
80100f2d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f30:	8b 55 d4             	mov    -0x2c(%ebp),%edx
80100f33:	89 50 04             	mov    %edx,0x4(%eax)
  curproc->sz = sz;
80100f36:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f39:	8b 55 e0             	mov    -0x20(%ebp),%edx
80100f3c:	89 10                	mov    %edx,(%eax)
  curproc->tf->eip = elf.entry;  // main
80100f3e:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f41:	8b 40 18             	mov    0x18(%eax),%eax
80100f44:	8b 95 20 ff ff ff    	mov    -0xe0(%ebp),%edx
80100f4a:	89 50 38             	mov    %edx,0x38(%eax)
  curproc->tf->esp = sp;
80100f4d:	8b 45 d0             	mov    -0x30(%ebp),%eax
80100f50:	8b 40 18             	mov    0x18(%eax),%eax
80100f53:	8b 55 dc             	mov    -0x24(%ebp),%edx
80100f56:	89 50 44             	mov    %edx,0x44(%eax)
  switchuvm(curproc);
80100f59:	83 ec 0c             	sub    $0xc,%esp
80100f5c:	ff 75 d0             	pushl  -0x30(%ebp)
80100f5f:	e8 a3 6d 00 00       	call   80107d07 <switchuvm>
80100f64:	83 c4 10             	add    $0x10,%esp
  freevm(oldpgdir);
80100f67:	83 ec 0c             	sub    $0xc,%esp
80100f6a:	ff 75 cc             	pushl  -0x34(%ebp)
80100f6d:	e8 39 72 00 00       	call   801081ab <freevm>
80100f72:	83 c4 10             	add    $0x10,%esp
  return 0;
80100f75:	b8 00 00 00 00       	mov    $0x0,%eax
80100f7a:	eb 57                	jmp    80100fd3 <exec+0x43d>
  ilock(ip);
  pgdir = 0;

  // Check ELF header
  if(readi(ip, (char*)&elf, 0, sizeof(elf)) != sizeof(elf))
    goto bad;
80100f7c:	90                   	nop
80100f7d:	eb 22                	jmp    80100fa1 <exec+0x40b>
  if(elf.magic != ELF_MAGIC)
    goto bad;
80100f7f:	90                   	nop
80100f80:	eb 1f                	jmp    80100fa1 <exec+0x40b>

  if((pgdir = setupkvm()) == 0)
    goto bad;
80100f82:	90                   	nop
80100f83:	eb 1c                	jmp    80100fa1 <exec+0x40b>

  // Load program into memory.
  sz = 0;
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    if(readi(ip, (char*)&ph, off, sizeof(ph)) != sizeof(ph))
      goto bad;
80100f85:	90                   	nop
80100f86:	eb 19                	jmp    80100fa1 <exec+0x40b>
    if(ph.type != ELF_PROG_LOAD)
      continue;
    if(ph.memsz < ph.filesz)
      goto bad;
80100f88:	90                   	nop
80100f89:	eb 16                	jmp    80100fa1 <exec+0x40b>
    if(ph.vaddr + ph.memsz < ph.vaddr)
      goto bad;
80100f8b:	90                   	nop
80100f8c:	eb 13                	jmp    80100fa1 <exec+0x40b>
    if((sz = allocuvm(pgdir, sz, ph.vaddr + ph.memsz)) == 0)
      goto bad;
80100f8e:	90                   	nop
80100f8f:	eb 10                	jmp    80100fa1 <exec+0x40b>
    if(ph.vaddr % PGSIZE != 0)
      goto bad;
80100f91:	90                   	nop
80100f92:	eb 0d                	jmp    80100fa1 <exec+0x40b>
    if(loaduvm(pgdir, (char*)ph.vaddr, ip, ph.off, ph.filesz) < 0)
      goto bad;
80100f94:	90                   	nop
80100f95:	eb 0a                	jmp    80100fa1 <exec+0x40b>

  // Allocate two pages at the next page boundary.
  // Make the first inaccessible.  Use the second as the user stack.
  sz = PGROUNDUP(sz);
  if((sz = allocuvm(pgdir, sz, sz + 2*PGSIZE)) == 0)
    goto bad;
80100f97:	90                   	nop
80100f98:	eb 07                	jmp    80100fa1 <exec+0x40b>
  sp = sz;

  // Push argument strings, prepare rest of stack in ustack.
  for(argc = 0; argv[argc]; argc++) {
    if(argc >= MAXARG)
      goto bad;
80100f9a:	90                   	nop
80100f9b:	eb 04                	jmp    80100fa1 <exec+0x40b>
    sp = (sp - (strlen(argv[argc]) + 1)) & ~3;
    if(copyout(pgdir, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
      goto bad;
80100f9d:	90                   	nop
80100f9e:	eb 01                	jmp    80100fa1 <exec+0x40b>
  ustack[1] = argc;
  ustack[2] = sp - (argc+1)*4;  // argv pointer

  sp -= (3+argc+1) * 4;
  if(copyout(pgdir, sp, ustack, (3+argc+1)*4) < 0)
    goto bad;
80100fa0:	90                   	nop
  switchuvm(curproc);
  freevm(oldpgdir);
  return 0;

 bad:
  if(pgdir)
80100fa1:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
80100fa5:	74 0e                	je     80100fb5 <exec+0x41f>
    freevm(pgdir);
80100fa7:	83 ec 0c             	sub    $0xc,%esp
80100faa:	ff 75 d4             	pushl  -0x2c(%ebp)
80100fad:	e8 f9 71 00 00       	call   801081ab <freevm>
80100fb2:	83 c4 10             	add    $0x10,%esp
  if(ip){
80100fb5:	83 7d d8 00          	cmpl   $0x0,-0x28(%ebp)
80100fb9:	74 13                	je     80100fce <exec+0x438>
    iunlockput(ip);
80100fbb:	83 ec 0c             	sub    $0xc,%esp
80100fbe:	ff 75 d8             	pushl  -0x28(%ebp)
80100fc1:	e8 7b 0c 00 00       	call   80101c41 <iunlockput>
80100fc6:	83 c4 10             	add    $0x10,%esp
    end_op();
80100fc9:	e8 f3 25 00 00       	call   801035c1 <end_op>
  }
  return -1;
80100fce:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80100fd3:	c9                   	leave  
80100fd4:	c3                   	ret    

80100fd5 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
80100fd5:	55                   	push   %ebp
80100fd6:	89 e5                	mov    %esp,%ebp
80100fd8:	83 ec 08             	sub    $0x8,%esp
  initlock(&ftable.lock, "ftable");
80100fdb:	83 ec 08             	sub    $0x8,%esp
80100fde:	68 02 85 10 80       	push   $0x80108502
80100fe3:	68 40 10 11 80       	push   $0x80111040
80100fe8:	e8 47 3f 00 00       	call   80104f34 <initlock>
80100fed:	83 c4 10             	add    $0x10,%esp
}
80100ff0:	90                   	nop
80100ff1:	c9                   	leave  
80100ff2:	c3                   	ret    

80100ff3 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
80100ff3:	55                   	push   %ebp
80100ff4:	89 e5                	mov    %esp,%ebp
80100ff6:	83 ec 18             	sub    $0x18,%esp
  struct file *f;

  acquire(&ftable.lock);
80100ff9:	83 ec 0c             	sub    $0xc,%esp
80100ffc:	68 40 10 11 80       	push   $0x80111040
80101001:	e8 50 3f 00 00       	call   80104f56 <acquire>
80101006:	83 c4 10             	add    $0x10,%esp
  for(f = ftable.file; f < ftable.file + NFILE; f++){
80101009:	c7 45 f4 74 10 11 80 	movl   $0x80111074,-0xc(%ebp)
80101010:	eb 2d                	jmp    8010103f <filealloc+0x4c>
    if(f->ref == 0){
80101012:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101015:	8b 40 04             	mov    0x4(%eax),%eax
80101018:	85 c0                	test   %eax,%eax
8010101a:	75 1f                	jne    8010103b <filealloc+0x48>
      f->ref = 1;
8010101c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010101f:	c7 40 04 01 00 00 00 	movl   $0x1,0x4(%eax)
      release(&ftable.lock);
80101026:	83 ec 0c             	sub    $0xc,%esp
80101029:	68 40 10 11 80       	push   $0x80111040
8010102e:	e8 91 3f 00 00       	call   80104fc4 <release>
80101033:	83 c4 10             	add    $0x10,%esp
      return f;
80101036:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101039:	eb 23                	jmp    8010105e <filealloc+0x6b>
filealloc(void)
{
  struct file *f;

  acquire(&ftable.lock);
  for(f = ftable.file; f < ftable.file + NFILE; f++){
8010103b:	83 45 f4 18          	addl   $0x18,-0xc(%ebp)
8010103f:	b8 d4 19 11 80       	mov    $0x801119d4,%eax
80101044:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80101047:	72 c9                	jb     80101012 <filealloc+0x1f>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
80101049:	83 ec 0c             	sub    $0xc,%esp
8010104c:	68 40 10 11 80       	push   $0x80111040
80101051:	e8 6e 3f 00 00       	call   80104fc4 <release>
80101056:	83 c4 10             	add    $0x10,%esp
  return 0;
80101059:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010105e:	c9                   	leave  
8010105f:	c3                   	ret    

80101060 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
80101060:	55                   	push   %ebp
80101061:	89 e5                	mov    %esp,%ebp
80101063:	83 ec 08             	sub    $0x8,%esp
  acquire(&ftable.lock);
80101066:	83 ec 0c             	sub    $0xc,%esp
80101069:	68 40 10 11 80       	push   $0x80111040
8010106e:	e8 e3 3e 00 00       	call   80104f56 <acquire>
80101073:	83 c4 10             	add    $0x10,%esp
  if(f->ref < 1)
80101076:	8b 45 08             	mov    0x8(%ebp),%eax
80101079:	8b 40 04             	mov    0x4(%eax),%eax
8010107c:	85 c0                	test   %eax,%eax
8010107e:	7f 0d                	jg     8010108d <filedup+0x2d>
    panic("filedup");
80101080:	83 ec 0c             	sub    $0xc,%esp
80101083:	68 09 85 10 80       	push   $0x80108509
80101088:	e8 13 f5 ff ff       	call   801005a0 <panic>
  f->ref++;
8010108d:	8b 45 08             	mov    0x8(%ebp),%eax
80101090:	8b 40 04             	mov    0x4(%eax),%eax
80101093:	8d 50 01             	lea    0x1(%eax),%edx
80101096:	8b 45 08             	mov    0x8(%ebp),%eax
80101099:	89 50 04             	mov    %edx,0x4(%eax)
  release(&ftable.lock);
8010109c:	83 ec 0c             	sub    $0xc,%esp
8010109f:	68 40 10 11 80       	push   $0x80111040
801010a4:	e8 1b 3f 00 00       	call   80104fc4 <release>
801010a9:	83 c4 10             	add    $0x10,%esp
  return f;
801010ac:	8b 45 08             	mov    0x8(%ebp),%eax
}
801010af:	c9                   	leave  
801010b0:	c3                   	ret    

801010b1 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
801010b1:	55                   	push   %ebp
801010b2:	89 e5                	mov    %esp,%ebp
801010b4:	83 ec 28             	sub    $0x28,%esp
  struct file ff;

  acquire(&ftable.lock);
801010b7:	83 ec 0c             	sub    $0xc,%esp
801010ba:	68 40 10 11 80       	push   $0x80111040
801010bf:	e8 92 3e 00 00       	call   80104f56 <acquire>
801010c4:	83 c4 10             	add    $0x10,%esp
  if(f->ref < 1)
801010c7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ca:	8b 40 04             	mov    0x4(%eax),%eax
801010cd:	85 c0                	test   %eax,%eax
801010cf:	7f 0d                	jg     801010de <fileclose+0x2d>
    panic("fileclose");
801010d1:	83 ec 0c             	sub    $0xc,%esp
801010d4:	68 11 85 10 80       	push   $0x80108511
801010d9:	e8 c2 f4 ff ff       	call   801005a0 <panic>
  if(--f->ref > 0){
801010de:	8b 45 08             	mov    0x8(%ebp),%eax
801010e1:	8b 40 04             	mov    0x4(%eax),%eax
801010e4:	8d 50 ff             	lea    -0x1(%eax),%edx
801010e7:	8b 45 08             	mov    0x8(%ebp),%eax
801010ea:	89 50 04             	mov    %edx,0x4(%eax)
801010ed:	8b 45 08             	mov    0x8(%ebp),%eax
801010f0:	8b 40 04             	mov    0x4(%eax),%eax
801010f3:	85 c0                	test   %eax,%eax
801010f5:	7e 15                	jle    8010110c <fileclose+0x5b>
    release(&ftable.lock);
801010f7:	83 ec 0c             	sub    $0xc,%esp
801010fa:	68 40 10 11 80       	push   $0x80111040
801010ff:	e8 c0 3e 00 00       	call   80104fc4 <release>
80101104:	83 c4 10             	add    $0x10,%esp
80101107:	e9 8b 00 00 00       	jmp    80101197 <fileclose+0xe6>
    return;
  }
  ff = *f;
8010110c:	8b 45 08             	mov    0x8(%ebp),%eax
8010110f:	8b 10                	mov    (%eax),%edx
80101111:	89 55 e0             	mov    %edx,-0x20(%ebp)
80101114:	8b 50 04             	mov    0x4(%eax),%edx
80101117:	89 55 e4             	mov    %edx,-0x1c(%ebp)
8010111a:	8b 50 08             	mov    0x8(%eax),%edx
8010111d:	89 55 e8             	mov    %edx,-0x18(%ebp)
80101120:	8b 50 0c             	mov    0xc(%eax),%edx
80101123:	89 55 ec             	mov    %edx,-0x14(%ebp)
80101126:	8b 50 10             	mov    0x10(%eax),%edx
80101129:	89 55 f0             	mov    %edx,-0x10(%ebp)
8010112c:	8b 40 14             	mov    0x14(%eax),%eax
8010112f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  f->ref = 0;
80101132:	8b 45 08             	mov    0x8(%ebp),%eax
80101135:	c7 40 04 00 00 00 00 	movl   $0x0,0x4(%eax)
  f->type = FD_NONE;
8010113c:	8b 45 08             	mov    0x8(%ebp),%eax
8010113f:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  release(&ftable.lock);
80101145:	83 ec 0c             	sub    $0xc,%esp
80101148:	68 40 10 11 80       	push   $0x80111040
8010114d:	e8 72 3e 00 00       	call   80104fc4 <release>
80101152:	83 c4 10             	add    $0x10,%esp

  if(ff.type == FD_PIPE)
80101155:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101158:	83 f8 01             	cmp    $0x1,%eax
8010115b:	75 19                	jne    80101176 <fileclose+0xc5>
    pipeclose(ff.pipe, ff.writable);
8010115d:	0f b6 45 e9          	movzbl -0x17(%ebp),%eax
80101161:	0f be d0             	movsbl %al,%edx
80101164:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101167:	83 ec 08             	sub    $0x8,%esp
8010116a:	52                   	push   %edx
8010116b:	50                   	push   %eax
8010116c:	e8 a1 2d 00 00       	call   80103f12 <pipeclose>
80101171:	83 c4 10             	add    $0x10,%esp
80101174:	eb 21                	jmp    80101197 <fileclose+0xe6>
  else if(ff.type == FD_INODE){
80101176:	8b 45 e0             	mov    -0x20(%ebp),%eax
80101179:	83 f8 02             	cmp    $0x2,%eax
8010117c:	75 19                	jne    80101197 <fileclose+0xe6>
    begin_op();
8010117e:	e8 b2 23 00 00       	call   80103535 <begin_op>
    iput(ff.ip);
80101183:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101186:	83 ec 0c             	sub    $0xc,%esp
80101189:	50                   	push   %eax
8010118a:	e8 e2 09 00 00       	call   80101b71 <iput>
8010118f:	83 c4 10             	add    $0x10,%esp
    end_op();
80101192:	e8 2a 24 00 00       	call   801035c1 <end_op>
  }
}
80101197:	c9                   	leave  
80101198:	c3                   	ret    

80101199 <filestat>:

// Get metadata about file f.
int
filestat(struct file *f, struct stat *st)
{
80101199:	55                   	push   %ebp
8010119a:	89 e5                	mov    %esp,%ebp
8010119c:	83 ec 08             	sub    $0x8,%esp
  if(f->type == FD_INODE){
8010119f:	8b 45 08             	mov    0x8(%ebp),%eax
801011a2:	8b 00                	mov    (%eax),%eax
801011a4:	83 f8 02             	cmp    $0x2,%eax
801011a7:	75 40                	jne    801011e9 <filestat+0x50>
    ilock(f->ip);
801011a9:	8b 45 08             	mov    0x8(%ebp),%eax
801011ac:	8b 40 10             	mov    0x10(%eax),%eax
801011af:	83 ec 0c             	sub    $0xc,%esp
801011b2:	50                   	push   %eax
801011b3:	e8 58 08 00 00       	call   80101a10 <ilock>
801011b8:	83 c4 10             	add    $0x10,%esp
    stati(f->ip, st);
801011bb:	8b 45 08             	mov    0x8(%ebp),%eax
801011be:	8b 40 10             	mov    0x10(%eax),%eax
801011c1:	83 ec 08             	sub    $0x8,%esp
801011c4:	ff 75 0c             	pushl  0xc(%ebp)
801011c7:	50                   	push   %eax
801011c8:	e8 ee 0c 00 00       	call   80101ebb <stati>
801011cd:	83 c4 10             	add    $0x10,%esp
    iunlock(f->ip);
801011d0:	8b 45 08             	mov    0x8(%ebp),%eax
801011d3:	8b 40 10             	mov    0x10(%eax),%eax
801011d6:	83 ec 0c             	sub    $0xc,%esp
801011d9:	50                   	push   %eax
801011da:	e8 44 09 00 00       	call   80101b23 <iunlock>
801011df:	83 c4 10             	add    $0x10,%esp
    return 0;
801011e2:	b8 00 00 00 00       	mov    $0x0,%eax
801011e7:	eb 05                	jmp    801011ee <filestat+0x55>
  }
  return -1;
801011e9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801011ee:	c9                   	leave  
801011ef:	c3                   	ret    

801011f0 <fileread>:

// Read from file f.
int
fileread(struct file *f, char *addr, int n)
{
801011f0:	55                   	push   %ebp
801011f1:	89 e5                	mov    %esp,%ebp
801011f3:	83 ec 18             	sub    $0x18,%esp
  int r;

  if(f->readable == 0)
801011f6:	8b 45 08             	mov    0x8(%ebp),%eax
801011f9:	0f b6 40 08          	movzbl 0x8(%eax),%eax
801011fd:	84 c0                	test   %al,%al
801011ff:	75 0a                	jne    8010120b <fileread+0x1b>
    return -1;
80101201:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101206:	e9 9b 00 00 00       	jmp    801012a6 <fileread+0xb6>
  if(f->type == FD_PIPE)
8010120b:	8b 45 08             	mov    0x8(%ebp),%eax
8010120e:	8b 00                	mov    (%eax),%eax
80101210:	83 f8 01             	cmp    $0x1,%eax
80101213:	75 1a                	jne    8010122f <fileread+0x3f>
    return piperead(f->pipe, addr, n);
80101215:	8b 45 08             	mov    0x8(%ebp),%eax
80101218:	8b 40 0c             	mov    0xc(%eax),%eax
8010121b:	83 ec 04             	sub    $0x4,%esp
8010121e:	ff 75 10             	pushl  0x10(%ebp)
80101221:	ff 75 0c             	pushl  0xc(%ebp)
80101224:	50                   	push   %eax
80101225:	e8 8f 2e 00 00       	call   801040b9 <piperead>
8010122a:	83 c4 10             	add    $0x10,%esp
8010122d:	eb 77                	jmp    801012a6 <fileread+0xb6>
  if(f->type == FD_INODE){
8010122f:	8b 45 08             	mov    0x8(%ebp),%eax
80101232:	8b 00                	mov    (%eax),%eax
80101234:	83 f8 02             	cmp    $0x2,%eax
80101237:	75 60                	jne    80101299 <fileread+0xa9>
    ilock(f->ip);
80101239:	8b 45 08             	mov    0x8(%ebp),%eax
8010123c:	8b 40 10             	mov    0x10(%eax),%eax
8010123f:	83 ec 0c             	sub    $0xc,%esp
80101242:	50                   	push   %eax
80101243:	e8 c8 07 00 00       	call   80101a10 <ilock>
80101248:	83 c4 10             	add    $0x10,%esp
    if((r = readi(f->ip, addr, f->off, n)) > 0)
8010124b:	8b 4d 10             	mov    0x10(%ebp),%ecx
8010124e:	8b 45 08             	mov    0x8(%ebp),%eax
80101251:	8b 50 14             	mov    0x14(%eax),%edx
80101254:	8b 45 08             	mov    0x8(%ebp),%eax
80101257:	8b 40 10             	mov    0x10(%eax),%eax
8010125a:	51                   	push   %ecx
8010125b:	52                   	push   %edx
8010125c:	ff 75 0c             	pushl  0xc(%ebp)
8010125f:	50                   	push   %eax
80101260:	e8 9c 0c 00 00       	call   80101f01 <readi>
80101265:	83 c4 10             	add    $0x10,%esp
80101268:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010126b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010126f:	7e 11                	jle    80101282 <fileread+0x92>
      f->off += r;
80101271:	8b 45 08             	mov    0x8(%ebp),%eax
80101274:	8b 50 14             	mov    0x14(%eax),%edx
80101277:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010127a:	01 c2                	add    %eax,%edx
8010127c:	8b 45 08             	mov    0x8(%ebp),%eax
8010127f:	89 50 14             	mov    %edx,0x14(%eax)
    iunlock(f->ip);
80101282:	8b 45 08             	mov    0x8(%ebp),%eax
80101285:	8b 40 10             	mov    0x10(%eax),%eax
80101288:	83 ec 0c             	sub    $0xc,%esp
8010128b:	50                   	push   %eax
8010128c:	e8 92 08 00 00       	call   80101b23 <iunlock>
80101291:	83 c4 10             	add    $0x10,%esp
    return r;
80101294:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101297:	eb 0d                	jmp    801012a6 <fileread+0xb6>
  }
  panic("fileread");
80101299:	83 ec 0c             	sub    $0xc,%esp
8010129c:	68 1b 85 10 80       	push   $0x8010851b
801012a1:	e8 fa f2 ff ff       	call   801005a0 <panic>
}
801012a6:	c9                   	leave  
801012a7:	c3                   	ret    

801012a8 <filewrite>:

//PAGEBREAK!
// Write to file f.
int
filewrite(struct file *f, char *addr, int n)
{
801012a8:	55                   	push   %ebp
801012a9:	89 e5                	mov    %esp,%ebp
801012ab:	53                   	push   %ebx
801012ac:	83 ec 14             	sub    $0x14,%esp
  int r;

  if(f->writable == 0)
801012af:	8b 45 08             	mov    0x8(%ebp),%eax
801012b2:	0f b6 40 09          	movzbl 0x9(%eax),%eax
801012b6:	84 c0                	test   %al,%al
801012b8:	75 0a                	jne    801012c4 <filewrite+0x1c>
    return -1;
801012ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801012bf:	e9 1b 01 00 00       	jmp    801013df <filewrite+0x137>
  if(f->type == FD_PIPE)
801012c4:	8b 45 08             	mov    0x8(%ebp),%eax
801012c7:	8b 00                	mov    (%eax),%eax
801012c9:	83 f8 01             	cmp    $0x1,%eax
801012cc:	75 1d                	jne    801012eb <filewrite+0x43>
    return pipewrite(f->pipe, addr, n);
801012ce:	8b 45 08             	mov    0x8(%ebp),%eax
801012d1:	8b 40 0c             	mov    0xc(%eax),%eax
801012d4:	83 ec 04             	sub    $0x4,%esp
801012d7:	ff 75 10             	pushl  0x10(%ebp)
801012da:	ff 75 0c             	pushl  0xc(%ebp)
801012dd:	50                   	push   %eax
801012de:	e8 d9 2c 00 00       	call   80103fbc <pipewrite>
801012e3:	83 c4 10             	add    $0x10,%esp
801012e6:	e9 f4 00 00 00       	jmp    801013df <filewrite+0x137>
  if(f->type == FD_INODE){
801012eb:	8b 45 08             	mov    0x8(%ebp),%eax
801012ee:	8b 00                	mov    (%eax),%eax
801012f0:	83 f8 02             	cmp    $0x2,%eax
801012f3:	0f 85 d9 00 00 00    	jne    801013d2 <filewrite+0x12a>
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
801012f9:	c7 45 ec 00 1a 00 00 	movl   $0x1a00,-0x14(%ebp)
    int i = 0;
80101300:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    while(i < n){
80101307:	e9 a3 00 00 00       	jmp    801013af <filewrite+0x107>
      int n1 = n - i;
8010130c:	8b 45 10             	mov    0x10(%ebp),%eax
8010130f:	2b 45 f4             	sub    -0xc(%ebp),%eax
80101312:	89 45 f0             	mov    %eax,-0x10(%ebp)
      if(n1 > max)
80101315:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101318:	3b 45 ec             	cmp    -0x14(%ebp),%eax
8010131b:	7e 06                	jle    80101323 <filewrite+0x7b>
        n1 = max;
8010131d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101320:	89 45 f0             	mov    %eax,-0x10(%ebp)

      begin_op();
80101323:	e8 0d 22 00 00       	call   80103535 <begin_op>
      ilock(f->ip);
80101328:	8b 45 08             	mov    0x8(%ebp),%eax
8010132b:	8b 40 10             	mov    0x10(%eax),%eax
8010132e:	83 ec 0c             	sub    $0xc,%esp
80101331:	50                   	push   %eax
80101332:	e8 d9 06 00 00       	call   80101a10 <ilock>
80101337:	83 c4 10             	add    $0x10,%esp
      if ((r = writei(f->ip, addr + i, f->off, n1)) > 0)
8010133a:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010133d:	8b 45 08             	mov    0x8(%ebp),%eax
80101340:	8b 50 14             	mov    0x14(%eax),%edx
80101343:	8b 5d f4             	mov    -0xc(%ebp),%ebx
80101346:	8b 45 0c             	mov    0xc(%ebp),%eax
80101349:	01 c3                	add    %eax,%ebx
8010134b:	8b 45 08             	mov    0x8(%ebp),%eax
8010134e:	8b 40 10             	mov    0x10(%eax),%eax
80101351:	51                   	push   %ecx
80101352:	52                   	push   %edx
80101353:	53                   	push   %ebx
80101354:	50                   	push   %eax
80101355:	e8 fe 0c 00 00       	call   80102058 <writei>
8010135a:	83 c4 10             	add    $0x10,%esp
8010135d:	89 45 e8             	mov    %eax,-0x18(%ebp)
80101360:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101364:	7e 11                	jle    80101377 <filewrite+0xcf>
        f->off += r;
80101366:	8b 45 08             	mov    0x8(%ebp),%eax
80101369:	8b 50 14             	mov    0x14(%eax),%edx
8010136c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010136f:	01 c2                	add    %eax,%edx
80101371:	8b 45 08             	mov    0x8(%ebp),%eax
80101374:	89 50 14             	mov    %edx,0x14(%eax)
      iunlock(f->ip);
80101377:	8b 45 08             	mov    0x8(%ebp),%eax
8010137a:	8b 40 10             	mov    0x10(%eax),%eax
8010137d:	83 ec 0c             	sub    $0xc,%esp
80101380:	50                   	push   %eax
80101381:	e8 9d 07 00 00       	call   80101b23 <iunlock>
80101386:	83 c4 10             	add    $0x10,%esp
      end_op();
80101389:	e8 33 22 00 00       	call   801035c1 <end_op>

      if(r < 0)
8010138e:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80101392:	78 29                	js     801013bd <filewrite+0x115>
        break;
      if(r != n1)
80101394:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101397:	3b 45 f0             	cmp    -0x10(%ebp),%eax
8010139a:	74 0d                	je     801013a9 <filewrite+0x101>
        panic("short filewrite");
8010139c:	83 ec 0c             	sub    $0xc,%esp
8010139f:	68 24 85 10 80       	push   $0x80108524
801013a4:	e8 f7 f1 ff ff       	call   801005a0 <panic>
      i += r;
801013a9:	8b 45 e8             	mov    -0x18(%ebp),%eax
801013ac:	01 45 f4             	add    %eax,-0xc(%ebp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((LOGSIZE-1-1-2) / 2) * 512;
    int i = 0;
    while(i < n){
801013af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013b2:	3b 45 10             	cmp    0x10(%ebp),%eax
801013b5:	0f 8c 51 ff ff ff    	jl     8010130c <filewrite+0x64>
801013bb:	eb 01                	jmp    801013be <filewrite+0x116>
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r < 0)
        break;
801013bd:	90                   	nop
      if(r != n1)
        panic("short filewrite");
      i += r;
    }
    return i == n ? n : -1;
801013be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801013c1:	3b 45 10             	cmp    0x10(%ebp),%eax
801013c4:	75 05                	jne    801013cb <filewrite+0x123>
801013c6:	8b 45 10             	mov    0x10(%ebp),%eax
801013c9:	eb 14                	jmp    801013df <filewrite+0x137>
801013cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801013d0:	eb 0d                	jmp    801013df <filewrite+0x137>
  }
  panic("filewrite");
801013d2:	83 ec 0c             	sub    $0xc,%esp
801013d5:	68 34 85 10 80       	push   $0x80108534
801013da:	e8 c1 f1 ff ff       	call   801005a0 <panic>
}
801013df:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801013e2:	c9                   	leave  
801013e3:	c3                   	ret    

801013e4 <readsb>:
struct superblock sb; 

// Read the super block.
void
readsb(int dev, struct superblock *sb)
{
801013e4:	55                   	push   %ebp
801013e5:	89 e5                	mov    %esp,%ebp
801013e7:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;

  bp = bread(dev, 1);
801013ea:	8b 45 08             	mov    0x8(%ebp),%eax
801013ed:	83 ec 08             	sub    $0x8,%esp
801013f0:	6a 01                	push   $0x1
801013f2:	50                   	push   %eax
801013f3:	e8 d6 ed ff ff       	call   801001ce <bread>
801013f8:	83 c4 10             	add    $0x10,%esp
801013fb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memmove(sb, bp->data, sizeof(*sb));
801013fe:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101401:	83 c0 5c             	add    $0x5c,%eax
80101404:	83 ec 04             	sub    $0x4,%esp
80101407:	6a 1c                	push   $0x1c
80101409:	50                   	push   %eax
8010140a:	ff 75 0c             	pushl  0xc(%ebp)
8010140d:	e8 7a 3e 00 00       	call   8010528c <memmove>
80101412:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
80101415:	83 ec 0c             	sub    $0xc,%esp
80101418:	ff 75 f4             	pushl  -0xc(%ebp)
8010141b:	e8 30 ee ff ff       	call   80100250 <brelse>
80101420:	83 c4 10             	add    $0x10,%esp
}
80101423:	90                   	nop
80101424:	c9                   	leave  
80101425:	c3                   	ret    

80101426 <bzero>:

// Zero a block.
static void
bzero(int dev, int bno)
{
80101426:	55                   	push   %ebp
80101427:	89 e5                	mov    %esp,%ebp
80101429:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;

  bp = bread(dev, bno);
8010142c:	8b 55 0c             	mov    0xc(%ebp),%edx
8010142f:	8b 45 08             	mov    0x8(%ebp),%eax
80101432:	83 ec 08             	sub    $0x8,%esp
80101435:	52                   	push   %edx
80101436:	50                   	push   %eax
80101437:	e8 92 ed ff ff       	call   801001ce <bread>
8010143c:	83 c4 10             	add    $0x10,%esp
8010143f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(bp->data, 0, BSIZE);
80101442:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101445:	83 c0 5c             	add    $0x5c,%eax
80101448:	83 ec 04             	sub    $0x4,%esp
8010144b:	68 00 02 00 00       	push   $0x200
80101450:	6a 00                	push   $0x0
80101452:	50                   	push   %eax
80101453:	e8 75 3d 00 00       	call   801051cd <memset>
80101458:	83 c4 10             	add    $0x10,%esp
  log_write(bp);
8010145b:	83 ec 0c             	sub    $0xc,%esp
8010145e:	ff 75 f4             	pushl  -0xc(%ebp)
80101461:	e8 07 23 00 00       	call   8010376d <log_write>
80101466:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
80101469:	83 ec 0c             	sub    $0xc,%esp
8010146c:	ff 75 f4             	pushl  -0xc(%ebp)
8010146f:	e8 dc ed ff ff       	call   80100250 <brelse>
80101474:	83 c4 10             	add    $0x10,%esp
}
80101477:	90                   	nop
80101478:	c9                   	leave  
80101479:	c3                   	ret    

8010147a <balloc>:
// Blocks.

// Allocate a zeroed disk block.
static uint
balloc(uint dev)
{
8010147a:	55                   	push   %ebp
8010147b:	89 e5                	mov    %esp,%ebp
8010147d:	83 ec 18             	sub    $0x18,%esp
  int b, bi, m;
  struct buf *bp;

  bp = 0;
80101480:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  for(b = 0; b < sb.size; b += BPB){
80101487:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
8010148e:	e9 13 01 00 00       	jmp    801015a6 <balloc+0x12c>
    bp = bread(dev, BBLOCK(b, sb));
80101493:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101496:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
8010149c:	85 c0                	test   %eax,%eax
8010149e:	0f 48 c2             	cmovs  %edx,%eax
801014a1:	c1 f8 0c             	sar    $0xc,%eax
801014a4:	89 c2                	mov    %eax,%edx
801014a6:	a1 58 1a 11 80       	mov    0x80111a58,%eax
801014ab:	01 d0                	add    %edx,%eax
801014ad:	83 ec 08             	sub    $0x8,%esp
801014b0:	50                   	push   %eax
801014b1:	ff 75 08             	pushl  0x8(%ebp)
801014b4:	e8 15 ed ff ff       	call   801001ce <bread>
801014b9:	83 c4 10             	add    $0x10,%esp
801014bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
801014bf:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
801014c6:	e9 a6 00 00 00       	jmp    80101571 <balloc+0xf7>
      m = 1 << (bi % 8);
801014cb:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014ce:	99                   	cltd   
801014cf:	c1 ea 1d             	shr    $0x1d,%edx
801014d2:	01 d0                	add    %edx,%eax
801014d4:	83 e0 07             	and    $0x7,%eax
801014d7:	29 d0                	sub    %edx,%eax
801014d9:	ba 01 00 00 00       	mov    $0x1,%edx
801014de:	89 c1                	mov    %eax,%ecx
801014e0:	d3 e2                	shl    %cl,%edx
801014e2:	89 d0                	mov    %edx,%eax
801014e4:	89 45 e8             	mov    %eax,-0x18(%ebp)
      if((bp->data[bi/8] & m) == 0){  // Is block free?
801014e7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801014ea:	8d 50 07             	lea    0x7(%eax),%edx
801014ed:	85 c0                	test   %eax,%eax
801014ef:	0f 48 c2             	cmovs  %edx,%eax
801014f2:	c1 f8 03             	sar    $0x3,%eax
801014f5:	89 c2                	mov    %eax,%edx
801014f7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801014fa:	0f b6 44 10 5c       	movzbl 0x5c(%eax,%edx,1),%eax
801014ff:	0f b6 c0             	movzbl %al,%eax
80101502:	23 45 e8             	and    -0x18(%ebp),%eax
80101505:	85 c0                	test   %eax,%eax
80101507:	75 64                	jne    8010156d <balloc+0xf3>
        bp->data[bi/8] |= m;  // Mark block in use.
80101509:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010150c:	8d 50 07             	lea    0x7(%eax),%edx
8010150f:	85 c0                	test   %eax,%eax
80101511:	0f 48 c2             	cmovs  %edx,%eax
80101514:	c1 f8 03             	sar    $0x3,%eax
80101517:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010151a:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
8010151f:	89 d1                	mov    %edx,%ecx
80101521:	8b 55 e8             	mov    -0x18(%ebp),%edx
80101524:	09 ca                	or     %ecx,%edx
80101526:	89 d1                	mov    %edx,%ecx
80101528:	8b 55 ec             	mov    -0x14(%ebp),%edx
8010152b:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
        log_write(bp);
8010152f:	83 ec 0c             	sub    $0xc,%esp
80101532:	ff 75 ec             	pushl  -0x14(%ebp)
80101535:	e8 33 22 00 00       	call   8010376d <log_write>
8010153a:	83 c4 10             	add    $0x10,%esp
        brelse(bp);
8010153d:	83 ec 0c             	sub    $0xc,%esp
80101540:	ff 75 ec             	pushl  -0x14(%ebp)
80101543:	e8 08 ed ff ff       	call   80100250 <brelse>
80101548:	83 c4 10             	add    $0x10,%esp
        bzero(dev, b + bi);
8010154b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010154e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101551:	01 c2                	add    %eax,%edx
80101553:	8b 45 08             	mov    0x8(%ebp),%eax
80101556:	83 ec 08             	sub    $0x8,%esp
80101559:	52                   	push   %edx
8010155a:	50                   	push   %eax
8010155b:	e8 c6 fe ff ff       	call   80101426 <bzero>
80101560:	83 c4 10             	add    $0x10,%esp
        return b + bi;
80101563:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101566:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101569:	01 d0                	add    %edx,%eax
8010156b:	eb 57                	jmp    801015c4 <balloc+0x14a>
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
    bp = bread(dev, BBLOCK(b, sb));
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
8010156d:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101571:	81 7d f0 ff 0f 00 00 	cmpl   $0xfff,-0x10(%ebp)
80101578:	7f 17                	jg     80101591 <balloc+0x117>
8010157a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010157d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101580:	01 d0                	add    %edx,%eax
80101582:	89 c2                	mov    %eax,%edx
80101584:	a1 40 1a 11 80       	mov    0x80111a40,%eax
80101589:	39 c2                	cmp    %eax,%edx
8010158b:	0f 82 3a ff ff ff    	jb     801014cb <balloc+0x51>
        brelse(bp);
        bzero(dev, b + bi);
        return b + bi;
      }
    }
    brelse(bp);
80101591:	83 ec 0c             	sub    $0xc,%esp
80101594:	ff 75 ec             	pushl  -0x14(%ebp)
80101597:	e8 b4 ec ff ff       	call   80100250 <brelse>
8010159c:	83 c4 10             	add    $0x10,%esp
{
  int b, bi, m;
  struct buf *bp;

  bp = 0;
  for(b = 0; b < sb.size; b += BPB){
8010159f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801015a6:	8b 15 40 1a 11 80    	mov    0x80111a40,%edx
801015ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801015af:	39 c2                	cmp    %eax,%edx
801015b1:	0f 87 dc fe ff ff    	ja     80101493 <balloc+0x19>
        return b + bi;
      }
    }
    brelse(bp);
  }
  panic("balloc: out of blocks");
801015b7:	83 ec 0c             	sub    $0xc,%esp
801015ba:	68 40 85 10 80       	push   $0x80108540
801015bf:	e8 dc ef ff ff       	call   801005a0 <panic>
}
801015c4:	c9                   	leave  
801015c5:	c3                   	ret    

801015c6 <bfree>:

// Free a disk block.
static void
bfree(int dev, uint b)
{
801015c6:	55                   	push   %ebp
801015c7:	89 e5                	mov    %esp,%ebp
801015c9:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  int bi, m;

  readsb(dev, &sb);
801015cc:	83 ec 08             	sub    $0x8,%esp
801015cf:	68 40 1a 11 80       	push   $0x80111a40
801015d4:	ff 75 08             	pushl  0x8(%ebp)
801015d7:	e8 08 fe ff ff       	call   801013e4 <readsb>
801015dc:	83 c4 10             	add    $0x10,%esp
  bp = bread(dev, BBLOCK(b, sb));
801015df:	8b 45 0c             	mov    0xc(%ebp),%eax
801015e2:	c1 e8 0c             	shr    $0xc,%eax
801015e5:	89 c2                	mov    %eax,%edx
801015e7:	a1 58 1a 11 80       	mov    0x80111a58,%eax
801015ec:	01 c2                	add    %eax,%edx
801015ee:	8b 45 08             	mov    0x8(%ebp),%eax
801015f1:	83 ec 08             	sub    $0x8,%esp
801015f4:	52                   	push   %edx
801015f5:	50                   	push   %eax
801015f6:	e8 d3 eb ff ff       	call   801001ce <bread>
801015fb:	83 c4 10             	add    $0x10,%esp
801015fe:	89 45 f4             	mov    %eax,-0xc(%ebp)
  bi = b % BPB;
80101601:	8b 45 0c             	mov    0xc(%ebp),%eax
80101604:	25 ff 0f 00 00       	and    $0xfff,%eax
80101609:	89 45 f0             	mov    %eax,-0x10(%ebp)
  m = 1 << (bi % 8);
8010160c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010160f:	99                   	cltd   
80101610:	c1 ea 1d             	shr    $0x1d,%edx
80101613:	01 d0                	add    %edx,%eax
80101615:	83 e0 07             	and    $0x7,%eax
80101618:	29 d0                	sub    %edx,%eax
8010161a:	ba 01 00 00 00       	mov    $0x1,%edx
8010161f:	89 c1                	mov    %eax,%ecx
80101621:	d3 e2                	shl    %cl,%edx
80101623:	89 d0                	mov    %edx,%eax
80101625:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((bp->data[bi/8] & m) == 0)
80101628:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010162b:	8d 50 07             	lea    0x7(%eax),%edx
8010162e:	85 c0                	test   %eax,%eax
80101630:	0f 48 c2             	cmovs  %edx,%eax
80101633:	c1 f8 03             	sar    $0x3,%eax
80101636:	89 c2                	mov    %eax,%edx
80101638:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010163b:	0f b6 44 10 5c       	movzbl 0x5c(%eax,%edx,1),%eax
80101640:	0f b6 c0             	movzbl %al,%eax
80101643:	23 45 ec             	and    -0x14(%ebp),%eax
80101646:	85 c0                	test   %eax,%eax
80101648:	75 0d                	jne    80101657 <bfree+0x91>
    panic("freeing free block");
8010164a:	83 ec 0c             	sub    $0xc,%esp
8010164d:	68 56 85 10 80       	push   $0x80108556
80101652:	e8 49 ef ff ff       	call   801005a0 <panic>
  bp->data[bi/8] &= ~m;
80101657:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010165a:	8d 50 07             	lea    0x7(%eax),%edx
8010165d:	85 c0                	test   %eax,%eax
8010165f:	0f 48 c2             	cmovs  %edx,%eax
80101662:	c1 f8 03             	sar    $0x3,%eax
80101665:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101668:	0f b6 54 02 5c       	movzbl 0x5c(%edx,%eax,1),%edx
8010166d:	89 d1                	mov    %edx,%ecx
8010166f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80101672:	f7 d2                	not    %edx
80101674:	21 ca                	and    %ecx,%edx
80101676:	89 d1                	mov    %edx,%ecx
80101678:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010167b:	88 4c 02 5c          	mov    %cl,0x5c(%edx,%eax,1)
  log_write(bp);
8010167f:	83 ec 0c             	sub    $0xc,%esp
80101682:	ff 75 f4             	pushl  -0xc(%ebp)
80101685:	e8 e3 20 00 00       	call   8010376d <log_write>
8010168a:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
8010168d:	83 ec 0c             	sub    $0xc,%esp
80101690:	ff 75 f4             	pushl  -0xc(%ebp)
80101693:	e8 b8 eb ff ff       	call   80100250 <brelse>
80101698:	83 c4 10             	add    $0x10,%esp
}
8010169b:	90                   	nop
8010169c:	c9                   	leave  
8010169d:	c3                   	ret    

8010169e <iinit>:
  struct inode inode[NINODE];
} icache;

void
iinit(int dev)
{
8010169e:	55                   	push   %ebp
8010169f:	89 e5                	mov    %esp,%ebp
801016a1:	57                   	push   %edi
801016a2:	56                   	push   %esi
801016a3:	53                   	push   %ebx
801016a4:	83 ec 2c             	sub    $0x2c,%esp
  int i = 0;
801016a7:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
  
  initlock(&icache.lock, "icache");
801016ae:	83 ec 08             	sub    $0x8,%esp
801016b1:	68 69 85 10 80       	push   $0x80108569
801016b6:	68 60 1a 11 80       	push   $0x80111a60
801016bb:	e8 74 38 00 00       	call   80104f34 <initlock>
801016c0:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NINODE; i++) {
801016c3:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
801016ca:	eb 2d                	jmp    801016f9 <iinit+0x5b>
    initsleeplock(&icache.inode[i].lock, "inode");
801016cc:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801016cf:	89 d0                	mov    %edx,%eax
801016d1:	c1 e0 03             	shl    $0x3,%eax
801016d4:	01 d0                	add    %edx,%eax
801016d6:	c1 e0 04             	shl    $0x4,%eax
801016d9:	83 c0 30             	add    $0x30,%eax
801016dc:	05 60 1a 11 80       	add    $0x80111a60,%eax
801016e1:	83 c0 10             	add    $0x10,%eax
801016e4:	83 ec 08             	sub    $0x8,%esp
801016e7:	68 70 85 10 80       	push   $0x80108570
801016ec:	50                   	push   %eax
801016ed:	e8 e5 36 00 00       	call   80104dd7 <initsleeplock>
801016f2:	83 c4 10             	add    $0x10,%esp
iinit(int dev)
{
  int i = 0;
  
  initlock(&icache.lock, "icache");
  for(i = 0; i < NINODE; i++) {
801016f5:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
801016f9:	83 7d e4 31          	cmpl   $0x31,-0x1c(%ebp)
801016fd:	7e cd                	jle    801016cc <iinit+0x2e>
    initsleeplock(&icache.inode[i].lock, "inode");
  }

  readsb(dev, &sb);
801016ff:	83 ec 08             	sub    $0x8,%esp
80101702:	68 40 1a 11 80       	push   $0x80111a40
80101707:	ff 75 08             	pushl  0x8(%ebp)
8010170a:	e8 d5 fc ff ff       	call   801013e4 <readsb>
8010170f:	83 c4 10             	add    $0x10,%esp
  cprintf("sb: size %d nblocks %d ninodes %d nlog %d logstart %d\
80101712:	a1 58 1a 11 80       	mov    0x80111a58,%eax
80101717:	89 45 d4             	mov    %eax,-0x2c(%ebp)
8010171a:	8b 3d 54 1a 11 80    	mov    0x80111a54,%edi
80101720:	8b 35 50 1a 11 80    	mov    0x80111a50,%esi
80101726:	8b 1d 4c 1a 11 80    	mov    0x80111a4c,%ebx
8010172c:	8b 0d 48 1a 11 80    	mov    0x80111a48,%ecx
80101732:	8b 15 44 1a 11 80    	mov    0x80111a44,%edx
80101738:	a1 40 1a 11 80       	mov    0x80111a40,%eax
8010173d:	ff 75 d4             	pushl  -0x2c(%ebp)
80101740:	57                   	push   %edi
80101741:	56                   	push   %esi
80101742:	53                   	push   %ebx
80101743:	51                   	push   %ecx
80101744:	52                   	push   %edx
80101745:	50                   	push   %eax
80101746:	68 78 85 10 80       	push   $0x80108578
8010174b:	e8 b0 ec ff ff       	call   80100400 <cprintf>
80101750:	83 c4 20             	add    $0x20,%esp
 inodestart %d bmap start %d\n", sb.size, sb.nblocks,
          sb.ninodes, sb.nlog, sb.logstart, sb.inodestart,
          sb.bmapstart);
}
80101753:	90                   	nop
80101754:	8d 65 f4             	lea    -0xc(%ebp),%esp
80101757:	5b                   	pop    %ebx
80101758:	5e                   	pop    %esi
80101759:	5f                   	pop    %edi
8010175a:	5d                   	pop    %ebp
8010175b:	c3                   	ret    

8010175c <ialloc>:
// Allocate an inode on device dev.
// Mark it as allocated by  giving it type type.
// Returns an unlocked but allocated and referenced inode.
struct inode*
ialloc(uint dev, short type)
{
8010175c:	55                   	push   %ebp
8010175d:	89 e5                	mov    %esp,%ebp
8010175f:	83 ec 28             	sub    $0x28,%esp
80101762:	8b 45 0c             	mov    0xc(%ebp),%eax
80101765:	66 89 45 e4          	mov    %ax,-0x1c(%ebp)
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
80101769:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
80101770:	e9 9e 00 00 00       	jmp    80101813 <ialloc+0xb7>
    bp = bread(dev, IBLOCK(inum, sb));
80101775:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101778:	c1 e8 03             	shr    $0x3,%eax
8010177b:	89 c2                	mov    %eax,%edx
8010177d:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101782:	01 d0                	add    %edx,%eax
80101784:	83 ec 08             	sub    $0x8,%esp
80101787:	50                   	push   %eax
80101788:	ff 75 08             	pushl  0x8(%ebp)
8010178b:	e8 3e ea ff ff       	call   801001ce <bread>
80101790:	83 c4 10             	add    $0x10,%esp
80101793:	89 45 f0             	mov    %eax,-0x10(%ebp)
    dip = (struct dinode*)bp->data + inum%IPB;
80101796:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101799:	8d 50 5c             	lea    0x5c(%eax),%edx
8010179c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010179f:	83 e0 07             	and    $0x7,%eax
801017a2:	c1 e0 06             	shl    $0x6,%eax
801017a5:	01 d0                	add    %edx,%eax
801017a7:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if(dip->type == 0){  // a free inode
801017aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017ad:	0f b7 00             	movzwl (%eax),%eax
801017b0:	66 85 c0             	test   %ax,%ax
801017b3:	75 4c                	jne    80101801 <ialloc+0xa5>
      memset(dip, 0, sizeof(*dip));
801017b5:	83 ec 04             	sub    $0x4,%esp
801017b8:	6a 40                	push   $0x40
801017ba:	6a 00                	push   $0x0
801017bc:	ff 75 ec             	pushl  -0x14(%ebp)
801017bf:	e8 09 3a 00 00       	call   801051cd <memset>
801017c4:	83 c4 10             	add    $0x10,%esp
      dip->type = type;
801017c7:	8b 45 ec             	mov    -0x14(%ebp),%eax
801017ca:	0f b7 55 e4          	movzwl -0x1c(%ebp),%edx
801017ce:	66 89 10             	mov    %dx,(%eax)
      log_write(bp);   // mark it allocated on the disk
801017d1:	83 ec 0c             	sub    $0xc,%esp
801017d4:	ff 75 f0             	pushl  -0x10(%ebp)
801017d7:	e8 91 1f 00 00       	call   8010376d <log_write>
801017dc:	83 c4 10             	add    $0x10,%esp
      brelse(bp);
801017df:	83 ec 0c             	sub    $0xc,%esp
801017e2:	ff 75 f0             	pushl  -0x10(%ebp)
801017e5:	e8 66 ea ff ff       	call   80100250 <brelse>
801017ea:	83 c4 10             	add    $0x10,%esp
      return iget(dev, inum);
801017ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801017f0:	83 ec 08             	sub    $0x8,%esp
801017f3:	50                   	push   %eax
801017f4:	ff 75 08             	pushl  0x8(%ebp)
801017f7:	e8 f8 00 00 00       	call   801018f4 <iget>
801017fc:	83 c4 10             	add    $0x10,%esp
801017ff:	eb 30                	jmp    80101831 <ialloc+0xd5>
    }
    brelse(bp);
80101801:	83 ec 0c             	sub    $0xc,%esp
80101804:	ff 75 f0             	pushl  -0x10(%ebp)
80101807:	e8 44 ea ff ff       	call   80100250 <brelse>
8010180c:	83 c4 10             	add    $0x10,%esp
{
  int inum;
  struct buf *bp;
  struct dinode *dip;

  for(inum = 1; inum < sb.ninodes; inum++){
8010180f:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101813:	8b 15 48 1a 11 80    	mov    0x80111a48,%edx
80101819:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010181c:	39 c2                	cmp    %eax,%edx
8010181e:	0f 87 51 ff ff ff    	ja     80101775 <ialloc+0x19>
      brelse(bp);
      return iget(dev, inum);
    }
    brelse(bp);
  }
  panic("ialloc: no inodes");
80101824:	83 ec 0c             	sub    $0xc,%esp
80101827:	68 cb 85 10 80       	push   $0x801085cb
8010182c:	e8 6f ed ff ff       	call   801005a0 <panic>
}
80101831:	c9                   	leave  
80101832:	c3                   	ret    

80101833 <iupdate>:
// Must be called after every change to an ip->xxx field
// that lives on disk, since i-node cache is write-through.
// Caller must hold ip->lock.
void
iupdate(struct inode *ip)
{
80101833:	55                   	push   %ebp
80101834:	89 e5                	mov    %esp,%ebp
80101836:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  struct dinode *dip;

  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101839:	8b 45 08             	mov    0x8(%ebp),%eax
8010183c:	8b 40 04             	mov    0x4(%eax),%eax
8010183f:	c1 e8 03             	shr    $0x3,%eax
80101842:	89 c2                	mov    %eax,%edx
80101844:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101849:	01 c2                	add    %eax,%edx
8010184b:	8b 45 08             	mov    0x8(%ebp),%eax
8010184e:	8b 00                	mov    (%eax),%eax
80101850:	83 ec 08             	sub    $0x8,%esp
80101853:	52                   	push   %edx
80101854:	50                   	push   %eax
80101855:	e8 74 e9 ff ff       	call   801001ce <bread>
8010185a:	83 c4 10             	add    $0x10,%esp
8010185d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  dip = (struct dinode*)bp->data + ip->inum%IPB;
80101860:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101863:	8d 50 5c             	lea    0x5c(%eax),%edx
80101866:	8b 45 08             	mov    0x8(%ebp),%eax
80101869:	8b 40 04             	mov    0x4(%eax),%eax
8010186c:	83 e0 07             	and    $0x7,%eax
8010186f:	c1 e0 06             	shl    $0x6,%eax
80101872:	01 d0                	add    %edx,%eax
80101874:	89 45 f0             	mov    %eax,-0x10(%ebp)
  dip->type = ip->type;
80101877:	8b 45 08             	mov    0x8(%ebp),%eax
8010187a:	0f b7 50 50          	movzwl 0x50(%eax),%edx
8010187e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101881:	66 89 10             	mov    %dx,(%eax)
  dip->major = ip->major;
80101884:	8b 45 08             	mov    0x8(%ebp),%eax
80101887:	0f b7 50 52          	movzwl 0x52(%eax),%edx
8010188b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010188e:	66 89 50 02          	mov    %dx,0x2(%eax)
  dip->minor = ip->minor;
80101892:	8b 45 08             	mov    0x8(%ebp),%eax
80101895:	0f b7 50 54          	movzwl 0x54(%eax),%edx
80101899:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010189c:	66 89 50 04          	mov    %dx,0x4(%eax)
  dip->nlink = ip->nlink;
801018a0:	8b 45 08             	mov    0x8(%ebp),%eax
801018a3:	0f b7 50 56          	movzwl 0x56(%eax),%edx
801018a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018aa:	66 89 50 06          	mov    %dx,0x6(%eax)
  dip->size = ip->size;
801018ae:	8b 45 08             	mov    0x8(%ebp),%eax
801018b1:	8b 50 58             	mov    0x58(%eax),%edx
801018b4:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018b7:	89 50 08             	mov    %edx,0x8(%eax)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
801018ba:	8b 45 08             	mov    0x8(%ebp),%eax
801018bd:	8d 50 5c             	lea    0x5c(%eax),%edx
801018c0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801018c3:	83 c0 0c             	add    $0xc,%eax
801018c6:	83 ec 04             	sub    $0x4,%esp
801018c9:	6a 34                	push   $0x34
801018cb:	52                   	push   %edx
801018cc:	50                   	push   %eax
801018cd:	e8 ba 39 00 00       	call   8010528c <memmove>
801018d2:	83 c4 10             	add    $0x10,%esp
  log_write(bp);
801018d5:	83 ec 0c             	sub    $0xc,%esp
801018d8:	ff 75 f4             	pushl  -0xc(%ebp)
801018db:	e8 8d 1e 00 00       	call   8010376d <log_write>
801018e0:	83 c4 10             	add    $0x10,%esp
  brelse(bp);
801018e3:	83 ec 0c             	sub    $0xc,%esp
801018e6:	ff 75 f4             	pushl  -0xc(%ebp)
801018e9:	e8 62 e9 ff ff       	call   80100250 <brelse>
801018ee:	83 c4 10             	add    $0x10,%esp
}
801018f1:	90                   	nop
801018f2:	c9                   	leave  
801018f3:	c3                   	ret    

801018f4 <iget>:
// Find the inode with number inum on device dev
// and return the in-memory copy. Does not lock
// the inode and does not read it from disk.
static struct inode*
iget(uint dev, uint inum)
{
801018f4:	55                   	push   %ebp
801018f5:	89 e5                	mov    %esp,%ebp
801018f7:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip, *empty;

  acquire(&icache.lock);
801018fa:	83 ec 0c             	sub    $0xc,%esp
801018fd:	68 60 1a 11 80       	push   $0x80111a60
80101902:	e8 4f 36 00 00       	call   80104f56 <acquire>
80101907:	83 c4 10             	add    $0x10,%esp

  // Is the inode already cached?
  empty = 0;
8010190a:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101911:	c7 45 f4 94 1a 11 80 	movl   $0x80111a94,-0xc(%ebp)
80101918:	eb 60                	jmp    8010197a <iget+0x86>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
8010191a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010191d:	8b 40 08             	mov    0x8(%eax),%eax
80101920:	85 c0                	test   %eax,%eax
80101922:	7e 39                	jle    8010195d <iget+0x69>
80101924:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101927:	8b 00                	mov    (%eax),%eax
80101929:	3b 45 08             	cmp    0x8(%ebp),%eax
8010192c:	75 2f                	jne    8010195d <iget+0x69>
8010192e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101931:	8b 40 04             	mov    0x4(%eax),%eax
80101934:	3b 45 0c             	cmp    0xc(%ebp),%eax
80101937:	75 24                	jne    8010195d <iget+0x69>
      ip->ref++;
80101939:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010193c:	8b 40 08             	mov    0x8(%eax),%eax
8010193f:	8d 50 01             	lea    0x1(%eax),%edx
80101942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101945:	89 50 08             	mov    %edx,0x8(%eax)
      release(&icache.lock);
80101948:	83 ec 0c             	sub    $0xc,%esp
8010194b:	68 60 1a 11 80       	push   $0x80111a60
80101950:	e8 6f 36 00 00       	call   80104fc4 <release>
80101955:	83 c4 10             	add    $0x10,%esp
      return ip;
80101958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010195b:	eb 77                	jmp    801019d4 <iget+0xe0>
    }
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
8010195d:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101961:	75 10                	jne    80101973 <iget+0x7f>
80101963:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101966:	8b 40 08             	mov    0x8(%eax),%eax
80101969:	85 c0                	test   %eax,%eax
8010196b:	75 06                	jne    80101973 <iget+0x7f>
      empty = ip;
8010196d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101970:	89 45 f0             	mov    %eax,-0x10(%ebp)

  acquire(&icache.lock);

  // Is the inode already cached?
  empty = 0;
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
80101973:	81 45 f4 90 00 00 00 	addl   $0x90,-0xc(%ebp)
8010197a:	81 7d f4 b4 36 11 80 	cmpl   $0x801136b4,-0xc(%ebp)
80101981:	72 97                	jb     8010191a <iget+0x26>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
      empty = ip;
  }

  // Recycle an inode cache entry.
  if(empty == 0)
80101983:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80101987:	75 0d                	jne    80101996 <iget+0xa2>
    panic("iget: no inodes");
80101989:	83 ec 0c             	sub    $0xc,%esp
8010198c:	68 dd 85 10 80       	push   $0x801085dd
80101991:	e8 0a ec ff ff       	call   801005a0 <panic>

  ip = empty;
80101996:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101999:	89 45 f4             	mov    %eax,-0xc(%ebp)
  ip->dev = dev;
8010199c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010199f:	8b 55 08             	mov    0x8(%ebp),%edx
801019a2:	89 10                	mov    %edx,(%eax)
  ip->inum = inum;
801019a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019a7:	8b 55 0c             	mov    0xc(%ebp),%edx
801019aa:	89 50 04             	mov    %edx,0x4(%eax)
  ip->ref = 1;
801019ad:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019b0:	c7 40 08 01 00 00 00 	movl   $0x1,0x8(%eax)
  ip->valid = 0;
801019b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801019ba:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
  release(&icache.lock);
801019c1:	83 ec 0c             	sub    $0xc,%esp
801019c4:	68 60 1a 11 80       	push   $0x80111a60
801019c9:	e8 f6 35 00 00       	call   80104fc4 <release>
801019ce:	83 c4 10             	add    $0x10,%esp

  return ip;
801019d1:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801019d4:	c9                   	leave  
801019d5:	c3                   	ret    

801019d6 <idup>:

// Increment reference count for ip.
// Returns ip to enable ip = idup(ip1) idiom.
struct inode*
idup(struct inode *ip)
{
801019d6:	55                   	push   %ebp
801019d7:	89 e5                	mov    %esp,%ebp
801019d9:	83 ec 08             	sub    $0x8,%esp
  acquire(&icache.lock);
801019dc:	83 ec 0c             	sub    $0xc,%esp
801019df:	68 60 1a 11 80       	push   $0x80111a60
801019e4:	e8 6d 35 00 00       	call   80104f56 <acquire>
801019e9:	83 c4 10             	add    $0x10,%esp
  ip->ref++;
801019ec:	8b 45 08             	mov    0x8(%ebp),%eax
801019ef:	8b 40 08             	mov    0x8(%eax),%eax
801019f2:	8d 50 01             	lea    0x1(%eax),%edx
801019f5:	8b 45 08             	mov    0x8(%ebp),%eax
801019f8:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
801019fb:	83 ec 0c             	sub    $0xc,%esp
801019fe:	68 60 1a 11 80       	push   $0x80111a60
80101a03:	e8 bc 35 00 00       	call   80104fc4 <release>
80101a08:	83 c4 10             	add    $0x10,%esp
  return ip;
80101a0b:	8b 45 08             	mov    0x8(%ebp),%eax
}
80101a0e:	c9                   	leave  
80101a0f:	c3                   	ret    

80101a10 <ilock>:

// Lock the given inode.
// Reads the inode from disk if necessary.
void
ilock(struct inode *ip)
{
80101a10:	55                   	push   %ebp
80101a11:	89 e5                	mov    %esp,%ebp
80101a13:	83 ec 18             	sub    $0x18,%esp
  struct buf *bp;
  struct dinode *dip;

  if(ip == 0 || ip->ref < 1)
80101a16:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101a1a:	74 0a                	je     80101a26 <ilock+0x16>
80101a1c:	8b 45 08             	mov    0x8(%ebp),%eax
80101a1f:	8b 40 08             	mov    0x8(%eax),%eax
80101a22:	85 c0                	test   %eax,%eax
80101a24:	7f 0d                	jg     80101a33 <ilock+0x23>
    panic("ilock");
80101a26:	83 ec 0c             	sub    $0xc,%esp
80101a29:	68 ed 85 10 80       	push   $0x801085ed
80101a2e:	e8 6d eb ff ff       	call   801005a0 <panic>

  acquiresleep(&ip->lock);
80101a33:	8b 45 08             	mov    0x8(%ebp),%eax
80101a36:	83 c0 0c             	add    $0xc,%eax
80101a39:	83 ec 0c             	sub    $0xc,%esp
80101a3c:	50                   	push   %eax
80101a3d:	e8 d1 33 00 00       	call   80104e13 <acquiresleep>
80101a42:	83 c4 10             	add    $0x10,%esp

  if(ip->valid == 0){
80101a45:	8b 45 08             	mov    0x8(%ebp),%eax
80101a48:	8b 40 4c             	mov    0x4c(%eax),%eax
80101a4b:	85 c0                	test   %eax,%eax
80101a4d:	0f 85 cd 00 00 00    	jne    80101b20 <ilock+0x110>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
80101a53:	8b 45 08             	mov    0x8(%ebp),%eax
80101a56:	8b 40 04             	mov    0x4(%eax),%eax
80101a59:	c1 e8 03             	shr    $0x3,%eax
80101a5c:	89 c2                	mov    %eax,%edx
80101a5e:	a1 54 1a 11 80       	mov    0x80111a54,%eax
80101a63:	01 c2                	add    %eax,%edx
80101a65:	8b 45 08             	mov    0x8(%ebp),%eax
80101a68:	8b 00                	mov    (%eax),%eax
80101a6a:	83 ec 08             	sub    $0x8,%esp
80101a6d:	52                   	push   %edx
80101a6e:	50                   	push   %eax
80101a6f:	e8 5a e7 ff ff       	call   801001ce <bread>
80101a74:	83 c4 10             	add    $0x10,%esp
80101a77:	89 45 f4             	mov    %eax,-0xc(%ebp)
    dip = (struct dinode*)bp->data + ip->inum%IPB;
80101a7a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101a7d:	8d 50 5c             	lea    0x5c(%eax),%edx
80101a80:	8b 45 08             	mov    0x8(%ebp),%eax
80101a83:	8b 40 04             	mov    0x4(%eax),%eax
80101a86:	83 e0 07             	and    $0x7,%eax
80101a89:	c1 e0 06             	shl    $0x6,%eax
80101a8c:	01 d0                	add    %edx,%eax
80101a8e:	89 45 f0             	mov    %eax,-0x10(%ebp)
    ip->type = dip->type;
80101a91:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101a94:	0f b7 10             	movzwl (%eax),%edx
80101a97:	8b 45 08             	mov    0x8(%ebp),%eax
80101a9a:	66 89 50 50          	mov    %dx,0x50(%eax)
    ip->major = dip->major;
80101a9e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aa1:	0f b7 50 02          	movzwl 0x2(%eax),%edx
80101aa5:	8b 45 08             	mov    0x8(%ebp),%eax
80101aa8:	66 89 50 52          	mov    %dx,0x52(%eax)
    ip->minor = dip->minor;
80101aac:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101aaf:	0f b7 50 04          	movzwl 0x4(%eax),%edx
80101ab3:	8b 45 08             	mov    0x8(%ebp),%eax
80101ab6:	66 89 50 54          	mov    %dx,0x54(%eax)
    ip->nlink = dip->nlink;
80101aba:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101abd:	0f b7 50 06          	movzwl 0x6(%eax),%edx
80101ac1:	8b 45 08             	mov    0x8(%ebp),%eax
80101ac4:	66 89 50 56          	mov    %dx,0x56(%eax)
    ip->size = dip->size;
80101ac8:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101acb:	8b 50 08             	mov    0x8(%eax),%edx
80101ace:	8b 45 08             	mov    0x8(%ebp),%eax
80101ad1:	89 50 58             	mov    %edx,0x58(%eax)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
80101ad4:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101ad7:	8d 50 0c             	lea    0xc(%eax),%edx
80101ada:	8b 45 08             	mov    0x8(%ebp),%eax
80101add:	83 c0 5c             	add    $0x5c,%eax
80101ae0:	83 ec 04             	sub    $0x4,%esp
80101ae3:	6a 34                	push   $0x34
80101ae5:	52                   	push   %edx
80101ae6:	50                   	push   %eax
80101ae7:	e8 a0 37 00 00       	call   8010528c <memmove>
80101aec:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80101aef:	83 ec 0c             	sub    $0xc,%esp
80101af2:	ff 75 f4             	pushl  -0xc(%ebp)
80101af5:	e8 56 e7 ff ff       	call   80100250 <brelse>
80101afa:	83 c4 10             	add    $0x10,%esp
    ip->valid = 1;
80101afd:	8b 45 08             	mov    0x8(%ebp),%eax
80101b00:	c7 40 4c 01 00 00 00 	movl   $0x1,0x4c(%eax)
    if(ip->type == 0)
80101b07:	8b 45 08             	mov    0x8(%ebp),%eax
80101b0a:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101b0e:	66 85 c0             	test   %ax,%ax
80101b11:	75 0d                	jne    80101b20 <ilock+0x110>
      panic("ilock: no type");
80101b13:	83 ec 0c             	sub    $0xc,%esp
80101b16:	68 f3 85 10 80       	push   $0x801085f3
80101b1b:	e8 80 ea ff ff       	call   801005a0 <panic>
  }
}
80101b20:	90                   	nop
80101b21:	c9                   	leave  
80101b22:	c3                   	ret    

80101b23 <iunlock>:

// Unlock the given inode.
void
iunlock(struct inode *ip)
{
80101b23:	55                   	push   %ebp
80101b24:	89 e5                	mov    %esp,%ebp
80101b26:	83 ec 08             	sub    $0x8,%esp
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
80101b29:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80101b2d:	74 20                	je     80101b4f <iunlock+0x2c>
80101b2f:	8b 45 08             	mov    0x8(%ebp),%eax
80101b32:	83 c0 0c             	add    $0xc,%eax
80101b35:	83 ec 0c             	sub    $0xc,%esp
80101b38:	50                   	push   %eax
80101b39:	e8 87 33 00 00       	call   80104ec5 <holdingsleep>
80101b3e:	83 c4 10             	add    $0x10,%esp
80101b41:	85 c0                	test   %eax,%eax
80101b43:	74 0a                	je     80101b4f <iunlock+0x2c>
80101b45:	8b 45 08             	mov    0x8(%ebp),%eax
80101b48:	8b 40 08             	mov    0x8(%eax),%eax
80101b4b:	85 c0                	test   %eax,%eax
80101b4d:	7f 0d                	jg     80101b5c <iunlock+0x39>
    panic("iunlock");
80101b4f:	83 ec 0c             	sub    $0xc,%esp
80101b52:	68 02 86 10 80       	push   $0x80108602
80101b57:	e8 44 ea ff ff       	call   801005a0 <panic>

  releasesleep(&ip->lock);
80101b5c:	8b 45 08             	mov    0x8(%ebp),%eax
80101b5f:	83 c0 0c             	add    $0xc,%eax
80101b62:	83 ec 0c             	sub    $0xc,%esp
80101b65:	50                   	push   %eax
80101b66:	e8 0c 33 00 00       	call   80104e77 <releasesleep>
80101b6b:	83 c4 10             	add    $0x10,%esp
}
80101b6e:	90                   	nop
80101b6f:	c9                   	leave  
80101b70:	c3                   	ret    

80101b71 <iput>:
// to it, free the inode (and its content) on disk.
// All calls to iput() must be inside a transaction in
// case it has to free the inode.
void
iput(struct inode *ip)
{
80101b71:	55                   	push   %ebp
80101b72:	89 e5                	mov    %esp,%ebp
80101b74:	83 ec 18             	sub    $0x18,%esp
  acquiresleep(&ip->lock);
80101b77:	8b 45 08             	mov    0x8(%ebp),%eax
80101b7a:	83 c0 0c             	add    $0xc,%eax
80101b7d:	83 ec 0c             	sub    $0xc,%esp
80101b80:	50                   	push   %eax
80101b81:	e8 8d 32 00 00       	call   80104e13 <acquiresleep>
80101b86:	83 c4 10             	add    $0x10,%esp
  if(ip->valid && ip->nlink == 0){
80101b89:	8b 45 08             	mov    0x8(%ebp),%eax
80101b8c:	8b 40 4c             	mov    0x4c(%eax),%eax
80101b8f:	85 c0                	test   %eax,%eax
80101b91:	74 6a                	je     80101bfd <iput+0x8c>
80101b93:	8b 45 08             	mov    0x8(%ebp),%eax
80101b96:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80101b9a:	66 85 c0             	test   %ax,%ax
80101b9d:	75 5e                	jne    80101bfd <iput+0x8c>
    acquire(&icache.lock);
80101b9f:	83 ec 0c             	sub    $0xc,%esp
80101ba2:	68 60 1a 11 80       	push   $0x80111a60
80101ba7:	e8 aa 33 00 00       	call   80104f56 <acquire>
80101bac:	83 c4 10             	add    $0x10,%esp
    int r = ip->ref;
80101baf:	8b 45 08             	mov    0x8(%ebp),%eax
80101bb2:	8b 40 08             	mov    0x8(%eax),%eax
80101bb5:	89 45 f4             	mov    %eax,-0xc(%ebp)
    release(&icache.lock);
80101bb8:	83 ec 0c             	sub    $0xc,%esp
80101bbb:	68 60 1a 11 80       	push   $0x80111a60
80101bc0:	e8 ff 33 00 00       	call   80104fc4 <release>
80101bc5:	83 c4 10             	add    $0x10,%esp
    if(r == 1){
80101bc8:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80101bcc:	75 2f                	jne    80101bfd <iput+0x8c>
      // inode has no links and no other references: truncate and free.
      itrunc(ip);
80101bce:	83 ec 0c             	sub    $0xc,%esp
80101bd1:	ff 75 08             	pushl  0x8(%ebp)
80101bd4:	e8 b2 01 00 00       	call   80101d8b <itrunc>
80101bd9:	83 c4 10             	add    $0x10,%esp
      ip->type = 0;
80101bdc:	8b 45 08             	mov    0x8(%ebp),%eax
80101bdf:	66 c7 40 50 00 00    	movw   $0x0,0x50(%eax)
      iupdate(ip);
80101be5:	83 ec 0c             	sub    $0xc,%esp
80101be8:	ff 75 08             	pushl  0x8(%ebp)
80101beb:	e8 43 fc ff ff       	call   80101833 <iupdate>
80101bf0:	83 c4 10             	add    $0x10,%esp
      ip->valid = 0;
80101bf3:	8b 45 08             	mov    0x8(%ebp),%eax
80101bf6:	c7 40 4c 00 00 00 00 	movl   $0x0,0x4c(%eax)
    }
  }
  releasesleep(&ip->lock);
80101bfd:	8b 45 08             	mov    0x8(%ebp),%eax
80101c00:	83 c0 0c             	add    $0xc,%eax
80101c03:	83 ec 0c             	sub    $0xc,%esp
80101c06:	50                   	push   %eax
80101c07:	e8 6b 32 00 00       	call   80104e77 <releasesleep>
80101c0c:	83 c4 10             	add    $0x10,%esp

  acquire(&icache.lock);
80101c0f:	83 ec 0c             	sub    $0xc,%esp
80101c12:	68 60 1a 11 80       	push   $0x80111a60
80101c17:	e8 3a 33 00 00       	call   80104f56 <acquire>
80101c1c:	83 c4 10             	add    $0x10,%esp
  ip->ref--;
80101c1f:	8b 45 08             	mov    0x8(%ebp),%eax
80101c22:	8b 40 08             	mov    0x8(%eax),%eax
80101c25:	8d 50 ff             	lea    -0x1(%eax),%edx
80101c28:	8b 45 08             	mov    0x8(%ebp),%eax
80101c2b:	89 50 08             	mov    %edx,0x8(%eax)
  release(&icache.lock);
80101c2e:	83 ec 0c             	sub    $0xc,%esp
80101c31:	68 60 1a 11 80       	push   $0x80111a60
80101c36:	e8 89 33 00 00       	call   80104fc4 <release>
80101c3b:	83 c4 10             	add    $0x10,%esp
}
80101c3e:	90                   	nop
80101c3f:	c9                   	leave  
80101c40:	c3                   	ret    

80101c41 <iunlockput>:

// Common idiom: unlock, then put.
void
iunlockput(struct inode *ip)
{
80101c41:	55                   	push   %ebp
80101c42:	89 e5                	mov    %esp,%ebp
80101c44:	83 ec 08             	sub    $0x8,%esp
  iunlock(ip);
80101c47:	83 ec 0c             	sub    $0xc,%esp
80101c4a:	ff 75 08             	pushl  0x8(%ebp)
80101c4d:	e8 d1 fe ff ff       	call   80101b23 <iunlock>
80101c52:	83 c4 10             	add    $0x10,%esp
  iput(ip);
80101c55:	83 ec 0c             	sub    $0xc,%esp
80101c58:	ff 75 08             	pushl  0x8(%ebp)
80101c5b:	e8 11 ff ff ff       	call   80101b71 <iput>
80101c60:	83 c4 10             	add    $0x10,%esp
}
80101c63:	90                   	nop
80101c64:	c9                   	leave  
80101c65:	c3                   	ret    

80101c66 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
80101c66:	55                   	push   %ebp
80101c67:	89 e5                	mov    %esp,%ebp
80101c69:	53                   	push   %ebx
80101c6a:	83 ec 14             	sub    $0x14,%esp
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
80101c6d:	83 7d 0c 0b          	cmpl   $0xb,0xc(%ebp)
80101c71:	77 42                	ja     80101cb5 <bmap+0x4f>
    if((addr = ip->addrs[bn]) == 0)
80101c73:	8b 45 08             	mov    0x8(%ebp),%eax
80101c76:	8b 55 0c             	mov    0xc(%ebp),%edx
80101c79:	83 c2 14             	add    $0x14,%edx
80101c7c:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101c80:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c83:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101c87:	75 24                	jne    80101cad <bmap+0x47>
      ip->addrs[bn] = addr = balloc(ip->dev);
80101c89:	8b 45 08             	mov    0x8(%ebp),%eax
80101c8c:	8b 00                	mov    (%eax),%eax
80101c8e:	83 ec 0c             	sub    $0xc,%esp
80101c91:	50                   	push   %eax
80101c92:	e8 e3 f7 ff ff       	call   8010147a <balloc>
80101c97:	83 c4 10             	add    $0x10,%esp
80101c9a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101c9d:	8b 45 08             	mov    0x8(%ebp),%eax
80101ca0:	8b 55 0c             	mov    0xc(%ebp),%edx
80101ca3:	8d 4a 14             	lea    0x14(%edx),%ecx
80101ca6:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101ca9:	89 54 88 0c          	mov    %edx,0xc(%eax,%ecx,4)
    return addr;
80101cad:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101cb0:	e9 d1 00 00 00       	jmp    80101d86 <bmap+0x120>
  }
  bn -= NDIRECT;
80101cb5:	83 6d 0c 0c          	subl   $0xc,0xc(%ebp)

  if(bn < NINDIRECT){
80101cb9:	83 7d 0c 7f          	cmpl   $0x7f,0xc(%ebp)
80101cbd:	0f 87 b6 00 00 00    	ja     80101d79 <bmap+0x113>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
80101cc3:	8b 45 08             	mov    0x8(%ebp),%eax
80101cc6:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101ccc:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ccf:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101cd3:	75 20                	jne    80101cf5 <bmap+0x8f>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
80101cd5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cd8:	8b 00                	mov    (%eax),%eax
80101cda:	83 ec 0c             	sub    $0xc,%esp
80101cdd:	50                   	push   %eax
80101cde:	e8 97 f7 ff ff       	call   8010147a <balloc>
80101ce3:	83 c4 10             	add    $0x10,%esp
80101ce6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101ce9:	8b 45 08             	mov    0x8(%ebp),%eax
80101cec:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101cef:	89 90 8c 00 00 00    	mov    %edx,0x8c(%eax)
    bp = bread(ip->dev, addr);
80101cf5:	8b 45 08             	mov    0x8(%ebp),%eax
80101cf8:	8b 00                	mov    (%eax),%eax
80101cfa:	83 ec 08             	sub    $0x8,%esp
80101cfd:	ff 75 f4             	pushl  -0xc(%ebp)
80101d00:	50                   	push   %eax
80101d01:	e8 c8 e4 ff ff       	call   801001ce <bread>
80101d06:	83 c4 10             	add    $0x10,%esp
80101d09:	89 45 f0             	mov    %eax,-0x10(%ebp)
    a = (uint*)bp->data;
80101d0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101d0f:	83 c0 5c             	add    $0x5c,%eax
80101d12:	89 45 ec             	mov    %eax,-0x14(%ebp)
    if((addr = a[bn]) == 0){
80101d15:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d18:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d1f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d22:	01 d0                	add    %edx,%eax
80101d24:	8b 00                	mov    (%eax),%eax
80101d26:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d29:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80101d2d:	75 37                	jne    80101d66 <bmap+0x100>
      a[bn] = addr = balloc(ip->dev);
80101d2f:	8b 45 0c             	mov    0xc(%ebp),%eax
80101d32:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101d39:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101d3c:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
80101d3f:	8b 45 08             	mov    0x8(%ebp),%eax
80101d42:	8b 00                	mov    (%eax),%eax
80101d44:	83 ec 0c             	sub    $0xc,%esp
80101d47:	50                   	push   %eax
80101d48:	e8 2d f7 ff ff       	call   8010147a <balloc>
80101d4d:	83 c4 10             	add    $0x10,%esp
80101d50:	89 45 f4             	mov    %eax,-0xc(%ebp)
80101d53:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d56:	89 03                	mov    %eax,(%ebx)
      log_write(bp);
80101d58:	83 ec 0c             	sub    $0xc,%esp
80101d5b:	ff 75 f0             	pushl  -0x10(%ebp)
80101d5e:	e8 0a 1a 00 00       	call   8010376d <log_write>
80101d63:	83 c4 10             	add    $0x10,%esp
    }
    brelse(bp);
80101d66:	83 ec 0c             	sub    $0xc,%esp
80101d69:	ff 75 f0             	pushl  -0x10(%ebp)
80101d6c:	e8 df e4 ff ff       	call   80100250 <brelse>
80101d71:	83 c4 10             	add    $0x10,%esp
    return addr;
80101d74:	8b 45 f4             	mov    -0xc(%ebp),%eax
80101d77:	eb 0d                	jmp    80101d86 <bmap+0x120>
  }

  panic("bmap: out of range");
80101d79:	83 ec 0c             	sub    $0xc,%esp
80101d7c:	68 0a 86 10 80       	push   $0x8010860a
80101d81:	e8 1a e8 ff ff       	call   801005a0 <panic>
}
80101d86:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80101d89:	c9                   	leave  
80101d8a:	c3                   	ret    

80101d8b <itrunc>:
// to it (no directory entries referring to it)
// and has no in-memory reference to it (is
// not an open file or current directory).
static void
itrunc(struct inode *ip)
{
80101d8b:	55                   	push   %ebp
80101d8c:	89 e5                	mov    %esp,%ebp
80101d8e:	83 ec 18             	sub    $0x18,%esp
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101d91:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101d98:	eb 45                	jmp    80101ddf <itrunc+0x54>
    if(ip->addrs[i]){
80101d9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101d9d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101da0:	83 c2 14             	add    $0x14,%edx
80101da3:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101da7:	85 c0                	test   %eax,%eax
80101da9:	74 30                	je     80101ddb <itrunc+0x50>
      bfree(ip->dev, ip->addrs[i]);
80101dab:	8b 45 08             	mov    0x8(%ebp),%eax
80101dae:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101db1:	83 c2 14             	add    $0x14,%edx
80101db4:	8b 44 90 0c          	mov    0xc(%eax,%edx,4),%eax
80101db8:	8b 55 08             	mov    0x8(%ebp),%edx
80101dbb:	8b 12                	mov    (%edx),%edx
80101dbd:	83 ec 08             	sub    $0x8,%esp
80101dc0:	50                   	push   %eax
80101dc1:	52                   	push   %edx
80101dc2:	e8 ff f7 ff ff       	call   801015c6 <bfree>
80101dc7:	83 c4 10             	add    $0x10,%esp
      ip->addrs[i] = 0;
80101dca:	8b 45 08             	mov    0x8(%ebp),%eax
80101dcd:	8b 55 f4             	mov    -0xc(%ebp),%edx
80101dd0:	83 c2 14             	add    $0x14,%edx
80101dd3:	c7 44 90 0c 00 00 00 	movl   $0x0,0xc(%eax,%edx,4)
80101dda:	00 
{
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
80101ddb:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80101ddf:	83 7d f4 0b          	cmpl   $0xb,-0xc(%ebp)
80101de3:	7e b5                	jle    80101d9a <itrunc+0xf>
      bfree(ip->dev, ip->addrs[i]);
      ip->addrs[i] = 0;
    }
  }

  if(ip->addrs[NDIRECT]){
80101de5:	8b 45 08             	mov    0x8(%ebp),%eax
80101de8:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101dee:	85 c0                	test   %eax,%eax
80101df0:	0f 84 aa 00 00 00    	je     80101ea0 <itrunc+0x115>
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
80101df6:	8b 45 08             	mov    0x8(%ebp),%eax
80101df9:	8b 90 8c 00 00 00    	mov    0x8c(%eax),%edx
80101dff:	8b 45 08             	mov    0x8(%ebp),%eax
80101e02:	8b 00                	mov    (%eax),%eax
80101e04:	83 ec 08             	sub    $0x8,%esp
80101e07:	52                   	push   %edx
80101e08:	50                   	push   %eax
80101e09:	e8 c0 e3 ff ff       	call   801001ce <bread>
80101e0e:	83 c4 10             	add    $0x10,%esp
80101e11:	89 45 ec             	mov    %eax,-0x14(%ebp)
    a = (uint*)bp->data;
80101e14:	8b 45 ec             	mov    -0x14(%ebp),%eax
80101e17:	83 c0 5c             	add    $0x5c,%eax
80101e1a:	89 45 e8             	mov    %eax,-0x18(%ebp)
    for(j = 0; j < NINDIRECT; j++){
80101e1d:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80101e24:	eb 3c                	jmp    80101e62 <itrunc+0xd7>
      if(a[j])
80101e26:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e29:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e30:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e33:	01 d0                	add    %edx,%eax
80101e35:	8b 00                	mov    (%eax),%eax
80101e37:	85 c0                	test   %eax,%eax
80101e39:	74 23                	je     80101e5e <itrunc+0xd3>
        bfree(ip->dev, a[j]);
80101e3b:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e3e:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80101e45:	8b 45 e8             	mov    -0x18(%ebp),%eax
80101e48:	01 d0                	add    %edx,%eax
80101e4a:	8b 00                	mov    (%eax),%eax
80101e4c:	8b 55 08             	mov    0x8(%ebp),%edx
80101e4f:	8b 12                	mov    (%edx),%edx
80101e51:	83 ec 08             	sub    $0x8,%esp
80101e54:	50                   	push   %eax
80101e55:	52                   	push   %edx
80101e56:	e8 6b f7 ff ff       	call   801015c6 <bfree>
80101e5b:	83 c4 10             	add    $0x10,%esp
  }

  if(ip->addrs[NDIRECT]){
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    a = (uint*)bp->data;
    for(j = 0; j < NINDIRECT; j++){
80101e5e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80101e62:	8b 45 f0             	mov    -0x10(%ebp),%eax
80101e65:	83 f8 7f             	cmp    $0x7f,%eax
80101e68:	76 bc                	jbe    80101e26 <itrunc+0x9b>
      if(a[j])
        bfree(ip->dev, a[j]);
    }
    brelse(bp);
80101e6a:	83 ec 0c             	sub    $0xc,%esp
80101e6d:	ff 75 ec             	pushl  -0x14(%ebp)
80101e70:	e8 db e3 ff ff       	call   80100250 <brelse>
80101e75:	83 c4 10             	add    $0x10,%esp
    bfree(ip->dev, ip->addrs[NDIRECT]);
80101e78:	8b 45 08             	mov    0x8(%ebp),%eax
80101e7b:	8b 80 8c 00 00 00    	mov    0x8c(%eax),%eax
80101e81:	8b 55 08             	mov    0x8(%ebp),%edx
80101e84:	8b 12                	mov    (%edx),%edx
80101e86:	83 ec 08             	sub    $0x8,%esp
80101e89:	50                   	push   %eax
80101e8a:	52                   	push   %edx
80101e8b:	e8 36 f7 ff ff       	call   801015c6 <bfree>
80101e90:	83 c4 10             	add    $0x10,%esp
    ip->addrs[NDIRECT] = 0;
80101e93:	8b 45 08             	mov    0x8(%ebp),%eax
80101e96:	c7 80 8c 00 00 00 00 	movl   $0x0,0x8c(%eax)
80101e9d:	00 00 00 
  }

  ip->size = 0;
80101ea0:	8b 45 08             	mov    0x8(%ebp),%eax
80101ea3:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  iupdate(ip);
80101eaa:	83 ec 0c             	sub    $0xc,%esp
80101ead:	ff 75 08             	pushl  0x8(%ebp)
80101eb0:	e8 7e f9 ff ff       	call   80101833 <iupdate>
80101eb5:	83 c4 10             	add    $0x10,%esp
}
80101eb8:	90                   	nop
80101eb9:	c9                   	leave  
80101eba:	c3                   	ret    

80101ebb <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
80101ebb:	55                   	push   %ebp
80101ebc:	89 e5                	mov    %esp,%ebp
  st->dev = ip->dev;
80101ebe:	8b 45 08             	mov    0x8(%ebp),%eax
80101ec1:	8b 00                	mov    (%eax),%eax
80101ec3:	89 c2                	mov    %eax,%edx
80101ec5:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ec8:	89 50 04             	mov    %edx,0x4(%eax)
  st->ino = ip->inum;
80101ecb:	8b 45 08             	mov    0x8(%ebp),%eax
80101ece:	8b 50 04             	mov    0x4(%eax),%edx
80101ed1:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ed4:	89 50 08             	mov    %edx,0x8(%eax)
  st->type = ip->type;
80101ed7:	8b 45 08             	mov    0x8(%ebp),%eax
80101eda:	0f b7 50 50          	movzwl 0x50(%eax),%edx
80101ede:	8b 45 0c             	mov    0xc(%ebp),%eax
80101ee1:	66 89 10             	mov    %dx,(%eax)
  st->nlink = ip->nlink;
80101ee4:	8b 45 08             	mov    0x8(%ebp),%eax
80101ee7:	0f b7 50 56          	movzwl 0x56(%eax),%edx
80101eeb:	8b 45 0c             	mov    0xc(%ebp),%eax
80101eee:	66 89 50 0c          	mov    %dx,0xc(%eax)
  st->size = ip->size;
80101ef2:	8b 45 08             	mov    0x8(%ebp),%eax
80101ef5:	8b 50 58             	mov    0x58(%eax),%edx
80101ef8:	8b 45 0c             	mov    0xc(%ebp),%eax
80101efb:	89 50 10             	mov    %edx,0x10(%eax)
}
80101efe:	90                   	nop
80101eff:	5d                   	pop    %ebp
80101f00:	c3                   	ret    

80101f01 <readi>:
//PAGEBREAK!
// Read data from inode.
// Caller must hold ip->lock.
int
readi(struct inode *ip, char *dst, uint off, uint n)
{
80101f01:	55                   	push   %ebp
80101f02:	89 e5                	mov    %esp,%ebp
80101f04:	83 ec 18             	sub    $0x18,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
80101f07:	8b 45 08             	mov    0x8(%ebp),%eax
80101f0a:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80101f0e:	66 83 f8 03          	cmp    $0x3,%ax
80101f12:	75 5c                	jne    80101f70 <readi+0x6f>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].read)
80101f14:	8b 45 08             	mov    0x8(%ebp),%eax
80101f17:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f1b:	66 85 c0             	test   %ax,%ax
80101f1e:	78 20                	js     80101f40 <readi+0x3f>
80101f20:	8b 45 08             	mov    0x8(%ebp),%eax
80101f23:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f27:	66 83 f8 09          	cmp    $0x9,%ax
80101f2b:	7f 13                	jg     80101f40 <readi+0x3f>
80101f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80101f30:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f34:	98                   	cwtl   
80101f35:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101f3c:	85 c0                	test   %eax,%eax
80101f3e:	75 0a                	jne    80101f4a <readi+0x49>
      return -1;
80101f40:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f45:	e9 0c 01 00 00       	jmp    80102056 <readi+0x155>
    return devsw[ip->major].read(ip, dst, n);
80101f4a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f4d:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80101f51:	98                   	cwtl   
80101f52:	8b 04 c5 e0 19 11 80 	mov    -0x7feee620(,%eax,8),%eax
80101f59:	8b 55 14             	mov    0x14(%ebp),%edx
80101f5c:	83 ec 04             	sub    $0x4,%esp
80101f5f:	52                   	push   %edx
80101f60:	ff 75 0c             	pushl  0xc(%ebp)
80101f63:	ff 75 08             	pushl  0x8(%ebp)
80101f66:	ff d0                	call   *%eax
80101f68:	83 c4 10             	add    $0x10,%esp
80101f6b:	e9 e6 00 00 00       	jmp    80102056 <readi+0x155>
  }

  if(off > ip->size || off + n < off)
80101f70:	8b 45 08             	mov    0x8(%ebp),%eax
80101f73:	8b 40 58             	mov    0x58(%eax),%eax
80101f76:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f79:	72 0d                	jb     80101f88 <readi+0x87>
80101f7b:	8b 55 10             	mov    0x10(%ebp),%edx
80101f7e:	8b 45 14             	mov    0x14(%ebp),%eax
80101f81:	01 d0                	add    %edx,%eax
80101f83:	3b 45 10             	cmp    0x10(%ebp),%eax
80101f86:	73 0a                	jae    80101f92 <readi+0x91>
    return -1;
80101f88:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80101f8d:	e9 c4 00 00 00       	jmp    80102056 <readi+0x155>
  if(off + n > ip->size)
80101f92:	8b 55 10             	mov    0x10(%ebp),%edx
80101f95:	8b 45 14             	mov    0x14(%ebp),%eax
80101f98:	01 c2                	add    %eax,%edx
80101f9a:	8b 45 08             	mov    0x8(%ebp),%eax
80101f9d:	8b 40 58             	mov    0x58(%eax),%eax
80101fa0:	39 c2                	cmp    %eax,%edx
80101fa2:	76 0c                	jbe    80101fb0 <readi+0xaf>
    n = ip->size - off;
80101fa4:	8b 45 08             	mov    0x8(%ebp),%eax
80101fa7:	8b 40 58             	mov    0x58(%eax),%eax
80101faa:	2b 45 10             	sub    0x10(%ebp),%eax
80101fad:	89 45 14             	mov    %eax,0x14(%ebp)

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80101fb0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80101fb7:	e9 8b 00 00 00       	jmp    80102047 <readi+0x146>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
80101fbc:	8b 45 10             	mov    0x10(%ebp),%eax
80101fbf:	c1 e8 09             	shr    $0x9,%eax
80101fc2:	83 ec 08             	sub    $0x8,%esp
80101fc5:	50                   	push   %eax
80101fc6:	ff 75 08             	pushl  0x8(%ebp)
80101fc9:	e8 98 fc ff ff       	call   80101c66 <bmap>
80101fce:	83 c4 10             	add    $0x10,%esp
80101fd1:	89 c2                	mov    %eax,%edx
80101fd3:	8b 45 08             	mov    0x8(%ebp),%eax
80101fd6:	8b 00                	mov    (%eax),%eax
80101fd8:	83 ec 08             	sub    $0x8,%esp
80101fdb:	52                   	push   %edx
80101fdc:	50                   	push   %eax
80101fdd:	e8 ec e1 ff ff       	call   801001ce <bread>
80101fe2:	83 c4 10             	add    $0x10,%esp
80101fe5:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
80101fe8:	8b 45 10             	mov    0x10(%ebp),%eax
80101feb:	25 ff 01 00 00       	and    $0x1ff,%eax
80101ff0:	ba 00 02 00 00       	mov    $0x200,%edx
80101ff5:	29 c2                	sub    %eax,%edx
80101ff7:	8b 45 14             	mov    0x14(%ebp),%eax
80101ffa:	2b 45 f4             	sub    -0xc(%ebp),%eax
80101ffd:	39 c2                	cmp    %eax,%edx
80101fff:	0f 46 c2             	cmovbe %edx,%eax
80102002:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dst, bp->data + off%BSIZE, m);
80102005:	8b 45 f0             	mov    -0x10(%ebp),%eax
80102008:	8d 50 5c             	lea    0x5c(%eax),%edx
8010200b:	8b 45 10             	mov    0x10(%ebp),%eax
8010200e:	25 ff 01 00 00       	and    $0x1ff,%eax
80102013:	01 d0                	add    %edx,%eax
80102015:	83 ec 04             	sub    $0x4,%esp
80102018:	ff 75 ec             	pushl  -0x14(%ebp)
8010201b:	50                   	push   %eax
8010201c:	ff 75 0c             	pushl  0xc(%ebp)
8010201f:	e8 68 32 00 00       	call   8010528c <memmove>
80102024:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80102027:	83 ec 0c             	sub    $0xc,%esp
8010202a:	ff 75 f0             	pushl  -0x10(%ebp)
8010202d:	e8 1e e2 ff ff       	call   80100250 <brelse>
80102032:	83 c4 10             	add    $0x10,%esp
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > ip->size)
    n = ip->size - off;

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
80102035:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102038:	01 45 f4             	add    %eax,-0xc(%ebp)
8010203b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010203e:	01 45 10             	add    %eax,0x10(%ebp)
80102041:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102044:	01 45 0c             	add    %eax,0xc(%ebp)
80102047:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010204a:	3b 45 14             	cmp    0x14(%ebp),%eax
8010204d:	0f 82 69 ff ff ff    	jb     80101fbc <readi+0xbb>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    memmove(dst, bp->data + off%BSIZE, m);
    brelse(bp);
  }
  return n;
80102053:	8b 45 14             	mov    0x14(%ebp),%eax
}
80102056:	c9                   	leave  
80102057:	c3                   	ret    

80102058 <writei>:
// PAGEBREAK!
// Write data to inode.
// Caller must hold ip->lock.
int
writei(struct inode *ip, char *src, uint off, uint n)
{
80102058:	55                   	push   %ebp
80102059:	89 e5                	mov    %esp,%ebp
8010205b:	83 ec 18             	sub    $0x18,%esp
  uint tot, m;
  struct buf *bp;

  if(ip->type == T_DEV){
8010205e:	8b 45 08             	mov    0x8(%ebp),%eax
80102061:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102065:	66 83 f8 03          	cmp    $0x3,%ax
80102069:	75 5c                	jne    801020c7 <writei+0x6f>
    if(ip->major < 0 || ip->major >= NDEV || !devsw[ip->major].write)
8010206b:	8b 45 08             	mov    0x8(%ebp),%eax
8010206e:	0f b7 40 52          	movzwl 0x52(%eax),%eax
80102072:	66 85 c0             	test   %ax,%ax
80102075:	78 20                	js     80102097 <writei+0x3f>
80102077:	8b 45 08             	mov    0x8(%ebp),%eax
8010207a:	0f b7 40 52          	movzwl 0x52(%eax),%eax
8010207e:	66 83 f8 09          	cmp    $0x9,%ax
80102082:	7f 13                	jg     80102097 <writei+0x3f>
80102084:	8b 45 08             	mov    0x8(%ebp),%eax
80102087:	0f b7 40 52          	movzwl 0x52(%eax),%eax
8010208b:	98                   	cwtl   
8010208c:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
80102093:	85 c0                	test   %eax,%eax
80102095:	75 0a                	jne    801020a1 <writei+0x49>
      return -1;
80102097:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010209c:	e9 3d 01 00 00       	jmp    801021de <writei+0x186>
    return devsw[ip->major].write(ip, src, n);
801020a1:	8b 45 08             	mov    0x8(%ebp),%eax
801020a4:	0f b7 40 52          	movzwl 0x52(%eax),%eax
801020a8:	98                   	cwtl   
801020a9:	8b 04 c5 e4 19 11 80 	mov    -0x7feee61c(,%eax,8),%eax
801020b0:	8b 55 14             	mov    0x14(%ebp),%edx
801020b3:	83 ec 04             	sub    $0x4,%esp
801020b6:	52                   	push   %edx
801020b7:	ff 75 0c             	pushl  0xc(%ebp)
801020ba:	ff 75 08             	pushl  0x8(%ebp)
801020bd:	ff d0                	call   *%eax
801020bf:	83 c4 10             	add    $0x10,%esp
801020c2:	e9 17 01 00 00       	jmp    801021de <writei+0x186>
  }

  if(off > ip->size || off + n < off)
801020c7:	8b 45 08             	mov    0x8(%ebp),%eax
801020ca:	8b 40 58             	mov    0x58(%eax),%eax
801020cd:	3b 45 10             	cmp    0x10(%ebp),%eax
801020d0:	72 0d                	jb     801020df <writei+0x87>
801020d2:	8b 55 10             	mov    0x10(%ebp),%edx
801020d5:	8b 45 14             	mov    0x14(%ebp),%eax
801020d8:	01 d0                	add    %edx,%eax
801020da:	3b 45 10             	cmp    0x10(%ebp),%eax
801020dd:	73 0a                	jae    801020e9 <writei+0x91>
    return -1;
801020df:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020e4:	e9 f5 00 00 00       	jmp    801021de <writei+0x186>
  if(off + n > MAXFILE*BSIZE)
801020e9:	8b 55 10             	mov    0x10(%ebp),%edx
801020ec:	8b 45 14             	mov    0x14(%ebp),%eax
801020ef:	01 d0                	add    %edx,%eax
801020f1:	3d 00 18 01 00       	cmp    $0x11800,%eax
801020f6:	76 0a                	jbe    80102102 <writei+0xaa>
    return -1;
801020f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801020fd:	e9 dc 00 00 00       	jmp    801021de <writei+0x186>

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102102:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102109:	e9 99 00 00 00       	jmp    801021a7 <writei+0x14f>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
8010210e:	8b 45 10             	mov    0x10(%ebp),%eax
80102111:	c1 e8 09             	shr    $0x9,%eax
80102114:	83 ec 08             	sub    $0x8,%esp
80102117:	50                   	push   %eax
80102118:	ff 75 08             	pushl  0x8(%ebp)
8010211b:	e8 46 fb ff ff       	call   80101c66 <bmap>
80102120:	83 c4 10             	add    $0x10,%esp
80102123:	89 c2                	mov    %eax,%edx
80102125:	8b 45 08             	mov    0x8(%ebp),%eax
80102128:	8b 00                	mov    (%eax),%eax
8010212a:	83 ec 08             	sub    $0x8,%esp
8010212d:	52                   	push   %edx
8010212e:	50                   	push   %eax
8010212f:	e8 9a e0 ff ff       	call   801001ce <bread>
80102134:	83 c4 10             	add    $0x10,%esp
80102137:	89 45 f0             	mov    %eax,-0x10(%ebp)
    m = min(n - tot, BSIZE - off%BSIZE);
8010213a:	8b 45 10             	mov    0x10(%ebp),%eax
8010213d:	25 ff 01 00 00       	and    $0x1ff,%eax
80102142:	ba 00 02 00 00       	mov    $0x200,%edx
80102147:	29 c2                	sub    %eax,%edx
80102149:	8b 45 14             	mov    0x14(%ebp),%eax
8010214c:	2b 45 f4             	sub    -0xc(%ebp),%eax
8010214f:	39 c2                	cmp    %eax,%edx
80102151:	0f 46 c2             	cmovbe %edx,%eax
80102154:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(bp->data + off%BSIZE, src, m);
80102157:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010215a:	8d 50 5c             	lea    0x5c(%eax),%edx
8010215d:	8b 45 10             	mov    0x10(%ebp),%eax
80102160:	25 ff 01 00 00       	and    $0x1ff,%eax
80102165:	01 d0                	add    %edx,%eax
80102167:	83 ec 04             	sub    $0x4,%esp
8010216a:	ff 75 ec             	pushl  -0x14(%ebp)
8010216d:	ff 75 0c             	pushl  0xc(%ebp)
80102170:	50                   	push   %eax
80102171:	e8 16 31 00 00       	call   8010528c <memmove>
80102176:	83 c4 10             	add    $0x10,%esp
    log_write(bp);
80102179:	83 ec 0c             	sub    $0xc,%esp
8010217c:	ff 75 f0             	pushl  -0x10(%ebp)
8010217f:	e8 e9 15 00 00       	call   8010376d <log_write>
80102184:	83 c4 10             	add    $0x10,%esp
    brelse(bp);
80102187:	83 ec 0c             	sub    $0xc,%esp
8010218a:	ff 75 f0             	pushl  -0x10(%ebp)
8010218d:	e8 be e0 ff ff       	call   80100250 <brelse>
80102192:	83 c4 10             	add    $0x10,%esp
  if(off > ip->size || off + n < off)
    return -1;
  if(off + n > MAXFILE*BSIZE)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
80102195:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102198:	01 45 f4             	add    %eax,-0xc(%ebp)
8010219b:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010219e:	01 45 10             	add    %eax,0x10(%ebp)
801021a1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801021a4:	01 45 0c             	add    %eax,0xc(%ebp)
801021a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801021aa:	3b 45 14             	cmp    0x14(%ebp),%eax
801021ad:	0f 82 5b ff ff ff    	jb     8010210e <writei+0xb6>
    memmove(bp->data + off%BSIZE, src, m);
    log_write(bp);
    brelse(bp);
  }

  if(n > 0 && off > ip->size){
801021b3:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
801021b7:	74 22                	je     801021db <writei+0x183>
801021b9:	8b 45 08             	mov    0x8(%ebp),%eax
801021bc:	8b 40 58             	mov    0x58(%eax),%eax
801021bf:	3b 45 10             	cmp    0x10(%ebp),%eax
801021c2:	73 17                	jae    801021db <writei+0x183>
    ip->size = off;
801021c4:	8b 45 08             	mov    0x8(%ebp),%eax
801021c7:	8b 55 10             	mov    0x10(%ebp),%edx
801021ca:	89 50 58             	mov    %edx,0x58(%eax)
    iupdate(ip);
801021cd:	83 ec 0c             	sub    $0xc,%esp
801021d0:	ff 75 08             	pushl  0x8(%ebp)
801021d3:	e8 5b f6 ff ff       	call   80101833 <iupdate>
801021d8:	83 c4 10             	add    $0x10,%esp
  }
  return n;
801021db:	8b 45 14             	mov    0x14(%ebp),%eax
}
801021de:	c9                   	leave  
801021df:	c3                   	ret    

801021e0 <namecmp>:
//PAGEBREAK!
// Directories

int
namecmp(const char *s, const char *t)
{
801021e0:	55                   	push   %ebp
801021e1:	89 e5                	mov    %esp,%ebp
801021e3:	83 ec 08             	sub    $0x8,%esp
  return strncmp(s, t, DIRSIZ);
801021e6:	83 ec 04             	sub    $0x4,%esp
801021e9:	6a 0e                	push   $0xe
801021eb:	ff 75 0c             	pushl  0xc(%ebp)
801021ee:	ff 75 08             	pushl  0x8(%ebp)
801021f1:	e8 2c 31 00 00       	call   80105322 <strncmp>
801021f6:	83 c4 10             	add    $0x10,%esp
}
801021f9:	c9                   	leave  
801021fa:	c3                   	ret    

801021fb <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
801021fb:	55                   	push   %ebp
801021fc:	89 e5                	mov    %esp,%ebp
801021fe:	83 ec 28             	sub    $0x28,%esp
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
80102201:	8b 45 08             	mov    0x8(%ebp),%eax
80102204:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102208:	66 83 f8 01          	cmp    $0x1,%ax
8010220c:	74 0d                	je     8010221b <dirlookup+0x20>
    panic("dirlookup not DIR");
8010220e:	83 ec 0c             	sub    $0xc,%esp
80102211:	68 1d 86 10 80       	push   $0x8010861d
80102216:	e8 85 e3 ff ff       	call   801005a0 <panic>

  for(off = 0; off < dp->size; off += sizeof(de)){
8010221b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102222:	eb 7b                	jmp    8010229f <dirlookup+0xa4>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80102224:	6a 10                	push   $0x10
80102226:	ff 75 f4             	pushl  -0xc(%ebp)
80102229:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010222c:	50                   	push   %eax
8010222d:	ff 75 08             	pushl  0x8(%ebp)
80102230:	e8 cc fc ff ff       	call   80101f01 <readi>
80102235:	83 c4 10             	add    $0x10,%esp
80102238:	83 f8 10             	cmp    $0x10,%eax
8010223b:	74 0d                	je     8010224a <dirlookup+0x4f>
      panic("dirlookup read");
8010223d:	83 ec 0c             	sub    $0xc,%esp
80102240:	68 2f 86 10 80       	push   $0x8010862f
80102245:	e8 56 e3 ff ff       	call   801005a0 <panic>
    if(de.inum == 0)
8010224a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010224e:	66 85 c0             	test   %ax,%ax
80102251:	74 47                	je     8010229a <dirlookup+0x9f>
      continue;
    if(namecmp(name, de.name) == 0){
80102253:	83 ec 08             	sub    $0x8,%esp
80102256:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102259:	83 c0 02             	add    $0x2,%eax
8010225c:	50                   	push   %eax
8010225d:	ff 75 0c             	pushl  0xc(%ebp)
80102260:	e8 7b ff ff ff       	call   801021e0 <namecmp>
80102265:	83 c4 10             	add    $0x10,%esp
80102268:	85 c0                	test   %eax,%eax
8010226a:	75 2f                	jne    8010229b <dirlookup+0xa0>
      // entry matches path element
      if(poff)
8010226c:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80102270:	74 08                	je     8010227a <dirlookup+0x7f>
        *poff = off;
80102272:	8b 45 10             	mov    0x10(%ebp),%eax
80102275:	8b 55 f4             	mov    -0xc(%ebp),%edx
80102278:	89 10                	mov    %edx,(%eax)
      inum = de.inum;
8010227a:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
8010227e:	0f b7 c0             	movzwl %ax,%eax
80102281:	89 45 f0             	mov    %eax,-0x10(%ebp)
      return iget(dp->dev, inum);
80102284:	8b 45 08             	mov    0x8(%ebp),%eax
80102287:	8b 00                	mov    (%eax),%eax
80102289:	83 ec 08             	sub    $0x8,%esp
8010228c:	ff 75 f0             	pushl  -0x10(%ebp)
8010228f:	50                   	push   %eax
80102290:	e8 5f f6 ff ff       	call   801018f4 <iget>
80102295:	83 c4 10             	add    $0x10,%esp
80102298:	eb 19                	jmp    801022b3 <dirlookup+0xb8>

  for(off = 0; off < dp->size; off += sizeof(de)){
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlookup read");
    if(de.inum == 0)
      continue;
8010229a:	90                   	nop
  struct dirent de;

  if(dp->type != T_DIR)
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
8010229b:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
8010229f:	8b 45 08             	mov    0x8(%ebp),%eax
801022a2:	8b 40 58             	mov    0x58(%eax),%eax
801022a5:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801022a8:	0f 87 76 ff ff ff    	ja     80102224 <dirlookup+0x29>
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
801022ae:	b8 00 00 00 00       	mov    $0x0,%eax
}
801022b3:	c9                   	leave  
801022b4:	c3                   	ret    

801022b5 <dirlink>:

// Write a new directory entry (name, inum) into the directory dp.
int
dirlink(struct inode *dp, char *name, uint inum)
{
801022b5:	55                   	push   %ebp
801022b6:	89 e5                	mov    %esp,%ebp
801022b8:	83 ec 28             	sub    $0x28,%esp
  int off;
  struct dirent de;
  struct inode *ip;

  // Check that name is not present.
  if((ip = dirlookup(dp, name, 0)) != 0){
801022bb:	83 ec 04             	sub    $0x4,%esp
801022be:	6a 00                	push   $0x0
801022c0:	ff 75 0c             	pushl  0xc(%ebp)
801022c3:	ff 75 08             	pushl  0x8(%ebp)
801022c6:	e8 30 ff ff ff       	call   801021fb <dirlookup>
801022cb:	83 c4 10             	add    $0x10,%esp
801022ce:	89 45 f0             	mov    %eax,-0x10(%ebp)
801022d1:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801022d5:	74 18                	je     801022ef <dirlink+0x3a>
    iput(ip);
801022d7:	83 ec 0c             	sub    $0xc,%esp
801022da:	ff 75 f0             	pushl  -0x10(%ebp)
801022dd:	e8 8f f8 ff ff       	call   80101b71 <iput>
801022e2:	83 c4 10             	add    $0x10,%esp
    return -1;
801022e5:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801022ea:	e9 9c 00 00 00       	jmp    8010238b <dirlink+0xd6>
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
801022ef:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801022f6:	eb 39                	jmp    80102331 <dirlink+0x7c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
801022f8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801022fb:	6a 10                	push   $0x10
801022fd:	50                   	push   %eax
801022fe:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102301:	50                   	push   %eax
80102302:	ff 75 08             	pushl  0x8(%ebp)
80102305:	e8 f7 fb ff ff       	call   80101f01 <readi>
8010230a:	83 c4 10             	add    $0x10,%esp
8010230d:	83 f8 10             	cmp    $0x10,%eax
80102310:	74 0d                	je     8010231f <dirlink+0x6a>
      panic("dirlink read");
80102312:	83 ec 0c             	sub    $0xc,%esp
80102315:	68 3e 86 10 80       	push   $0x8010863e
8010231a:	e8 81 e2 ff ff       	call   801005a0 <panic>
    if(de.inum == 0)
8010231f:	0f b7 45 e0          	movzwl -0x20(%ebp),%eax
80102323:	66 85 c0             	test   %ax,%ax
80102326:	74 18                	je     80102340 <dirlink+0x8b>
    iput(ip);
    return -1;
  }

  // Look for an empty dirent.
  for(off = 0; off < dp->size; off += sizeof(de)){
80102328:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010232b:	83 c0 10             	add    $0x10,%eax
8010232e:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102331:	8b 45 08             	mov    0x8(%ebp),%eax
80102334:	8b 50 58             	mov    0x58(%eax),%edx
80102337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010233a:	39 c2                	cmp    %eax,%edx
8010233c:	77 ba                	ja     801022f8 <dirlink+0x43>
8010233e:	eb 01                	jmp    80102341 <dirlink+0x8c>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("dirlink read");
    if(de.inum == 0)
      break;
80102340:	90                   	nop
  }

  strncpy(de.name, name, DIRSIZ);
80102341:	83 ec 04             	sub    $0x4,%esp
80102344:	6a 0e                	push   $0xe
80102346:	ff 75 0c             	pushl  0xc(%ebp)
80102349:	8d 45 e0             	lea    -0x20(%ebp),%eax
8010234c:	83 c0 02             	add    $0x2,%eax
8010234f:	50                   	push   %eax
80102350:	e8 23 30 00 00       	call   80105378 <strncpy>
80102355:	83 c4 10             	add    $0x10,%esp
  de.inum = inum;
80102358:	8b 45 10             	mov    0x10(%ebp),%eax
8010235b:	66 89 45 e0          	mov    %ax,-0x20(%ebp)
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
8010235f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102362:	6a 10                	push   $0x10
80102364:	50                   	push   %eax
80102365:	8d 45 e0             	lea    -0x20(%ebp),%eax
80102368:	50                   	push   %eax
80102369:	ff 75 08             	pushl  0x8(%ebp)
8010236c:	e8 e7 fc ff ff       	call   80102058 <writei>
80102371:	83 c4 10             	add    $0x10,%esp
80102374:	83 f8 10             	cmp    $0x10,%eax
80102377:	74 0d                	je     80102386 <dirlink+0xd1>
    panic("dirlink");
80102379:	83 ec 0c             	sub    $0xc,%esp
8010237c:	68 4b 86 10 80       	push   $0x8010864b
80102381:	e8 1a e2 ff ff       	call   801005a0 <panic>

  return 0;
80102386:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010238b:	c9                   	leave  
8010238c:	c3                   	ret    

8010238d <skipelem>:
//   skipelem("a", name) = "", setting name = "a"
//   skipelem("", name) = skipelem("////", name) = 0
//
static char*
skipelem(char *path, char *name)
{
8010238d:	55                   	push   %ebp
8010238e:	89 e5                	mov    %esp,%ebp
80102390:	83 ec 18             	sub    $0x18,%esp
  char *s;
  int len;

  while(*path == '/')
80102393:	eb 04                	jmp    80102399 <skipelem+0xc>
    path++;
80102395:	83 45 08 01          	addl   $0x1,0x8(%ebp)
skipelem(char *path, char *name)
{
  char *s;
  int len;

  while(*path == '/')
80102399:	8b 45 08             	mov    0x8(%ebp),%eax
8010239c:	0f b6 00             	movzbl (%eax),%eax
8010239f:	3c 2f                	cmp    $0x2f,%al
801023a1:	74 f2                	je     80102395 <skipelem+0x8>
    path++;
  if(*path == 0)
801023a3:	8b 45 08             	mov    0x8(%ebp),%eax
801023a6:	0f b6 00             	movzbl (%eax),%eax
801023a9:	84 c0                	test   %al,%al
801023ab:	75 07                	jne    801023b4 <skipelem+0x27>
    return 0;
801023ad:	b8 00 00 00 00       	mov    $0x0,%eax
801023b2:	eb 7b                	jmp    8010242f <skipelem+0xa2>
  s = path;
801023b4:	8b 45 08             	mov    0x8(%ebp),%eax
801023b7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(*path != '/' && *path != 0)
801023ba:	eb 04                	jmp    801023c0 <skipelem+0x33>
    path++;
801023bc:	83 45 08 01          	addl   $0x1,0x8(%ebp)
  while(*path == '/')
    path++;
  if(*path == 0)
    return 0;
  s = path;
  while(*path != '/' && *path != 0)
801023c0:	8b 45 08             	mov    0x8(%ebp),%eax
801023c3:	0f b6 00             	movzbl (%eax),%eax
801023c6:	3c 2f                	cmp    $0x2f,%al
801023c8:	74 0a                	je     801023d4 <skipelem+0x47>
801023ca:	8b 45 08             	mov    0x8(%ebp),%eax
801023cd:	0f b6 00             	movzbl (%eax),%eax
801023d0:	84 c0                	test   %al,%al
801023d2:	75 e8                	jne    801023bc <skipelem+0x2f>
    path++;
  len = path - s;
801023d4:	8b 55 08             	mov    0x8(%ebp),%edx
801023d7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801023da:	29 c2                	sub    %eax,%edx
801023dc:	89 d0                	mov    %edx,%eax
801023de:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(len >= DIRSIZ)
801023e1:	83 7d f0 0d          	cmpl   $0xd,-0x10(%ebp)
801023e5:	7e 15                	jle    801023fc <skipelem+0x6f>
    memmove(name, s, DIRSIZ);
801023e7:	83 ec 04             	sub    $0x4,%esp
801023ea:	6a 0e                	push   $0xe
801023ec:	ff 75 f4             	pushl  -0xc(%ebp)
801023ef:	ff 75 0c             	pushl  0xc(%ebp)
801023f2:	e8 95 2e 00 00       	call   8010528c <memmove>
801023f7:	83 c4 10             	add    $0x10,%esp
801023fa:	eb 26                	jmp    80102422 <skipelem+0x95>
  else {
    memmove(name, s, len);
801023fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801023ff:	83 ec 04             	sub    $0x4,%esp
80102402:	50                   	push   %eax
80102403:	ff 75 f4             	pushl  -0xc(%ebp)
80102406:	ff 75 0c             	pushl  0xc(%ebp)
80102409:	e8 7e 2e 00 00       	call   8010528c <memmove>
8010240e:	83 c4 10             	add    $0x10,%esp
    name[len] = 0;
80102411:	8b 55 f0             	mov    -0x10(%ebp),%edx
80102414:	8b 45 0c             	mov    0xc(%ebp),%eax
80102417:	01 d0                	add    %edx,%eax
80102419:	c6 00 00             	movb   $0x0,(%eax)
  }
  while(*path == '/')
8010241c:	eb 04                	jmp    80102422 <skipelem+0x95>
    path++;
8010241e:	83 45 08 01          	addl   $0x1,0x8(%ebp)
    memmove(name, s, DIRSIZ);
  else {
    memmove(name, s, len);
    name[len] = 0;
  }
  while(*path == '/')
80102422:	8b 45 08             	mov    0x8(%ebp),%eax
80102425:	0f b6 00             	movzbl (%eax),%eax
80102428:	3c 2f                	cmp    $0x2f,%al
8010242a:	74 f2                	je     8010241e <skipelem+0x91>
    path++;
  return path;
8010242c:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010242f:	c9                   	leave  
80102430:	c3                   	ret    

80102431 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
80102431:	55                   	push   %ebp
80102432:	89 e5                	mov    %esp,%ebp
80102434:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip, *next;

  if(*path == '/')
80102437:	8b 45 08             	mov    0x8(%ebp),%eax
8010243a:	0f b6 00             	movzbl (%eax),%eax
8010243d:	3c 2f                	cmp    $0x2f,%al
8010243f:	75 17                	jne    80102458 <namex+0x27>
    ip = iget(ROOTDEV, ROOTINO);
80102441:	83 ec 08             	sub    $0x8,%esp
80102444:	6a 01                	push   $0x1
80102446:	6a 01                	push   $0x1
80102448:	e8 a7 f4 ff ff       	call   801018f4 <iget>
8010244d:	83 c4 10             	add    $0x10,%esp
80102450:	89 45 f4             	mov    %eax,-0xc(%ebp)
80102453:	e9 ba 00 00 00       	jmp    80102512 <namex+0xe1>
  else
    ip = idup(myproc()->cwd);
80102458:	e8 2b 1e 00 00       	call   80104288 <myproc>
8010245d:	8b 40 68             	mov    0x68(%eax),%eax
80102460:	83 ec 0c             	sub    $0xc,%esp
80102463:	50                   	push   %eax
80102464:	e8 6d f5 ff ff       	call   801019d6 <idup>
80102469:	83 c4 10             	add    $0x10,%esp
8010246c:	89 45 f4             	mov    %eax,-0xc(%ebp)

  while((path = skipelem(path, name)) != 0){
8010246f:	e9 9e 00 00 00       	jmp    80102512 <namex+0xe1>
    ilock(ip);
80102474:	83 ec 0c             	sub    $0xc,%esp
80102477:	ff 75 f4             	pushl  -0xc(%ebp)
8010247a:	e8 91 f5 ff ff       	call   80101a10 <ilock>
8010247f:	83 c4 10             	add    $0x10,%esp
    if(ip->type != T_DIR){
80102482:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102485:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80102489:	66 83 f8 01          	cmp    $0x1,%ax
8010248d:	74 18                	je     801024a7 <namex+0x76>
      iunlockput(ip);
8010248f:	83 ec 0c             	sub    $0xc,%esp
80102492:	ff 75 f4             	pushl  -0xc(%ebp)
80102495:	e8 a7 f7 ff ff       	call   80101c41 <iunlockput>
8010249a:	83 c4 10             	add    $0x10,%esp
      return 0;
8010249d:	b8 00 00 00 00       	mov    $0x0,%eax
801024a2:	e9 a7 00 00 00       	jmp    8010254e <namex+0x11d>
    }
    if(nameiparent && *path == '\0'){
801024a7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
801024ab:	74 20                	je     801024cd <namex+0x9c>
801024ad:	8b 45 08             	mov    0x8(%ebp),%eax
801024b0:	0f b6 00             	movzbl (%eax),%eax
801024b3:	84 c0                	test   %al,%al
801024b5:	75 16                	jne    801024cd <namex+0x9c>
      // Stop one level early.
      iunlock(ip);
801024b7:	83 ec 0c             	sub    $0xc,%esp
801024ba:	ff 75 f4             	pushl  -0xc(%ebp)
801024bd:	e8 61 f6 ff ff       	call   80101b23 <iunlock>
801024c2:	83 c4 10             	add    $0x10,%esp
      return ip;
801024c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801024c8:	e9 81 00 00 00       	jmp    8010254e <namex+0x11d>
    }
    if((next = dirlookup(ip, name, 0)) == 0){
801024cd:	83 ec 04             	sub    $0x4,%esp
801024d0:	6a 00                	push   $0x0
801024d2:	ff 75 10             	pushl  0x10(%ebp)
801024d5:	ff 75 f4             	pushl  -0xc(%ebp)
801024d8:	e8 1e fd ff ff       	call   801021fb <dirlookup>
801024dd:	83 c4 10             	add    $0x10,%esp
801024e0:	89 45 f0             	mov    %eax,-0x10(%ebp)
801024e3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801024e7:	75 15                	jne    801024fe <namex+0xcd>
      iunlockput(ip);
801024e9:	83 ec 0c             	sub    $0xc,%esp
801024ec:	ff 75 f4             	pushl  -0xc(%ebp)
801024ef:	e8 4d f7 ff ff       	call   80101c41 <iunlockput>
801024f4:	83 c4 10             	add    $0x10,%esp
      return 0;
801024f7:	b8 00 00 00 00       	mov    $0x0,%eax
801024fc:	eb 50                	jmp    8010254e <namex+0x11d>
    }
    iunlockput(ip);
801024fe:	83 ec 0c             	sub    $0xc,%esp
80102501:	ff 75 f4             	pushl  -0xc(%ebp)
80102504:	e8 38 f7 ff ff       	call   80101c41 <iunlockput>
80102509:	83 c4 10             	add    $0x10,%esp
    ip = next;
8010250c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010250f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(*path == '/')
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);

  while((path = skipelem(path, name)) != 0){
80102512:	83 ec 08             	sub    $0x8,%esp
80102515:	ff 75 10             	pushl  0x10(%ebp)
80102518:	ff 75 08             	pushl  0x8(%ebp)
8010251b:	e8 6d fe ff ff       	call   8010238d <skipelem>
80102520:	83 c4 10             	add    $0x10,%esp
80102523:	89 45 08             	mov    %eax,0x8(%ebp)
80102526:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010252a:	0f 85 44 ff ff ff    	jne    80102474 <namex+0x43>
      return 0;
    }
    iunlockput(ip);
    ip = next;
  }
  if(nameiparent){
80102530:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80102534:	74 15                	je     8010254b <namex+0x11a>
    iput(ip);
80102536:	83 ec 0c             	sub    $0xc,%esp
80102539:	ff 75 f4             	pushl  -0xc(%ebp)
8010253c:	e8 30 f6 ff ff       	call   80101b71 <iput>
80102541:	83 c4 10             	add    $0x10,%esp
    return 0;
80102544:	b8 00 00 00 00       	mov    $0x0,%eax
80102549:	eb 03                	jmp    8010254e <namex+0x11d>
  }
  return ip;
8010254b:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010254e:	c9                   	leave  
8010254f:	c3                   	ret    

80102550 <namei>:

struct inode*
namei(char *path)
{
80102550:	55                   	push   %ebp
80102551:	89 e5                	mov    %esp,%ebp
80102553:	83 ec 18             	sub    $0x18,%esp
  char name[DIRSIZ];
  return namex(path, 0, name);
80102556:	83 ec 04             	sub    $0x4,%esp
80102559:	8d 45 ea             	lea    -0x16(%ebp),%eax
8010255c:	50                   	push   %eax
8010255d:	6a 00                	push   $0x0
8010255f:	ff 75 08             	pushl  0x8(%ebp)
80102562:	e8 ca fe ff ff       	call   80102431 <namex>
80102567:	83 c4 10             	add    $0x10,%esp
}
8010256a:	c9                   	leave  
8010256b:	c3                   	ret    

8010256c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
8010256c:	55                   	push   %ebp
8010256d:	89 e5                	mov    %esp,%ebp
8010256f:	83 ec 08             	sub    $0x8,%esp
  return namex(path, 1, name);
80102572:	83 ec 04             	sub    $0x4,%esp
80102575:	ff 75 0c             	pushl  0xc(%ebp)
80102578:	6a 01                	push   $0x1
8010257a:	ff 75 08             	pushl  0x8(%ebp)
8010257d:	e8 af fe ff ff       	call   80102431 <namex>
80102582:	83 c4 10             	add    $0x10,%esp
}
80102585:	c9                   	leave  
80102586:	c3                   	ret    

80102587 <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102587:	55                   	push   %ebp
80102588:	89 e5                	mov    %esp,%ebp
8010258a:	83 ec 14             	sub    $0x14,%esp
8010258d:	8b 45 08             	mov    0x8(%ebp),%eax
80102590:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102594:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102598:	89 c2                	mov    %eax,%edx
8010259a:	ec                   	in     (%dx),%al
8010259b:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
8010259e:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
801025a2:	c9                   	leave  
801025a3:	c3                   	ret    

801025a4 <insl>:

static inline void
insl(int port, void *addr, int cnt)
{
801025a4:	55                   	push   %ebp
801025a5:	89 e5                	mov    %esp,%ebp
801025a7:	57                   	push   %edi
801025a8:	53                   	push   %ebx
  asm volatile("cld; rep insl" :
801025a9:	8b 55 08             	mov    0x8(%ebp),%edx
801025ac:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025af:	8b 45 10             	mov    0x10(%ebp),%eax
801025b2:	89 cb                	mov    %ecx,%ebx
801025b4:	89 df                	mov    %ebx,%edi
801025b6:	89 c1                	mov    %eax,%ecx
801025b8:	fc                   	cld    
801025b9:	f3 6d                	rep insl (%dx),%es:(%edi)
801025bb:	89 c8                	mov    %ecx,%eax
801025bd:	89 fb                	mov    %edi,%ebx
801025bf:	89 5d 0c             	mov    %ebx,0xc(%ebp)
801025c2:	89 45 10             	mov    %eax,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "memory", "cc");
}
801025c5:	90                   	nop
801025c6:	5b                   	pop    %ebx
801025c7:	5f                   	pop    %edi
801025c8:	5d                   	pop    %ebp
801025c9:	c3                   	ret    

801025ca <outb>:

static inline void
outb(ushort port, uchar data)
{
801025ca:	55                   	push   %ebp
801025cb:	89 e5                	mov    %esp,%ebp
801025cd:	83 ec 08             	sub    $0x8,%esp
801025d0:	8b 55 08             	mov    0x8(%ebp),%edx
801025d3:	8b 45 0c             	mov    0xc(%ebp),%eax
801025d6:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
801025da:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
801025dd:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
801025e1:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
801025e5:	ee                   	out    %al,(%dx)
}
801025e6:	90                   	nop
801025e7:	c9                   	leave  
801025e8:	c3                   	ret    

801025e9 <outsl>:
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
}

static inline void
outsl(int port, const void *addr, int cnt)
{
801025e9:	55                   	push   %ebp
801025ea:	89 e5                	mov    %esp,%ebp
801025ec:	56                   	push   %esi
801025ed:	53                   	push   %ebx
  asm volatile("cld; rep outsl" :
801025ee:	8b 55 08             	mov    0x8(%ebp),%edx
801025f1:	8b 4d 0c             	mov    0xc(%ebp),%ecx
801025f4:	8b 45 10             	mov    0x10(%ebp),%eax
801025f7:	89 cb                	mov    %ecx,%ebx
801025f9:	89 de                	mov    %ebx,%esi
801025fb:	89 c1                	mov    %eax,%ecx
801025fd:	fc                   	cld    
801025fe:	f3 6f                	rep outsl %ds:(%esi),(%dx)
80102600:	89 c8                	mov    %ecx,%eax
80102602:	89 f3                	mov    %esi,%ebx
80102604:	89 5d 0c             	mov    %ebx,0xc(%ebp)
80102607:	89 45 10             	mov    %eax,0x10(%ebp)
               "=S" (addr), "=c" (cnt) :
               "d" (port), "0" (addr), "1" (cnt) :
               "cc");
}
8010260a:	90                   	nop
8010260b:	5b                   	pop    %ebx
8010260c:	5e                   	pop    %esi
8010260d:	5d                   	pop    %ebp
8010260e:	c3                   	ret    

8010260f <idewait>:
static void idestart(struct buf*);

// Wait for IDE disk to become ready.
static int
idewait(int checkerr)
{
8010260f:	55                   	push   %ebp
80102610:	89 e5                	mov    %esp,%ebp
80102612:	83 ec 10             	sub    $0x10,%esp
  int r;

  while(((r = inb(0x1f7)) & (IDE_BSY|IDE_DRDY)) != IDE_DRDY)
80102615:	90                   	nop
80102616:	68 f7 01 00 00       	push   $0x1f7
8010261b:	e8 67 ff ff ff       	call   80102587 <inb>
80102620:	83 c4 04             	add    $0x4,%esp
80102623:	0f b6 c0             	movzbl %al,%eax
80102626:	89 45 fc             	mov    %eax,-0x4(%ebp)
80102629:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010262c:	25 c0 00 00 00       	and    $0xc0,%eax
80102631:	83 f8 40             	cmp    $0x40,%eax
80102634:	75 e0                	jne    80102616 <idewait+0x7>
    ;
  if(checkerr && (r & (IDE_DF|IDE_ERR)) != 0)
80102636:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010263a:	74 11                	je     8010264d <idewait+0x3e>
8010263c:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010263f:	83 e0 21             	and    $0x21,%eax
80102642:	85 c0                	test   %eax,%eax
80102644:	74 07                	je     8010264d <idewait+0x3e>
    return -1;
80102646:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010264b:	eb 05                	jmp    80102652 <idewait+0x43>
  return 0;
8010264d:	b8 00 00 00 00       	mov    $0x0,%eax
}
80102652:	c9                   	leave  
80102653:	c3                   	ret    

80102654 <ideinit>:

void
ideinit(void)
{
80102654:	55                   	push   %ebp
80102655:	89 e5                	mov    %esp,%ebp
80102657:	83 ec 18             	sub    $0x18,%esp
  int i;

  initlock(&idelock, "ide");
8010265a:	83 ec 08             	sub    $0x8,%esp
8010265d:	68 53 86 10 80       	push   $0x80108653
80102662:	68 e0 b5 10 80       	push   $0x8010b5e0
80102667:	e8 c8 28 00 00       	call   80104f34 <initlock>
8010266c:	83 c4 10             	add    $0x10,%esp
  ioapicenable(IRQ_IDE, ncpu - 1);
8010266f:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80102674:	83 e8 01             	sub    $0x1,%eax
80102677:	83 ec 08             	sub    $0x8,%esp
8010267a:	50                   	push   %eax
8010267b:	6a 0e                	push   $0xe
8010267d:	e8 a2 04 00 00       	call   80102b24 <ioapicenable>
80102682:	83 c4 10             	add    $0x10,%esp
  idewait(0);
80102685:	83 ec 0c             	sub    $0xc,%esp
80102688:	6a 00                	push   $0x0
8010268a:	e8 80 ff ff ff       	call   8010260f <idewait>
8010268f:	83 c4 10             	add    $0x10,%esp

  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
80102692:	83 ec 08             	sub    $0x8,%esp
80102695:	68 f0 00 00 00       	push   $0xf0
8010269a:	68 f6 01 00 00       	push   $0x1f6
8010269f:	e8 26 ff ff ff       	call   801025ca <outb>
801026a4:	83 c4 10             	add    $0x10,%esp
  for(i=0; i<1000; i++){
801026a7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801026ae:	eb 24                	jmp    801026d4 <ideinit+0x80>
    if(inb(0x1f7) != 0){
801026b0:	83 ec 0c             	sub    $0xc,%esp
801026b3:	68 f7 01 00 00       	push   $0x1f7
801026b8:	e8 ca fe ff ff       	call   80102587 <inb>
801026bd:	83 c4 10             	add    $0x10,%esp
801026c0:	84 c0                	test   %al,%al
801026c2:	74 0c                	je     801026d0 <ideinit+0x7c>
      havedisk1 = 1;
801026c4:	c7 05 18 b6 10 80 01 	movl   $0x1,0x8010b618
801026cb:	00 00 00 
      break;
801026ce:	eb 0d                	jmp    801026dd <ideinit+0x89>
  ioapicenable(IRQ_IDE, ncpu - 1);
  idewait(0);

  // Check if disk 1 is present
  outb(0x1f6, 0xe0 | (1<<4));
  for(i=0; i<1000; i++){
801026d0:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801026d4:	81 7d f4 e7 03 00 00 	cmpl   $0x3e7,-0xc(%ebp)
801026db:	7e d3                	jle    801026b0 <ideinit+0x5c>
      break;
    }
  }

  // Switch back to disk 0.
  outb(0x1f6, 0xe0 | (0<<4));
801026dd:	83 ec 08             	sub    $0x8,%esp
801026e0:	68 e0 00 00 00       	push   $0xe0
801026e5:	68 f6 01 00 00       	push   $0x1f6
801026ea:	e8 db fe ff ff       	call   801025ca <outb>
801026ef:	83 c4 10             	add    $0x10,%esp
}
801026f2:	90                   	nop
801026f3:	c9                   	leave  
801026f4:	c3                   	ret    

801026f5 <idestart>:

// Start the request for b.  Caller must hold idelock.
static void
idestart(struct buf *b)
{
801026f5:	55                   	push   %ebp
801026f6:	89 e5                	mov    %esp,%ebp
801026f8:	83 ec 18             	sub    $0x18,%esp
  if(b == 0)
801026fb:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801026ff:	75 0d                	jne    8010270e <idestart+0x19>
    panic("idestart");
80102701:	83 ec 0c             	sub    $0xc,%esp
80102704:	68 57 86 10 80       	push   $0x80108657
80102709:	e8 92 de ff ff       	call   801005a0 <panic>
  if(b->blockno >= FSSIZE)
8010270e:	8b 45 08             	mov    0x8(%ebp),%eax
80102711:	8b 40 08             	mov    0x8(%eax),%eax
80102714:	3d e7 03 00 00       	cmp    $0x3e7,%eax
80102719:	76 0d                	jbe    80102728 <idestart+0x33>
    panic("incorrect blockno");
8010271b:	83 ec 0c             	sub    $0xc,%esp
8010271e:	68 60 86 10 80       	push   $0x80108660
80102723:	e8 78 de ff ff       	call   801005a0 <panic>
  int sector_per_block =  BSIZE/SECTOR_SIZE;
80102728:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
  int sector = b->blockno * sector_per_block;
8010272f:	8b 45 08             	mov    0x8(%ebp),%eax
80102732:	8b 50 08             	mov    0x8(%eax),%edx
80102735:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102738:	0f af c2             	imul   %edx,%eax
8010273b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  int read_cmd = (sector_per_block == 1) ? IDE_CMD_READ :  IDE_CMD_RDMUL;
8010273e:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80102742:	75 07                	jne    8010274b <idestart+0x56>
80102744:	b8 20 00 00 00       	mov    $0x20,%eax
80102749:	eb 05                	jmp    80102750 <idestart+0x5b>
8010274b:	b8 c4 00 00 00       	mov    $0xc4,%eax
80102750:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int write_cmd = (sector_per_block == 1) ? IDE_CMD_WRITE : IDE_CMD_WRMUL;
80102753:	83 7d f4 01          	cmpl   $0x1,-0xc(%ebp)
80102757:	75 07                	jne    80102760 <idestart+0x6b>
80102759:	b8 30 00 00 00       	mov    $0x30,%eax
8010275e:	eb 05                	jmp    80102765 <idestart+0x70>
80102760:	b8 c5 00 00 00       	mov    $0xc5,%eax
80102765:	89 45 e8             	mov    %eax,-0x18(%ebp)

  if (sector_per_block > 7) panic("idestart");
80102768:	83 7d f4 07          	cmpl   $0x7,-0xc(%ebp)
8010276c:	7e 0d                	jle    8010277b <idestart+0x86>
8010276e:	83 ec 0c             	sub    $0xc,%esp
80102771:	68 57 86 10 80       	push   $0x80108657
80102776:	e8 25 de ff ff       	call   801005a0 <panic>

  idewait(0);
8010277b:	83 ec 0c             	sub    $0xc,%esp
8010277e:	6a 00                	push   $0x0
80102780:	e8 8a fe ff ff       	call   8010260f <idewait>
80102785:	83 c4 10             	add    $0x10,%esp
  outb(0x3f6, 0);  // generate interrupt
80102788:	83 ec 08             	sub    $0x8,%esp
8010278b:	6a 00                	push   $0x0
8010278d:	68 f6 03 00 00       	push   $0x3f6
80102792:	e8 33 fe ff ff       	call   801025ca <outb>
80102797:	83 c4 10             	add    $0x10,%esp
  outb(0x1f2, sector_per_block);  // number of sectors
8010279a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010279d:	0f b6 c0             	movzbl %al,%eax
801027a0:	83 ec 08             	sub    $0x8,%esp
801027a3:	50                   	push   %eax
801027a4:	68 f2 01 00 00       	push   $0x1f2
801027a9:	e8 1c fe ff ff       	call   801025ca <outb>
801027ae:	83 c4 10             	add    $0x10,%esp
  outb(0x1f3, sector & 0xff);
801027b1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027b4:	0f b6 c0             	movzbl %al,%eax
801027b7:	83 ec 08             	sub    $0x8,%esp
801027ba:	50                   	push   %eax
801027bb:	68 f3 01 00 00       	push   $0x1f3
801027c0:	e8 05 fe ff ff       	call   801025ca <outb>
801027c5:	83 c4 10             	add    $0x10,%esp
  outb(0x1f4, (sector >> 8) & 0xff);
801027c8:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027cb:	c1 f8 08             	sar    $0x8,%eax
801027ce:	0f b6 c0             	movzbl %al,%eax
801027d1:	83 ec 08             	sub    $0x8,%esp
801027d4:	50                   	push   %eax
801027d5:	68 f4 01 00 00       	push   $0x1f4
801027da:	e8 eb fd ff ff       	call   801025ca <outb>
801027df:	83 c4 10             	add    $0x10,%esp
  outb(0x1f5, (sector >> 16) & 0xff);
801027e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801027e5:	c1 f8 10             	sar    $0x10,%eax
801027e8:	0f b6 c0             	movzbl %al,%eax
801027eb:	83 ec 08             	sub    $0x8,%esp
801027ee:	50                   	push   %eax
801027ef:	68 f5 01 00 00       	push   $0x1f5
801027f4:	e8 d1 fd ff ff       	call   801025ca <outb>
801027f9:	83 c4 10             	add    $0x10,%esp
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
801027fc:	8b 45 08             	mov    0x8(%ebp),%eax
801027ff:	8b 40 04             	mov    0x4(%eax),%eax
80102802:	83 e0 01             	and    $0x1,%eax
80102805:	c1 e0 04             	shl    $0x4,%eax
80102808:	89 c2                	mov    %eax,%edx
8010280a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010280d:	c1 f8 18             	sar    $0x18,%eax
80102810:	83 e0 0f             	and    $0xf,%eax
80102813:	09 d0                	or     %edx,%eax
80102815:	83 c8 e0             	or     $0xffffffe0,%eax
80102818:	0f b6 c0             	movzbl %al,%eax
8010281b:	83 ec 08             	sub    $0x8,%esp
8010281e:	50                   	push   %eax
8010281f:	68 f6 01 00 00       	push   $0x1f6
80102824:	e8 a1 fd ff ff       	call   801025ca <outb>
80102829:	83 c4 10             	add    $0x10,%esp
  if(b->flags & B_DIRTY){
8010282c:	8b 45 08             	mov    0x8(%ebp),%eax
8010282f:	8b 00                	mov    (%eax),%eax
80102831:	83 e0 04             	and    $0x4,%eax
80102834:	85 c0                	test   %eax,%eax
80102836:	74 35                	je     8010286d <idestart+0x178>
    outb(0x1f7, write_cmd);
80102838:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010283b:	0f b6 c0             	movzbl %al,%eax
8010283e:	83 ec 08             	sub    $0x8,%esp
80102841:	50                   	push   %eax
80102842:	68 f7 01 00 00       	push   $0x1f7
80102847:	e8 7e fd ff ff       	call   801025ca <outb>
8010284c:	83 c4 10             	add    $0x10,%esp
    outsl(0x1f0, b->data, BSIZE/4);
8010284f:	8b 45 08             	mov    0x8(%ebp),%eax
80102852:	83 c0 5c             	add    $0x5c,%eax
80102855:	83 ec 04             	sub    $0x4,%esp
80102858:	68 80 00 00 00       	push   $0x80
8010285d:	50                   	push   %eax
8010285e:	68 f0 01 00 00       	push   $0x1f0
80102863:	e8 81 fd ff ff       	call   801025e9 <outsl>
80102868:	83 c4 10             	add    $0x10,%esp
  } else {
    outb(0x1f7, read_cmd);
  }
}
8010286b:	eb 17                	jmp    80102884 <idestart+0x18f>
  outb(0x1f6, 0xe0 | ((b->dev&1)<<4) | ((sector>>24)&0x0f));
  if(b->flags & B_DIRTY){
    outb(0x1f7, write_cmd);
    outsl(0x1f0, b->data, BSIZE/4);
  } else {
    outb(0x1f7, read_cmd);
8010286d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80102870:	0f b6 c0             	movzbl %al,%eax
80102873:	83 ec 08             	sub    $0x8,%esp
80102876:	50                   	push   %eax
80102877:	68 f7 01 00 00       	push   $0x1f7
8010287c:	e8 49 fd ff ff       	call   801025ca <outb>
80102881:	83 c4 10             	add    $0x10,%esp
  }
}
80102884:	90                   	nop
80102885:	c9                   	leave  
80102886:	c3                   	ret    

80102887 <ideintr>:

// Interrupt handler.
void
ideintr(void)
{
80102887:	55                   	push   %ebp
80102888:	89 e5                	mov    %esp,%ebp
8010288a:	83 ec 18             	sub    $0x18,%esp
  struct buf *b;

  // First queued buffer is the active request.
  acquire(&idelock);
8010288d:	83 ec 0c             	sub    $0xc,%esp
80102890:	68 e0 b5 10 80       	push   $0x8010b5e0
80102895:	e8 bc 26 00 00       	call   80104f56 <acquire>
8010289a:	83 c4 10             	add    $0x10,%esp

  if((b = idequeue) == 0){
8010289d:	a1 14 b6 10 80       	mov    0x8010b614,%eax
801028a2:	89 45 f4             	mov    %eax,-0xc(%ebp)
801028a5:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801028a9:	75 15                	jne    801028c0 <ideintr+0x39>
    release(&idelock);
801028ab:	83 ec 0c             	sub    $0xc,%esp
801028ae:	68 e0 b5 10 80       	push   $0x8010b5e0
801028b3:	e8 0c 27 00 00       	call   80104fc4 <release>
801028b8:	83 c4 10             	add    $0x10,%esp
    return;
801028bb:	e9 9a 00 00 00       	jmp    8010295a <ideintr+0xd3>
  }
  idequeue = b->qnext;
801028c0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028c3:	8b 40 58             	mov    0x58(%eax),%eax
801028c6:	a3 14 b6 10 80       	mov    %eax,0x8010b614

  // Read data if needed.
  if(!(b->flags & B_DIRTY) && idewait(1) >= 0)
801028cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028ce:	8b 00                	mov    (%eax),%eax
801028d0:	83 e0 04             	and    $0x4,%eax
801028d3:	85 c0                	test   %eax,%eax
801028d5:	75 2d                	jne    80102904 <ideintr+0x7d>
801028d7:	83 ec 0c             	sub    $0xc,%esp
801028da:	6a 01                	push   $0x1
801028dc:	e8 2e fd ff ff       	call   8010260f <idewait>
801028e1:	83 c4 10             	add    $0x10,%esp
801028e4:	85 c0                	test   %eax,%eax
801028e6:	78 1c                	js     80102904 <ideintr+0x7d>
    insl(0x1f0, b->data, BSIZE/4);
801028e8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801028eb:	83 c0 5c             	add    $0x5c,%eax
801028ee:	83 ec 04             	sub    $0x4,%esp
801028f1:	68 80 00 00 00       	push   $0x80
801028f6:	50                   	push   %eax
801028f7:	68 f0 01 00 00       	push   $0x1f0
801028fc:	e8 a3 fc ff ff       	call   801025a4 <insl>
80102901:	83 c4 10             	add    $0x10,%esp

  // Wake process waiting for this buf.
  b->flags |= B_VALID;
80102904:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102907:	8b 00                	mov    (%eax),%eax
80102909:	83 c8 02             	or     $0x2,%eax
8010290c:	89 c2                	mov    %eax,%edx
8010290e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102911:	89 10                	mov    %edx,(%eax)
  b->flags &= ~B_DIRTY;
80102913:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102916:	8b 00                	mov    (%eax),%eax
80102918:	83 e0 fb             	and    $0xfffffffb,%eax
8010291b:	89 c2                	mov    %eax,%edx
8010291d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102920:	89 10                	mov    %edx,(%eax)
  wakeup(b);
80102922:	83 ec 0c             	sub    $0xc,%esp
80102925:	ff 75 f4             	pushl  -0xc(%ebp)
80102928:	e8 f6 22 00 00       	call   80104c23 <wakeup>
8010292d:	83 c4 10             	add    $0x10,%esp

  // Start disk on next buf in queue.
  if(idequeue != 0)
80102930:	a1 14 b6 10 80       	mov    0x8010b614,%eax
80102935:	85 c0                	test   %eax,%eax
80102937:	74 11                	je     8010294a <ideintr+0xc3>
    idestart(idequeue);
80102939:	a1 14 b6 10 80       	mov    0x8010b614,%eax
8010293e:	83 ec 0c             	sub    $0xc,%esp
80102941:	50                   	push   %eax
80102942:	e8 ae fd ff ff       	call   801026f5 <idestart>
80102947:	83 c4 10             	add    $0x10,%esp

  release(&idelock);
8010294a:	83 ec 0c             	sub    $0xc,%esp
8010294d:	68 e0 b5 10 80       	push   $0x8010b5e0
80102952:	e8 6d 26 00 00       	call   80104fc4 <release>
80102957:	83 c4 10             	add    $0x10,%esp
}
8010295a:	c9                   	leave  
8010295b:	c3                   	ret    

8010295c <iderw>:
// Sync buf with disk.
// If B_DIRTY is set, write buf to disk, clear B_DIRTY, set B_VALID.
// Else if B_VALID is not set, read buf from disk, set B_VALID.
void
iderw(struct buf *b)
{
8010295c:	55                   	push   %ebp
8010295d:	89 e5                	mov    %esp,%ebp
8010295f:	83 ec 18             	sub    $0x18,%esp
  struct buf **pp;

  if(!holdingsleep(&b->lock))
80102962:	8b 45 08             	mov    0x8(%ebp),%eax
80102965:	83 c0 0c             	add    $0xc,%eax
80102968:	83 ec 0c             	sub    $0xc,%esp
8010296b:	50                   	push   %eax
8010296c:	e8 54 25 00 00       	call   80104ec5 <holdingsleep>
80102971:	83 c4 10             	add    $0x10,%esp
80102974:	85 c0                	test   %eax,%eax
80102976:	75 0d                	jne    80102985 <iderw+0x29>
    panic("iderw: buf not locked");
80102978:	83 ec 0c             	sub    $0xc,%esp
8010297b:	68 72 86 10 80       	push   $0x80108672
80102980:	e8 1b dc ff ff       	call   801005a0 <panic>
  if((b->flags & (B_VALID|B_DIRTY)) == B_VALID)
80102985:	8b 45 08             	mov    0x8(%ebp),%eax
80102988:	8b 00                	mov    (%eax),%eax
8010298a:	83 e0 06             	and    $0x6,%eax
8010298d:	83 f8 02             	cmp    $0x2,%eax
80102990:	75 0d                	jne    8010299f <iderw+0x43>
    panic("iderw: nothing to do");
80102992:	83 ec 0c             	sub    $0xc,%esp
80102995:	68 88 86 10 80       	push   $0x80108688
8010299a:	e8 01 dc ff ff       	call   801005a0 <panic>
  if(b->dev != 0 && !havedisk1)
8010299f:	8b 45 08             	mov    0x8(%ebp),%eax
801029a2:	8b 40 04             	mov    0x4(%eax),%eax
801029a5:	85 c0                	test   %eax,%eax
801029a7:	74 16                	je     801029bf <iderw+0x63>
801029a9:	a1 18 b6 10 80       	mov    0x8010b618,%eax
801029ae:	85 c0                	test   %eax,%eax
801029b0:	75 0d                	jne    801029bf <iderw+0x63>
    panic("iderw: ide disk 1 not present");
801029b2:	83 ec 0c             	sub    $0xc,%esp
801029b5:	68 9d 86 10 80       	push   $0x8010869d
801029ba:	e8 e1 db ff ff       	call   801005a0 <panic>

  acquire(&idelock);  //DOC:acquire-lock
801029bf:	83 ec 0c             	sub    $0xc,%esp
801029c2:	68 e0 b5 10 80       	push   $0x8010b5e0
801029c7:	e8 8a 25 00 00       	call   80104f56 <acquire>
801029cc:	83 c4 10             	add    $0x10,%esp

  // Append b to idequeue.
  b->qnext = 0;
801029cf:	8b 45 08             	mov    0x8(%ebp),%eax
801029d2:	c7 40 58 00 00 00 00 	movl   $0x0,0x58(%eax)
  for(pp=&idequeue; *pp; pp=&(*pp)->qnext)  //DOC:insert-queue
801029d9:	c7 45 f4 14 b6 10 80 	movl   $0x8010b614,-0xc(%ebp)
801029e0:	eb 0b                	jmp    801029ed <iderw+0x91>
801029e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029e5:	8b 00                	mov    (%eax),%eax
801029e7:	83 c0 58             	add    $0x58,%eax
801029ea:	89 45 f4             	mov    %eax,-0xc(%ebp)
801029ed:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f0:	8b 00                	mov    (%eax),%eax
801029f2:	85 c0                	test   %eax,%eax
801029f4:	75 ec                	jne    801029e2 <iderw+0x86>
    ;
  *pp = b;
801029f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801029f9:	8b 55 08             	mov    0x8(%ebp),%edx
801029fc:	89 10                	mov    %edx,(%eax)

  // Start disk if necessary.
  if(idequeue == b)
801029fe:	a1 14 b6 10 80       	mov    0x8010b614,%eax
80102a03:	3b 45 08             	cmp    0x8(%ebp),%eax
80102a06:	75 23                	jne    80102a2b <iderw+0xcf>
    idestart(b);
80102a08:	83 ec 0c             	sub    $0xc,%esp
80102a0b:	ff 75 08             	pushl  0x8(%ebp)
80102a0e:	e8 e2 fc ff ff       	call   801026f5 <idestart>
80102a13:	83 c4 10             	add    $0x10,%esp

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a16:	eb 13                	jmp    80102a2b <iderw+0xcf>
    sleep(b, &idelock);
80102a18:	83 ec 08             	sub    $0x8,%esp
80102a1b:	68 e0 b5 10 80       	push   $0x8010b5e0
80102a20:	ff 75 08             	pushl  0x8(%ebp)
80102a23:	e8 15 21 00 00       	call   80104b3d <sleep>
80102a28:	83 c4 10             	add    $0x10,%esp
  // Start disk if necessary.
  if(idequeue == b)
    idestart(b);

  // Wait for request to finish.
  while((b->flags & (B_VALID|B_DIRTY)) != B_VALID){
80102a2b:	8b 45 08             	mov    0x8(%ebp),%eax
80102a2e:	8b 00                	mov    (%eax),%eax
80102a30:	83 e0 06             	and    $0x6,%eax
80102a33:	83 f8 02             	cmp    $0x2,%eax
80102a36:	75 e0                	jne    80102a18 <iderw+0xbc>
    sleep(b, &idelock);
  }


  release(&idelock);
80102a38:	83 ec 0c             	sub    $0xc,%esp
80102a3b:	68 e0 b5 10 80       	push   $0x8010b5e0
80102a40:	e8 7f 25 00 00       	call   80104fc4 <release>
80102a45:	83 c4 10             	add    $0x10,%esp
}
80102a48:	90                   	nop
80102a49:	c9                   	leave  
80102a4a:	c3                   	ret    

80102a4b <ioapicread>:
  uint data;
};

static uint
ioapicread(int reg)
{
80102a4b:	55                   	push   %ebp
80102a4c:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a4e:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a53:	8b 55 08             	mov    0x8(%ebp),%edx
80102a56:	89 10                	mov    %edx,(%eax)
  return ioapic->data;
80102a58:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a5d:	8b 40 10             	mov    0x10(%eax),%eax
}
80102a60:	5d                   	pop    %ebp
80102a61:	c3                   	ret    

80102a62 <ioapicwrite>:

static void
ioapicwrite(int reg, uint data)
{
80102a62:	55                   	push   %ebp
80102a63:	89 e5                	mov    %esp,%ebp
  ioapic->reg = reg;
80102a65:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a6a:	8b 55 08             	mov    0x8(%ebp),%edx
80102a6d:	89 10                	mov    %edx,(%eax)
  ioapic->data = data;
80102a6f:	a1 b4 36 11 80       	mov    0x801136b4,%eax
80102a74:	8b 55 0c             	mov    0xc(%ebp),%edx
80102a77:	89 50 10             	mov    %edx,0x10(%eax)
}
80102a7a:	90                   	nop
80102a7b:	5d                   	pop    %ebp
80102a7c:	c3                   	ret    

80102a7d <ioapicinit>:

void
ioapicinit(void)
{
80102a7d:	55                   	push   %ebp
80102a7e:	89 e5                	mov    %esp,%ebp
80102a80:	83 ec 18             	sub    $0x18,%esp
  int i, id, maxintr;

  ioapic = (volatile struct ioapic*)IOAPIC;
80102a83:	c7 05 b4 36 11 80 00 	movl   $0xfec00000,0x801136b4
80102a8a:	00 c0 fe 
  maxintr = (ioapicread(REG_VER) >> 16) & 0xFF;
80102a8d:	6a 01                	push   $0x1
80102a8f:	e8 b7 ff ff ff       	call   80102a4b <ioapicread>
80102a94:	83 c4 04             	add    $0x4,%esp
80102a97:	c1 e8 10             	shr    $0x10,%eax
80102a9a:	25 ff 00 00 00       	and    $0xff,%eax
80102a9f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  id = ioapicread(REG_ID) >> 24;
80102aa2:	6a 00                	push   $0x0
80102aa4:	e8 a2 ff ff ff       	call   80102a4b <ioapicread>
80102aa9:	83 c4 04             	add    $0x4,%esp
80102aac:	c1 e8 18             	shr    $0x18,%eax
80102aaf:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(id != ioapicid)
80102ab2:	0f b6 05 e0 37 11 80 	movzbl 0x801137e0,%eax
80102ab9:	0f b6 c0             	movzbl %al,%eax
80102abc:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80102abf:	74 10                	je     80102ad1 <ioapicinit+0x54>
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");
80102ac1:	83 ec 0c             	sub    $0xc,%esp
80102ac4:	68 bc 86 10 80       	push   $0x801086bc
80102ac9:	e8 32 d9 ff ff       	call   80100400 <cprintf>
80102ace:	83 c4 10             	add    $0x10,%esp

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102ad1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80102ad8:	eb 3f                	jmp    80102b19 <ioapicinit+0x9c>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
80102ada:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102add:	83 c0 20             	add    $0x20,%eax
80102ae0:	0d 00 00 01 00       	or     $0x10000,%eax
80102ae5:	89 c2                	mov    %eax,%edx
80102ae7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aea:	83 c0 08             	add    $0x8,%eax
80102aed:	01 c0                	add    %eax,%eax
80102aef:	83 ec 08             	sub    $0x8,%esp
80102af2:	52                   	push   %edx
80102af3:	50                   	push   %eax
80102af4:	e8 69 ff ff ff       	call   80102a62 <ioapicwrite>
80102af9:	83 c4 10             	add    $0x10,%esp
    ioapicwrite(REG_TABLE+2*i+1, 0);
80102afc:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102aff:	83 c0 08             	add    $0x8,%eax
80102b02:	01 c0                	add    %eax,%eax
80102b04:	83 c0 01             	add    $0x1,%eax
80102b07:	83 ec 08             	sub    $0x8,%esp
80102b0a:	6a 00                	push   $0x0
80102b0c:	50                   	push   %eax
80102b0d:	e8 50 ff ff ff       	call   80102a62 <ioapicwrite>
80102b12:	83 c4 10             	add    $0x10,%esp
  if(id != ioapicid)
    cprintf("ioapicinit: id isn't equal to ioapicid; not a MP\n");

  // Mark all interrupts edge-triggered, active high, disabled,
  // and not routed to any CPUs.
  for(i = 0; i <= maxintr; i++){
80102b15:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80102b19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102b1c:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80102b1f:	7e b9                	jle    80102ada <ioapicinit+0x5d>
    ioapicwrite(REG_TABLE+2*i, INT_DISABLED | (T_IRQ0 + i));
    ioapicwrite(REG_TABLE+2*i+1, 0);
  }
}
80102b21:	90                   	nop
80102b22:	c9                   	leave  
80102b23:	c3                   	ret    

80102b24 <ioapicenable>:

void
ioapicenable(int irq, int cpunum)
{
80102b24:	55                   	push   %ebp
80102b25:	89 e5                	mov    %esp,%ebp
  // Mark interrupt edge-triggered, active high,
  // enabled, and routed to the given cpunum,
  // which happens to be that cpu's APIC ID.
  ioapicwrite(REG_TABLE+2*irq, T_IRQ0 + irq);
80102b27:	8b 45 08             	mov    0x8(%ebp),%eax
80102b2a:	83 c0 20             	add    $0x20,%eax
80102b2d:	89 c2                	mov    %eax,%edx
80102b2f:	8b 45 08             	mov    0x8(%ebp),%eax
80102b32:	83 c0 08             	add    $0x8,%eax
80102b35:	01 c0                	add    %eax,%eax
80102b37:	52                   	push   %edx
80102b38:	50                   	push   %eax
80102b39:	e8 24 ff ff ff       	call   80102a62 <ioapicwrite>
80102b3e:	83 c4 08             	add    $0x8,%esp
  ioapicwrite(REG_TABLE+2*irq+1, cpunum << 24);
80102b41:	8b 45 0c             	mov    0xc(%ebp),%eax
80102b44:	c1 e0 18             	shl    $0x18,%eax
80102b47:	89 c2                	mov    %eax,%edx
80102b49:	8b 45 08             	mov    0x8(%ebp),%eax
80102b4c:	83 c0 08             	add    $0x8,%eax
80102b4f:	01 c0                	add    %eax,%eax
80102b51:	83 c0 01             	add    $0x1,%eax
80102b54:	52                   	push   %edx
80102b55:	50                   	push   %eax
80102b56:	e8 07 ff ff ff       	call   80102a62 <ioapicwrite>
80102b5b:	83 c4 08             	add    $0x8,%esp
}
80102b5e:	90                   	nop
80102b5f:	c9                   	leave  
80102b60:	c3                   	ret    

80102b61 <kinit1>:
// the pages mapped by entrypgdir on free list.
// 2. main() calls kinit2() with the rest of the physical pages
// after installing a full page table that maps them on all cores.
void
kinit1(void *vstart, void *vend)
{
80102b61:	55                   	push   %ebp
80102b62:	89 e5                	mov    %esp,%ebp
80102b64:	83 ec 08             	sub    $0x8,%esp
  initlock(&kmem.lock, "kmem");
80102b67:	83 ec 08             	sub    $0x8,%esp
80102b6a:	68 ee 86 10 80       	push   $0x801086ee
80102b6f:	68 c0 36 11 80       	push   $0x801136c0
80102b74:	e8 bb 23 00 00       	call   80104f34 <initlock>
80102b79:	83 c4 10             	add    $0x10,%esp
  kmem.use_lock = 0;
80102b7c:	c7 05 f4 36 11 80 00 	movl   $0x0,0x801136f4
80102b83:	00 00 00 
  freerange(vstart, vend);
80102b86:	83 ec 08             	sub    $0x8,%esp
80102b89:	ff 75 0c             	pushl  0xc(%ebp)
80102b8c:	ff 75 08             	pushl  0x8(%ebp)
80102b8f:	e8 2a 00 00 00       	call   80102bbe <freerange>
80102b94:	83 c4 10             	add    $0x10,%esp
}
80102b97:	90                   	nop
80102b98:	c9                   	leave  
80102b99:	c3                   	ret    

80102b9a <kinit2>:

void
kinit2(void *vstart, void *vend)
{
80102b9a:	55                   	push   %ebp
80102b9b:	89 e5                	mov    %esp,%ebp
80102b9d:	83 ec 08             	sub    $0x8,%esp
  freerange(vstart, vend);
80102ba0:	83 ec 08             	sub    $0x8,%esp
80102ba3:	ff 75 0c             	pushl  0xc(%ebp)
80102ba6:	ff 75 08             	pushl  0x8(%ebp)
80102ba9:	e8 10 00 00 00       	call   80102bbe <freerange>
80102bae:	83 c4 10             	add    $0x10,%esp
  kmem.use_lock = 1;
80102bb1:	c7 05 f4 36 11 80 01 	movl   $0x1,0x801136f4
80102bb8:	00 00 00 
}
80102bbb:	90                   	nop
80102bbc:	c9                   	leave  
80102bbd:	c3                   	ret    

80102bbe <freerange>:

void
freerange(void *vstart, void *vend)
{
80102bbe:	55                   	push   %ebp
80102bbf:	89 e5                	mov    %esp,%ebp
80102bc1:	83 ec 18             	sub    $0x18,%esp
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
80102bc4:	8b 45 08             	mov    0x8(%ebp),%eax
80102bc7:	05 ff 0f 00 00       	add    $0xfff,%eax
80102bcc:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80102bd1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102bd4:	eb 15                	jmp    80102beb <freerange+0x2d>
    kfree(p);
80102bd6:	83 ec 0c             	sub    $0xc,%esp
80102bd9:	ff 75 f4             	pushl  -0xc(%ebp)
80102bdc:	e8 1a 00 00 00       	call   80102bfb <kfree>
80102be1:	83 c4 10             	add    $0x10,%esp
void
freerange(void *vstart, void *vend)
{
  char *p;
  p = (char*)PGROUNDUP((uint)vstart);
  for(; p + PGSIZE <= (char*)vend; p += PGSIZE)
80102be4:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80102beb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102bee:	05 00 10 00 00       	add    $0x1000,%eax
80102bf3:	3b 45 0c             	cmp    0xc(%ebp),%eax
80102bf6:	76 de                	jbe    80102bd6 <freerange+0x18>
    kfree(p);
}
80102bf8:	90                   	nop
80102bf9:	c9                   	leave  
80102bfa:	c3                   	ret    

80102bfb <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(char *v)
{
80102bfb:	55                   	push   %ebp
80102bfc:	89 e5                	mov    %esp,%ebp
80102bfe:	83 ec 18             	sub    $0x18,%esp
  struct run *r;

  if((uint)v % PGSIZE || v < end || V2P(v) >= PHYSTOP)
80102c01:	8b 45 08             	mov    0x8(%ebp),%eax
80102c04:	25 ff 0f 00 00       	and    $0xfff,%eax
80102c09:	85 c0                	test   %eax,%eax
80102c0b:	75 18                	jne    80102c25 <kfree+0x2a>
80102c0d:	81 7d 08 28 65 11 80 	cmpl   $0x80116528,0x8(%ebp)
80102c14:	72 0f                	jb     80102c25 <kfree+0x2a>
80102c16:	8b 45 08             	mov    0x8(%ebp),%eax
80102c19:	05 00 00 00 80       	add    $0x80000000,%eax
80102c1e:	3d ff ff ff 0d       	cmp    $0xdffffff,%eax
80102c23:	76 0d                	jbe    80102c32 <kfree+0x37>
    panic("kfree");
80102c25:	83 ec 0c             	sub    $0xc,%esp
80102c28:	68 f3 86 10 80       	push   $0x801086f3
80102c2d:	e8 6e d9 ff ff       	call   801005a0 <panic>

  // Fill with junk to catch dangling refs.
  memset(v, 1, PGSIZE);
80102c32:	83 ec 04             	sub    $0x4,%esp
80102c35:	68 00 10 00 00       	push   $0x1000
80102c3a:	6a 01                	push   $0x1
80102c3c:	ff 75 08             	pushl  0x8(%ebp)
80102c3f:	e8 89 25 00 00       	call   801051cd <memset>
80102c44:	83 c4 10             	add    $0x10,%esp

  if(kmem.use_lock)
80102c47:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102c4c:	85 c0                	test   %eax,%eax
80102c4e:	74 10                	je     80102c60 <kfree+0x65>
    acquire(&kmem.lock);
80102c50:	83 ec 0c             	sub    $0xc,%esp
80102c53:	68 c0 36 11 80       	push   $0x801136c0
80102c58:	e8 f9 22 00 00       	call   80104f56 <acquire>
80102c5d:	83 c4 10             	add    $0x10,%esp
  r = (struct run*)v;
80102c60:	8b 45 08             	mov    0x8(%ebp),%eax
80102c63:	89 45 f4             	mov    %eax,-0xc(%ebp)
  r->next = kmem.freelist;
80102c66:	8b 15 f8 36 11 80    	mov    0x801136f8,%edx
80102c6c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c6f:	89 10                	mov    %edx,(%eax)
  kmem.freelist = r;
80102c71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102c74:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102c79:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102c7e:	85 c0                	test   %eax,%eax
80102c80:	74 10                	je     80102c92 <kfree+0x97>
    release(&kmem.lock);
80102c82:	83 ec 0c             	sub    $0xc,%esp
80102c85:	68 c0 36 11 80       	push   $0x801136c0
80102c8a:	e8 35 23 00 00       	call   80104fc4 <release>
80102c8f:	83 c4 10             	add    $0x10,%esp
}
80102c92:	90                   	nop
80102c93:	c9                   	leave  
80102c94:	c3                   	ret    

80102c95 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
char*
kalloc(void)
{
80102c95:	55                   	push   %ebp
80102c96:	89 e5                	mov    %esp,%ebp
80102c98:	83 ec 18             	sub    $0x18,%esp
  struct run *r;

  if(kmem.use_lock)
80102c9b:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102ca0:	85 c0                	test   %eax,%eax
80102ca2:	74 10                	je     80102cb4 <kalloc+0x1f>
    acquire(&kmem.lock);
80102ca4:	83 ec 0c             	sub    $0xc,%esp
80102ca7:	68 c0 36 11 80       	push   $0x801136c0
80102cac:	e8 a5 22 00 00       	call   80104f56 <acquire>
80102cb1:	83 c4 10             	add    $0x10,%esp
  r = kmem.freelist;
80102cb4:	a1 f8 36 11 80       	mov    0x801136f8,%eax
80102cb9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(r)
80102cbc:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80102cc0:	74 0a                	je     80102ccc <kalloc+0x37>
    kmem.freelist = r->next;
80102cc2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102cc5:	8b 00                	mov    (%eax),%eax
80102cc7:	a3 f8 36 11 80       	mov    %eax,0x801136f8
  if(kmem.use_lock)
80102ccc:	a1 f4 36 11 80       	mov    0x801136f4,%eax
80102cd1:	85 c0                	test   %eax,%eax
80102cd3:	74 10                	je     80102ce5 <kalloc+0x50>
    release(&kmem.lock);
80102cd5:	83 ec 0c             	sub    $0xc,%esp
80102cd8:	68 c0 36 11 80       	push   $0x801136c0
80102cdd:	e8 e2 22 00 00       	call   80104fc4 <release>
80102ce2:	83 c4 10             	add    $0x10,%esp
  return (char*)r;
80102ce5:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80102ce8:	c9                   	leave  
80102ce9:	c3                   	ret    

80102cea <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102cea:	55                   	push   %ebp
80102ceb:	89 e5                	mov    %esp,%ebp
80102ced:	83 ec 14             	sub    $0x14,%esp
80102cf0:	8b 45 08             	mov    0x8(%ebp),%eax
80102cf3:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102cf7:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102cfb:	89 c2                	mov    %eax,%edx
80102cfd:	ec                   	in     (%dx),%al
80102cfe:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102d01:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102d05:	c9                   	leave  
80102d06:	c3                   	ret    

80102d07 <kbdgetc>:
#include "defs.h"
#include "kbd.h"

int
kbdgetc(void)
{
80102d07:	55                   	push   %ebp
80102d08:	89 e5                	mov    %esp,%ebp
80102d0a:	83 ec 10             	sub    $0x10,%esp
  static uchar *charcode[4] = {
    normalmap, shiftmap, ctlmap, ctlmap
  };
  uint st, data, c;

  st = inb(KBSTATP);
80102d0d:	6a 64                	push   $0x64
80102d0f:	e8 d6 ff ff ff       	call   80102cea <inb>
80102d14:	83 c4 04             	add    $0x4,%esp
80102d17:	0f b6 c0             	movzbl %al,%eax
80102d1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((st & KBS_DIB) == 0)
80102d1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80102d20:	83 e0 01             	and    $0x1,%eax
80102d23:	85 c0                	test   %eax,%eax
80102d25:	75 0a                	jne    80102d31 <kbdgetc+0x2a>
    return -1;
80102d27:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80102d2c:	e9 23 01 00 00       	jmp    80102e54 <kbdgetc+0x14d>
  data = inb(KBDATAP);
80102d31:	6a 60                	push   $0x60
80102d33:	e8 b2 ff ff ff       	call   80102cea <inb>
80102d38:	83 c4 04             	add    $0x4,%esp
80102d3b:	0f b6 c0             	movzbl %al,%eax
80102d3e:	89 45 fc             	mov    %eax,-0x4(%ebp)

  if(data == 0xE0){
80102d41:	81 7d fc e0 00 00 00 	cmpl   $0xe0,-0x4(%ebp)
80102d48:	75 17                	jne    80102d61 <kbdgetc+0x5a>
    shift |= E0ESC;
80102d4a:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d4f:	83 c8 40             	or     $0x40,%eax
80102d52:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102d57:	b8 00 00 00 00       	mov    $0x0,%eax
80102d5c:	e9 f3 00 00 00       	jmp    80102e54 <kbdgetc+0x14d>
  } else if(data & 0x80){
80102d61:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d64:	25 80 00 00 00       	and    $0x80,%eax
80102d69:	85 c0                	test   %eax,%eax
80102d6b:	74 45                	je     80102db2 <kbdgetc+0xab>
    // Key released
    data = (shift & E0ESC ? data : data & 0x7F);
80102d6d:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102d72:	83 e0 40             	and    $0x40,%eax
80102d75:	85 c0                	test   %eax,%eax
80102d77:	75 08                	jne    80102d81 <kbdgetc+0x7a>
80102d79:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d7c:	83 e0 7f             	and    $0x7f,%eax
80102d7f:	eb 03                	jmp    80102d84 <kbdgetc+0x7d>
80102d81:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d84:	89 45 fc             	mov    %eax,-0x4(%ebp)
    shift &= ~(shiftcode[data] | E0ESC);
80102d87:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102d8a:	05 20 90 10 80       	add    $0x80109020,%eax
80102d8f:	0f b6 00             	movzbl (%eax),%eax
80102d92:	83 c8 40             	or     $0x40,%eax
80102d95:	0f b6 c0             	movzbl %al,%eax
80102d98:	f7 d0                	not    %eax
80102d9a:	89 c2                	mov    %eax,%edx
80102d9c:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102da1:	21 d0                	and    %edx,%eax
80102da3:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
    return 0;
80102da8:	b8 00 00 00 00       	mov    $0x0,%eax
80102dad:	e9 a2 00 00 00       	jmp    80102e54 <kbdgetc+0x14d>
  } else if(shift & E0ESC){
80102db2:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102db7:	83 e0 40             	and    $0x40,%eax
80102dba:	85 c0                	test   %eax,%eax
80102dbc:	74 14                	je     80102dd2 <kbdgetc+0xcb>
    // Last character was an E0 escape; or with 0x80
    data |= 0x80;
80102dbe:	81 4d fc 80 00 00 00 	orl    $0x80,-0x4(%ebp)
    shift &= ~E0ESC;
80102dc5:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102dca:	83 e0 bf             	and    $0xffffffbf,%eax
80102dcd:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  }

  shift |= shiftcode[data];
80102dd2:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102dd5:	05 20 90 10 80       	add    $0x80109020,%eax
80102dda:	0f b6 00             	movzbl (%eax),%eax
80102ddd:	0f b6 d0             	movzbl %al,%edx
80102de0:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102de5:	09 d0                	or     %edx,%eax
80102de7:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  shift ^= togglecode[data];
80102dec:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102def:	05 20 91 10 80       	add    $0x80109120,%eax
80102df4:	0f b6 00             	movzbl (%eax),%eax
80102df7:	0f b6 d0             	movzbl %al,%edx
80102dfa:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102dff:	31 d0                	xor    %edx,%eax
80102e01:	a3 1c b6 10 80       	mov    %eax,0x8010b61c
  c = charcode[shift & (CTL | SHIFT)][data];
80102e06:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102e0b:	83 e0 03             	and    $0x3,%eax
80102e0e:	8b 14 85 20 95 10 80 	mov    -0x7fef6ae0(,%eax,4),%edx
80102e15:	8b 45 fc             	mov    -0x4(%ebp),%eax
80102e18:	01 d0                	add    %edx,%eax
80102e1a:	0f b6 00             	movzbl (%eax),%eax
80102e1d:	0f b6 c0             	movzbl %al,%eax
80102e20:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(shift & CAPSLOCK){
80102e23:	a1 1c b6 10 80       	mov    0x8010b61c,%eax
80102e28:	83 e0 08             	and    $0x8,%eax
80102e2b:	85 c0                	test   %eax,%eax
80102e2d:	74 22                	je     80102e51 <kbdgetc+0x14a>
    if('a' <= c && c <= 'z')
80102e2f:	83 7d f8 60          	cmpl   $0x60,-0x8(%ebp)
80102e33:	76 0c                	jbe    80102e41 <kbdgetc+0x13a>
80102e35:	83 7d f8 7a          	cmpl   $0x7a,-0x8(%ebp)
80102e39:	77 06                	ja     80102e41 <kbdgetc+0x13a>
      c += 'A' - 'a';
80102e3b:	83 6d f8 20          	subl   $0x20,-0x8(%ebp)
80102e3f:	eb 10                	jmp    80102e51 <kbdgetc+0x14a>
    else if('A' <= c && c <= 'Z')
80102e41:	83 7d f8 40          	cmpl   $0x40,-0x8(%ebp)
80102e45:	76 0a                	jbe    80102e51 <kbdgetc+0x14a>
80102e47:	83 7d f8 5a          	cmpl   $0x5a,-0x8(%ebp)
80102e4b:	77 04                	ja     80102e51 <kbdgetc+0x14a>
      c += 'a' - 'A';
80102e4d:	83 45 f8 20          	addl   $0x20,-0x8(%ebp)
  }
  return c;
80102e51:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80102e54:	c9                   	leave  
80102e55:	c3                   	ret    

80102e56 <kbdintr>:

void
kbdintr(void)
{
80102e56:	55                   	push   %ebp
80102e57:	89 e5                	mov    %esp,%ebp
80102e59:	83 ec 08             	sub    $0x8,%esp
  consoleintr(kbdgetc);
80102e5c:	83 ec 0c             	sub    $0xc,%esp
80102e5f:	68 07 2d 10 80       	push   $0x80102d07
80102e64:	e8 c3 d9 ff ff       	call   8010082c <consoleintr>
80102e69:	83 c4 10             	add    $0x10,%esp
}
80102e6c:	90                   	nop
80102e6d:	c9                   	leave  
80102e6e:	c3                   	ret    

80102e6f <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80102e6f:	55                   	push   %ebp
80102e70:	89 e5                	mov    %esp,%ebp
80102e72:	83 ec 14             	sub    $0x14,%esp
80102e75:	8b 45 08             	mov    0x8(%ebp),%eax
80102e78:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80102e7c:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80102e80:	89 c2                	mov    %eax,%edx
80102e82:	ec                   	in     (%dx),%al
80102e83:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80102e86:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80102e8a:	c9                   	leave  
80102e8b:	c3                   	ret    

80102e8c <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80102e8c:	55                   	push   %ebp
80102e8d:	89 e5                	mov    %esp,%ebp
80102e8f:	83 ec 08             	sub    $0x8,%esp
80102e92:	8b 55 08             	mov    0x8(%ebp),%edx
80102e95:	8b 45 0c             	mov    0xc(%ebp),%eax
80102e98:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80102e9c:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80102e9f:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80102ea3:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80102ea7:	ee                   	out    %al,(%dx)
}
80102ea8:	90                   	nop
80102ea9:	c9                   	leave  
80102eaa:	c3                   	ret    

80102eab <lapicw>:
volatile uint *lapic;  // Initialized in mp.c

//PAGEBREAK!
static void
lapicw(int index, int value)
{
80102eab:	55                   	push   %ebp
80102eac:	89 e5                	mov    %esp,%ebp
  lapic[index] = value;
80102eae:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102eb3:	8b 55 08             	mov    0x8(%ebp),%edx
80102eb6:	c1 e2 02             	shl    $0x2,%edx
80102eb9:	01 c2                	add    %eax,%edx
80102ebb:	8b 45 0c             	mov    0xc(%ebp),%eax
80102ebe:	89 02                	mov    %eax,(%edx)
  lapic[ID];  // wait for write to finish, by reading
80102ec0:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102ec5:	83 c0 20             	add    $0x20,%eax
80102ec8:	8b 00                	mov    (%eax),%eax
}
80102eca:	90                   	nop
80102ecb:	5d                   	pop    %ebp
80102ecc:	c3                   	ret    

80102ecd <lapicinit>:

void
lapicinit(void)
{
80102ecd:	55                   	push   %ebp
80102ece:	89 e5                	mov    %esp,%ebp
  if(!lapic)
80102ed0:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102ed5:	85 c0                	test   %eax,%eax
80102ed7:	0f 84 0b 01 00 00    	je     80102fe8 <lapicinit+0x11b>
    return;

  // Enable local APIC; set spurious interrupt vector.
  lapicw(SVR, ENABLE | (T_IRQ0 + IRQ_SPURIOUS));
80102edd:	68 3f 01 00 00       	push   $0x13f
80102ee2:	6a 3c                	push   $0x3c
80102ee4:	e8 c2 ff ff ff       	call   80102eab <lapicw>
80102ee9:	83 c4 08             	add    $0x8,%esp

  // The timer repeatedly counts down at bus frequency
  // from lapic[TICR] and then issues an interrupt.
  // If xv6 cared more about precise timekeeping,
  // TICR would be calibrated using an external time source.
  lapicw(TDCR, X1);
80102eec:	6a 0b                	push   $0xb
80102eee:	68 f8 00 00 00       	push   $0xf8
80102ef3:	e8 b3 ff ff ff       	call   80102eab <lapicw>
80102ef8:	83 c4 08             	add    $0x8,%esp
  lapicw(TIMER, PERIODIC | (T_IRQ0 + IRQ_TIMER));
80102efb:	68 20 00 02 00       	push   $0x20020
80102f00:	68 c8 00 00 00       	push   $0xc8
80102f05:	e8 a1 ff ff ff       	call   80102eab <lapicw>
80102f0a:	83 c4 08             	add    $0x8,%esp
  lapicw(TICR, 10000000);
80102f0d:	68 80 96 98 00       	push   $0x989680
80102f12:	68 e0 00 00 00       	push   $0xe0
80102f17:	e8 8f ff ff ff       	call   80102eab <lapicw>
80102f1c:	83 c4 08             	add    $0x8,%esp

  // Disable logical interrupt lines.
  lapicw(LINT0, MASKED);
80102f1f:	68 00 00 01 00       	push   $0x10000
80102f24:	68 d4 00 00 00       	push   $0xd4
80102f29:	e8 7d ff ff ff       	call   80102eab <lapicw>
80102f2e:	83 c4 08             	add    $0x8,%esp
  lapicw(LINT1, MASKED);
80102f31:	68 00 00 01 00       	push   $0x10000
80102f36:	68 d8 00 00 00       	push   $0xd8
80102f3b:	e8 6b ff ff ff       	call   80102eab <lapicw>
80102f40:	83 c4 08             	add    $0x8,%esp

  // Disable performance counter overflow interrupts
  // on machines that provide that interrupt entry.
  if(((lapic[VER]>>16) & 0xFF) >= 4)
80102f43:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102f48:	83 c0 30             	add    $0x30,%eax
80102f4b:	8b 00                	mov    (%eax),%eax
80102f4d:	c1 e8 10             	shr    $0x10,%eax
80102f50:	0f b6 c0             	movzbl %al,%eax
80102f53:	83 f8 03             	cmp    $0x3,%eax
80102f56:	76 12                	jbe    80102f6a <lapicinit+0x9d>
    lapicw(PCINT, MASKED);
80102f58:	68 00 00 01 00       	push   $0x10000
80102f5d:	68 d0 00 00 00       	push   $0xd0
80102f62:	e8 44 ff ff ff       	call   80102eab <lapicw>
80102f67:	83 c4 08             	add    $0x8,%esp

  // Map error interrupt to IRQ_ERROR.
  lapicw(ERROR, T_IRQ0 + IRQ_ERROR);
80102f6a:	6a 33                	push   $0x33
80102f6c:	68 dc 00 00 00       	push   $0xdc
80102f71:	e8 35 ff ff ff       	call   80102eab <lapicw>
80102f76:	83 c4 08             	add    $0x8,%esp

  // Clear error status register (requires back-to-back writes).
  lapicw(ESR, 0);
80102f79:	6a 00                	push   $0x0
80102f7b:	68 a0 00 00 00       	push   $0xa0
80102f80:	e8 26 ff ff ff       	call   80102eab <lapicw>
80102f85:	83 c4 08             	add    $0x8,%esp
  lapicw(ESR, 0);
80102f88:	6a 00                	push   $0x0
80102f8a:	68 a0 00 00 00       	push   $0xa0
80102f8f:	e8 17 ff ff ff       	call   80102eab <lapicw>
80102f94:	83 c4 08             	add    $0x8,%esp

  // Ack any outstanding interrupts.
  lapicw(EOI, 0);
80102f97:	6a 00                	push   $0x0
80102f99:	6a 2c                	push   $0x2c
80102f9b:	e8 0b ff ff ff       	call   80102eab <lapicw>
80102fa0:	83 c4 08             	add    $0x8,%esp

  // Send an Init Level De-Assert to synchronise arbitration ID's.
  lapicw(ICRHI, 0);
80102fa3:	6a 00                	push   $0x0
80102fa5:	68 c4 00 00 00       	push   $0xc4
80102faa:	e8 fc fe ff ff       	call   80102eab <lapicw>
80102faf:	83 c4 08             	add    $0x8,%esp
  lapicw(ICRLO, BCAST | INIT | LEVEL);
80102fb2:	68 00 85 08 00       	push   $0x88500
80102fb7:	68 c0 00 00 00       	push   $0xc0
80102fbc:	e8 ea fe ff ff       	call   80102eab <lapicw>
80102fc1:	83 c4 08             	add    $0x8,%esp
  while(lapic[ICRLO] & DELIVS)
80102fc4:	90                   	nop
80102fc5:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102fca:	05 00 03 00 00       	add    $0x300,%eax
80102fcf:	8b 00                	mov    (%eax),%eax
80102fd1:	25 00 10 00 00       	and    $0x1000,%eax
80102fd6:	85 c0                	test   %eax,%eax
80102fd8:	75 eb                	jne    80102fc5 <lapicinit+0xf8>
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
80102fda:	6a 00                	push   $0x0
80102fdc:	6a 20                	push   $0x20
80102fde:	e8 c8 fe ff ff       	call   80102eab <lapicw>
80102fe3:	83 c4 08             	add    $0x8,%esp
80102fe6:	eb 01                	jmp    80102fe9 <lapicinit+0x11c>

void
lapicinit(void)
{
  if(!lapic)
    return;
80102fe8:	90                   	nop
  while(lapic[ICRLO] & DELIVS)
    ;

  // Enable interrupts on the APIC (but not on the processor).
  lapicw(TPR, 0);
}
80102fe9:	c9                   	leave  
80102fea:	c3                   	ret    

80102feb <lapicid>:

int
lapicid(void)
{
80102feb:	55                   	push   %ebp
80102fec:	89 e5                	mov    %esp,%ebp
  if (!lapic)
80102fee:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80102ff3:	85 c0                	test   %eax,%eax
80102ff5:	75 07                	jne    80102ffe <lapicid+0x13>
    return 0;
80102ff7:	b8 00 00 00 00       	mov    $0x0,%eax
80102ffc:	eb 0d                	jmp    8010300b <lapicid+0x20>
  return lapic[ID] >> 24;
80102ffe:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80103003:	83 c0 20             	add    $0x20,%eax
80103006:	8b 00                	mov    (%eax),%eax
80103008:	c1 e8 18             	shr    $0x18,%eax
}
8010300b:	5d                   	pop    %ebp
8010300c:	c3                   	ret    

8010300d <lapiceoi>:

// Acknowledge interrupt.
void
lapiceoi(void)
{
8010300d:	55                   	push   %ebp
8010300e:	89 e5                	mov    %esp,%ebp
  if(lapic)
80103010:	a1 fc 36 11 80       	mov    0x801136fc,%eax
80103015:	85 c0                	test   %eax,%eax
80103017:	74 0c                	je     80103025 <lapiceoi+0x18>
    lapicw(EOI, 0);
80103019:	6a 00                	push   $0x0
8010301b:	6a 2c                	push   $0x2c
8010301d:	e8 89 fe ff ff       	call   80102eab <lapicw>
80103022:	83 c4 08             	add    $0x8,%esp
}
80103025:	90                   	nop
80103026:	c9                   	leave  
80103027:	c3                   	ret    

80103028 <microdelay>:

// Spin for a given number of microseconds.
// On real hardware would want to tune this dynamically.
void
microdelay(int us)
{
80103028:	55                   	push   %ebp
80103029:	89 e5                	mov    %esp,%ebp
}
8010302b:	90                   	nop
8010302c:	5d                   	pop    %ebp
8010302d:	c3                   	ret    

8010302e <lapicstartap>:

// Start additional processor running entry code at addr.
// See Appendix B of MultiProcessor Specification.
void
lapicstartap(uchar apicid, uint addr)
{
8010302e:	55                   	push   %ebp
8010302f:	89 e5                	mov    %esp,%ebp
80103031:	83 ec 14             	sub    $0x14,%esp
80103034:	8b 45 08             	mov    0x8(%ebp),%eax
80103037:	88 45 ec             	mov    %al,-0x14(%ebp)
  ushort *wrv;

  // "The BSP must initialize CMOS shutdown code to 0AH
  // and the warm reset vector (DWORD based at 40:67) to point at
  // the AP startup code prior to the [universal startup algorithm]."
  outb(CMOS_PORT, 0xF);  // offset 0xF is shutdown code
8010303a:	6a 0f                	push   $0xf
8010303c:	6a 70                	push   $0x70
8010303e:	e8 49 fe ff ff       	call   80102e8c <outb>
80103043:	83 c4 08             	add    $0x8,%esp
  outb(CMOS_PORT+1, 0x0A);
80103046:	6a 0a                	push   $0xa
80103048:	6a 71                	push   $0x71
8010304a:	e8 3d fe ff ff       	call   80102e8c <outb>
8010304f:	83 c4 08             	add    $0x8,%esp
  wrv = (ushort*)P2V((0x40<<4 | 0x67));  // Warm reset vector
80103052:	c7 45 f8 67 04 00 80 	movl   $0x80000467,-0x8(%ebp)
  wrv[0] = 0;
80103059:	8b 45 f8             	mov    -0x8(%ebp),%eax
8010305c:	66 c7 00 00 00       	movw   $0x0,(%eax)
  wrv[1] = addr >> 4;
80103061:	8b 45 f8             	mov    -0x8(%ebp),%eax
80103064:	83 c0 02             	add    $0x2,%eax
80103067:	8b 55 0c             	mov    0xc(%ebp),%edx
8010306a:	c1 ea 04             	shr    $0x4,%edx
8010306d:	66 89 10             	mov    %dx,(%eax)

  // "Universal startup algorithm."
  // Send INIT (level-triggered) interrupt to reset other CPU.
  lapicw(ICRHI, apicid<<24);
80103070:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
80103074:	c1 e0 18             	shl    $0x18,%eax
80103077:	50                   	push   %eax
80103078:	68 c4 00 00 00       	push   $0xc4
8010307d:	e8 29 fe ff ff       	call   80102eab <lapicw>
80103082:	83 c4 08             	add    $0x8,%esp
  lapicw(ICRLO, INIT | LEVEL | ASSERT);
80103085:	68 00 c5 00 00       	push   $0xc500
8010308a:	68 c0 00 00 00       	push   $0xc0
8010308f:	e8 17 fe ff ff       	call   80102eab <lapicw>
80103094:	83 c4 08             	add    $0x8,%esp
  microdelay(200);
80103097:	68 c8 00 00 00       	push   $0xc8
8010309c:	e8 87 ff ff ff       	call   80103028 <microdelay>
801030a1:	83 c4 04             	add    $0x4,%esp
  lapicw(ICRLO, INIT | LEVEL);
801030a4:	68 00 85 00 00       	push   $0x8500
801030a9:	68 c0 00 00 00       	push   $0xc0
801030ae:	e8 f8 fd ff ff       	call   80102eab <lapicw>
801030b3:	83 c4 08             	add    $0x8,%esp
  microdelay(100);    // should be 10ms, but too slow in Bochs!
801030b6:	6a 64                	push   $0x64
801030b8:	e8 6b ff ff ff       	call   80103028 <microdelay>
801030bd:	83 c4 04             	add    $0x4,%esp
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
801030c0:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
801030c7:	eb 3d                	jmp    80103106 <lapicstartap+0xd8>
    lapicw(ICRHI, apicid<<24);
801030c9:	0f b6 45 ec          	movzbl -0x14(%ebp),%eax
801030cd:	c1 e0 18             	shl    $0x18,%eax
801030d0:	50                   	push   %eax
801030d1:	68 c4 00 00 00       	push   $0xc4
801030d6:	e8 d0 fd ff ff       	call   80102eab <lapicw>
801030db:	83 c4 08             	add    $0x8,%esp
    lapicw(ICRLO, STARTUP | (addr>>12));
801030de:	8b 45 0c             	mov    0xc(%ebp),%eax
801030e1:	c1 e8 0c             	shr    $0xc,%eax
801030e4:	80 cc 06             	or     $0x6,%ah
801030e7:	50                   	push   %eax
801030e8:	68 c0 00 00 00       	push   $0xc0
801030ed:	e8 b9 fd ff ff       	call   80102eab <lapicw>
801030f2:	83 c4 08             	add    $0x8,%esp
    microdelay(200);
801030f5:	68 c8 00 00 00       	push   $0xc8
801030fa:	e8 29 ff ff ff       	call   80103028 <microdelay>
801030ff:	83 c4 04             	add    $0x4,%esp
  // Send startup IPI (twice!) to enter code.
  // Regular hardware is supposed to only accept a STARTUP
  // when it is in the halted state due to an INIT.  So the second
  // should be ignored, but it is part of the official Intel algorithm.
  // Bochs complains about the second one.  Too bad for Bochs.
  for(i = 0; i < 2; i++){
80103102:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103106:	83 7d fc 01          	cmpl   $0x1,-0x4(%ebp)
8010310a:	7e bd                	jle    801030c9 <lapicstartap+0x9b>
    lapicw(ICRHI, apicid<<24);
    lapicw(ICRLO, STARTUP | (addr>>12));
    microdelay(200);
  }
}
8010310c:	90                   	nop
8010310d:	c9                   	leave  
8010310e:	c3                   	ret    

8010310f <cmos_read>:
#define DAY     0x07
#define MONTH   0x08
#define YEAR    0x09

static uint cmos_read(uint reg)
{
8010310f:	55                   	push   %ebp
80103110:	89 e5                	mov    %esp,%ebp
  outb(CMOS_PORT,  reg);
80103112:	8b 45 08             	mov    0x8(%ebp),%eax
80103115:	0f b6 c0             	movzbl %al,%eax
80103118:	50                   	push   %eax
80103119:	6a 70                	push   $0x70
8010311b:	e8 6c fd ff ff       	call   80102e8c <outb>
80103120:	83 c4 08             	add    $0x8,%esp
  microdelay(200);
80103123:	68 c8 00 00 00       	push   $0xc8
80103128:	e8 fb fe ff ff       	call   80103028 <microdelay>
8010312d:	83 c4 04             	add    $0x4,%esp

  return inb(CMOS_RETURN);
80103130:	6a 71                	push   $0x71
80103132:	e8 38 fd ff ff       	call   80102e6f <inb>
80103137:	83 c4 04             	add    $0x4,%esp
8010313a:	0f b6 c0             	movzbl %al,%eax
}
8010313d:	c9                   	leave  
8010313e:	c3                   	ret    

8010313f <fill_rtcdate>:

static void fill_rtcdate(struct rtcdate *r)
{
8010313f:	55                   	push   %ebp
80103140:	89 e5                	mov    %esp,%ebp
  r->second = cmos_read(SECS);
80103142:	6a 00                	push   $0x0
80103144:	e8 c6 ff ff ff       	call   8010310f <cmos_read>
80103149:	83 c4 04             	add    $0x4,%esp
8010314c:	89 c2                	mov    %eax,%edx
8010314e:	8b 45 08             	mov    0x8(%ebp),%eax
80103151:	89 10                	mov    %edx,(%eax)
  r->minute = cmos_read(MINS);
80103153:	6a 02                	push   $0x2
80103155:	e8 b5 ff ff ff       	call   8010310f <cmos_read>
8010315a:	83 c4 04             	add    $0x4,%esp
8010315d:	89 c2                	mov    %eax,%edx
8010315f:	8b 45 08             	mov    0x8(%ebp),%eax
80103162:	89 50 04             	mov    %edx,0x4(%eax)
  r->hour   = cmos_read(HOURS);
80103165:	6a 04                	push   $0x4
80103167:	e8 a3 ff ff ff       	call   8010310f <cmos_read>
8010316c:	83 c4 04             	add    $0x4,%esp
8010316f:	89 c2                	mov    %eax,%edx
80103171:	8b 45 08             	mov    0x8(%ebp),%eax
80103174:	89 50 08             	mov    %edx,0x8(%eax)
  r->day    = cmos_read(DAY);
80103177:	6a 07                	push   $0x7
80103179:	e8 91 ff ff ff       	call   8010310f <cmos_read>
8010317e:	83 c4 04             	add    $0x4,%esp
80103181:	89 c2                	mov    %eax,%edx
80103183:	8b 45 08             	mov    0x8(%ebp),%eax
80103186:	89 50 0c             	mov    %edx,0xc(%eax)
  r->month  = cmos_read(MONTH);
80103189:	6a 08                	push   $0x8
8010318b:	e8 7f ff ff ff       	call   8010310f <cmos_read>
80103190:	83 c4 04             	add    $0x4,%esp
80103193:	89 c2                	mov    %eax,%edx
80103195:	8b 45 08             	mov    0x8(%ebp),%eax
80103198:	89 50 10             	mov    %edx,0x10(%eax)
  r->year   = cmos_read(YEAR);
8010319b:	6a 09                	push   $0x9
8010319d:	e8 6d ff ff ff       	call   8010310f <cmos_read>
801031a2:	83 c4 04             	add    $0x4,%esp
801031a5:	89 c2                	mov    %eax,%edx
801031a7:	8b 45 08             	mov    0x8(%ebp),%eax
801031aa:	89 50 14             	mov    %edx,0x14(%eax)
}
801031ad:	90                   	nop
801031ae:	c9                   	leave  
801031af:	c3                   	ret    

801031b0 <cmostime>:

// qemu seems to use 24-hour GWT and the values are BCD encoded
void cmostime(struct rtcdate *r)
{
801031b0:	55                   	push   %ebp
801031b1:	89 e5                	mov    %esp,%ebp
801031b3:	83 ec 48             	sub    $0x48,%esp
  struct rtcdate t1, t2;
  int sb, bcd;

  sb = cmos_read(CMOS_STATB);
801031b6:	6a 0b                	push   $0xb
801031b8:	e8 52 ff ff ff       	call   8010310f <cmos_read>
801031bd:	83 c4 04             	add    $0x4,%esp
801031c0:	89 45 f4             	mov    %eax,-0xc(%ebp)

  bcd = (sb & (1 << 2)) == 0;
801031c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801031c6:	83 e0 04             	and    $0x4,%eax
801031c9:	85 c0                	test   %eax,%eax
801031cb:	0f 94 c0             	sete   %al
801031ce:	0f b6 c0             	movzbl %al,%eax
801031d1:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
801031d4:	8d 45 d8             	lea    -0x28(%ebp),%eax
801031d7:	50                   	push   %eax
801031d8:	e8 62 ff ff ff       	call   8010313f <fill_rtcdate>
801031dd:	83 c4 04             	add    $0x4,%esp
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
801031e0:	6a 0a                	push   $0xa
801031e2:	e8 28 ff ff ff       	call   8010310f <cmos_read>
801031e7:	83 c4 04             	add    $0x4,%esp
801031ea:	25 80 00 00 00       	and    $0x80,%eax
801031ef:	85 c0                	test   %eax,%eax
801031f1:	75 27                	jne    8010321a <cmostime+0x6a>
        continue;
    fill_rtcdate(&t2);
801031f3:	8d 45 c0             	lea    -0x40(%ebp),%eax
801031f6:	50                   	push   %eax
801031f7:	e8 43 ff ff ff       	call   8010313f <fill_rtcdate>
801031fc:	83 c4 04             	add    $0x4,%esp
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
801031ff:	83 ec 04             	sub    $0x4,%esp
80103202:	6a 18                	push   $0x18
80103204:	8d 45 c0             	lea    -0x40(%ebp),%eax
80103207:	50                   	push   %eax
80103208:	8d 45 d8             	lea    -0x28(%ebp),%eax
8010320b:	50                   	push   %eax
8010320c:	e8 23 20 00 00       	call   80105234 <memcmp>
80103211:	83 c4 10             	add    $0x10,%esp
80103214:	85 c0                	test   %eax,%eax
80103216:	74 05                	je     8010321d <cmostime+0x6d>
80103218:	eb ba                	jmp    801031d4 <cmostime+0x24>

  // make sure CMOS doesn't modify time while we read it
  for(;;) {
    fill_rtcdate(&t1);
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
8010321a:	90                   	nop
    fill_rtcdate(&t2);
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
  }
8010321b:	eb b7                	jmp    801031d4 <cmostime+0x24>
    fill_rtcdate(&t1);
    if(cmos_read(CMOS_STATA) & CMOS_UIP)
        continue;
    fill_rtcdate(&t2);
    if(memcmp(&t1, &t2, sizeof(t1)) == 0)
      break;
8010321d:	90                   	nop
  }

  // convert
  if(bcd) {
8010321e:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103222:	0f 84 b4 00 00 00    	je     801032dc <cmostime+0x12c>
#define    CONV(x)     (t1.x = ((t1.x >> 4) * 10) + (t1.x & 0xf))
    CONV(second);
80103228:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010322b:	c1 e8 04             	shr    $0x4,%eax
8010322e:	89 c2                	mov    %eax,%edx
80103230:	89 d0                	mov    %edx,%eax
80103232:	c1 e0 02             	shl    $0x2,%eax
80103235:	01 d0                	add    %edx,%eax
80103237:	01 c0                	add    %eax,%eax
80103239:	89 c2                	mov    %eax,%edx
8010323b:	8b 45 d8             	mov    -0x28(%ebp),%eax
8010323e:	83 e0 0f             	and    $0xf,%eax
80103241:	01 d0                	add    %edx,%eax
80103243:	89 45 d8             	mov    %eax,-0x28(%ebp)
    CONV(minute);
80103246:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103249:	c1 e8 04             	shr    $0x4,%eax
8010324c:	89 c2                	mov    %eax,%edx
8010324e:	89 d0                	mov    %edx,%eax
80103250:	c1 e0 02             	shl    $0x2,%eax
80103253:	01 d0                	add    %edx,%eax
80103255:	01 c0                	add    %eax,%eax
80103257:	89 c2                	mov    %eax,%edx
80103259:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010325c:	83 e0 0f             	and    $0xf,%eax
8010325f:	01 d0                	add    %edx,%eax
80103261:	89 45 dc             	mov    %eax,-0x24(%ebp)
    CONV(hour  );
80103264:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103267:	c1 e8 04             	shr    $0x4,%eax
8010326a:	89 c2                	mov    %eax,%edx
8010326c:	89 d0                	mov    %edx,%eax
8010326e:	c1 e0 02             	shl    $0x2,%eax
80103271:	01 d0                	add    %edx,%eax
80103273:	01 c0                	add    %eax,%eax
80103275:	89 c2                	mov    %eax,%edx
80103277:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010327a:	83 e0 0f             	and    $0xf,%eax
8010327d:	01 d0                	add    %edx,%eax
8010327f:	89 45 e0             	mov    %eax,-0x20(%ebp)
    CONV(day   );
80103282:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103285:	c1 e8 04             	shr    $0x4,%eax
80103288:	89 c2                	mov    %eax,%edx
8010328a:	89 d0                	mov    %edx,%eax
8010328c:	c1 e0 02             	shl    $0x2,%eax
8010328f:	01 d0                	add    %edx,%eax
80103291:	01 c0                	add    %eax,%eax
80103293:	89 c2                	mov    %eax,%edx
80103295:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103298:	83 e0 0f             	and    $0xf,%eax
8010329b:	01 d0                	add    %edx,%eax
8010329d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    CONV(month );
801032a0:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032a3:	c1 e8 04             	shr    $0x4,%eax
801032a6:	89 c2                	mov    %eax,%edx
801032a8:	89 d0                	mov    %edx,%eax
801032aa:	c1 e0 02             	shl    $0x2,%eax
801032ad:	01 d0                	add    %edx,%eax
801032af:	01 c0                	add    %eax,%eax
801032b1:	89 c2                	mov    %eax,%edx
801032b3:	8b 45 e8             	mov    -0x18(%ebp),%eax
801032b6:	83 e0 0f             	and    $0xf,%eax
801032b9:	01 d0                	add    %edx,%eax
801032bb:	89 45 e8             	mov    %eax,-0x18(%ebp)
    CONV(year  );
801032be:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032c1:	c1 e8 04             	shr    $0x4,%eax
801032c4:	89 c2                	mov    %eax,%edx
801032c6:	89 d0                	mov    %edx,%eax
801032c8:	c1 e0 02             	shl    $0x2,%eax
801032cb:	01 d0                	add    %edx,%eax
801032cd:	01 c0                	add    %eax,%eax
801032cf:	89 c2                	mov    %eax,%edx
801032d1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801032d4:	83 e0 0f             	and    $0xf,%eax
801032d7:	01 d0                	add    %edx,%eax
801032d9:	89 45 ec             	mov    %eax,-0x14(%ebp)
#undef     CONV
  }

  *r = t1;
801032dc:	8b 45 08             	mov    0x8(%ebp),%eax
801032df:	8b 55 d8             	mov    -0x28(%ebp),%edx
801032e2:	89 10                	mov    %edx,(%eax)
801032e4:	8b 55 dc             	mov    -0x24(%ebp),%edx
801032e7:	89 50 04             	mov    %edx,0x4(%eax)
801032ea:	8b 55 e0             	mov    -0x20(%ebp),%edx
801032ed:	89 50 08             	mov    %edx,0x8(%eax)
801032f0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
801032f3:	89 50 0c             	mov    %edx,0xc(%eax)
801032f6:	8b 55 e8             	mov    -0x18(%ebp),%edx
801032f9:	89 50 10             	mov    %edx,0x10(%eax)
801032fc:	8b 55 ec             	mov    -0x14(%ebp),%edx
801032ff:	89 50 14             	mov    %edx,0x14(%eax)
  r->year += 2000;
80103302:	8b 45 08             	mov    0x8(%ebp),%eax
80103305:	8b 40 14             	mov    0x14(%eax),%eax
80103308:	8d 90 d0 07 00 00    	lea    0x7d0(%eax),%edx
8010330e:	8b 45 08             	mov    0x8(%ebp),%eax
80103311:	89 50 14             	mov    %edx,0x14(%eax)
}
80103314:	90                   	nop
80103315:	c9                   	leave  
80103316:	c3                   	ret    

80103317 <initlog>:
static void recover_from_log(void);
static void commit();

void
initlog(int dev)
{
80103317:	55                   	push   %ebp
80103318:	89 e5                	mov    %esp,%ebp
8010331a:	83 ec 28             	sub    $0x28,%esp
  if (sizeof(struct logheader) >= BSIZE)
    panic("initlog: too big logheader");

  struct superblock sb;
  initlock(&log.lock, "log");
8010331d:	83 ec 08             	sub    $0x8,%esp
80103320:	68 f9 86 10 80       	push   $0x801086f9
80103325:	68 00 37 11 80       	push   $0x80113700
8010332a:	e8 05 1c 00 00       	call   80104f34 <initlock>
8010332f:	83 c4 10             	add    $0x10,%esp
  readsb(dev, &sb);
80103332:	83 ec 08             	sub    $0x8,%esp
80103335:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103338:	50                   	push   %eax
80103339:	ff 75 08             	pushl  0x8(%ebp)
8010333c:	e8 a3 e0 ff ff       	call   801013e4 <readsb>
80103341:	83 c4 10             	add    $0x10,%esp
  log.start = sb.logstart;
80103344:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103347:	a3 34 37 11 80       	mov    %eax,0x80113734
  log.size = sb.nlog;
8010334c:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010334f:	a3 38 37 11 80       	mov    %eax,0x80113738
  log.dev = dev;
80103354:	8b 45 08             	mov    0x8(%ebp),%eax
80103357:	a3 44 37 11 80       	mov    %eax,0x80113744
  recover_from_log();
8010335c:	e8 b2 01 00 00       	call   80103513 <recover_from_log>
}
80103361:	90                   	nop
80103362:	c9                   	leave  
80103363:	c3                   	ret    

80103364 <install_trans>:

// Copy committed blocks from log to their home location
static void
install_trans(void)
{
80103364:	55                   	push   %ebp
80103365:	89 e5                	mov    %esp,%ebp
80103367:	83 ec 18             	sub    $0x18,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010336a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103371:	e9 95 00 00 00       	jmp    8010340b <install_trans+0xa7>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
80103376:	8b 15 34 37 11 80    	mov    0x80113734,%edx
8010337c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010337f:	01 d0                	add    %edx,%eax
80103381:	83 c0 01             	add    $0x1,%eax
80103384:	89 c2                	mov    %eax,%edx
80103386:	a1 44 37 11 80       	mov    0x80113744,%eax
8010338b:	83 ec 08             	sub    $0x8,%esp
8010338e:	52                   	push   %edx
8010338f:	50                   	push   %eax
80103390:	e8 39 ce ff ff       	call   801001ce <bread>
80103395:	83 c4 10             	add    $0x10,%esp
80103398:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
8010339b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010339e:	83 c0 10             	add    $0x10,%eax
801033a1:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801033a8:	89 c2                	mov    %eax,%edx
801033aa:	a1 44 37 11 80       	mov    0x80113744,%eax
801033af:	83 ec 08             	sub    $0x8,%esp
801033b2:	52                   	push   %edx
801033b3:	50                   	push   %eax
801033b4:	e8 15 ce ff ff       	call   801001ce <bread>
801033b9:	83 c4 10             	add    $0x10,%esp
801033bc:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
801033bf:	8b 45 f0             	mov    -0x10(%ebp),%eax
801033c2:	8d 50 5c             	lea    0x5c(%eax),%edx
801033c5:	8b 45 ec             	mov    -0x14(%ebp),%eax
801033c8:	83 c0 5c             	add    $0x5c,%eax
801033cb:	83 ec 04             	sub    $0x4,%esp
801033ce:	68 00 02 00 00       	push   $0x200
801033d3:	52                   	push   %edx
801033d4:	50                   	push   %eax
801033d5:	e8 b2 1e 00 00       	call   8010528c <memmove>
801033da:	83 c4 10             	add    $0x10,%esp
    bwrite(dbuf);  // write dst to disk
801033dd:	83 ec 0c             	sub    $0xc,%esp
801033e0:	ff 75 ec             	pushl  -0x14(%ebp)
801033e3:	e8 1f ce ff ff       	call   80100207 <bwrite>
801033e8:	83 c4 10             	add    $0x10,%esp
    brelse(lbuf);
801033eb:	83 ec 0c             	sub    $0xc,%esp
801033ee:	ff 75 f0             	pushl  -0x10(%ebp)
801033f1:	e8 5a ce ff ff       	call   80100250 <brelse>
801033f6:	83 c4 10             	add    $0x10,%esp
    brelse(dbuf);
801033f9:	83 ec 0c             	sub    $0xc,%esp
801033fc:	ff 75 ec             	pushl  -0x14(%ebp)
801033ff:	e8 4c ce ff ff       	call   80100250 <brelse>
80103404:	83 c4 10             	add    $0x10,%esp
static void
install_trans(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103407:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010340b:	a1 48 37 11 80       	mov    0x80113748,%eax
80103410:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103413:	0f 8f 5d ff ff ff    	jg     80103376 <install_trans+0x12>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    bwrite(dbuf);  // write dst to disk
    brelse(lbuf);
    brelse(dbuf);
  }
}
80103419:	90                   	nop
8010341a:	c9                   	leave  
8010341b:	c3                   	ret    

8010341c <read_head>:

// Read the log header from disk into the in-memory log header
static void
read_head(void)
{
8010341c:	55                   	push   %ebp
8010341d:	89 e5                	mov    %esp,%ebp
8010341f:	83 ec 18             	sub    $0x18,%esp
  struct buf *buf = bread(log.dev, log.start);
80103422:	a1 34 37 11 80       	mov    0x80113734,%eax
80103427:	89 c2                	mov    %eax,%edx
80103429:	a1 44 37 11 80       	mov    0x80113744,%eax
8010342e:	83 ec 08             	sub    $0x8,%esp
80103431:	52                   	push   %edx
80103432:	50                   	push   %eax
80103433:	e8 96 cd ff ff       	call   801001ce <bread>
80103438:	83 c4 10             	add    $0x10,%esp
8010343b:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *lh = (struct logheader *) (buf->data);
8010343e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103441:	83 c0 5c             	add    $0x5c,%eax
80103444:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  log.lh.n = lh->n;
80103447:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010344a:	8b 00                	mov    (%eax),%eax
8010344c:	a3 48 37 11 80       	mov    %eax,0x80113748
  for (i = 0; i < log.lh.n; i++) {
80103451:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103458:	eb 1b                	jmp    80103475 <read_head+0x59>
    log.lh.block[i] = lh->block[i];
8010345a:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010345d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103460:	8b 44 90 04          	mov    0x4(%eax,%edx,4),%eax
80103464:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103467:	83 c2 10             	add    $0x10,%edx
8010346a:	89 04 95 0c 37 11 80 	mov    %eax,-0x7feec8f4(,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *lh = (struct logheader *) (buf->data);
  int i;
  log.lh.n = lh->n;
  for (i = 0; i < log.lh.n; i++) {
80103471:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80103475:	a1 48 37 11 80       	mov    0x80113748,%eax
8010347a:	3b 45 f4             	cmp    -0xc(%ebp),%eax
8010347d:	7f db                	jg     8010345a <read_head+0x3e>
    log.lh.block[i] = lh->block[i];
  }
  brelse(buf);
8010347f:	83 ec 0c             	sub    $0xc,%esp
80103482:	ff 75 f0             	pushl  -0x10(%ebp)
80103485:	e8 c6 cd ff ff       	call   80100250 <brelse>
8010348a:	83 c4 10             	add    $0x10,%esp
}
8010348d:	90                   	nop
8010348e:	c9                   	leave  
8010348f:	c3                   	ret    

80103490 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
80103490:	55                   	push   %ebp
80103491:	89 e5                	mov    %esp,%ebp
80103493:	83 ec 18             	sub    $0x18,%esp
  struct buf *buf = bread(log.dev, log.start);
80103496:	a1 34 37 11 80       	mov    0x80113734,%eax
8010349b:	89 c2                	mov    %eax,%edx
8010349d:	a1 44 37 11 80       	mov    0x80113744,%eax
801034a2:	83 ec 08             	sub    $0x8,%esp
801034a5:	52                   	push   %edx
801034a6:	50                   	push   %eax
801034a7:	e8 22 cd ff ff       	call   801001ce <bread>
801034ac:	83 c4 10             	add    $0x10,%esp
801034af:	89 45 f0             	mov    %eax,-0x10(%ebp)
  struct logheader *hb = (struct logheader *) (buf->data);
801034b2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801034b5:	83 c0 5c             	add    $0x5c,%eax
801034b8:	89 45 ec             	mov    %eax,-0x14(%ebp)
  int i;
  hb->n = log.lh.n;
801034bb:	8b 15 48 37 11 80    	mov    0x80113748,%edx
801034c1:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034c4:	89 10                	mov    %edx,(%eax)
  for (i = 0; i < log.lh.n; i++) {
801034c6:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801034cd:	eb 1b                	jmp    801034ea <write_head+0x5a>
    hb->block[i] = log.lh.block[i];
801034cf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801034d2:	83 c0 10             	add    $0x10,%eax
801034d5:	8b 0c 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%ecx
801034dc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801034df:	8b 55 f4             	mov    -0xc(%ebp),%edx
801034e2:	89 4c 90 04          	mov    %ecx,0x4(%eax,%edx,4)
{
  struct buf *buf = bread(log.dev, log.start);
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
  for (i = 0; i < log.lh.n; i++) {
801034e6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801034ea:	a1 48 37 11 80       	mov    0x80113748,%eax
801034ef:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801034f2:	7f db                	jg     801034cf <write_head+0x3f>
    hb->block[i] = log.lh.block[i];
  }
  bwrite(buf);
801034f4:	83 ec 0c             	sub    $0xc,%esp
801034f7:	ff 75 f0             	pushl  -0x10(%ebp)
801034fa:	e8 08 cd ff ff       	call   80100207 <bwrite>
801034ff:	83 c4 10             	add    $0x10,%esp
  brelse(buf);
80103502:	83 ec 0c             	sub    $0xc,%esp
80103505:	ff 75 f0             	pushl  -0x10(%ebp)
80103508:	e8 43 cd ff ff       	call   80100250 <brelse>
8010350d:	83 c4 10             	add    $0x10,%esp
}
80103510:	90                   	nop
80103511:	c9                   	leave  
80103512:	c3                   	ret    

80103513 <recover_from_log>:

static void
recover_from_log(void)
{
80103513:	55                   	push   %ebp
80103514:	89 e5                	mov    %esp,%ebp
80103516:	83 ec 08             	sub    $0x8,%esp
  read_head();
80103519:	e8 fe fe ff ff       	call   8010341c <read_head>
  install_trans(); // if committed, copy from log to disk
8010351e:	e8 41 fe ff ff       	call   80103364 <install_trans>
  log.lh.n = 0;
80103523:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
8010352a:	00 00 00 
  write_head(); // clear the log
8010352d:	e8 5e ff ff ff       	call   80103490 <write_head>
}
80103532:	90                   	nop
80103533:	c9                   	leave  
80103534:	c3                   	ret    

80103535 <begin_op>:

// called at the start of each FS system call.
void
begin_op(void)
{
80103535:	55                   	push   %ebp
80103536:	89 e5                	mov    %esp,%ebp
80103538:	83 ec 08             	sub    $0x8,%esp
  acquire(&log.lock);
8010353b:	83 ec 0c             	sub    $0xc,%esp
8010353e:	68 00 37 11 80       	push   $0x80113700
80103543:	e8 0e 1a 00 00       	call   80104f56 <acquire>
80103548:	83 c4 10             	add    $0x10,%esp
  while(1){
    if(log.committing){
8010354b:	a1 40 37 11 80       	mov    0x80113740,%eax
80103550:	85 c0                	test   %eax,%eax
80103552:	74 17                	je     8010356b <begin_op+0x36>
      sleep(&log, &log.lock);
80103554:	83 ec 08             	sub    $0x8,%esp
80103557:	68 00 37 11 80       	push   $0x80113700
8010355c:	68 00 37 11 80       	push   $0x80113700
80103561:	e8 d7 15 00 00       	call   80104b3d <sleep>
80103566:	83 c4 10             	add    $0x10,%esp
80103569:	eb e0                	jmp    8010354b <begin_op+0x16>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
8010356b:	8b 0d 48 37 11 80    	mov    0x80113748,%ecx
80103571:	a1 3c 37 11 80       	mov    0x8011373c,%eax
80103576:	8d 50 01             	lea    0x1(%eax),%edx
80103579:	89 d0                	mov    %edx,%eax
8010357b:	c1 e0 02             	shl    $0x2,%eax
8010357e:	01 d0                	add    %edx,%eax
80103580:	01 c0                	add    %eax,%eax
80103582:	01 c8                	add    %ecx,%eax
80103584:	83 f8 1e             	cmp    $0x1e,%eax
80103587:	7e 17                	jle    801035a0 <begin_op+0x6b>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
80103589:	83 ec 08             	sub    $0x8,%esp
8010358c:	68 00 37 11 80       	push   $0x80113700
80103591:	68 00 37 11 80       	push   $0x80113700
80103596:	e8 a2 15 00 00       	call   80104b3d <sleep>
8010359b:	83 c4 10             	add    $0x10,%esp
8010359e:	eb ab                	jmp    8010354b <begin_op+0x16>
    } else {
      log.outstanding += 1;
801035a0:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801035a5:	83 c0 01             	add    $0x1,%eax
801035a8:	a3 3c 37 11 80       	mov    %eax,0x8011373c
      release(&log.lock);
801035ad:	83 ec 0c             	sub    $0xc,%esp
801035b0:	68 00 37 11 80       	push   $0x80113700
801035b5:	e8 0a 1a 00 00       	call   80104fc4 <release>
801035ba:	83 c4 10             	add    $0x10,%esp
      break;
801035bd:	90                   	nop
    }
  }
}
801035be:	90                   	nop
801035bf:	c9                   	leave  
801035c0:	c3                   	ret    

801035c1 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
801035c1:	55                   	push   %ebp
801035c2:	89 e5                	mov    %esp,%ebp
801035c4:	83 ec 18             	sub    $0x18,%esp
  int do_commit = 0;
801035c7:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

  acquire(&log.lock);
801035ce:	83 ec 0c             	sub    $0xc,%esp
801035d1:	68 00 37 11 80       	push   $0x80113700
801035d6:	e8 7b 19 00 00       	call   80104f56 <acquire>
801035db:	83 c4 10             	add    $0x10,%esp
  log.outstanding -= 1;
801035de:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801035e3:	83 e8 01             	sub    $0x1,%eax
801035e6:	a3 3c 37 11 80       	mov    %eax,0x8011373c
  if(log.committing)
801035eb:	a1 40 37 11 80       	mov    0x80113740,%eax
801035f0:	85 c0                	test   %eax,%eax
801035f2:	74 0d                	je     80103601 <end_op+0x40>
    panic("log.committing");
801035f4:	83 ec 0c             	sub    $0xc,%esp
801035f7:	68 fd 86 10 80       	push   $0x801086fd
801035fc:	e8 9f cf ff ff       	call   801005a0 <panic>
  if(log.outstanding == 0){
80103601:	a1 3c 37 11 80       	mov    0x8011373c,%eax
80103606:	85 c0                	test   %eax,%eax
80103608:	75 13                	jne    8010361d <end_op+0x5c>
    do_commit = 1;
8010360a:	c7 45 f4 01 00 00 00 	movl   $0x1,-0xc(%ebp)
    log.committing = 1;
80103611:	c7 05 40 37 11 80 01 	movl   $0x1,0x80113740
80103618:	00 00 00 
8010361b:	eb 10                	jmp    8010362d <end_op+0x6c>
  } else {
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
8010361d:	83 ec 0c             	sub    $0xc,%esp
80103620:	68 00 37 11 80       	push   $0x80113700
80103625:	e8 f9 15 00 00       	call   80104c23 <wakeup>
8010362a:	83 c4 10             	add    $0x10,%esp
  }
  release(&log.lock);
8010362d:	83 ec 0c             	sub    $0xc,%esp
80103630:	68 00 37 11 80       	push   $0x80113700
80103635:	e8 8a 19 00 00       	call   80104fc4 <release>
8010363a:	83 c4 10             	add    $0x10,%esp

  if(do_commit){
8010363d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103641:	74 3f                	je     80103682 <end_op+0xc1>
    // call commit w/o holding locks, since not allowed
    // to sleep with locks.
    commit();
80103643:	e8 f5 00 00 00       	call   8010373d <commit>
    acquire(&log.lock);
80103648:	83 ec 0c             	sub    $0xc,%esp
8010364b:	68 00 37 11 80       	push   $0x80113700
80103650:	e8 01 19 00 00       	call   80104f56 <acquire>
80103655:	83 c4 10             	add    $0x10,%esp
    log.committing = 0;
80103658:	c7 05 40 37 11 80 00 	movl   $0x0,0x80113740
8010365f:	00 00 00 
    wakeup(&log);
80103662:	83 ec 0c             	sub    $0xc,%esp
80103665:	68 00 37 11 80       	push   $0x80113700
8010366a:	e8 b4 15 00 00       	call   80104c23 <wakeup>
8010366f:	83 c4 10             	add    $0x10,%esp
    release(&log.lock);
80103672:	83 ec 0c             	sub    $0xc,%esp
80103675:	68 00 37 11 80       	push   $0x80113700
8010367a:	e8 45 19 00 00       	call   80104fc4 <release>
8010367f:	83 c4 10             	add    $0x10,%esp
  }
}
80103682:	90                   	nop
80103683:	c9                   	leave  
80103684:	c3                   	ret    

80103685 <write_log>:

// Copy modified blocks from cache to log.
static void
write_log(void)
{
80103685:	55                   	push   %ebp
80103686:	89 e5                	mov    %esp,%ebp
80103688:	83 ec 18             	sub    $0x18,%esp
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
8010368b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103692:	e9 95 00 00 00       	jmp    8010372c <write_log+0xa7>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
80103697:	8b 15 34 37 11 80    	mov    0x80113734,%edx
8010369d:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036a0:	01 d0                	add    %edx,%eax
801036a2:	83 c0 01             	add    $0x1,%eax
801036a5:	89 c2                	mov    %eax,%edx
801036a7:	a1 44 37 11 80       	mov    0x80113744,%eax
801036ac:	83 ec 08             	sub    $0x8,%esp
801036af:	52                   	push   %edx
801036b0:	50                   	push   %eax
801036b1:	e8 18 cb ff ff       	call   801001ce <bread>
801036b6:	83 c4 10             	add    $0x10,%esp
801036b9:	89 45 f0             	mov    %eax,-0x10(%ebp)
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
801036bc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801036bf:	83 c0 10             	add    $0x10,%eax
801036c2:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801036c9:	89 c2                	mov    %eax,%edx
801036cb:	a1 44 37 11 80       	mov    0x80113744,%eax
801036d0:	83 ec 08             	sub    $0x8,%esp
801036d3:	52                   	push   %edx
801036d4:	50                   	push   %eax
801036d5:	e8 f4 ca ff ff       	call   801001ce <bread>
801036da:	83 c4 10             	add    $0x10,%esp
801036dd:	89 45 ec             	mov    %eax,-0x14(%ebp)
    memmove(to->data, from->data, BSIZE);
801036e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801036e3:	8d 50 5c             	lea    0x5c(%eax),%edx
801036e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801036e9:	83 c0 5c             	add    $0x5c,%eax
801036ec:	83 ec 04             	sub    $0x4,%esp
801036ef:	68 00 02 00 00       	push   $0x200
801036f4:	52                   	push   %edx
801036f5:	50                   	push   %eax
801036f6:	e8 91 1b 00 00       	call   8010528c <memmove>
801036fb:	83 c4 10             	add    $0x10,%esp
    bwrite(to);  // write the log
801036fe:	83 ec 0c             	sub    $0xc,%esp
80103701:	ff 75 f0             	pushl  -0x10(%ebp)
80103704:	e8 fe ca ff ff       	call   80100207 <bwrite>
80103709:	83 c4 10             	add    $0x10,%esp
    brelse(from);
8010370c:	83 ec 0c             	sub    $0xc,%esp
8010370f:	ff 75 ec             	pushl  -0x14(%ebp)
80103712:	e8 39 cb ff ff       	call   80100250 <brelse>
80103717:	83 c4 10             	add    $0x10,%esp
    brelse(to);
8010371a:	83 ec 0c             	sub    $0xc,%esp
8010371d:	ff 75 f0             	pushl  -0x10(%ebp)
80103720:	e8 2b cb ff ff       	call   80100250 <brelse>
80103725:	83 c4 10             	add    $0x10,%esp
static void
write_log(void)
{
  int tail;

  for (tail = 0; tail < log.lh.n; tail++) {
80103728:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010372c:	a1 48 37 11 80       	mov    0x80113748,%eax
80103731:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103734:	0f 8f 5d ff ff ff    	jg     80103697 <write_log+0x12>
    memmove(to->data, from->data, BSIZE);
    bwrite(to);  // write the log
    brelse(from);
    brelse(to);
  }
}
8010373a:	90                   	nop
8010373b:	c9                   	leave  
8010373c:	c3                   	ret    

8010373d <commit>:

static void
commit()
{
8010373d:	55                   	push   %ebp
8010373e:	89 e5                	mov    %esp,%ebp
80103740:	83 ec 08             	sub    $0x8,%esp
  if (log.lh.n > 0) {
80103743:	a1 48 37 11 80       	mov    0x80113748,%eax
80103748:	85 c0                	test   %eax,%eax
8010374a:	7e 1e                	jle    8010376a <commit+0x2d>
    write_log();     // Write modified blocks from cache to log
8010374c:	e8 34 ff ff ff       	call   80103685 <write_log>
    write_head();    // Write header to disk -- the real commit
80103751:	e8 3a fd ff ff       	call   80103490 <write_head>
    install_trans(); // Now install writes to home locations
80103756:	e8 09 fc ff ff       	call   80103364 <install_trans>
    log.lh.n = 0;
8010375b:	c7 05 48 37 11 80 00 	movl   $0x0,0x80113748
80103762:	00 00 00 
    write_head();    // Erase the transaction from the log
80103765:	e8 26 fd ff ff       	call   80103490 <write_head>
  }
}
8010376a:	90                   	nop
8010376b:	c9                   	leave  
8010376c:	c3                   	ret    

8010376d <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
8010376d:	55                   	push   %ebp
8010376e:	89 e5                	mov    %esp,%ebp
80103770:	83 ec 18             	sub    $0x18,%esp
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
80103773:	a1 48 37 11 80       	mov    0x80113748,%eax
80103778:	83 f8 1d             	cmp    $0x1d,%eax
8010377b:	7f 12                	jg     8010378f <log_write+0x22>
8010377d:	a1 48 37 11 80       	mov    0x80113748,%eax
80103782:	8b 15 38 37 11 80    	mov    0x80113738,%edx
80103788:	83 ea 01             	sub    $0x1,%edx
8010378b:	39 d0                	cmp    %edx,%eax
8010378d:	7c 0d                	jl     8010379c <log_write+0x2f>
    panic("too big a transaction");
8010378f:	83 ec 0c             	sub    $0xc,%esp
80103792:	68 0c 87 10 80       	push   $0x8010870c
80103797:	e8 04 ce ff ff       	call   801005a0 <panic>
  if (log.outstanding < 1)
8010379c:	a1 3c 37 11 80       	mov    0x8011373c,%eax
801037a1:	85 c0                	test   %eax,%eax
801037a3:	7f 0d                	jg     801037b2 <log_write+0x45>
    panic("log_write outside of trans");
801037a5:	83 ec 0c             	sub    $0xc,%esp
801037a8:	68 22 87 10 80       	push   $0x80108722
801037ad:	e8 ee cd ff ff       	call   801005a0 <panic>

  acquire(&log.lock);
801037b2:	83 ec 0c             	sub    $0xc,%esp
801037b5:	68 00 37 11 80       	push   $0x80113700
801037ba:	e8 97 17 00 00       	call   80104f56 <acquire>
801037bf:	83 c4 10             	add    $0x10,%esp
  for (i = 0; i < log.lh.n; i++) {
801037c2:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801037c9:	eb 1d                	jmp    801037e8 <log_write+0x7b>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
801037cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801037ce:	83 c0 10             	add    $0x10,%eax
801037d1:	8b 04 85 0c 37 11 80 	mov    -0x7feec8f4(,%eax,4),%eax
801037d8:	89 c2                	mov    %eax,%edx
801037da:	8b 45 08             	mov    0x8(%ebp),%eax
801037dd:	8b 40 08             	mov    0x8(%eax),%eax
801037e0:	39 c2                	cmp    %eax,%edx
801037e2:	74 10                	je     801037f4 <log_write+0x87>
    panic("too big a transaction");
  if (log.outstanding < 1)
    panic("log_write outside of trans");

  acquire(&log.lock);
  for (i = 0; i < log.lh.n; i++) {
801037e4:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801037e8:	a1 48 37 11 80       	mov    0x80113748,%eax
801037ed:	3b 45 f4             	cmp    -0xc(%ebp),%eax
801037f0:	7f d9                	jg     801037cb <log_write+0x5e>
801037f2:	eb 01                	jmp    801037f5 <log_write+0x88>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
      break;
801037f4:	90                   	nop
  }
  log.lh.block[i] = b->blockno;
801037f5:	8b 45 08             	mov    0x8(%ebp),%eax
801037f8:	8b 40 08             	mov    0x8(%eax),%eax
801037fb:	89 c2                	mov    %eax,%edx
801037fd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103800:	83 c0 10             	add    $0x10,%eax
80103803:	89 14 85 0c 37 11 80 	mov    %edx,-0x7feec8f4(,%eax,4)
  if (i == log.lh.n)
8010380a:	a1 48 37 11 80       	mov    0x80113748,%eax
8010380f:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103812:	75 0d                	jne    80103821 <log_write+0xb4>
    log.lh.n++;
80103814:	a1 48 37 11 80       	mov    0x80113748,%eax
80103819:	83 c0 01             	add    $0x1,%eax
8010381c:	a3 48 37 11 80       	mov    %eax,0x80113748
  b->flags |= B_DIRTY; // prevent eviction
80103821:	8b 45 08             	mov    0x8(%ebp),%eax
80103824:	8b 00                	mov    (%eax),%eax
80103826:	83 c8 04             	or     $0x4,%eax
80103829:	89 c2                	mov    %eax,%edx
8010382b:	8b 45 08             	mov    0x8(%ebp),%eax
8010382e:	89 10                	mov    %edx,(%eax)
  release(&log.lock);
80103830:	83 ec 0c             	sub    $0xc,%esp
80103833:	68 00 37 11 80       	push   $0x80113700
80103838:	e8 87 17 00 00       	call   80104fc4 <release>
8010383d:	83 c4 10             	add    $0x10,%esp
}
80103840:	90                   	nop
80103841:	c9                   	leave  
80103842:	c3                   	ret    

80103843 <xchg>:
  asm volatile("sti");
}

static inline uint
xchg(volatile uint *addr, uint newval)
{
80103843:	55                   	push   %ebp
80103844:	89 e5                	mov    %esp,%ebp
80103846:	83 ec 10             	sub    $0x10,%esp
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80103849:	8b 55 08             	mov    0x8(%ebp),%edx
8010384c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010384f:	8b 4d 08             	mov    0x8(%ebp),%ecx
80103852:	f0 87 02             	lock xchg %eax,(%edx)
80103855:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80103858:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010385b:	c9                   	leave  
8010385c:	c3                   	ret    

8010385d <main>:
// Bootstrap processor starts running C code here.
// Allocate a real stack and switch to it, first
// doing some setup required for memory allocator to work.
int
main(void)
{
8010385d:	8d 4c 24 04          	lea    0x4(%esp),%ecx
80103861:	83 e4 f0             	and    $0xfffffff0,%esp
80103864:	ff 71 fc             	pushl  -0x4(%ecx)
80103867:	55                   	push   %ebp
80103868:	89 e5                	mov    %esp,%ebp
8010386a:	51                   	push   %ecx
8010386b:	83 ec 04             	sub    $0x4,%esp
  kinit1(end, P2V(4*1024*1024)); // phys page allocator
8010386e:	83 ec 08             	sub    $0x8,%esp
80103871:	68 00 00 40 80       	push   $0x80400000
80103876:	68 28 65 11 80       	push   $0x80116528
8010387b:	e8 e1 f2 ff ff       	call   80102b61 <kinit1>
80103880:	83 c4 10             	add    $0x10,%esp
  kvmalloc();      // kernel page table
80103883:	e8 4e 44 00 00       	call   80107cd6 <kvmalloc>
  mpinit();        // detect other processors
80103888:	e8 ba 03 00 00       	call   80103c47 <mpinit>
  lapicinit();     // interrupt controller
8010388d:	e8 3b f6 ff ff       	call   80102ecd <lapicinit>
  seginit();       // segment descriptors
80103892:	e8 2a 3f 00 00       	call   801077c1 <seginit>
  picinit();       // disable pic
80103897:	e8 fc 04 00 00       	call   80103d98 <picinit>
  ioapicinit();    // another interrupt controller
8010389c:	e8 dc f1 ff ff       	call   80102a7d <ioapicinit>
  consoleinit();   // console hardware
801038a1:	e8 a5 d2 ff ff       	call   80100b4b <consoleinit>
  uartinit();      // serial port
801038a6:	e8 af 32 00 00       	call   80106b5a <uartinit>
  pinit();         // process table
801038ab:	e8 21 09 00 00       	call   801041d1 <pinit>
  tvinit();        // trap vectors
801038b0:	e8 e0 2c 00 00       	call   80106595 <tvinit>
  binit();         // buffer cache
801038b5:	e8 7a c7 ff ff       	call   80100034 <binit>
  fileinit();      // file table
801038ba:	e8 16 d7 ff ff       	call   80100fd5 <fileinit>
  ideinit();       // disk 
801038bf:	e8 90 ed ff ff       	call   80102654 <ideinit>
  startothers();   // start other processors
801038c4:	e8 80 00 00 00       	call   80103949 <startothers>
  kinit2(P2V(4*1024*1024), P2V(PHYSTOP)); // must come after startothers()
801038c9:	83 ec 08             	sub    $0x8,%esp
801038cc:	68 00 00 00 8e       	push   $0x8e000000
801038d1:	68 00 00 40 80       	push   $0x80400000
801038d6:	e8 bf f2 ff ff       	call   80102b9a <kinit2>
801038db:	83 c4 10             	add    $0x10,%esp
  userinit();      // first user process
801038de:	e8 d4 0a 00 00       	call   801043b7 <userinit>
  mpmain();        // finish this processor's setup
801038e3:	e8 1a 00 00 00       	call   80103902 <mpmain>

801038e8 <mpenter>:
}

// Other CPUs jump here from entryother.S.
static void
mpenter(void)
{
801038e8:	55                   	push   %ebp
801038e9:	89 e5                	mov    %esp,%ebp
801038eb:	83 ec 08             	sub    $0x8,%esp
  switchkvm();
801038ee:	e8 fb 43 00 00       	call   80107cee <switchkvm>
  seginit();
801038f3:	e8 c9 3e 00 00       	call   801077c1 <seginit>
  lapicinit();
801038f8:	e8 d0 f5 ff ff       	call   80102ecd <lapicinit>
  mpmain();
801038fd:	e8 00 00 00 00       	call   80103902 <mpmain>

80103902 <mpmain>:
}

// Common CPU setup code.
static void
mpmain(void)
{
80103902:	55                   	push   %ebp
80103903:	89 e5                	mov    %esp,%ebp
80103905:	53                   	push   %ebx
80103906:	83 ec 04             	sub    $0x4,%esp
  cprintf("cpu%d: starting %d\n", cpuid(), cpuid());
80103909:	e8 e1 08 00 00       	call   801041ef <cpuid>
8010390e:	89 c3                	mov    %eax,%ebx
80103910:	e8 da 08 00 00       	call   801041ef <cpuid>
80103915:	83 ec 04             	sub    $0x4,%esp
80103918:	53                   	push   %ebx
80103919:	50                   	push   %eax
8010391a:	68 3d 87 10 80       	push   $0x8010873d
8010391f:	e8 dc ca ff ff       	call   80100400 <cprintf>
80103924:	83 c4 10             	add    $0x10,%esp
  idtinit();       // load idt register
80103927:	e8 df 2d 00 00       	call   8010670b <idtinit>
  xchg(&(mycpu()->started), 1); // tell startothers() we're up
8010392c:	e8 df 08 00 00       	call   80104210 <mycpu>
80103931:	05 a0 00 00 00       	add    $0xa0,%eax
80103936:	83 ec 08             	sub    $0x8,%esp
80103939:	6a 01                	push   $0x1
8010393b:	50                   	push   %eax
8010393c:	e8 02 ff ff ff       	call   80103843 <xchg>
80103941:	83 c4 10             	add    $0x10,%esp
  scheduler();     // start running processes
80103944:	e8 01 10 00 00       	call   8010494a <scheduler>

80103949 <startothers>:
pde_t entrypgdir[];  // For entry.S

// Start the non-boot (AP) processors.
static void
startothers(void)
{
80103949:	55                   	push   %ebp
8010394a:	89 e5                	mov    %esp,%ebp
8010394c:	83 ec 18             	sub    $0x18,%esp
  char *stack;

  // Write entry code to unused memory at 0x7000.
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
8010394f:	c7 45 f0 00 70 00 80 	movl   $0x80007000,-0x10(%ebp)
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);
80103956:	b8 8a 00 00 00       	mov    $0x8a,%eax
8010395b:	83 ec 04             	sub    $0x4,%esp
8010395e:	50                   	push   %eax
8010395f:	68 ec b4 10 80       	push   $0x8010b4ec
80103964:	ff 75 f0             	pushl  -0x10(%ebp)
80103967:	e8 20 19 00 00       	call   8010528c <memmove>
8010396c:	83 c4 10             	add    $0x10,%esp

  for(c = cpus; c < cpus+ncpu; c++){
8010396f:	c7 45 f4 00 38 11 80 	movl   $0x80113800,-0xc(%ebp)
80103976:	eb 79                	jmp    801039f1 <startothers+0xa8>
    if(c == mycpu())  // We've started already.
80103978:	e8 93 08 00 00       	call   80104210 <mycpu>
8010397d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103980:	74 67                	je     801039e9 <startothers+0xa0>
      continue;

    // Tell entryother.S what stack to use, where to enter, and what
    // pgdir to use. We cannot use kpgdir yet, because the AP processor
    // is running in low  memory, so we use entrypgdir for the APs too.
    stack = kalloc();
80103982:	e8 0e f3 ff ff       	call   80102c95 <kalloc>
80103987:	89 45 ec             	mov    %eax,-0x14(%ebp)
    *(void**)(code-4) = stack + KSTACKSIZE;
8010398a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010398d:	83 e8 04             	sub    $0x4,%eax
80103990:	8b 55 ec             	mov    -0x14(%ebp),%edx
80103993:	81 c2 00 10 00 00    	add    $0x1000,%edx
80103999:	89 10                	mov    %edx,(%eax)
    *(void**)(code-8) = mpenter;
8010399b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010399e:	83 e8 08             	sub    $0x8,%eax
801039a1:	c7 00 e8 38 10 80    	movl   $0x801038e8,(%eax)
    *(int**)(code-12) = (void *) V2P(entrypgdir);
801039a7:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039aa:	83 e8 0c             	sub    $0xc,%eax
801039ad:	ba 00 a0 10 80       	mov    $0x8010a000,%edx
801039b2:	81 c2 00 00 00 80    	add    $0x80000000,%edx
801039b8:	89 10                	mov    %edx,(%eax)

    lapicstartap(c->apicid, V2P(code));
801039ba:	8b 45 f0             	mov    -0x10(%ebp),%eax
801039bd:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
801039c3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039c6:	0f b6 00             	movzbl (%eax),%eax
801039c9:	0f b6 c0             	movzbl %al,%eax
801039cc:	83 ec 08             	sub    $0x8,%esp
801039cf:	52                   	push   %edx
801039d0:	50                   	push   %eax
801039d1:	e8 58 f6 ff ff       	call   8010302e <lapicstartap>
801039d6:	83 c4 10             	add    $0x10,%esp

    // wait for cpu to finish mpmain()
    while(c->started == 0)
801039d9:	90                   	nop
801039da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801039dd:	8b 80 a0 00 00 00    	mov    0xa0(%eax),%eax
801039e3:	85 c0                	test   %eax,%eax
801039e5:	74 f3                	je     801039da <startothers+0x91>
801039e7:	eb 01                	jmp    801039ea <startothers+0xa1>
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
    if(c == mycpu())  // We've started already.
      continue;
801039e9:	90                   	nop
  // The linker has placed the image of entryother.S in
  // _binary_entryother_start.
  code = P2V(0x7000);
  memmove(code, _binary_entryother_start, (uint)_binary_entryother_size);

  for(c = cpus; c < cpus+ncpu; c++){
801039ea:	81 45 f4 b0 00 00 00 	addl   $0xb0,-0xc(%ebp)
801039f1:	a1 80 3d 11 80       	mov    0x80113d80,%eax
801039f6:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
801039fc:	05 00 38 11 80       	add    $0x80113800,%eax
80103a01:	3b 45 f4             	cmp    -0xc(%ebp),%eax
80103a04:	0f 87 6e ff ff ff    	ja     80103978 <startothers+0x2f>

    // wait for cpu to finish mpmain()
    while(c->started == 0)
      ;
  }
}
80103a0a:	90                   	nop
80103a0b:	c9                   	leave  
80103a0c:	c3                   	ret    

80103a0d <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80103a0d:	55                   	push   %ebp
80103a0e:	89 e5                	mov    %esp,%ebp
80103a10:	83 ec 14             	sub    $0x14,%esp
80103a13:	8b 45 08             	mov    0x8(%ebp),%eax
80103a16:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80103a1a:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80103a1e:	89 c2                	mov    %eax,%edx
80103a20:	ec                   	in     (%dx),%al
80103a21:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80103a24:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80103a28:	c9                   	leave  
80103a29:	c3                   	ret    

80103a2a <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103a2a:	55                   	push   %ebp
80103a2b:	89 e5                	mov    %esp,%ebp
80103a2d:	83 ec 08             	sub    $0x8,%esp
80103a30:	8b 55 08             	mov    0x8(%ebp),%edx
80103a33:	8b 45 0c             	mov    0xc(%ebp),%eax
80103a36:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103a3a:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103a3d:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103a41:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103a45:	ee                   	out    %al,(%dx)
}
80103a46:	90                   	nop
80103a47:	c9                   	leave  
80103a48:	c3                   	ret    

80103a49 <sum>:
int ncpu;
uchar ioapicid;

static uchar
sum(uchar *addr, int len)
{
80103a49:	55                   	push   %ebp
80103a4a:	89 e5                	mov    %esp,%ebp
80103a4c:	83 ec 10             	sub    $0x10,%esp
  int i, sum;

  sum = 0;
80103a4f:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
  for(i=0; i<len; i++)
80103a56:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80103a5d:	eb 15                	jmp    80103a74 <sum+0x2b>
    sum += addr[i];
80103a5f:	8b 55 fc             	mov    -0x4(%ebp),%edx
80103a62:	8b 45 08             	mov    0x8(%ebp),%eax
80103a65:	01 d0                	add    %edx,%eax
80103a67:	0f b6 00             	movzbl (%eax),%eax
80103a6a:	0f b6 c0             	movzbl %al,%eax
80103a6d:	01 45 f8             	add    %eax,-0x8(%ebp)
sum(uchar *addr, int len)
{
  int i, sum;

  sum = 0;
  for(i=0; i<len; i++)
80103a70:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80103a74:	8b 45 fc             	mov    -0x4(%ebp),%eax
80103a77:	3b 45 0c             	cmp    0xc(%ebp),%eax
80103a7a:	7c e3                	jl     80103a5f <sum+0x16>
    sum += addr[i];
  return sum;
80103a7c:	8b 45 f8             	mov    -0x8(%ebp),%eax
}
80103a7f:	c9                   	leave  
80103a80:	c3                   	ret    

80103a81 <mpsearch1>:

// Look for an MP structure in the len bytes at addr.
static struct mp*
mpsearch1(uint a, int len)
{
80103a81:	55                   	push   %ebp
80103a82:	89 e5                	mov    %esp,%ebp
80103a84:	83 ec 18             	sub    $0x18,%esp
  uchar *e, *p, *addr;

  addr = P2V(a);
80103a87:	8b 45 08             	mov    0x8(%ebp),%eax
80103a8a:	05 00 00 00 80       	add    $0x80000000,%eax
80103a8f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  e = addr+len;
80103a92:	8b 55 0c             	mov    0xc(%ebp),%edx
80103a95:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103a98:	01 d0                	add    %edx,%eax
80103a9a:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(p = addr; p < e; p += sizeof(struct mp))
80103a9d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103aa0:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103aa3:	eb 36                	jmp    80103adb <mpsearch1+0x5a>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
80103aa5:	83 ec 04             	sub    $0x4,%esp
80103aa8:	6a 04                	push   $0x4
80103aaa:	68 54 87 10 80       	push   $0x80108754
80103aaf:	ff 75 f4             	pushl  -0xc(%ebp)
80103ab2:	e8 7d 17 00 00       	call   80105234 <memcmp>
80103ab7:	83 c4 10             	add    $0x10,%esp
80103aba:	85 c0                	test   %eax,%eax
80103abc:	75 19                	jne    80103ad7 <mpsearch1+0x56>
80103abe:	83 ec 08             	sub    $0x8,%esp
80103ac1:	6a 10                	push   $0x10
80103ac3:	ff 75 f4             	pushl  -0xc(%ebp)
80103ac6:	e8 7e ff ff ff       	call   80103a49 <sum>
80103acb:	83 c4 10             	add    $0x10,%esp
80103ace:	84 c0                	test   %al,%al
80103ad0:	75 05                	jne    80103ad7 <mpsearch1+0x56>
      return (struct mp*)p;
80103ad2:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ad5:	eb 11                	jmp    80103ae8 <mpsearch1+0x67>
{
  uchar *e, *p, *addr;

  addr = P2V(a);
  e = addr+len;
  for(p = addr; p < e; p += sizeof(struct mp))
80103ad7:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80103adb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ade:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80103ae1:	72 c2                	jb     80103aa5 <mpsearch1+0x24>
    if(memcmp(p, "_MP_", 4) == 0 && sum(p, sizeof(struct mp)) == 0)
      return (struct mp*)p;
  return 0;
80103ae3:	b8 00 00 00 00       	mov    $0x0,%eax
}
80103ae8:	c9                   	leave  
80103ae9:	c3                   	ret    

80103aea <mpsearch>:
// 1) in the first KB of the EBDA;
// 2) in the last KB of system base memory;
// 3) in the BIOS ROM between 0xE0000 and 0xFFFFF.
static struct mp*
mpsearch(void)
{
80103aea:	55                   	push   %ebp
80103aeb:	89 e5                	mov    %esp,%ebp
80103aed:	83 ec 18             	sub    $0x18,%esp
  uchar *bda;
  uint p;
  struct mp *mp;

  bda = (uchar *) P2V(0x400);
80103af0:	c7 45 f4 00 04 00 80 	movl   $0x80000400,-0xc(%ebp)
  if((p = ((bda[0x0F]<<8)| bda[0x0E]) << 4)){
80103af7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103afa:	83 c0 0f             	add    $0xf,%eax
80103afd:	0f b6 00             	movzbl (%eax),%eax
80103b00:	0f b6 c0             	movzbl %al,%eax
80103b03:	c1 e0 08             	shl    $0x8,%eax
80103b06:	89 c2                	mov    %eax,%edx
80103b08:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b0b:	83 c0 0e             	add    $0xe,%eax
80103b0e:	0f b6 00             	movzbl (%eax),%eax
80103b11:	0f b6 c0             	movzbl %al,%eax
80103b14:	09 d0                	or     %edx,%eax
80103b16:	c1 e0 04             	shl    $0x4,%eax
80103b19:	89 45 f0             	mov    %eax,-0x10(%ebp)
80103b1c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103b20:	74 21                	je     80103b43 <mpsearch+0x59>
    if((mp = mpsearch1(p, 1024)))
80103b22:	83 ec 08             	sub    $0x8,%esp
80103b25:	68 00 04 00 00       	push   $0x400
80103b2a:	ff 75 f0             	pushl  -0x10(%ebp)
80103b2d:	e8 4f ff ff ff       	call   80103a81 <mpsearch1>
80103b32:	83 c4 10             	add    $0x10,%esp
80103b35:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b38:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b3c:	74 51                	je     80103b8f <mpsearch+0xa5>
      return mp;
80103b3e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b41:	eb 61                	jmp    80103ba4 <mpsearch+0xba>
  } else {
    p = ((bda[0x14]<<8)|bda[0x13])*1024;
80103b43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b46:	83 c0 14             	add    $0x14,%eax
80103b49:	0f b6 00             	movzbl (%eax),%eax
80103b4c:	0f b6 c0             	movzbl %al,%eax
80103b4f:	c1 e0 08             	shl    $0x8,%eax
80103b52:	89 c2                	mov    %eax,%edx
80103b54:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103b57:	83 c0 13             	add    $0x13,%eax
80103b5a:	0f b6 00             	movzbl (%eax),%eax
80103b5d:	0f b6 c0             	movzbl %al,%eax
80103b60:	09 d0                	or     %edx,%eax
80103b62:	c1 e0 0a             	shl    $0xa,%eax
80103b65:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if((mp = mpsearch1(p-1024, 1024)))
80103b68:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103b6b:	2d 00 04 00 00       	sub    $0x400,%eax
80103b70:	83 ec 08             	sub    $0x8,%esp
80103b73:	68 00 04 00 00       	push   $0x400
80103b78:	50                   	push   %eax
80103b79:	e8 03 ff ff ff       	call   80103a81 <mpsearch1>
80103b7e:	83 c4 10             	add    $0x10,%esp
80103b81:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103b84:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103b88:	74 05                	je     80103b8f <mpsearch+0xa5>
      return mp;
80103b8a:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103b8d:	eb 15                	jmp    80103ba4 <mpsearch+0xba>
  }
  return mpsearch1(0xF0000, 0x10000);
80103b8f:	83 ec 08             	sub    $0x8,%esp
80103b92:	68 00 00 01 00       	push   $0x10000
80103b97:	68 00 00 0f 00       	push   $0xf0000
80103b9c:	e8 e0 fe ff ff       	call   80103a81 <mpsearch1>
80103ba1:	83 c4 10             	add    $0x10,%esp
}
80103ba4:	c9                   	leave  
80103ba5:	c3                   	ret    

80103ba6 <mpconfig>:
// Check for correct signature, calculate the checksum and,
// if correct, check the version.
// To do: check extended table checksum.
static struct mpconf*
mpconfig(struct mp **pmp)
{
80103ba6:	55                   	push   %ebp
80103ba7:	89 e5                	mov    %esp,%ebp
80103ba9:	83 ec 18             	sub    $0x18,%esp
  struct mpconf *conf;
  struct mp *mp;

  if((mp = mpsearch()) == 0 || mp->physaddr == 0)
80103bac:	e8 39 ff ff ff       	call   80103aea <mpsearch>
80103bb1:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103bb4:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103bb8:	74 0a                	je     80103bc4 <mpconfig+0x1e>
80103bba:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bbd:	8b 40 04             	mov    0x4(%eax),%eax
80103bc0:	85 c0                	test   %eax,%eax
80103bc2:	75 07                	jne    80103bcb <mpconfig+0x25>
    return 0;
80103bc4:	b8 00 00 00 00       	mov    $0x0,%eax
80103bc9:	eb 7a                	jmp    80103c45 <mpconfig+0x9f>
  conf = (struct mpconf*) P2V((uint) mp->physaddr);
80103bcb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103bce:	8b 40 04             	mov    0x4(%eax),%eax
80103bd1:	05 00 00 00 80       	add    $0x80000000,%eax
80103bd6:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(memcmp(conf, "PCMP", 4) != 0)
80103bd9:	83 ec 04             	sub    $0x4,%esp
80103bdc:	6a 04                	push   $0x4
80103bde:	68 59 87 10 80       	push   $0x80108759
80103be3:	ff 75 f0             	pushl  -0x10(%ebp)
80103be6:	e8 49 16 00 00       	call   80105234 <memcmp>
80103beb:	83 c4 10             	add    $0x10,%esp
80103bee:	85 c0                	test   %eax,%eax
80103bf0:	74 07                	je     80103bf9 <mpconfig+0x53>
    return 0;
80103bf2:	b8 00 00 00 00       	mov    $0x0,%eax
80103bf7:	eb 4c                	jmp    80103c45 <mpconfig+0x9f>
  if(conf->version != 1 && conf->version != 4)
80103bf9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103bfc:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c00:	3c 01                	cmp    $0x1,%al
80103c02:	74 12                	je     80103c16 <mpconfig+0x70>
80103c04:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c07:	0f b6 40 06          	movzbl 0x6(%eax),%eax
80103c0b:	3c 04                	cmp    $0x4,%al
80103c0d:	74 07                	je     80103c16 <mpconfig+0x70>
    return 0;
80103c0f:	b8 00 00 00 00       	mov    $0x0,%eax
80103c14:	eb 2f                	jmp    80103c45 <mpconfig+0x9f>
  if(sum((uchar*)conf, conf->length) != 0)
80103c16:	8b 45 f0             	mov    -0x10(%ebp),%eax
80103c19:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c1d:	0f b7 c0             	movzwl %ax,%eax
80103c20:	83 ec 08             	sub    $0x8,%esp
80103c23:	50                   	push   %eax
80103c24:	ff 75 f0             	pushl  -0x10(%ebp)
80103c27:	e8 1d fe ff ff       	call   80103a49 <sum>
80103c2c:	83 c4 10             	add    $0x10,%esp
80103c2f:	84 c0                	test   %al,%al
80103c31:	74 07                	je     80103c3a <mpconfig+0x94>
    return 0;
80103c33:	b8 00 00 00 00       	mov    $0x0,%eax
80103c38:	eb 0b                	jmp    80103c45 <mpconfig+0x9f>
  *pmp = mp;
80103c3a:	8b 45 08             	mov    0x8(%ebp),%eax
80103c3d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103c40:	89 10                	mov    %edx,(%eax)
  return conf;
80103c42:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80103c45:	c9                   	leave  
80103c46:	c3                   	ret    

80103c47 <mpinit>:

void
mpinit(void)
{
80103c47:	55                   	push   %ebp
80103c48:	89 e5                	mov    %esp,%ebp
80103c4a:	83 ec 28             	sub    $0x28,%esp
  struct mp *mp;
  struct mpconf *conf;
  struct mpproc *proc;
  struct mpioapic *ioapic;

  if((conf = mpconfig(&mp)) == 0)
80103c4d:	83 ec 0c             	sub    $0xc,%esp
80103c50:	8d 45 dc             	lea    -0x24(%ebp),%eax
80103c53:	50                   	push   %eax
80103c54:	e8 4d ff ff ff       	call   80103ba6 <mpconfig>
80103c59:	83 c4 10             	add    $0x10,%esp
80103c5c:	89 45 ec             	mov    %eax,-0x14(%ebp)
80103c5f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80103c63:	75 0d                	jne    80103c72 <mpinit+0x2b>
    panic("Expect to run on an SMP");
80103c65:	83 ec 0c             	sub    $0xc,%esp
80103c68:	68 5e 87 10 80       	push   $0x8010875e
80103c6d:	e8 2e c9 ff ff       	call   801005a0 <panic>
  ismp = 1;
80103c72:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
  lapic = (uint*)conf->lapicaddr;
80103c79:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c7c:	8b 40 24             	mov    0x24(%eax),%eax
80103c7f:	a3 fc 36 11 80       	mov    %eax,0x801136fc
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103c84:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c87:	83 c0 2c             	add    $0x2c,%eax
80103c8a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103c8d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c90:	0f b7 40 04          	movzwl 0x4(%eax),%eax
80103c94:	0f b7 d0             	movzwl %ax,%edx
80103c97:	8b 45 ec             	mov    -0x14(%ebp),%eax
80103c9a:	01 d0                	add    %edx,%eax
80103c9c:	89 45 e8             	mov    %eax,-0x18(%ebp)
80103c9f:	eb 7b                	jmp    80103d1c <mpinit+0xd5>
    switch(*p){
80103ca1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103ca4:	0f b6 00             	movzbl (%eax),%eax
80103ca7:	0f b6 c0             	movzbl %al,%eax
80103caa:	83 f8 04             	cmp    $0x4,%eax
80103cad:	77 65                	ja     80103d14 <mpinit+0xcd>
80103caf:	8b 04 85 98 87 10 80 	mov    -0x7fef7868(,%eax,4),%eax
80103cb6:	ff e0                	jmp    *%eax
    case MPPROC:
      proc = (struct mpproc*)p;
80103cb8:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cbb:	89 45 e4             	mov    %eax,-0x1c(%ebp)
      if(ncpu < NCPU) {
80103cbe:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103cc3:	83 f8 07             	cmp    $0x7,%eax
80103cc6:	7f 28                	jg     80103cf0 <mpinit+0xa9>
        cpus[ncpu].apicid = proc->apicid;  // apicid may differ from ncpu
80103cc8:	8b 15 80 3d 11 80    	mov    0x80113d80,%edx
80103cce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80103cd1:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103cd5:	69 d2 b0 00 00 00    	imul   $0xb0,%edx,%edx
80103cdb:	81 c2 00 38 11 80    	add    $0x80113800,%edx
80103ce1:	88 02                	mov    %al,(%edx)
        ncpu++;
80103ce3:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80103ce8:	83 c0 01             	add    $0x1,%eax
80103ceb:	a3 80 3d 11 80       	mov    %eax,0x80113d80
      }
      p += sizeof(struct mpproc);
80103cf0:	83 45 f4 14          	addl   $0x14,-0xc(%ebp)
      continue;
80103cf4:	eb 26                	jmp    80103d1c <mpinit+0xd5>
    case MPIOAPIC:
      ioapic = (struct mpioapic*)p;
80103cf6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103cf9:	89 45 e0             	mov    %eax,-0x20(%ebp)
      ioapicid = ioapic->apicno;
80103cfc:	8b 45 e0             	mov    -0x20(%ebp),%eax
80103cff:	0f b6 40 01          	movzbl 0x1(%eax),%eax
80103d03:	a2 e0 37 11 80       	mov    %al,0x801137e0
      p += sizeof(struct mpioapic);
80103d08:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103d0c:	eb 0e                	jmp    80103d1c <mpinit+0xd5>
    case MPBUS:
    case MPIOINTR:
    case MPLINTR:
      p += 8;
80103d0e:	83 45 f4 08          	addl   $0x8,-0xc(%ebp)
      continue;
80103d12:	eb 08                	jmp    80103d1c <mpinit+0xd5>
    default:
      ismp = 0;
80103d14:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
      break;
80103d1b:	90                   	nop

  if((conf = mpconfig(&mp)) == 0)
    panic("Expect to run on an SMP");
  ismp = 1;
  lapic = (uint*)conf->lapicaddr;
  for(p=(uchar*)(conf+1), e=(uchar*)conf+conf->length; p<e; ){
80103d1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103d1f:	3b 45 e8             	cmp    -0x18(%ebp),%eax
80103d22:	0f 82 79 ff ff ff    	jb     80103ca1 <mpinit+0x5a>
    default:
      ismp = 0;
      break;
    }
  }
  if(!ismp)
80103d28:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80103d2c:	75 0d                	jne    80103d3b <mpinit+0xf4>
    panic("Didn't find a suitable machine");
80103d2e:	83 ec 0c             	sub    $0xc,%esp
80103d31:	68 78 87 10 80       	push   $0x80108778
80103d36:	e8 65 c8 ff ff       	call   801005a0 <panic>

  if(mp->imcrp){
80103d3b:	8b 45 dc             	mov    -0x24(%ebp),%eax
80103d3e:	0f b6 40 0c          	movzbl 0xc(%eax),%eax
80103d42:	84 c0                	test   %al,%al
80103d44:	74 30                	je     80103d76 <mpinit+0x12f>
    // Bochs doesn't support IMCR, so this doesn't run on Bochs.
    // But it would on real hardware.
    outb(0x22, 0x70);   // Select IMCR
80103d46:	83 ec 08             	sub    $0x8,%esp
80103d49:	6a 70                	push   $0x70
80103d4b:	6a 22                	push   $0x22
80103d4d:	e8 d8 fc ff ff       	call   80103a2a <outb>
80103d52:	83 c4 10             	add    $0x10,%esp
    outb(0x23, inb(0x23) | 1);  // Mask external interrupts.
80103d55:	83 ec 0c             	sub    $0xc,%esp
80103d58:	6a 23                	push   $0x23
80103d5a:	e8 ae fc ff ff       	call   80103a0d <inb>
80103d5f:	83 c4 10             	add    $0x10,%esp
80103d62:	83 c8 01             	or     $0x1,%eax
80103d65:	0f b6 c0             	movzbl %al,%eax
80103d68:	83 ec 08             	sub    $0x8,%esp
80103d6b:	50                   	push   %eax
80103d6c:	6a 23                	push   $0x23
80103d6e:	e8 b7 fc ff ff       	call   80103a2a <outb>
80103d73:	83 c4 10             	add    $0x10,%esp
  }
}
80103d76:	90                   	nop
80103d77:	c9                   	leave  
80103d78:	c3                   	ret    

80103d79 <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80103d79:	55                   	push   %ebp
80103d7a:	89 e5                	mov    %esp,%ebp
80103d7c:	83 ec 08             	sub    $0x8,%esp
80103d7f:	8b 55 08             	mov    0x8(%ebp),%edx
80103d82:	8b 45 0c             	mov    0xc(%ebp),%eax
80103d85:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80103d89:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80103d8c:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80103d90:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80103d94:	ee                   	out    %al,(%dx)
}
80103d95:	90                   	nop
80103d96:	c9                   	leave  
80103d97:	c3                   	ret    

80103d98 <picinit>:
#define IO_PIC2         0xA0    // Slave (IRQs 8-15)

// Don't use the 8259A interrupt controllers.  Xv6 assumes SMP hardware.
void
picinit(void)
{
80103d98:	55                   	push   %ebp
80103d99:	89 e5                	mov    %esp,%ebp
  // mask all interrupts
  outb(IO_PIC1+1, 0xFF);
80103d9b:	68 ff 00 00 00       	push   $0xff
80103da0:	6a 21                	push   $0x21
80103da2:	e8 d2 ff ff ff       	call   80103d79 <outb>
80103da7:	83 c4 08             	add    $0x8,%esp
  outb(IO_PIC2+1, 0xFF);
80103daa:	68 ff 00 00 00       	push   $0xff
80103daf:	68 a1 00 00 00       	push   $0xa1
80103db4:	e8 c0 ff ff ff       	call   80103d79 <outb>
80103db9:	83 c4 08             	add    $0x8,%esp
}
80103dbc:	90                   	nop
80103dbd:	c9                   	leave  
80103dbe:	c3                   	ret    

80103dbf <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
80103dbf:	55                   	push   %ebp
80103dc0:	89 e5                	mov    %esp,%ebp
80103dc2:	83 ec 18             	sub    $0x18,%esp
  struct pipe *p;

  p = 0;
80103dc5:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  *f0 = *f1 = 0;
80103dcc:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dcf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
80103dd5:	8b 45 0c             	mov    0xc(%ebp),%eax
80103dd8:	8b 10                	mov    (%eax),%edx
80103dda:	8b 45 08             	mov    0x8(%ebp),%eax
80103ddd:	89 10                	mov    %edx,(%eax)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
80103ddf:	e8 0f d2 ff ff       	call   80100ff3 <filealloc>
80103de4:	89 c2                	mov    %eax,%edx
80103de6:	8b 45 08             	mov    0x8(%ebp),%eax
80103de9:	89 10                	mov    %edx,(%eax)
80103deb:	8b 45 08             	mov    0x8(%ebp),%eax
80103dee:	8b 00                	mov    (%eax),%eax
80103df0:	85 c0                	test   %eax,%eax
80103df2:	0f 84 cb 00 00 00    	je     80103ec3 <pipealloc+0x104>
80103df8:	e8 f6 d1 ff ff       	call   80100ff3 <filealloc>
80103dfd:	89 c2                	mov    %eax,%edx
80103dff:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e02:	89 10                	mov    %edx,(%eax)
80103e04:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e07:	8b 00                	mov    (%eax),%eax
80103e09:	85 c0                	test   %eax,%eax
80103e0b:	0f 84 b2 00 00 00    	je     80103ec3 <pipealloc+0x104>
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
80103e11:	e8 7f ee ff ff       	call   80102c95 <kalloc>
80103e16:	89 45 f4             	mov    %eax,-0xc(%ebp)
80103e19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103e1d:	0f 84 9f 00 00 00    	je     80103ec2 <pipealloc+0x103>
    goto bad;
  p->readopen = 1;
80103e23:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e26:	c7 80 3c 02 00 00 01 	movl   $0x1,0x23c(%eax)
80103e2d:	00 00 00 
  p->writeopen = 1;
80103e30:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e33:	c7 80 40 02 00 00 01 	movl   $0x1,0x240(%eax)
80103e3a:	00 00 00 
  p->nwrite = 0;
80103e3d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e40:	c7 80 38 02 00 00 00 	movl   $0x0,0x238(%eax)
80103e47:	00 00 00 
  p->nread = 0;
80103e4a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e4d:	c7 80 34 02 00 00 00 	movl   $0x0,0x234(%eax)
80103e54:	00 00 00 
  initlock(&p->lock, "pipe");
80103e57:	8b 45 f4             	mov    -0xc(%ebp),%eax
80103e5a:	83 ec 08             	sub    $0x8,%esp
80103e5d:	68 ac 87 10 80       	push   $0x801087ac
80103e62:	50                   	push   %eax
80103e63:	e8 cc 10 00 00       	call   80104f34 <initlock>
80103e68:	83 c4 10             	add    $0x10,%esp
  (*f0)->type = FD_PIPE;
80103e6b:	8b 45 08             	mov    0x8(%ebp),%eax
80103e6e:	8b 00                	mov    (%eax),%eax
80103e70:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f0)->readable = 1;
80103e76:	8b 45 08             	mov    0x8(%ebp),%eax
80103e79:	8b 00                	mov    (%eax),%eax
80103e7b:	c6 40 08 01          	movb   $0x1,0x8(%eax)
  (*f0)->writable = 0;
80103e7f:	8b 45 08             	mov    0x8(%ebp),%eax
80103e82:	8b 00                	mov    (%eax),%eax
80103e84:	c6 40 09 00          	movb   $0x0,0x9(%eax)
  (*f0)->pipe = p;
80103e88:	8b 45 08             	mov    0x8(%ebp),%eax
80103e8b:	8b 00                	mov    (%eax),%eax
80103e8d:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103e90:	89 50 0c             	mov    %edx,0xc(%eax)
  (*f1)->type = FD_PIPE;
80103e93:	8b 45 0c             	mov    0xc(%ebp),%eax
80103e96:	8b 00                	mov    (%eax),%eax
80103e98:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  (*f1)->readable = 0;
80103e9e:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ea1:	8b 00                	mov    (%eax),%eax
80103ea3:	c6 40 08 00          	movb   $0x0,0x8(%eax)
  (*f1)->writable = 1;
80103ea7:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eaa:	8b 00                	mov    (%eax),%eax
80103eac:	c6 40 09 01          	movb   $0x1,0x9(%eax)
  (*f1)->pipe = p;
80103eb0:	8b 45 0c             	mov    0xc(%ebp),%eax
80103eb3:	8b 00                	mov    (%eax),%eax
80103eb5:	8b 55 f4             	mov    -0xc(%ebp),%edx
80103eb8:	89 50 0c             	mov    %edx,0xc(%eax)
  return 0;
80103ebb:	b8 00 00 00 00       	mov    $0x0,%eax
80103ec0:	eb 4e                	jmp    80103f10 <pipealloc+0x151>
  p = 0;
  *f0 = *f1 = 0;
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    goto bad;
  if((p = (struct pipe*)kalloc()) == 0)
    goto bad;
80103ec2:	90                   	nop
  (*f1)->pipe = p;
  return 0;

//PAGEBREAK: 20
 bad:
  if(p)
80103ec3:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80103ec7:	74 0e                	je     80103ed7 <pipealloc+0x118>
    kfree((char*)p);
80103ec9:	83 ec 0c             	sub    $0xc,%esp
80103ecc:	ff 75 f4             	pushl  -0xc(%ebp)
80103ecf:	e8 27 ed ff ff       	call   80102bfb <kfree>
80103ed4:	83 c4 10             	add    $0x10,%esp
  if(*f0)
80103ed7:	8b 45 08             	mov    0x8(%ebp),%eax
80103eda:	8b 00                	mov    (%eax),%eax
80103edc:	85 c0                	test   %eax,%eax
80103ede:	74 11                	je     80103ef1 <pipealloc+0x132>
    fileclose(*f0);
80103ee0:	8b 45 08             	mov    0x8(%ebp),%eax
80103ee3:	8b 00                	mov    (%eax),%eax
80103ee5:	83 ec 0c             	sub    $0xc,%esp
80103ee8:	50                   	push   %eax
80103ee9:	e8 c3 d1 ff ff       	call   801010b1 <fileclose>
80103eee:	83 c4 10             	add    $0x10,%esp
  if(*f1)
80103ef1:	8b 45 0c             	mov    0xc(%ebp),%eax
80103ef4:	8b 00                	mov    (%eax),%eax
80103ef6:	85 c0                	test   %eax,%eax
80103ef8:	74 11                	je     80103f0b <pipealloc+0x14c>
    fileclose(*f1);
80103efa:	8b 45 0c             	mov    0xc(%ebp),%eax
80103efd:	8b 00                	mov    (%eax),%eax
80103eff:	83 ec 0c             	sub    $0xc,%esp
80103f02:	50                   	push   %eax
80103f03:	e8 a9 d1 ff ff       	call   801010b1 <fileclose>
80103f08:	83 c4 10             	add    $0x10,%esp
  return -1;
80103f0b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80103f10:	c9                   	leave  
80103f11:	c3                   	ret    

80103f12 <pipeclose>:

void
pipeclose(struct pipe *p, int writable)
{
80103f12:	55                   	push   %ebp
80103f13:	89 e5                	mov    %esp,%ebp
80103f15:	83 ec 08             	sub    $0x8,%esp
  acquire(&p->lock);
80103f18:	8b 45 08             	mov    0x8(%ebp),%eax
80103f1b:	83 ec 0c             	sub    $0xc,%esp
80103f1e:	50                   	push   %eax
80103f1f:	e8 32 10 00 00       	call   80104f56 <acquire>
80103f24:	83 c4 10             	add    $0x10,%esp
  if(writable){
80103f27:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80103f2b:	74 23                	je     80103f50 <pipeclose+0x3e>
    p->writeopen = 0;
80103f2d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f30:	c7 80 40 02 00 00 00 	movl   $0x0,0x240(%eax)
80103f37:	00 00 00 
    wakeup(&p->nread);
80103f3a:	8b 45 08             	mov    0x8(%ebp),%eax
80103f3d:	05 34 02 00 00       	add    $0x234,%eax
80103f42:	83 ec 0c             	sub    $0xc,%esp
80103f45:	50                   	push   %eax
80103f46:	e8 d8 0c 00 00       	call   80104c23 <wakeup>
80103f4b:	83 c4 10             	add    $0x10,%esp
80103f4e:	eb 21                	jmp    80103f71 <pipeclose+0x5f>
  } else {
    p->readopen = 0;
80103f50:	8b 45 08             	mov    0x8(%ebp),%eax
80103f53:	c7 80 3c 02 00 00 00 	movl   $0x0,0x23c(%eax)
80103f5a:	00 00 00 
    wakeup(&p->nwrite);
80103f5d:	8b 45 08             	mov    0x8(%ebp),%eax
80103f60:	05 38 02 00 00       	add    $0x238,%eax
80103f65:	83 ec 0c             	sub    $0xc,%esp
80103f68:	50                   	push   %eax
80103f69:	e8 b5 0c 00 00       	call   80104c23 <wakeup>
80103f6e:	83 c4 10             	add    $0x10,%esp
  }
  if(p->readopen == 0 && p->writeopen == 0){
80103f71:	8b 45 08             	mov    0x8(%ebp),%eax
80103f74:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103f7a:	85 c0                	test   %eax,%eax
80103f7c:	75 2c                	jne    80103faa <pipeclose+0x98>
80103f7e:	8b 45 08             	mov    0x8(%ebp),%eax
80103f81:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
80103f87:	85 c0                	test   %eax,%eax
80103f89:	75 1f                	jne    80103faa <pipeclose+0x98>
    release(&p->lock);
80103f8b:	8b 45 08             	mov    0x8(%ebp),%eax
80103f8e:	83 ec 0c             	sub    $0xc,%esp
80103f91:	50                   	push   %eax
80103f92:	e8 2d 10 00 00       	call   80104fc4 <release>
80103f97:	83 c4 10             	add    $0x10,%esp
    kfree((char*)p);
80103f9a:	83 ec 0c             	sub    $0xc,%esp
80103f9d:	ff 75 08             	pushl  0x8(%ebp)
80103fa0:	e8 56 ec ff ff       	call   80102bfb <kfree>
80103fa5:	83 c4 10             	add    $0x10,%esp
80103fa8:	eb 0f                	jmp    80103fb9 <pipeclose+0xa7>
  } else
    release(&p->lock);
80103faa:	8b 45 08             	mov    0x8(%ebp),%eax
80103fad:	83 ec 0c             	sub    $0xc,%esp
80103fb0:	50                   	push   %eax
80103fb1:	e8 0e 10 00 00       	call   80104fc4 <release>
80103fb6:	83 c4 10             	add    $0x10,%esp
}
80103fb9:	90                   	nop
80103fba:	c9                   	leave  
80103fbb:	c3                   	ret    

80103fbc <pipewrite>:

//PAGEBREAK: 40
int
pipewrite(struct pipe *p, char *addr, int n)
{
80103fbc:	55                   	push   %ebp
80103fbd:	89 e5                	mov    %esp,%ebp
80103fbf:	83 ec 18             	sub    $0x18,%esp
  int i;

  acquire(&p->lock);
80103fc2:	8b 45 08             	mov    0x8(%ebp),%eax
80103fc5:	83 ec 0c             	sub    $0xc,%esp
80103fc8:	50                   	push   %eax
80103fc9:	e8 88 0f 00 00       	call   80104f56 <acquire>
80103fce:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < n; i++){
80103fd1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80103fd8:	e9 ac 00 00 00       	jmp    80104089 <pipewrite+0xcd>
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
      if(p->readopen == 0 || myproc()->killed){
80103fdd:	8b 45 08             	mov    0x8(%ebp),%eax
80103fe0:	8b 80 3c 02 00 00    	mov    0x23c(%eax),%eax
80103fe6:	85 c0                	test   %eax,%eax
80103fe8:	74 0c                	je     80103ff6 <pipewrite+0x3a>
80103fea:	e8 99 02 00 00       	call   80104288 <myproc>
80103fef:	8b 40 24             	mov    0x24(%eax),%eax
80103ff2:	85 c0                	test   %eax,%eax
80103ff4:	74 19                	je     8010400f <pipewrite+0x53>
        release(&p->lock);
80103ff6:	8b 45 08             	mov    0x8(%ebp),%eax
80103ff9:	83 ec 0c             	sub    $0xc,%esp
80103ffc:	50                   	push   %eax
80103ffd:	e8 c2 0f 00 00       	call   80104fc4 <release>
80104002:	83 c4 10             	add    $0x10,%esp
        return -1;
80104005:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010400a:	e9 a8 00 00 00       	jmp    801040b7 <pipewrite+0xfb>
      }
      wakeup(&p->nread);
8010400f:	8b 45 08             	mov    0x8(%ebp),%eax
80104012:	05 34 02 00 00       	add    $0x234,%eax
80104017:	83 ec 0c             	sub    $0xc,%esp
8010401a:	50                   	push   %eax
8010401b:	e8 03 0c 00 00       	call   80104c23 <wakeup>
80104020:	83 c4 10             	add    $0x10,%esp
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
80104023:	8b 45 08             	mov    0x8(%ebp),%eax
80104026:	8b 55 08             	mov    0x8(%ebp),%edx
80104029:	81 c2 38 02 00 00    	add    $0x238,%edx
8010402f:	83 ec 08             	sub    $0x8,%esp
80104032:	50                   	push   %eax
80104033:	52                   	push   %edx
80104034:	e8 04 0b 00 00       	call   80104b3d <sleep>
80104039:	83 c4 10             	add    $0x10,%esp
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
    while(p->nwrite == p->nread + PIPESIZE){  //DOC: pipewrite-full
8010403c:	8b 45 08             	mov    0x8(%ebp),%eax
8010403f:	8b 90 38 02 00 00    	mov    0x238(%eax),%edx
80104045:	8b 45 08             	mov    0x8(%ebp),%eax
80104048:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
8010404e:	05 00 02 00 00       	add    $0x200,%eax
80104053:	39 c2                	cmp    %eax,%edx
80104055:	74 86                	je     80103fdd <pipewrite+0x21>
        return -1;
      }
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
80104057:	8b 45 08             	mov    0x8(%ebp),%eax
8010405a:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104060:	8d 48 01             	lea    0x1(%eax),%ecx
80104063:	8b 55 08             	mov    0x8(%ebp),%edx
80104066:	89 8a 38 02 00 00    	mov    %ecx,0x238(%edx)
8010406c:	25 ff 01 00 00       	and    $0x1ff,%eax
80104071:	89 c1                	mov    %eax,%ecx
80104073:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104076:	8b 45 0c             	mov    0xc(%ebp),%eax
80104079:	01 d0                	add    %edx,%eax
8010407b:	0f b6 10             	movzbl (%eax),%edx
8010407e:	8b 45 08             	mov    0x8(%ebp),%eax
80104081:	88 54 08 34          	mov    %dl,0x34(%eax,%ecx,1)
pipewrite(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  for(i = 0; i < n; i++){
80104085:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104089:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010408c:	3b 45 10             	cmp    0x10(%ebp),%eax
8010408f:	7c ab                	jl     8010403c <pipewrite+0x80>
      wakeup(&p->nread);
      sleep(&p->nwrite, &p->lock);  //DOC: pipewrite-sleep
    }
    p->data[p->nwrite++ % PIPESIZE] = addr[i];
  }
  wakeup(&p->nread);  //DOC: pipewrite-wakeup1
80104091:	8b 45 08             	mov    0x8(%ebp),%eax
80104094:	05 34 02 00 00       	add    $0x234,%eax
80104099:	83 ec 0c             	sub    $0xc,%esp
8010409c:	50                   	push   %eax
8010409d:	e8 81 0b 00 00       	call   80104c23 <wakeup>
801040a2:	83 c4 10             	add    $0x10,%esp
  release(&p->lock);
801040a5:	8b 45 08             	mov    0x8(%ebp),%eax
801040a8:	83 ec 0c             	sub    $0xc,%esp
801040ab:	50                   	push   %eax
801040ac:	e8 13 0f 00 00       	call   80104fc4 <release>
801040b1:	83 c4 10             	add    $0x10,%esp
  return n;
801040b4:	8b 45 10             	mov    0x10(%ebp),%eax
}
801040b7:	c9                   	leave  
801040b8:	c3                   	ret    

801040b9 <piperead>:

int
piperead(struct pipe *p, char *addr, int n)
{
801040b9:	55                   	push   %ebp
801040ba:	89 e5                	mov    %esp,%ebp
801040bc:	53                   	push   %ebx
801040bd:	83 ec 14             	sub    $0x14,%esp
  int i;

  acquire(&p->lock);
801040c0:	8b 45 08             	mov    0x8(%ebp),%eax
801040c3:	83 ec 0c             	sub    $0xc,%esp
801040c6:	50                   	push   %eax
801040c7:	e8 8a 0e 00 00       	call   80104f56 <acquire>
801040cc:	83 c4 10             	add    $0x10,%esp
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
801040cf:	eb 3e                	jmp    8010410f <piperead+0x56>
    if(myproc()->killed){
801040d1:	e8 b2 01 00 00       	call   80104288 <myproc>
801040d6:	8b 40 24             	mov    0x24(%eax),%eax
801040d9:	85 c0                	test   %eax,%eax
801040db:	74 19                	je     801040f6 <piperead+0x3d>
      release(&p->lock);
801040dd:	8b 45 08             	mov    0x8(%ebp),%eax
801040e0:	83 ec 0c             	sub    $0xc,%esp
801040e3:	50                   	push   %eax
801040e4:	e8 db 0e 00 00       	call   80104fc4 <release>
801040e9:	83 c4 10             	add    $0x10,%esp
      return -1;
801040ec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801040f1:	e9 bf 00 00 00       	jmp    801041b5 <piperead+0xfc>
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
801040f6:	8b 45 08             	mov    0x8(%ebp),%eax
801040f9:	8b 55 08             	mov    0x8(%ebp),%edx
801040fc:	81 c2 34 02 00 00    	add    $0x234,%edx
80104102:	83 ec 08             	sub    $0x8,%esp
80104105:	50                   	push   %eax
80104106:	52                   	push   %edx
80104107:	e8 31 0a 00 00       	call   80104b3d <sleep>
8010410c:	83 c4 10             	add    $0x10,%esp
piperead(struct pipe *p, char *addr, int n)
{
  int i;

  acquire(&p->lock);
  while(p->nread == p->nwrite && p->writeopen){  //DOC: pipe-empty
8010410f:	8b 45 08             	mov    0x8(%ebp),%eax
80104112:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104118:	8b 45 08             	mov    0x8(%ebp),%eax
8010411b:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
80104121:	39 c2                	cmp    %eax,%edx
80104123:	75 0d                	jne    80104132 <piperead+0x79>
80104125:	8b 45 08             	mov    0x8(%ebp),%eax
80104128:	8b 80 40 02 00 00    	mov    0x240(%eax),%eax
8010412e:	85 c0                	test   %eax,%eax
80104130:	75 9f                	jne    801040d1 <piperead+0x18>
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104132:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104139:	eb 49                	jmp    80104184 <piperead+0xcb>
    if(p->nread == p->nwrite)
8010413b:	8b 45 08             	mov    0x8(%ebp),%eax
8010413e:	8b 90 34 02 00 00    	mov    0x234(%eax),%edx
80104144:	8b 45 08             	mov    0x8(%ebp),%eax
80104147:	8b 80 38 02 00 00    	mov    0x238(%eax),%eax
8010414d:	39 c2                	cmp    %eax,%edx
8010414f:	74 3d                	je     8010418e <piperead+0xd5>
      break;
    addr[i] = p->data[p->nread++ % PIPESIZE];
80104151:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104154:	8b 45 0c             	mov    0xc(%ebp),%eax
80104157:	8d 1c 02             	lea    (%edx,%eax,1),%ebx
8010415a:	8b 45 08             	mov    0x8(%ebp),%eax
8010415d:	8b 80 34 02 00 00    	mov    0x234(%eax),%eax
80104163:	8d 48 01             	lea    0x1(%eax),%ecx
80104166:	8b 55 08             	mov    0x8(%ebp),%edx
80104169:	89 8a 34 02 00 00    	mov    %ecx,0x234(%edx)
8010416f:	25 ff 01 00 00       	and    $0x1ff,%eax
80104174:	89 c2                	mov    %eax,%edx
80104176:	8b 45 08             	mov    0x8(%ebp),%eax
80104179:	0f b6 44 10 34       	movzbl 0x34(%eax,%edx,1),%eax
8010417e:	88 03                	mov    %al,(%ebx)
      release(&p->lock);
      return -1;
    }
    sleep(&p->nread, &p->lock); //DOC: piperead-sleep
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
80104180:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104184:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104187:	3b 45 10             	cmp    0x10(%ebp),%eax
8010418a:	7c af                	jl     8010413b <piperead+0x82>
8010418c:	eb 01                	jmp    8010418f <piperead+0xd6>
    if(p->nread == p->nwrite)
      break;
8010418e:	90                   	nop
    addr[i] = p->data[p->nread++ % PIPESIZE];
  }
  wakeup(&p->nwrite);  //DOC: piperead-wakeup
8010418f:	8b 45 08             	mov    0x8(%ebp),%eax
80104192:	05 38 02 00 00       	add    $0x238,%eax
80104197:	83 ec 0c             	sub    $0xc,%esp
8010419a:	50                   	push   %eax
8010419b:	e8 83 0a 00 00       	call   80104c23 <wakeup>
801041a0:	83 c4 10             	add    $0x10,%esp
  release(&p->lock);
801041a3:	8b 45 08             	mov    0x8(%ebp),%eax
801041a6:	83 ec 0c             	sub    $0xc,%esp
801041a9:	50                   	push   %eax
801041aa:	e8 15 0e 00 00       	call   80104fc4 <release>
801041af:	83 c4 10             	add    $0x10,%esp
  return i;
801041b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801041b5:	8b 5d fc             	mov    -0x4(%ebp),%ebx
801041b8:	c9                   	leave  
801041b9:	c3                   	ret    

801041ba <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
801041ba:	55                   	push   %ebp
801041bb:	89 e5                	mov    %esp,%ebp
801041bd:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
801041c0:	9c                   	pushf  
801041c1:	58                   	pop    %eax
801041c2:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
801041c5:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801041c8:	c9                   	leave  
801041c9:	c3                   	ret    

801041ca <sti>:
  asm volatile("cli");
}

static inline void
sti(void)
{
801041ca:	55                   	push   %ebp
801041cb:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
801041cd:	fb                   	sti    
}
801041ce:	90                   	nop
801041cf:	5d                   	pop    %ebp
801041d0:	c3                   	ret    

801041d1 <pinit>:

static void wakeup1(void *chan);

void
pinit(void)
{
801041d1:	55                   	push   %ebp
801041d2:	89 e5                	mov    %esp,%ebp
801041d4:	83 ec 08             	sub    $0x8,%esp
  initlock(&ptable.lock, "ptable");
801041d7:	83 ec 08             	sub    $0x8,%esp
801041da:	68 b4 87 10 80       	push   $0x801087b4
801041df:	68 a0 3d 11 80       	push   $0x80113da0
801041e4:	e8 4b 0d 00 00       	call   80104f34 <initlock>
801041e9:	83 c4 10             	add    $0x10,%esp
}
801041ec:	90                   	nop
801041ed:	c9                   	leave  
801041ee:	c3                   	ret    

801041ef <cpuid>:

// Must be called with interrupts disabled
int
cpuid() {
801041ef:	55                   	push   %ebp
801041f0:	89 e5                	mov    %esp,%ebp
801041f2:	83 ec 08             	sub    $0x8,%esp
  return mycpu()-cpus;
801041f5:	e8 16 00 00 00       	call   80104210 <mycpu>
801041fa:	89 c2                	mov    %eax,%edx
801041fc:	b8 00 38 11 80       	mov    $0x80113800,%eax
80104201:	29 c2                	sub    %eax,%edx
80104203:	89 d0                	mov    %edx,%eax
80104205:	c1 f8 04             	sar    $0x4,%eax
80104208:	69 c0 a3 8b 2e ba    	imul   $0xba2e8ba3,%eax,%eax
}
8010420e:	c9                   	leave  
8010420f:	c3                   	ret    

80104210 <mycpu>:

// Must be called with interrupts disabled to avoid the caller being
// rescheduled between reading lapicid and running through the loop.
struct cpu*
mycpu(void)
{
80104210:	55                   	push   %ebp
80104211:	89 e5                	mov    %esp,%ebp
80104213:	83 ec 18             	sub    $0x18,%esp
  int apicid, i;
  
  if(readeflags()&FL_IF)
80104216:	e8 9f ff ff ff       	call   801041ba <readeflags>
8010421b:	25 00 02 00 00       	and    $0x200,%eax
80104220:	85 c0                	test   %eax,%eax
80104222:	74 0d                	je     80104231 <mycpu+0x21>
    panic("mycpu called with interrupts enabled\n");
80104224:	83 ec 0c             	sub    $0xc,%esp
80104227:	68 bc 87 10 80       	push   $0x801087bc
8010422c:	e8 6f c3 ff ff       	call   801005a0 <panic>
  
  apicid = lapicid();
80104231:	e8 b5 ed ff ff       	call   80102feb <lapicid>
80104236:	89 45 f0             	mov    %eax,-0x10(%ebp)
  // APIC IDs are not guaranteed to be contiguous. Maybe we should have
  // a reverse map, or reserve a register to store &cpus[i].
  for (i = 0; i < ncpu; ++i) {
80104239:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104240:	eb 2d                	jmp    8010426f <mycpu+0x5f>
    if (cpus[i].apicid == apicid)
80104242:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104245:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
8010424b:	05 00 38 11 80       	add    $0x80113800,%eax
80104250:	0f b6 00             	movzbl (%eax),%eax
80104253:	0f b6 c0             	movzbl %al,%eax
80104256:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80104259:	75 10                	jne    8010426b <mycpu+0x5b>
      return &cpus[i];
8010425b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010425e:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
80104264:	05 00 38 11 80       	add    $0x80113800,%eax
80104269:	eb 1b                	jmp    80104286 <mycpu+0x76>
    panic("mycpu called with interrupts enabled\n");
  
  apicid = lapicid();
  // APIC IDs are not guaranteed to be contiguous. Maybe we should have
  // a reverse map, or reserve a register to store &cpus[i].
  for (i = 0; i < ncpu; ++i) {
8010426b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010426f:	a1 80 3d 11 80       	mov    0x80113d80,%eax
80104274:	39 45 f4             	cmp    %eax,-0xc(%ebp)
80104277:	7c c9                	jl     80104242 <mycpu+0x32>
    if (cpus[i].apicid == apicid)
      return &cpus[i];
  }
  panic("unknown apicid\n");
80104279:	83 ec 0c             	sub    $0xc,%esp
8010427c:	68 e2 87 10 80       	push   $0x801087e2
80104281:	e8 1a c3 ff ff       	call   801005a0 <panic>
}
80104286:	c9                   	leave  
80104287:	c3                   	ret    

80104288 <myproc>:

// Disable interrupts so that we are not rescheduled
// while reading proc from the cpu structure
struct proc*
myproc(void) {
80104288:	55                   	push   %ebp
80104289:	89 e5                	mov    %esp,%ebp
8010428b:	83 ec 18             	sub    $0x18,%esp
  struct cpu *c;
  struct proc *p;
  pushcli();
8010428e:	e8 2e 0e 00 00       	call   801050c1 <pushcli>
  c = mycpu();
80104293:	e8 78 ff ff ff       	call   80104210 <mycpu>
80104298:	89 45 f4             	mov    %eax,-0xc(%ebp)
  p = c->proc;
8010429b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010429e:	8b 80 ac 00 00 00    	mov    0xac(%eax),%eax
801042a4:	89 45 f0             	mov    %eax,-0x10(%ebp)
  popcli();
801042a7:	e8 63 0e 00 00       	call   8010510f <popcli>
  return p;
801042ac:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
801042af:	c9                   	leave  
801042b0:	c3                   	ret    

801042b1 <allocproc>:
// If found, change state to EMBRYO and initialize
// state required to run in the kernel.
// Otherwise return 0.
static struct proc*
allocproc(void)
{
801042b1:	55                   	push   %ebp
801042b2:	89 e5                	mov    %esp,%ebp
801042b4:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);
801042b7:	83 ec 0c             	sub    $0xc,%esp
801042ba:	68 a0 3d 11 80       	push   $0x80113da0
801042bf:	e8 92 0c 00 00       	call   80104f56 <acquire>
801042c4:	83 c4 10             	add    $0x10,%esp

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042c7:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
801042ce:	eb 0e                	jmp    801042de <allocproc+0x2d>
    if(p->state == UNUSED)
801042d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801042d3:	8b 40 0c             	mov    0xc(%eax),%eax
801042d6:	85 c0                	test   %eax,%eax
801042d8:	74 27                	je     80104301 <allocproc+0x50>
  struct proc *p;
  char *sp;

  acquire(&ptable.lock);

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
801042da:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801042de:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
801042e5:	72 e9                	jb     801042d0 <allocproc+0x1f>
    if(p->state == UNUSED)
      goto found;

  release(&ptable.lock);
801042e7:	83 ec 0c             	sub    $0xc,%esp
801042ea:	68 a0 3d 11 80       	push   $0x80113da0
801042ef:	e8 d0 0c 00 00       	call   80104fc4 <release>
801042f4:	83 c4 10             	add    $0x10,%esp
  return 0;
801042f7:	b8 00 00 00 00       	mov    $0x0,%eax
801042fc:	e9 b4 00 00 00       	jmp    801043b5 <allocproc+0x104>

  acquire(&ptable.lock);

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
    if(p->state == UNUSED)
      goto found;
80104301:	90                   	nop

  release(&ptable.lock);
  return 0;

found:
  p->state = EMBRYO;
80104302:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104305:	c7 40 0c 01 00 00 00 	movl   $0x1,0xc(%eax)
  p->pid = nextpid++;
8010430c:	a1 00 b0 10 80       	mov    0x8010b000,%eax
80104311:	8d 50 01             	lea    0x1(%eax),%edx
80104314:	89 15 00 b0 10 80    	mov    %edx,0x8010b000
8010431a:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010431d:	89 42 10             	mov    %eax,0x10(%edx)

  release(&ptable.lock);
80104320:	83 ec 0c             	sub    $0xc,%esp
80104323:	68 a0 3d 11 80       	push   $0x80113da0
80104328:	e8 97 0c 00 00       	call   80104fc4 <release>
8010432d:	83 c4 10             	add    $0x10,%esp

  // Allocate kernel stack.
  if((p->kstack = kalloc()) == 0){
80104330:	e8 60 e9 ff ff       	call   80102c95 <kalloc>
80104335:	89 c2                	mov    %eax,%edx
80104337:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010433a:	89 50 08             	mov    %edx,0x8(%eax)
8010433d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104340:	8b 40 08             	mov    0x8(%eax),%eax
80104343:	85 c0                	test   %eax,%eax
80104345:	75 11                	jne    80104358 <allocproc+0xa7>
    p->state = UNUSED;
80104347:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010434a:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return 0;
80104351:	b8 00 00 00 00       	mov    $0x0,%eax
80104356:	eb 5d                	jmp    801043b5 <allocproc+0x104>
  }
  sp = p->kstack + KSTACKSIZE;
80104358:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010435b:	8b 40 08             	mov    0x8(%eax),%eax
8010435e:	05 00 10 00 00       	add    $0x1000,%eax
80104363:	89 45 f0             	mov    %eax,-0x10(%ebp)

  // Leave room for trap frame.
  sp -= sizeof *p->tf;
80104366:	83 6d f0 4c          	subl   $0x4c,-0x10(%ebp)
  p->tf = (struct trapframe*)sp;
8010436a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010436d:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104370:	89 50 18             	mov    %edx,0x18(%eax)

  // Set up new context to start executing at forkret,
  // which returns to trapret.
  sp -= 4;
80104373:	83 6d f0 04          	subl   $0x4,-0x10(%ebp)
  *(uint*)sp = (uint)trapret;
80104377:	ba 4f 65 10 80       	mov    $0x8010654f,%edx
8010437c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010437f:	89 10                	mov    %edx,(%eax)

  sp -= sizeof *p->context;
80104381:	83 6d f0 14          	subl   $0x14,-0x10(%ebp)
  p->context = (struct context*)sp;
80104385:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104388:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010438b:	89 50 1c             	mov    %edx,0x1c(%eax)
  memset(p->context, 0, sizeof *p->context);
8010438e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104391:	8b 40 1c             	mov    0x1c(%eax),%eax
80104394:	83 ec 04             	sub    $0x4,%esp
80104397:	6a 14                	push   $0x14
80104399:	6a 00                	push   $0x0
8010439b:	50                   	push   %eax
8010439c:	e8 2c 0e 00 00       	call   801051cd <memset>
801043a1:	83 c4 10             	add    $0x10,%esp
  p->context->eip = (uint)forkret;
801043a4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043a7:	8b 40 1c             	mov    0x1c(%eax),%eax
801043aa:	ba f7 4a 10 80       	mov    $0x80104af7,%edx
801043af:	89 50 10             	mov    %edx,0x10(%eax)

  return p;
801043b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
801043b5:	c9                   	leave  
801043b6:	c3                   	ret    

801043b7 <userinit>:

//PAGEBREAK: 32
// Set up first user process.
void
userinit(void)
{
801043b7:	55                   	push   %ebp
801043b8:	89 e5                	mov    %esp,%ebp
801043ba:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  extern char _binary_initcode_start[], _binary_initcode_size[];

  p = allocproc();
801043bd:	e8 ef fe ff ff       	call   801042b1 <allocproc>
801043c2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  initproc = p;
801043c5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043c8:	a3 20 b6 10 80       	mov    %eax,0x8010b620
  if((p->pgdir = setupkvm()) == 0)
801043cd:	e8 6b 38 00 00       	call   80107c3d <setupkvm>
801043d2:	89 c2                	mov    %eax,%edx
801043d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043d7:	89 50 04             	mov    %edx,0x4(%eax)
801043da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043dd:	8b 40 04             	mov    0x4(%eax),%eax
801043e0:	85 c0                	test   %eax,%eax
801043e2:	75 0d                	jne    801043f1 <userinit+0x3a>
    panic("userinit: out of memory?");
801043e4:	83 ec 0c             	sub    $0xc,%esp
801043e7:	68 f2 87 10 80       	push   $0x801087f2
801043ec:	e8 af c1 ff ff       	call   801005a0 <panic>
  inituvm(p->pgdir, _binary_initcode_start, (int)_binary_initcode_size);
801043f1:	ba 2c 00 00 00       	mov    $0x2c,%edx
801043f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801043f9:	8b 40 04             	mov    0x4(%eax),%eax
801043fc:	83 ec 04             	sub    $0x4,%esp
801043ff:	52                   	push   %edx
80104400:	68 c0 b4 10 80       	push   $0x8010b4c0
80104405:	50                   	push   %eax
80104406:	e8 9a 3a 00 00       	call   80107ea5 <inituvm>
8010440b:	83 c4 10             	add    $0x10,%esp
  p->sz = PGSIZE;
8010440e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104411:	c7 00 00 10 00 00    	movl   $0x1000,(%eax)
  memset(p->tf, 0, sizeof(*p->tf));
80104417:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010441a:	8b 40 18             	mov    0x18(%eax),%eax
8010441d:	83 ec 04             	sub    $0x4,%esp
80104420:	6a 4c                	push   $0x4c
80104422:	6a 00                	push   $0x0
80104424:	50                   	push   %eax
80104425:	e8 a3 0d 00 00       	call   801051cd <memset>
8010442a:	83 c4 10             	add    $0x10,%esp
  p->tf->cs = (SEG_UCODE << 3) | DPL_USER;
8010442d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104430:	8b 40 18             	mov    0x18(%eax),%eax
80104433:	66 c7 40 3c 1b 00    	movw   $0x1b,0x3c(%eax)
  p->tf->ds = (SEG_UDATA << 3) | DPL_USER;
80104439:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010443c:	8b 40 18             	mov    0x18(%eax),%eax
8010443f:	66 c7 40 2c 23 00    	movw   $0x23,0x2c(%eax)
  p->tf->es = p->tf->ds;
80104445:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104448:	8b 40 18             	mov    0x18(%eax),%eax
8010444b:	8b 55 f4             	mov    -0xc(%ebp),%edx
8010444e:	8b 52 18             	mov    0x18(%edx),%edx
80104451:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104455:	66 89 50 28          	mov    %dx,0x28(%eax)
  p->tf->ss = p->tf->ds;
80104459:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010445c:	8b 40 18             	mov    0x18(%eax),%eax
8010445f:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104462:	8b 52 18             	mov    0x18(%edx),%edx
80104465:	0f b7 52 2c          	movzwl 0x2c(%edx),%edx
80104469:	66 89 50 48          	mov    %dx,0x48(%eax)
  p->tf->eflags = FL_IF;
8010446d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104470:	8b 40 18             	mov    0x18(%eax),%eax
80104473:	c7 40 40 00 02 00 00 	movl   $0x200,0x40(%eax)
  p->tf->esp = PGSIZE;
8010447a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010447d:	8b 40 18             	mov    0x18(%eax),%eax
80104480:	c7 40 44 00 10 00 00 	movl   $0x1000,0x44(%eax)
  p->tf->eip = 0;  // beginning of initcode.S
80104487:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010448a:	8b 40 18             	mov    0x18(%eax),%eax
8010448d:	c7 40 38 00 00 00 00 	movl   $0x0,0x38(%eax)

  safestrcpy(p->name, "initcode", sizeof(p->name));
80104494:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104497:	83 c0 6c             	add    $0x6c,%eax
8010449a:	83 ec 04             	sub    $0x4,%esp
8010449d:	6a 10                	push   $0x10
8010449f:	68 0b 88 10 80       	push   $0x8010880b
801044a4:	50                   	push   %eax
801044a5:	e8 26 0f 00 00       	call   801053d0 <safestrcpy>
801044aa:	83 c4 10             	add    $0x10,%esp
  p->cwd = namei("/");
801044ad:	83 ec 0c             	sub    $0xc,%esp
801044b0:	68 14 88 10 80       	push   $0x80108814
801044b5:	e8 96 e0 ff ff       	call   80102550 <namei>
801044ba:	83 c4 10             	add    $0x10,%esp
801044bd:	89 c2                	mov    %eax,%edx
801044bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044c2:	89 50 68             	mov    %edx,0x68(%eax)

  // this assignment to p->state lets other cores
  // run this process. the acquire forces the above
  // writes to be visible, and the lock is also needed
  // because the assignment might not be atomic.
  acquire(&ptable.lock);
801044c5:	83 ec 0c             	sub    $0xc,%esp
801044c8:	68 a0 3d 11 80       	push   $0x80113da0
801044cd:	e8 84 0a 00 00       	call   80104f56 <acquire>
801044d2:	83 c4 10             	add    $0x10,%esp

  p->state = RUNNABLE;
801044d5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801044d8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
801044df:	83 ec 0c             	sub    $0xc,%esp
801044e2:	68 a0 3d 11 80       	push   $0x80113da0
801044e7:	e8 d8 0a 00 00       	call   80104fc4 <release>
801044ec:	83 c4 10             	add    $0x10,%esp
}
801044ef:	90                   	nop
801044f0:	c9                   	leave  
801044f1:	c3                   	ret    

801044f2 <growproc>:

// Grow current process's memory by n bytes.
// Return 0 on success, -1 on failure.
int
growproc(int n)
{
801044f2:	55                   	push   %ebp
801044f3:	89 e5                	mov    %esp,%ebp
801044f5:	83 ec 18             	sub    $0x18,%esp
  uint sz;
  struct proc *curproc = myproc();
801044f8:	e8 8b fd ff ff       	call   80104288 <myproc>
801044fd:	89 45 f0             	mov    %eax,-0x10(%ebp)

  sz = curproc->sz;
80104500:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104503:	8b 00                	mov    (%eax),%eax
80104505:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(n > 0){
80104508:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
8010450c:	7e 2e                	jle    8010453c <growproc+0x4a>
    if((sz = allocuvm(curproc->pgdir, sz, sz + n)) == 0)
8010450e:	8b 55 08             	mov    0x8(%ebp),%edx
80104511:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104514:	01 c2                	add    %eax,%edx
80104516:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104519:	8b 40 04             	mov    0x4(%eax),%eax
8010451c:	83 ec 04             	sub    $0x4,%esp
8010451f:	52                   	push   %edx
80104520:	ff 75 f4             	pushl  -0xc(%ebp)
80104523:	50                   	push   %eax
80104524:	e8 b9 3a 00 00       	call   80107fe2 <allocuvm>
80104529:	83 c4 10             	add    $0x10,%esp
8010452c:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010452f:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104533:	75 3b                	jne    80104570 <growproc+0x7e>
      return -1;
80104535:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010453a:	eb 4f                	jmp    8010458b <growproc+0x99>
  } else if(n < 0){
8010453c:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80104540:	79 2e                	jns    80104570 <growproc+0x7e>
    if((sz = deallocuvm(curproc->pgdir, sz, sz + n)) == 0)
80104542:	8b 55 08             	mov    0x8(%ebp),%edx
80104545:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104548:	01 c2                	add    %eax,%edx
8010454a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010454d:	8b 40 04             	mov    0x4(%eax),%eax
80104550:	83 ec 04             	sub    $0x4,%esp
80104553:	52                   	push   %edx
80104554:	ff 75 f4             	pushl  -0xc(%ebp)
80104557:	50                   	push   %eax
80104558:	e8 8a 3b 00 00       	call   801080e7 <deallocuvm>
8010455d:	83 c4 10             	add    $0x10,%esp
80104560:	89 45 f4             	mov    %eax,-0xc(%ebp)
80104563:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104567:	75 07                	jne    80104570 <growproc+0x7e>
      return -1;
80104569:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010456e:	eb 1b                	jmp    8010458b <growproc+0x99>
  }
  curproc->sz = sz;
80104570:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104573:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104576:	89 10                	mov    %edx,(%eax)
  switchuvm(curproc);
80104578:	83 ec 0c             	sub    $0xc,%esp
8010457b:	ff 75 f0             	pushl  -0x10(%ebp)
8010457e:	e8 84 37 00 00       	call   80107d07 <switchuvm>
80104583:	83 c4 10             	add    $0x10,%esp
  return 0;
80104586:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010458b:	c9                   	leave  
8010458c:	c3                   	ret    

8010458d <fork>:
// Create a new process copying p as the parent.
// Sets up stack to return as if from system call.
// Caller must set state of returned proc to RUNNABLE.
int
fork(void)
{
8010458d:	55                   	push   %ebp
8010458e:	89 e5                	mov    %esp,%ebp
80104590:	57                   	push   %edi
80104591:	56                   	push   %esi
80104592:	53                   	push   %ebx
80104593:	83 ec 1c             	sub    $0x1c,%esp
  int i, pid;
  struct proc *np;
  struct proc *curproc = myproc();
80104596:	e8 ed fc ff ff       	call   80104288 <myproc>
8010459b:	89 45 e0             	mov    %eax,-0x20(%ebp)

  // Allocate process.
  if((np = allocproc()) == 0){
8010459e:	e8 0e fd ff ff       	call   801042b1 <allocproc>
801045a3:	89 45 dc             	mov    %eax,-0x24(%ebp)
801045a6:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
801045aa:	75 0a                	jne    801045b6 <fork+0x29>
    return -1;
801045ac:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801045b1:	e9 4c 01 00 00       	jmp    80104702 <fork+0x175>
  }

  // Copy process state from proc.
  if((np->pgdir = copyuvm(curproc->pgdir, curproc->sz)) == 0){
801045b6:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045b9:	8b 10                	mov    (%eax),%edx
801045bb:	8b 45 e0             	mov    -0x20(%ebp),%eax
801045be:	8b 40 04             	mov    0x4(%eax),%eax
801045c1:	83 ec 08             	sub    $0x8,%esp
801045c4:	52                   	push   %edx
801045c5:	50                   	push   %eax
801045c6:	e8 ba 3c 00 00       	call   80108285 <copyuvm>
801045cb:	83 c4 10             	add    $0x10,%esp
801045ce:	89 c2                	mov    %eax,%edx
801045d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045d3:	89 50 04             	mov    %edx,0x4(%eax)
801045d6:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045d9:	8b 40 04             	mov    0x4(%eax),%eax
801045dc:	85 c0                	test   %eax,%eax
801045de:	75 30                	jne    80104610 <fork+0x83>
    kfree(np->kstack);
801045e0:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045e3:	8b 40 08             	mov    0x8(%eax),%eax
801045e6:	83 ec 0c             	sub    $0xc,%esp
801045e9:	50                   	push   %eax
801045ea:	e8 0c e6 ff ff       	call   80102bfb <kfree>
801045ef:	83 c4 10             	add    $0x10,%esp
    np->kstack = 0;
801045f2:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045f5:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
    np->state = UNUSED;
801045fc:	8b 45 dc             	mov    -0x24(%ebp),%eax
801045ff:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
    return -1;
80104606:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010460b:	e9 f2 00 00 00       	jmp    80104702 <fork+0x175>
  }
  np->sz = curproc->sz;
80104610:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104613:	8b 10                	mov    (%eax),%edx
80104615:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104618:	89 10                	mov    %edx,(%eax)
  np->parent = curproc;
8010461a:	8b 45 dc             	mov    -0x24(%ebp),%eax
8010461d:	8b 55 e0             	mov    -0x20(%ebp),%edx
80104620:	89 50 14             	mov    %edx,0x14(%eax)
  *np->tf = *curproc->tf;
80104623:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104626:	8b 50 18             	mov    0x18(%eax),%edx
80104629:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010462c:	8b 40 18             	mov    0x18(%eax),%eax
8010462f:	89 c3                	mov    %eax,%ebx
80104631:	b8 13 00 00 00       	mov    $0x13,%eax
80104636:	89 d7                	mov    %edx,%edi
80104638:	89 de                	mov    %ebx,%esi
8010463a:	89 c1                	mov    %eax,%ecx
8010463c:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;
8010463e:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104641:	8b 40 18             	mov    0x18(%eax),%eax
80104644:	c7 40 1c 00 00 00 00 	movl   $0x0,0x1c(%eax)

  for(i = 0; i < NOFILE; i++)
8010464b:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
80104652:	eb 3d                	jmp    80104691 <fork+0x104>
    if(curproc->ofile[i])
80104654:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104657:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010465a:	83 c2 08             	add    $0x8,%edx
8010465d:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104661:	85 c0                	test   %eax,%eax
80104663:	74 28                	je     8010468d <fork+0x100>
      np->ofile[i] = filedup(curproc->ofile[i]);
80104665:	8b 45 e0             	mov    -0x20(%ebp),%eax
80104668:	8b 55 e4             	mov    -0x1c(%ebp),%edx
8010466b:	83 c2 08             	add    $0x8,%edx
8010466e:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104672:	83 ec 0c             	sub    $0xc,%esp
80104675:	50                   	push   %eax
80104676:	e8 e5 c9 ff ff       	call   80101060 <filedup>
8010467b:	83 c4 10             	add    $0x10,%esp
8010467e:	89 c1                	mov    %eax,%ecx
80104680:	8b 45 dc             	mov    -0x24(%ebp),%eax
80104683:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80104686:	83 c2 08             	add    $0x8,%edx
80104689:	89 4c 90 08          	mov    %ecx,0x8(%eax,%edx,4)
  *np->tf = *curproc->tf;

  // Clear %eax so that fork returns 0 in the child.
  np->tf->eax = 0;

  for(i = 0; i < NOFILE; i++)
8010468d:	83 45 e4 01          	addl   $0x1,-0x1c(%ebp)
80104691:	83 7d e4 0f          	cmpl   $0xf,-0x1c(%ebp)
80104695:	7e bd                	jle    80104654 <fork+0xc7>
    if(curproc->ofile[i])
      np->ofile[i] = filedup(curproc->ofile[i]);
  np->cwd = idup(curproc->cwd);
80104697:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010469a:	8b 40 68             	mov    0x68(%eax),%eax
8010469d:	83 ec 0c             	sub    $0xc,%esp
801046a0:	50                   	push   %eax
801046a1:	e8 30 d3 ff ff       	call   801019d6 <idup>
801046a6:	83 c4 10             	add    $0x10,%esp
801046a9:	89 c2                	mov    %eax,%edx
801046ab:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046ae:	89 50 68             	mov    %edx,0x68(%eax)

  safestrcpy(np->name, curproc->name, sizeof(curproc->name));
801046b1:	8b 45 e0             	mov    -0x20(%ebp),%eax
801046b4:	8d 50 6c             	lea    0x6c(%eax),%edx
801046b7:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046ba:	83 c0 6c             	add    $0x6c,%eax
801046bd:	83 ec 04             	sub    $0x4,%esp
801046c0:	6a 10                	push   $0x10
801046c2:	52                   	push   %edx
801046c3:	50                   	push   %eax
801046c4:	e8 07 0d 00 00       	call   801053d0 <safestrcpy>
801046c9:	83 c4 10             	add    $0x10,%esp

  pid = np->pid;
801046cc:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046cf:	8b 40 10             	mov    0x10(%eax),%eax
801046d2:	89 45 d8             	mov    %eax,-0x28(%ebp)

  acquire(&ptable.lock);
801046d5:	83 ec 0c             	sub    $0xc,%esp
801046d8:	68 a0 3d 11 80       	push   $0x80113da0
801046dd:	e8 74 08 00 00       	call   80104f56 <acquire>
801046e2:	83 c4 10             	add    $0x10,%esp

  np->state = RUNNABLE;
801046e5:	8b 45 dc             	mov    -0x24(%ebp),%eax
801046e8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)

  release(&ptable.lock);
801046ef:	83 ec 0c             	sub    $0xc,%esp
801046f2:	68 a0 3d 11 80       	push   $0x80113da0
801046f7:	e8 c8 08 00 00       	call   80104fc4 <release>
801046fc:	83 c4 10             	add    $0x10,%esp

  return pid;
801046ff:	8b 45 d8             	mov    -0x28(%ebp),%eax
}
80104702:	8d 65 f4             	lea    -0xc(%ebp),%esp
80104705:	5b                   	pop    %ebx
80104706:	5e                   	pop    %esi
80104707:	5f                   	pop    %edi
80104708:	5d                   	pop    %ebp
80104709:	c3                   	ret    

8010470a <exit>:
// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait() to find out it exited.
void
exit(void)
{
8010470a:	55                   	push   %ebp
8010470b:	89 e5                	mov    %esp,%ebp
8010470d:	83 ec 18             	sub    $0x18,%esp
  struct proc *curproc = myproc();
80104710:	e8 73 fb ff ff       	call   80104288 <myproc>
80104715:	89 45 ec             	mov    %eax,-0x14(%ebp)
  struct proc *p;
  int fd;

  if(curproc == initproc)
80104718:	a1 20 b6 10 80       	mov    0x8010b620,%eax
8010471d:	39 45 ec             	cmp    %eax,-0x14(%ebp)
80104720:	75 0d                	jne    8010472f <exit+0x25>
    panic("init exiting");
80104722:	83 ec 0c             	sub    $0xc,%esp
80104725:	68 16 88 10 80       	push   $0x80108816
8010472a:	e8 71 be ff ff       	call   801005a0 <panic>

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
8010472f:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
80104736:	eb 3f                	jmp    80104777 <exit+0x6d>
    if(curproc->ofile[fd]){
80104738:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010473b:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010473e:	83 c2 08             	add    $0x8,%edx
80104741:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104745:	85 c0                	test   %eax,%eax
80104747:	74 2a                	je     80104773 <exit+0x69>
      fileclose(curproc->ofile[fd]);
80104749:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010474c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010474f:	83 c2 08             	add    $0x8,%edx
80104752:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
80104756:	83 ec 0c             	sub    $0xc,%esp
80104759:	50                   	push   %eax
8010475a:	e8 52 c9 ff ff       	call   801010b1 <fileclose>
8010475f:	83 c4 10             	add    $0x10,%esp
      curproc->ofile[fd] = 0;
80104762:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104765:	8b 55 f0             	mov    -0x10(%ebp),%edx
80104768:	83 c2 08             	add    $0x8,%edx
8010476b:	c7 44 90 08 00 00 00 	movl   $0x0,0x8(%eax,%edx,4)
80104772:	00 

  if(curproc == initproc)
    panic("init exiting");

  // Close all open files.
  for(fd = 0; fd < NOFILE; fd++){
80104773:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
80104777:	83 7d f0 0f          	cmpl   $0xf,-0x10(%ebp)
8010477b:	7e bb                	jle    80104738 <exit+0x2e>
      fileclose(curproc->ofile[fd]);
      curproc->ofile[fd] = 0;
    }
  }

  begin_op();
8010477d:	e8 b3 ed ff ff       	call   80103535 <begin_op>
  iput(curproc->cwd);
80104782:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104785:	8b 40 68             	mov    0x68(%eax),%eax
80104788:	83 ec 0c             	sub    $0xc,%esp
8010478b:	50                   	push   %eax
8010478c:	e8 e0 d3 ff ff       	call   80101b71 <iput>
80104791:	83 c4 10             	add    $0x10,%esp
  end_op();
80104794:	e8 28 ee ff ff       	call   801035c1 <end_op>
  curproc->cwd = 0;
80104799:	8b 45 ec             	mov    -0x14(%ebp),%eax
8010479c:	c7 40 68 00 00 00 00 	movl   $0x0,0x68(%eax)

  acquire(&ptable.lock);
801047a3:	83 ec 0c             	sub    $0xc,%esp
801047a6:	68 a0 3d 11 80       	push   $0x80113da0
801047ab:	e8 a6 07 00 00       	call   80104f56 <acquire>
801047b0:	83 c4 10             	add    $0x10,%esp

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);
801047b3:	8b 45 ec             	mov    -0x14(%ebp),%eax
801047b6:	8b 40 14             	mov    0x14(%eax),%eax
801047b9:	83 ec 0c             	sub    $0xc,%esp
801047bc:	50                   	push   %eax
801047bd:	e8 22 04 00 00       	call   80104be4 <wakeup1>
801047c2:	83 c4 10             	add    $0x10,%esp

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801047c5:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
801047cc:	eb 37                	jmp    80104805 <exit+0xfb>
    if(p->parent == curproc){
801047ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047d1:	8b 40 14             	mov    0x14(%eax),%eax
801047d4:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801047d7:	75 28                	jne    80104801 <exit+0xf7>
      p->parent = initproc;
801047d9:	8b 15 20 b6 10 80    	mov    0x8010b620,%edx
801047df:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047e2:	89 50 14             	mov    %edx,0x14(%eax)
      if(p->state == ZOMBIE)
801047e5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801047e8:	8b 40 0c             	mov    0xc(%eax),%eax
801047eb:	83 f8 05             	cmp    $0x5,%eax
801047ee:	75 11                	jne    80104801 <exit+0xf7>
        wakeup1(initproc);
801047f0:	a1 20 b6 10 80       	mov    0x8010b620,%eax
801047f5:	83 ec 0c             	sub    $0xc,%esp
801047f8:	50                   	push   %eax
801047f9:	e8 e6 03 00 00       	call   80104be4 <wakeup1>
801047fe:	83 c4 10             	add    $0x10,%esp

  // Parent might be sleeping in wait().
  wakeup1(curproc->parent);

  // Pass abandoned children to init.
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104801:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104805:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
8010480c:	72 c0                	jb     801047ce <exit+0xc4>
        wakeup1(initproc);
    }
  }

  // Jump into the scheduler, never to return.
  curproc->state = ZOMBIE;
8010480e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104811:	c7 40 0c 05 00 00 00 	movl   $0x5,0xc(%eax)
  sched();
80104818:	e8 e5 01 00 00       	call   80104a02 <sched>
  panic("zombie exit");
8010481d:	83 ec 0c             	sub    $0xc,%esp
80104820:	68 23 88 10 80       	push   $0x80108823
80104825:	e8 76 bd ff ff       	call   801005a0 <panic>

8010482a <wait>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int
wait(void)
{
8010482a:	55                   	push   %ebp
8010482b:	89 e5                	mov    %esp,%ebp
8010482d:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  int havekids, pid;
  struct proc *curproc = myproc();
80104830:	e8 53 fa ff ff       	call   80104288 <myproc>
80104835:	89 45 ec             	mov    %eax,-0x14(%ebp)
  
  acquire(&ptable.lock);
80104838:	83 ec 0c             	sub    $0xc,%esp
8010483b:	68 a0 3d 11 80       	push   $0x80113da0
80104840:	e8 11 07 00 00       	call   80104f56 <acquire>
80104845:	83 c4 10             	add    $0x10,%esp
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
80104848:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010484f:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104856:	e9 a1 00 00 00       	jmp    801048fc <wait+0xd2>
      if(p->parent != curproc)
8010485b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010485e:	8b 40 14             	mov    0x14(%eax),%eax
80104861:	3b 45 ec             	cmp    -0x14(%ebp),%eax
80104864:	0f 85 8d 00 00 00    	jne    801048f7 <wait+0xcd>
        continue;
      havekids = 1;
8010486a:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
      if(p->state == ZOMBIE){
80104871:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104874:	8b 40 0c             	mov    0xc(%eax),%eax
80104877:	83 f8 05             	cmp    $0x5,%eax
8010487a:	75 7c                	jne    801048f8 <wait+0xce>
        // Found one.
        pid = p->pid;
8010487c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010487f:	8b 40 10             	mov    0x10(%eax),%eax
80104882:	89 45 e8             	mov    %eax,-0x18(%ebp)
        kfree(p->kstack);
80104885:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104888:	8b 40 08             	mov    0x8(%eax),%eax
8010488b:	83 ec 0c             	sub    $0xc,%esp
8010488e:	50                   	push   %eax
8010488f:	e8 67 e3 ff ff       	call   80102bfb <kfree>
80104894:	83 c4 10             	add    $0x10,%esp
        p->kstack = 0;
80104897:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010489a:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
        freevm(p->pgdir);
801048a1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048a4:	8b 40 04             	mov    0x4(%eax),%eax
801048a7:	83 ec 0c             	sub    $0xc,%esp
801048aa:	50                   	push   %eax
801048ab:	e8 fb 38 00 00       	call   801081ab <freevm>
801048b0:	83 c4 10             	add    $0x10,%esp
        p->pid = 0;
801048b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048b6:	c7 40 10 00 00 00 00 	movl   $0x0,0x10(%eax)
        p->parent = 0;
801048bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048c0:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
        p->name[0] = 0;
801048c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048ca:	c6 40 6c 00          	movb   $0x0,0x6c(%eax)
        p->killed = 0;
801048ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048d1:	c7 40 24 00 00 00 00 	movl   $0x0,0x24(%eax)
        p->state = UNUSED;
801048d8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801048db:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
        release(&ptable.lock);
801048e2:	83 ec 0c             	sub    $0xc,%esp
801048e5:	68 a0 3d 11 80       	push   $0x80113da0
801048ea:	e8 d5 06 00 00       	call   80104fc4 <release>
801048ef:	83 c4 10             	add    $0x10,%esp
        return pid;
801048f2:	8b 45 e8             	mov    -0x18(%ebp),%eax
801048f5:	eb 51                	jmp    80104948 <wait+0x11e>
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->parent != curproc)
        continue;
801048f7:	90                   	nop
  
  acquire(&ptable.lock);
  for(;;){
    // Scan through table looking for exited children.
    havekids = 0;
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801048f8:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801048fc:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104903:	0f 82 52 ff ff ff    	jb     8010485b <wait+0x31>
        return pid;
      }
    }

    // No point waiting if we don't have any children.
    if(!havekids || curproc->killed){
80104909:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010490d:	74 0a                	je     80104919 <wait+0xef>
8010490f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80104912:	8b 40 24             	mov    0x24(%eax),%eax
80104915:	85 c0                	test   %eax,%eax
80104917:	74 17                	je     80104930 <wait+0x106>
      release(&ptable.lock);
80104919:	83 ec 0c             	sub    $0xc,%esp
8010491c:	68 a0 3d 11 80       	push   $0x80113da0
80104921:	e8 9e 06 00 00       	call   80104fc4 <release>
80104926:	83 c4 10             	add    $0x10,%esp
      return -1;
80104929:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010492e:	eb 18                	jmp    80104948 <wait+0x11e>
    }

    // Wait for children to exit.  (See wakeup1 call in proc_exit.)
    sleep(curproc, &ptable.lock);  //DOC: wait-sleep
80104930:	83 ec 08             	sub    $0x8,%esp
80104933:	68 a0 3d 11 80       	push   $0x80113da0
80104938:	ff 75 ec             	pushl  -0x14(%ebp)
8010493b:	e8 fd 01 00 00       	call   80104b3d <sleep>
80104940:	83 c4 10             	add    $0x10,%esp
  }
80104943:	e9 00 ff ff ff       	jmp    80104848 <wait+0x1e>
}
80104948:	c9                   	leave  
80104949:	c3                   	ret    

8010494a <scheduler>:
//  - swtch to start running that process
//  - eventually that process transfers control
//      via swtch back to the scheduler.
void
scheduler(void)
{
8010494a:	55                   	push   %ebp
8010494b:	89 e5                	mov    %esp,%ebp
8010494d:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;
  struct cpu *c = mycpu();
80104950:	e8 bb f8 ff ff       	call   80104210 <mycpu>
80104955:	89 45 f0             	mov    %eax,-0x10(%ebp)
  c->proc = 0;
80104958:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010495b:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
80104962:	00 00 00 
  
  for(;;){
    // Enable interrupts on this processor.
    sti();
80104965:	e8 60 f8 ff ff       	call   801041ca <sti>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
8010496a:	83 ec 0c             	sub    $0xc,%esp
8010496d:	68 a0 3d 11 80       	push   $0x80113da0
80104972:	e8 df 05 00 00       	call   80104f56 <acquire>
80104977:	83 c4 10             	add    $0x10,%esp
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
8010497a:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104981:	eb 61                	jmp    801049e4 <scheduler+0x9a>
      if(p->state != RUNNABLE)
80104983:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104986:	8b 40 0c             	mov    0xc(%eax),%eax
80104989:	83 f8 03             	cmp    $0x3,%eax
8010498c:	75 51                	jne    801049df <scheduler+0x95>
        continue;

      // Switch to chosen process.  It is the process's job
      // to release ptable.lock and then reacquire it
      // before jumping back to us.
      c->proc = p;
8010498e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104991:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104994:	89 90 ac 00 00 00    	mov    %edx,0xac(%eax)
      switchuvm(p);
8010499a:	83 ec 0c             	sub    $0xc,%esp
8010499d:	ff 75 f4             	pushl  -0xc(%ebp)
801049a0:	e8 62 33 00 00       	call   80107d07 <switchuvm>
801049a5:	83 c4 10             	add    $0x10,%esp
      p->state = RUNNING;
801049a8:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049ab:	c7 40 0c 04 00 00 00 	movl   $0x4,0xc(%eax)

      swtch(&(c->scheduler), p->context);
801049b2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801049b5:	8b 40 1c             	mov    0x1c(%eax),%eax
801049b8:	8b 55 f0             	mov    -0x10(%ebp),%edx
801049bb:	83 c2 04             	add    $0x4,%edx
801049be:	83 ec 08             	sub    $0x8,%esp
801049c1:	50                   	push   %eax
801049c2:	52                   	push   %edx
801049c3:	e8 79 0a 00 00       	call   80105441 <swtch>
801049c8:	83 c4 10             	add    $0x10,%esp
      switchkvm();
801049cb:	e8 1e 33 00 00       	call   80107cee <switchkvm>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
801049d0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801049d3:	c7 80 ac 00 00 00 00 	movl   $0x0,0xac(%eax)
801049da:	00 00 00 
801049dd:	eb 01                	jmp    801049e0 <scheduler+0x96>

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
      if(p->state != RUNNABLE)
        continue;
801049df:	90                   	nop
    // Enable interrupts on this processor.
    sti();

    // Loop over process table looking for process to run.
    acquire(&ptable.lock);
    for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
801049e0:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
801049e4:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
801049eb:	72 96                	jb     80104983 <scheduler+0x39>

      // Process is done running for now.
      // It should have changed its p->state before coming back.
      c->proc = 0;
    }
    release(&ptable.lock);
801049ed:	83 ec 0c             	sub    $0xc,%esp
801049f0:	68 a0 3d 11 80       	push   $0x80113da0
801049f5:	e8 ca 05 00 00       	call   80104fc4 <release>
801049fa:	83 c4 10             	add    $0x10,%esp

  }
801049fd:	e9 63 ff ff ff       	jmp    80104965 <scheduler+0x1b>

80104a02 <sched>:
// be proc->intena and proc->ncli, but that would
// break in the few places where a lock is held but
// there's no process.
void
sched(void)
{
80104a02:	55                   	push   %ebp
80104a03:	89 e5                	mov    %esp,%ebp
80104a05:	83 ec 18             	sub    $0x18,%esp
  int intena;
  struct proc *p = myproc();
80104a08:	e8 7b f8 ff ff       	call   80104288 <myproc>
80104a0d:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(!holding(&ptable.lock))
80104a10:	83 ec 0c             	sub    $0xc,%esp
80104a13:	68 a0 3d 11 80       	push   $0x80113da0
80104a18:	e8 73 06 00 00       	call   80105090 <holding>
80104a1d:	83 c4 10             	add    $0x10,%esp
80104a20:	85 c0                	test   %eax,%eax
80104a22:	75 0d                	jne    80104a31 <sched+0x2f>
    panic("sched ptable.lock");
80104a24:	83 ec 0c             	sub    $0xc,%esp
80104a27:	68 2f 88 10 80       	push   $0x8010882f
80104a2c:	e8 6f bb ff ff       	call   801005a0 <panic>
  if(mycpu()->ncli != 1)
80104a31:	e8 da f7 ff ff       	call   80104210 <mycpu>
80104a36:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
80104a3c:	83 f8 01             	cmp    $0x1,%eax
80104a3f:	74 0d                	je     80104a4e <sched+0x4c>
    panic("sched locks");
80104a41:	83 ec 0c             	sub    $0xc,%esp
80104a44:	68 41 88 10 80       	push   $0x80108841
80104a49:	e8 52 bb ff ff       	call   801005a0 <panic>
  if(p->state == RUNNING)
80104a4e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104a51:	8b 40 0c             	mov    0xc(%eax),%eax
80104a54:	83 f8 04             	cmp    $0x4,%eax
80104a57:	75 0d                	jne    80104a66 <sched+0x64>
    panic("sched running");
80104a59:	83 ec 0c             	sub    $0xc,%esp
80104a5c:	68 4d 88 10 80       	push   $0x8010884d
80104a61:	e8 3a bb ff ff       	call   801005a0 <panic>
  if(readeflags()&FL_IF)
80104a66:	e8 4f f7 ff ff       	call   801041ba <readeflags>
80104a6b:	25 00 02 00 00       	and    $0x200,%eax
80104a70:	85 c0                	test   %eax,%eax
80104a72:	74 0d                	je     80104a81 <sched+0x7f>
    panic("sched interruptible");
80104a74:	83 ec 0c             	sub    $0xc,%esp
80104a77:	68 5b 88 10 80       	push   $0x8010885b
80104a7c:	e8 1f bb ff ff       	call   801005a0 <panic>
  intena = mycpu()->intena;
80104a81:	e8 8a f7 ff ff       	call   80104210 <mycpu>
80104a86:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80104a8c:	89 45 f0             	mov    %eax,-0x10(%ebp)
  swtch(&p->context, mycpu()->scheduler);
80104a8f:	e8 7c f7 ff ff       	call   80104210 <mycpu>
80104a94:	8b 40 04             	mov    0x4(%eax),%eax
80104a97:	8b 55 f4             	mov    -0xc(%ebp),%edx
80104a9a:	83 c2 1c             	add    $0x1c,%edx
80104a9d:	83 ec 08             	sub    $0x8,%esp
80104aa0:	50                   	push   %eax
80104aa1:	52                   	push   %edx
80104aa2:	e8 9a 09 00 00       	call   80105441 <swtch>
80104aa7:	83 c4 10             	add    $0x10,%esp
  mycpu()->intena = intena;
80104aaa:	e8 61 f7 ff ff       	call   80104210 <mycpu>
80104aaf:	89 c2                	mov    %eax,%edx
80104ab1:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104ab4:	89 82 a8 00 00 00    	mov    %eax,0xa8(%edx)
}
80104aba:	90                   	nop
80104abb:	c9                   	leave  
80104abc:	c3                   	ret    

80104abd <yield>:

// Give up the CPU for one scheduling round.
void
yield(void)
{
80104abd:	55                   	push   %ebp
80104abe:	89 e5                	mov    %esp,%ebp
80104ac0:	83 ec 08             	sub    $0x8,%esp
  acquire(&ptable.lock);  //DOC: yieldlock
80104ac3:	83 ec 0c             	sub    $0xc,%esp
80104ac6:	68 a0 3d 11 80       	push   $0x80113da0
80104acb:	e8 86 04 00 00       	call   80104f56 <acquire>
80104ad0:	83 c4 10             	add    $0x10,%esp
  myproc()->state = RUNNABLE;
80104ad3:	e8 b0 f7 ff ff       	call   80104288 <myproc>
80104ad8:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
  sched();
80104adf:	e8 1e ff ff ff       	call   80104a02 <sched>
  release(&ptable.lock);
80104ae4:	83 ec 0c             	sub    $0xc,%esp
80104ae7:	68 a0 3d 11 80       	push   $0x80113da0
80104aec:	e8 d3 04 00 00       	call   80104fc4 <release>
80104af1:	83 c4 10             	add    $0x10,%esp
}
80104af4:	90                   	nop
80104af5:	c9                   	leave  
80104af6:	c3                   	ret    

80104af7 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch here.  "Return" to user space.
void
forkret(void)
{
80104af7:	55                   	push   %ebp
80104af8:	89 e5                	mov    %esp,%ebp
80104afa:	83 ec 08             	sub    $0x8,%esp
  static int first = 1;
  // Still holding ptable.lock from scheduler.
  release(&ptable.lock);
80104afd:	83 ec 0c             	sub    $0xc,%esp
80104b00:	68 a0 3d 11 80       	push   $0x80113da0
80104b05:	e8 ba 04 00 00       	call   80104fc4 <release>
80104b0a:	83 c4 10             	add    $0x10,%esp

  if (first) {
80104b0d:	a1 04 b0 10 80       	mov    0x8010b004,%eax
80104b12:	85 c0                	test   %eax,%eax
80104b14:	74 24                	je     80104b3a <forkret+0x43>
    // Some initialization functions must be run in the context
    // of a regular process (e.g., they call sleep), and thus cannot
    // be run from main().
    first = 0;
80104b16:	c7 05 04 b0 10 80 00 	movl   $0x0,0x8010b004
80104b1d:	00 00 00 
    iinit(ROOTDEV);
80104b20:	83 ec 0c             	sub    $0xc,%esp
80104b23:	6a 01                	push   $0x1
80104b25:	e8 74 cb ff ff       	call   8010169e <iinit>
80104b2a:	83 c4 10             	add    $0x10,%esp
    initlog(ROOTDEV);
80104b2d:	83 ec 0c             	sub    $0xc,%esp
80104b30:	6a 01                	push   $0x1
80104b32:	e8 e0 e7 ff ff       	call   80103317 <initlog>
80104b37:	83 c4 10             	add    $0x10,%esp
  }

  // Return to "caller", actually trapret (see allocproc).
}
80104b3a:	90                   	nop
80104b3b:	c9                   	leave  
80104b3c:	c3                   	ret    

80104b3d <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
80104b3d:	55                   	push   %ebp
80104b3e:	89 e5                	mov    %esp,%ebp
80104b40:	83 ec 18             	sub    $0x18,%esp
  struct proc *p = myproc();
80104b43:	e8 40 f7 ff ff       	call   80104288 <myproc>
80104b48:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  if(p == 0)
80104b4b:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80104b4f:	75 0d                	jne    80104b5e <sleep+0x21>
    panic("sleep");
80104b51:	83 ec 0c             	sub    $0xc,%esp
80104b54:	68 6f 88 10 80       	push   $0x8010886f
80104b59:	e8 42 ba ff ff       	call   801005a0 <panic>

  if(lk == 0)
80104b5e:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
80104b62:	75 0d                	jne    80104b71 <sleep+0x34>
    panic("sleep without lk");
80104b64:	83 ec 0c             	sub    $0xc,%esp
80104b67:	68 75 88 10 80       	push   $0x80108875
80104b6c:	e8 2f ba ff ff       	call   801005a0 <panic>
  // change p->state and then call sched.
  // Once we hold ptable.lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup runs with ptable.lock locked),
  // so it's okay to release lk.
  if(lk != &ptable.lock){  //DOC: sleeplock0
80104b71:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104b78:	74 1e                	je     80104b98 <sleep+0x5b>
    acquire(&ptable.lock);  //DOC: sleeplock1
80104b7a:	83 ec 0c             	sub    $0xc,%esp
80104b7d:	68 a0 3d 11 80       	push   $0x80113da0
80104b82:	e8 cf 03 00 00       	call   80104f56 <acquire>
80104b87:	83 c4 10             	add    $0x10,%esp
    release(lk);
80104b8a:	83 ec 0c             	sub    $0xc,%esp
80104b8d:	ff 75 0c             	pushl  0xc(%ebp)
80104b90:	e8 2f 04 00 00       	call   80104fc4 <release>
80104b95:	83 c4 10             	add    $0x10,%esp
  }
  // Go to sleep.
  p->chan = chan;
80104b98:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104b9b:	8b 55 08             	mov    0x8(%ebp),%edx
80104b9e:	89 50 20             	mov    %edx,0x20(%eax)
  p->state = SLEEPING;
80104ba1:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104ba4:	c7 40 0c 02 00 00 00 	movl   $0x2,0xc(%eax)

  sched();
80104bab:	e8 52 fe ff ff       	call   80104a02 <sched>

  // Tidy up.
  p->chan = 0;
80104bb0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104bb3:	c7 40 20 00 00 00 00 	movl   $0x0,0x20(%eax)

  // Reacquire original lock.
  if(lk != &ptable.lock){  //DOC: sleeplock2
80104bba:	81 7d 0c a0 3d 11 80 	cmpl   $0x80113da0,0xc(%ebp)
80104bc1:	74 1e                	je     80104be1 <sleep+0xa4>
    release(&ptable.lock);
80104bc3:	83 ec 0c             	sub    $0xc,%esp
80104bc6:	68 a0 3d 11 80       	push   $0x80113da0
80104bcb:	e8 f4 03 00 00       	call   80104fc4 <release>
80104bd0:	83 c4 10             	add    $0x10,%esp
    acquire(lk);
80104bd3:	83 ec 0c             	sub    $0xc,%esp
80104bd6:	ff 75 0c             	pushl  0xc(%ebp)
80104bd9:	e8 78 03 00 00       	call   80104f56 <acquire>
80104bde:	83 c4 10             	add    $0x10,%esp
  }
}
80104be1:	90                   	nop
80104be2:	c9                   	leave  
80104be3:	c3                   	ret    

80104be4 <wakeup1>:
//PAGEBREAK!
// Wake up all processes sleeping on chan.
// The ptable lock must be held.
static void
wakeup1(void *chan)
{
80104be4:	55                   	push   %ebp
80104be5:	89 e5                	mov    %esp,%ebp
80104be7:	83 ec 10             	sub    $0x10,%esp
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104bea:	c7 45 fc d4 3d 11 80 	movl   $0x80113dd4,-0x4(%ebp)
80104bf1:	eb 24                	jmp    80104c17 <wakeup1+0x33>
    if(p->state == SLEEPING && p->chan == chan)
80104bf3:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104bf6:	8b 40 0c             	mov    0xc(%eax),%eax
80104bf9:	83 f8 02             	cmp    $0x2,%eax
80104bfc:	75 15                	jne    80104c13 <wakeup1+0x2f>
80104bfe:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c01:	8b 40 20             	mov    0x20(%eax),%eax
80104c04:	3b 45 08             	cmp    0x8(%ebp),%eax
80104c07:	75 0a                	jne    80104c13 <wakeup1+0x2f>
      p->state = RUNNABLE;
80104c09:	8b 45 fc             	mov    -0x4(%ebp),%eax
80104c0c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
static void
wakeup1(void *chan)
{
  struct proc *p;

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++)
80104c13:	83 45 fc 7c          	addl   $0x7c,-0x4(%ebp)
80104c17:	81 7d fc d4 5c 11 80 	cmpl   $0x80115cd4,-0x4(%ebp)
80104c1e:	72 d3                	jb     80104bf3 <wakeup1+0xf>
    if(p->state == SLEEPING && p->chan == chan)
      p->state = RUNNABLE;
}
80104c20:	90                   	nop
80104c21:	c9                   	leave  
80104c22:	c3                   	ret    

80104c23 <wakeup>:

// Wake up all processes sleeping on chan.
void
wakeup(void *chan)
{
80104c23:	55                   	push   %ebp
80104c24:	89 e5                	mov    %esp,%ebp
80104c26:	83 ec 08             	sub    $0x8,%esp
  acquire(&ptable.lock);
80104c29:	83 ec 0c             	sub    $0xc,%esp
80104c2c:	68 a0 3d 11 80       	push   $0x80113da0
80104c31:	e8 20 03 00 00       	call   80104f56 <acquire>
80104c36:	83 c4 10             	add    $0x10,%esp
  wakeup1(chan);
80104c39:	83 ec 0c             	sub    $0xc,%esp
80104c3c:	ff 75 08             	pushl  0x8(%ebp)
80104c3f:	e8 a0 ff ff ff       	call   80104be4 <wakeup1>
80104c44:	83 c4 10             	add    $0x10,%esp
  release(&ptable.lock);
80104c47:	83 ec 0c             	sub    $0xc,%esp
80104c4a:	68 a0 3d 11 80       	push   $0x80113da0
80104c4f:	e8 70 03 00 00       	call   80104fc4 <release>
80104c54:	83 c4 10             	add    $0x10,%esp
}
80104c57:	90                   	nop
80104c58:	c9                   	leave  
80104c59:	c3                   	ret    

80104c5a <kill>:
// Kill the process with the given pid.
// Process won't exit until it returns
// to user space (see trap in trap.c).
int
kill(int pid)
{
80104c5a:	55                   	push   %ebp
80104c5b:	89 e5                	mov    %esp,%ebp
80104c5d:	83 ec 18             	sub    $0x18,%esp
  struct proc *p;

  acquire(&ptable.lock);
80104c60:	83 ec 0c             	sub    $0xc,%esp
80104c63:	68 a0 3d 11 80       	push   $0x80113da0
80104c68:	e8 e9 02 00 00       	call   80104f56 <acquire>
80104c6d:	83 c4 10             	add    $0x10,%esp
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104c70:	c7 45 f4 d4 3d 11 80 	movl   $0x80113dd4,-0xc(%ebp)
80104c77:	eb 45                	jmp    80104cbe <kill+0x64>
    if(p->pid == pid){
80104c79:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c7c:	8b 40 10             	mov    0x10(%eax),%eax
80104c7f:	3b 45 08             	cmp    0x8(%ebp),%eax
80104c82:	75 36                	jne    80104cba <kill+0x60>
      p->killed = 1;
80104c84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c87:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
      // Wake process from sleep if necessary.
      if(p->state == SLEEPING)
80104c8e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c91:	8b 40 0c             	mov    0xc(%eax),%eax
80104c94:	83 f8 02             	cmp    $0x2,%eax
80104c97:	75 0a                	jne    80104ca3 <kill+0x49>
        p->state = RUNNABLE;
80104c99:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104c9c:	c7 40 0c 03 00 00 00 	movl   $0x3,0xc(%eax)
      release(&ptable.lock);
80104ca3:	83 ec 0c             	sub    $0xc,%esp
80104ca6:	68 a0 3d 11 80       	push   $0x80113da0
80104cab:	e8 14 03 00 00       	call   80104fc4 <release>
80104cb0:	83 c4 10             	add    $0x10,%esp
      return 0;
80104cb3:	b8 00 00 00 00       	mov    $0x0,%eax
80104cb8:	eb 22                	jmp    80104cdc <kill+0x82>
kill(int pid)
{
  struct proc *p;

  acquire(&ptable.lock);
  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104cba:	83 45 f4 7c          	addl   $0x7c,-0xc(%ebp)
80104cbe:	81 7d f4 d4 5c 11 80 	cmpl   $0x80115cd4,-0xc(%ebp)
80104cc5:	72 b2                	jb     80104c79 <kill+0x1f>
        p->state = RUNNABLE;
      release(&ptable.lock);
      return 0;
    }
  }
  release(&ptable.lock);
80104cc7:	83 ec 0c             	sub    $0xc,%esp
80104cca:	68 a0 3d 11 80       	push   $0x80113da0
80104ccf:	e8 f0 02 00 00       	call   80104fc4 <release>
80104cd4:	83 c4 10             	add    $0x10,%esp
  return -1;
80104cd7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80104cdc:	c9                   	leave  
80104cdd:	c3                   	ret    

80104cde <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
80104cde:	55                   	push   %ebp
80104cdf:	89 e5                	mov    %esp,%ebp
80104ce1:	83 ec 48             	sub    $0x48,%esp
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104ce4:	c7 45 f0 d4 3d 11 80 	movl   $0x80113dd4,-0x10(%ebp)
80104ceb:	e9 d7 00 00 00       	jmp    80104dc7 <procdump+0xe9>
    if(p->state == UNUSED)
80104cf0:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104cf3:	8b 40 0c             	mov    0xc(%eax),%eax
80104cf6:	85 c0                	test   %eax,%eax
80104cf8:	0f 84 c4 00 00 00    	je     80104dc2 <procdump+0xe4>
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
80104cfe:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d01:	8b 40 0c             	mov    0xc(%eax),%eax
80104d04:	83 f8 05             	cmp    $0x5,%eax
80104d07:	77 23                	ja     80104d2c <procdump+0x4e>
80104d09:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d0c:	8b 40 0c             	mov    0xc(%eax),%eax
80104d0f:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104d16:	85 c0                	test   %eax,%eax
80104d18:	74 12                	je     80104d2c <procdump+0x4e>
      state = states[p->state];
80104d1a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d1d:	8b 40 0c             	mov    0xc(%eax),%eax
80104d20:	8b 04 85 08 b0 10 80 	mov    -0x7fef4ff8(,%eax,4),%eax
80104d27:	89 45 ec             	mov    %eax,-0x14(%ebp)
80104d2a:	eb 07                	jmp    80104d33 <procdump+0x55>
    else
      state = "???";
80104d2c:	c7 45 ec 86 88 10 80 	movl   $0x80108886,-0x14(%ebp)
    cprintf("%d %s %s", p->pid, state, p->name);
80104d33:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d36:	8d 50 6c             	lea    0x6c(%eax),%edx
80104d39:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d3c:	8b 40 10             	mov    0x10(%eax),%eax
80104d3f:	52                   	push   %edx
80104d40:	ff 75 ec             	pushl  -0x14(%ebp)
80104d43:	50                   	push   %eax
80104d44:	68 8a 88 10 80       	push   $0x8010888a
80104d49:	e8 b2 b6 ff ff       	call   80100400 <cprintf>
80104d4e:	83 c4 10             	add    $0x10,%esp
    if(p->state == SLEEPING){
80104d51:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d54:	8b 40 0c             	mov    0xc(%eax),%eax
80104d57:	83 f8 02             	cmp    $0x2,%eax
80104d5a:	75 54                	jne    80104db0 <procdump+0xd2>
      getcallerpcs((uint*)p->context->ebp+2, pc);
80104d5c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80104d5f:	8b 40 1c             	mov    0x1c(%eax),%eax
80104d62:	8b 40 0c             	mov    0xc(%eax),%eax
80104d65:	83 c0 08             	add    $0x8,%eax
80104d68:	89 c2                	mov    %eax,%edx
80104d6a:	83 ec 08             	sub    $0x8,%esp
80104d6d:	8d 45 c4             	lea    -0x3c(%ebp),%eax
80104d70:	50                   	push   %eax
80104d71:	52                   	push   %edx
80104d72:	e8 9f 02 00 00       	call   80105016 <getcallerpcs>
80104d77:	83 c4 10             	add    $0x10,%esp
      for(i=0; i<10 && pc[i] != 0; i++)
80104d7a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80104d81:	eb 1c                	jmp    80104d9f <procdump+0xc1>
        cprintf(" %p", pc[i]);
80104d83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104d86:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104d8a:	83 ec 08             	sub    $0x8,%esp
80104d8d:	50                   	push   %eax
80104d8e:	68 93 88 10 80       	push   $0x80108893
80104d93:	e8 68 b6 ff ff       	call   80100400 <cprintf>
80104d98:	83 c4 10             	add    $0x10,%esp
    else
      state = "???";
    cprintf("%d %s %s", p->pid, state, p->name);
    if(p->state == SLEEPING){
      getcallerpcs((uint*)p->context->ebp+2, pc);
      for(i=0; i<10 && pc[i] != 0; i++)
80104d9b:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80104d9f:	83 7d f4 09          	cmpl   $0x9,-0xc(%ebp)
80104da3:	7f 0b                	jg     80104db0 <procdump+0xd2>
80104da5:	8b 45 f4             	mov    -0xc(%ebp),%eax
80104da8:	8b 44 85 c4          	mov    -0x3c(%ebp,%eax,4),%eax
80104dac:	85 c0                	test   %eax,%eax
80104dae:	75 d3                	jne    80104d83 <procdump+0xa5>
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
80104db0:	83 ec 0c             	sub    $0xc,%esp
80104db3:	68 97 88 10 80       	push   $0x80108897
80104db8:	e8 43 b6 ff ff       	call   80100400 <cprintf>
80104dbd:	83 c4 10             	add    $0x10,%esp
80104dc0:	eb 01                	jmp    80104dc3 <procdump+0xe5>
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
    if(p->state == UNUSED)
      continue;
80104dc2:	90                   	nop
  int i;
  struct proc *p;
  char *state;
  uint pc[10];

  for(p = ptable.proc; p < &ptable.proc[NPROC]; p++){
80104dc3:	83 45 f0 7c          	addl   $0x7c,-0x10(%ebp)
80104dc7:	81 7d f0 d4 5c 11 80 	cmpl   $0x80115cd4,-0x10(%ebp)
80104dce:	0f 82 1c ff ff ff    	jb     80104cf0 <procdump+0x12>
      for(i=0; i<10 && pc[i] != 0; i++)
        cprintf(" %p", pc[i]);
    }
    cprintf("\n");
  }
}
80104dd4:	90                   	nop
80104dd5:	c9                   	leave  
80104dd6:	c3                   	ret    

80104dd7 <initsleeplock>:
#include "spinlock.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
80104dd7:	55                   	push   %ebp
80104dd8:	89 e5                	mov    %esp,%ebp
80104dda:	83 ec 08             	sub    $0x8,%esp
  initlock(&lk->lk, "sleep lock");
80104ddd:	8b 45 08             	mov    0x8(%ebp),%eax
80104de0:	83 c0 04             	add    $0x4,%eax
80104de3:	83 ec 08             	sub    $0x8,%esp
80104de6:	68 c3 88 10 80       	push   $0x801088c3
80104deb:	50                   	push   %eax
80104dec:	e8 43 01 00 00       	call   80104f34 <initlock>
80104df1:	83 c4 10             	add    $0x10,%esp
  lk->name = name;
80104df4:	8b 45 08             	mov    0x8(%ebp),%eax
80104df7:	8b 55 0c             	mov    0xc(%ebp),%edx
80104dfa:	89 50 38             	mov    %edx,0x38(%eax)
  lk->locked = 0;
80104dfd:	8b 45 08             	mov    0x8(%ebp),%eax
80104e00:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104e06:	8b 45 08             	mov    0x8(%ebp),%eax
80104e09:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
}
80104e10:	90                   	nop
80104e11:	c9                   	leave  
80104e12:	c3                   	ret    

80104e13 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
80104e13:	55                   	push   %ebp
80104e14:	89 e5                	mov    %esp,%ebp
80104e16:	83 ec 08             	sub    $0x8,%esp
  acquire(&lk->lk);
80104e19:	8b 45 08             	mov    0x8(%ebp),%eax
80104e1c:	83 c0 04             	add    $0x4,%eax
80104e1f:	83 ec 0c             	sub    $0xc,%esp
80104e22:	50                   	push   %eax
80104e23:	e8 2e 01 00 00       	call   80104f56 <acquire>
80104e28:	83 c4 10             	add    $0x10,%esp
  while (lk->locked) {
80104e2b:	eb 15                	jmp    80104e42 <acquiresleep+0x2f>
    sleep(lk, &lk->lk);
80104e2d:	8b 45 08             	mov    0x8(%ebp),%eax
80104e30:	83 c0 04             	add    $0x4,%eax
80104e33:	83 ec 08             	sub    $0x8,%esp
80104e36:	50                   	push   %eax
80104e37:	ff 75 08             	pushl  0x8(%ebp)
80104e3a:	e8 fe fc ff ff       	call   80104b3d <sleep>
80104e3f:	83 c4 10             	add    $0x10,%esp

void
acquiresleep(struct sleeplock *lk)
{
  acquire(&lk->lk);
  while (lk->locked) {
80104e42:	8b 45 08             	mov    0x8(%ebp),%eax
80104e45:	8b 00                	mov    (%eax),%eax
80104e47:	85 c0                	test   %eax,%eax
80104e49:	75 e2                	jne    80104e2d <acquiresleep+0x1a>
    sleep(lk, &lk->lk);
  }
  lk->locked = 1;
80104e4b:	8b 45 08             	mov    0x8(%ebp),%eax
80104e4e:	c7 00 01 00 00 00    	movl   $0x1,(%eax)
  lk->pid = myproc()->pid;
80104e54:	e8 2f f4 ff ff       	call   80104288 <myproc>
80104e59:	8b 50 10             	mov    0x10(%eax),%edx
80104e5c:	8b 45 08             	mov    0x8(%ebp),%eax
80104e5f:	89 50 3c             	mov    %edx,0x3c(%eax)
  release(&lk->lk);
80104e62:	8b 45 08             	mov    0x8(%ebp),%eax
80104e65:	83 c0 04             	add    $0x4,%eax
80104e68:	83 ec 0c             	sub    $0xc,%esp
80104e6b:	50                   	push   %eax
80104e6c:	e8 53 01 00 00       	call   80104fc4 <release>
80104e71:	83 c4 10             	add    $0x10,%esp
}
80104e74:	90                   	nop
80104e75:	c9                   	leave  
80104e76:	c3                   	ret    

80104e77 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
80104e77:	55                   	push   %ebp
80104e78:	89 e5                	mov    %esp,%ebp
80104e7a:	83 ec 08             	sub    $0x8,%esp
  acquire(&lk->lk);
80104e7d:	8b 45 08             	mov    0x8(%ebp),%eax
80104e80:	83 c0 04             	add    $0x4,%eax
80104e83:	83 ec 0c             	sub    $0xc,%esp
80104e86:	50                   	push   %eax
80104e87:	e8 ca 00 00 00       	call   80104f56 <acquire>
80104e8c:	83 c4 10             	add    $0x10,%esp
  lk->locked = 0;
80104e8f:	8b 45 08             	mov    0x8(%ebp),%eax
80104e92:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->pid = 0;
80104e98:	8b 45 08             	mov    0x8(%ebp),%eax
80104e9b:	c7 40 3c 00 00 00 00 	movl   $0x0,0x3c(%eax)
  wakeup(lk);
80104ea2:	83 ec 0c             	sub    $0xc,%esp
80104ea5:	ff 75 08             	pushl  0x8(%ebp)
80104ea8:	e8 76 fd ff ff       	call   80104c23 <wakeup>
80104ead:	83 c4 10             	add    $0x10,%esp
  release(&lk->lk);
80104eb0:	8b 45 08             	mov    0x8(%ebp),%eax
80104eb3:	83 c0 04             	add    $0x4,%eax
80104eb6:	83 ec 0c             	sub    $0xc,%esp
80104eb9:	50                   	push   %eax
80104eba:	e8 05 01 00 00       	call   80104fc4 <release>
80104ebf:	83 c4 10             	add    $0x10,%esp
}
80104ec2:	90                   	nop
80104ec3:	c9                   	leave  
80104ec4:	c3                   	ret    

80104ec5 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
80104ec5:	55                   	push   %ebp
80104ec6:	89 e5                	mov    %esp,%ebp
80104ec8:	83 ec 18             	sub    $0x18,%esp
  int r;
  
  acquire(&lk->lk);
80104ecb:	8b 45 08             	mov    0x8(%ebp),%eax
80104ece:	83 c0 04             	add    $0x4,%eax
80104ed1:	83 ec 0c             	sub    $0xc,%esp
80104ed4:	50                   	push   %eax
80104ed5:	e8 7c 00 00 00       	call   80104f56 <acquire>
80104eda:	83 c4 10             	add    $0x10,%esp
  r = lk->locked;
80104edd:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee0:	8b 00                	mov    (%eax),%eax
80104ee2:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&lk->lk);
80104ee5:	8b 45 08             	mov    0x8(%ebp),%eax
80104ee8:	83 c0 04             	add    $0x4,%eax
80104eeb:	83 ec 0c             	sub    $0xc,%esp
80104eee:	50                   	push   %eax
80104eef:	e8 d0 00 00 00       	call   80104fc4 <release>
80104ef4:	83 c4 10             	add    $0x10,%esp
  return r;
80104ef7:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80104efa:	c9                   	leave  
80104efb:	c3                   	ret    

80104efc <readeflags>:
  asm volatile("ltr %0" : : "r" (sel));
}

static inline uint
readeflags(void)
{
80104efc:	55                   	push   %ebp
80104efd:	89 e5                	mov    %esp,%ebp
80104eff:	83 ec 10             	sub    $0x10,%esp
  uint eflags;
  asm volatile("pushfl; popl %0" : "=r" (eflags));
80104f02:	9c                   	pushf  
80104f03:	58                   	pop    %eax
80104f04:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return eflags;
80104f07:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f0a:	c9                   	leave  
80104f0b:	c3                   	ret    

80104f0c <cli>:
  asm volatile("movw %0, %%gs" : : "r" (v));
}

static inline void
cli(void)
{
80104f0c:	55                   	push   %ebp
80104f0d:	89 e5                	mov    %esp,%ebp
  asm volatile("cli");
80104f0f:	fa                   	cli    
}
80104f10:	90                   	nop
80104f11:	5d                   	pop    %ebp
80104f12:	c3                   	ret    

80104f13 <sti>:

static inline void
sti(void)
{
80104f13:	55                   	push   %ebp
80104f14:	89 e5                	mov    %esp,%ebp
  asm volatile("sti");
80104f16:	fb                   	sti    
}
80104f17:	90                   	nop
80104f18:	5d                   	pop    %ebp
80104f19:	c3                   	ret    

80104f1a <xchg>:

static inline uint
xchg(volatile uint *addr, uint newval)
{
80104f1a:	55                   	push   %ebp
80104f1b:	89 e5                	mov    %esp,%ebp
80104f1d:	83 ec 10             	sub    $0x10,%esp
  uint result;

  // The + in "+m" denotes a read-modify-write operand.
  asm volatile("lock; xchgl %0, %1" :
80104f20:	8b 55 08             	mov    0x8(%ebp),%edx
80104f23:	8b 45 0c             	mov    0xc(%ebp),%eax
80104f26:	8b 4d 08             	mov    0x8(%ebp),%ecx
80104f29:	f0 87 02             	lock xchg %eax,(%edx)
80104f2c:	89 45 fc             	mov    %eax,-0x4(%ebp)
               "+m" (*addr), "=a" (result) :
               "1" (newval) :
               "cc");
  return result;
80104f2f:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80104f32:	c9                   	leave  
80104f33:	c3                   	ret    

80104f34 <initlock>:
#include "proc.h"
#include "spinlock.h"

void
initlock(struct spinlock *lk, char *name)
{
80104f34:	55                   	push   %ebp
80104f35:	89 e5                	mov    %esp,%ebp
  lk->name = name;
80104f37:	8b 45 08             	mov    0x8(%ebp),%eax
80104f3a:	8b 55 0c             	mov    0xc(%ebp),%edx
80104f3d:	89 50 04             	mov    %edx,0x4(%eax)
  lk->locked = 0;
80104f40:	8b 45 08             	mov    0x8(%ebp),%eax
80104f43:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
  lk->cpu = 0;
80104f49:	8b 45 08             	mov    0x8(%ebp),%eax
80104f4c:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
}
80104f53:	90                   	nop
80104f54:	5d                   	pop    %ebp
80104f55:	c3                   	ret    

80104f56 <acquire>:
// Loops (spins) until the lock is acquired.
// Holding a lock for a long time may cause
// other CPUs to waste time spinning to acquire it.
void
acquire(struct spinlock *lk)
{
80104f56:	55                   	push   %ebp
80104f57:	89 e5                	mov    %esp,%ebp
80104f59:	53                   	push   %ebx
80104f5a:	83 ec 04             	sub    $0x4,%esp
  pushcli(); // disable interrupts to avoid deadlock.
80104f5d:	e8 5f 01 00 00       	call   801050c1 <pushcli>
  if(holding(lk))
80104f62:	8b 45 08             	mov    0x8(%ebp),%eax
80104f65:	83 ec 0c             	sub    $0xc,%esp
80104f68:	50                   	push   %eax
80104f69:	e8 22 01 00 00       	call   80105090 <holding>
80104f6e:	83 c4 10             	add    $0x10,%esp
80104f71:	85 c0                	test   %eax,%eax
80104f73:	74 0d                	je     80104f82 <acquire+0x2c>
    panic("acquire");
80104f75:	83 ec 0c             	sub    $0xc,%esp
80104f78:	68 ce 88 10 80       	push   $0x801088ce
80104f7d:	e8 1e b6 ff ff       	call   801005a0 <panic>

  // The xchg is atomic.
  while(xchg(&lk->locked, 1) != 0)
80104f82:	90                   	nop
80104f83:	8b 45 08             	mov    0x8(%ebp),%eax
80104f86:	83 ec 08             	sub    $0x8,%esp
80104f89:	6a 01                	push   $0x1
80104f8b:	50                   	push   %eax
80104f8c:	e8 89 ff ff ff       	call   80104f1a <xchg>
80104f91:	83 c4 10             	add    $0x10,%esp
80104f94:	85 c0                	test   %eax,%eax
80104f96:	75 eb                	jne    80104f83 <acquire+0x2d>
    ;

  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that the critical section's memory
  // references happen after the lock is acquired.
  __sync_synchronize();
80104f98:	f0 83 0c 24 00       	lock orl $0x0,(%esp)

  // Record info about lock acquisition for debugging.
  lk->cpu = mycpu();
80104f9d:	8b 5d 08             	mov    0x8(%ebp),%ebx
80104fa0:	e8 6b f2 ff ff       	call   80104210 <mycpu>
80104fa5:	89 43 08             	mov    %eax,0x8(%ebx)
  getcallerpcs(&lk, lk->pcs);
80104fa8:	8b 45 08             	mov    0x8(%ebp),%eax
80104fab:	83 c0 0c             	add    $0xc,%eax
80104fae:	83 ec 08             	sub    $0x8,%esp
80104fb1:	50                   	push   %eax
80104fb2:	8d 45 08             	lea    0x8(%ebp),%eax
80104fb5:	50                   	push   %eax
80104fb6:	e8 5b 00 00 00       	call   80105016 <getcallerpcs>
80104fbb:	83 c4 10             	add    $0x10,%esp
}
80104fbe:	90                   	nop
80104fbf:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80104fc2:	c9                   	leave  
80104fc3:	c3                   	ret    

80104fc4 <release>:

// Release the lock.
void
release(struct spinlock *lk)
{
80104fc4:	55                   	push   %ebp
80104fc5:	89 e5                	mov    %esp,%ebp
80104fc7:	83 ec 08             	sub    $0x8,%esp
  if(!holding(lk))
80104fca:	83 ec 0c             	sub    $0xc,%esp
80104fcd:	ff 75 08             	pushl  0x8(%ebp)
80104fd0:	e8 bb 00 00 00       	call   80105090 <holding>
80104fd5:	83 c4 10             	add    $0x10,%esp
80104fd8:	85 c0                	test   %eax,%eax
80104fda:	75 0d                	jne    80104fe9 <release+0x25>
    panic("release");
80104fdc:	83 ec 0c             	sub    $0xc,%esp
80104fdf:	68 d6 88 10 80       	push   $0x801088d6
80104fe4:	e8 b7 b5 ff ff       	call   801005a0 <panic>

  lk->pcs[0] = 0;
80104fe9:	8b 45 08             	mov    0x8(%ebp),%eax
80104fec:	c7 40 0c 00 00 00 00 	movl   $0x0,0xc(%eax)
  lk->cpu = 0;
80104ff3:	8b 45 08             	mov    0x8(%ebp),%eax
80104ff6:	c7 40 08 00 00 00 00 	movl   $0x0,0x8(%eax)
  // Tell the C compiler and the processor to not move loads or stores
  // past this point, to ensure that all the stores in the critical
  // section are visible to other cores before the lock is released.
  // Both the C compiler and the hardware may re-order loads and
  // stores; __sync_synchronize() tells them both not to.
  __sync_synchronize();
80104ffd:	f0 83 0c 24 00       	lock orl $0x0,(%esp)

  // Release the lock, equivalent to lk->locked = 0.
  // This code can't use a C assignment, since it might
  // not be atomic. A real OS would use C atomics here.
  asm volatile("movl $0, %0" : "+m" (lk->locked) : );
80105002:	8b 45 08             	mov    0x8(%ebp),%eax
80105005:	8b 55 08             	mov    0x8(%ebp),%edx
80105008:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  popcli();
8010500e:	e8 fc 00 00 00       	call   8010510f <popcli>
}
80105013:	90                   	nop
80105014:	c9                   	leave  
80105015:	c3                   	ret    

80105016 <getcallerpcs>:

// Record the current call stack in pcs[] by following the %ebp chain.
void
getcallerpcs(void *v, uint pcs[])
{
80105016:	55                   	push   %ebp
80105017:	89 e5                	mov    %esp,%ebp
80105019:	83 ec 10             	sub    $0x10,%esp
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
8010501c:	8b 45 08             	mov    0x8(%ebp),%eax
8010501f:	83 e8 08             	sub    $0x8,%eax
80105022:	89 45 fc             	mov    %eax,-0x4(%ebp)
  for(i = 0; i < 10; i++){
80105025:	c7 45 f8 00 00 00 00 	movl   $0x0,-0x8(%ebp)
8010502c:	eb 38                	jmp    80105066 <getcallerpcs+0x50>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
8010502e:	83 7d fc 00          	cmpl   $0x0,-0x4(%ebp)
80105032:	74 53                	je     80105087 <getcallerpcs+0x71>
80105034:	81 7d fc ff ff ff 7f 	cmpl   $0x7fffffff,-0x4(%ebp)
8010503b:	76 4a                	jbe    80105087 <getcallerpcs+0x71>
8010503d:	83 7d fc ff          	cmpl   $0xffffffff,-0x4(%ebp)
80105041:	74 44                	je     80105087 <getcallerpcs+0x71>
      break;
    pcs[i] = ebp[1];     // saved %eip
80105043:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105046:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
8010504d:	8b 45 0c             	mov    0xc(%ebp),%eax
80105050:	01 c2                	add    %eax,%edx
80105052:	8b 45 fc             	mov    -0x4(%ebp),%eax
80105055:	8b 40 04             	mov    0x4(%eax),%eax
80105058:	89 02                	mov    %eax,(%edx)
    ebp = (uint*)ebp[0]; // saved %ebp
8010505a:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010505d:	8b 00                	mov    (%eax),%eax
8010505f:	89 45 fc             	mov    %eax,-0x4(%ebp)
{
  uint *ebp;
  int i;

  ebp = (uint*)v - 2;
  for(i = 0; i < 10; i++){
80105062:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105066:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010506a:	7e c2                	jle    8010502e <getcallerpcs+0x18>
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
8010506c:	eb 19                	jmp    80105087 <getcallerpcs+0x71>
    pcs[i] = 0;
8010506e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105071:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80105078:	8b 45 0c             	mov    0xc(%ebp),%eax
8010507b:	01 d0                	add    %edx,%eax
8010507d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
    if(ebp == 0 || ebp < (uint*)KERNBASE || ebp == (uint*)0xffffffff)
      break;
    pcs[i] = ebp[1];     // saved %eip
    ebp = (uint*)ebp[0]; // saved %ebp
  }
  for(; i < 10; i++)
80105083:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
80105087:	83 7d f8 09          	cmpl   $0x9,-0x8(%ebp)
8010508b:	7e e1                	jle    8010506e <getcallerpcs+0x58>
    pcs[i] = 0;
}
8010508d:	90                   	nop
8010508e:	c9                   	leave  
8010508f:	c3                   	ret    

80105090 <holding>:

// Check whether this cpu is holding the lock.
int
holding(struct spinlock *lock)
{
80105090:	55                   	push   %ebp
80105091:	89 e5                	mov    %esp,%ebp
80105093:	53                   	push   %ebx
80105094:	83 ec 04             	sub    $0x4,%esp
  return lock->locked && lock->cpu == mycpu();
80105097:	8b 45 08             	mov    0x8(%ebp),%eax
8010509a:	8b 00                	mov    (%eax),%eax
8010509c:	85 c0                	test   %eax,%eax
8010509e:	74 16                	je     801050b6 <holding+0x26>
801050a0:	8b 45 08             	mov    0x8(%ebp),%eax
801050a3:	8b 58 08             	mov    0x8(%eax),%ebx
801050a6:	e8 65 f1 ff ff       	call   80104210 <mycpu>
801050ab:	39 c3                	cmp    %eax,%ebx
801050ad:	75 07                	jne    801050b6 <holding+0x26>
801050af:	b8 01 00 00 00       	mov    $0x1,%eax
801050b4:	eb 05                	jmp    801050bb <holding+0x2b>
801050b6:	b8 00 00 00 00       	mov    $0x0,%eax
}
801050bb:	83 c4 04             	add    $0x4,%esp
801050be:	5b                   	pop    %ebx
801050bf:	5d                   	pop    %ebp
801050c0:	c3                   	ret    

801050c1 <pushcli>:
// it takes two popcli to undo two pushcli.  Also, if interrupts
// are off, then pushcli, popcli leaves them off.

void
pushcli(void)
{
801050c1:	55                   	push   %ebp
801050c2:	89 e5                	mov    %esp,%ebp
801050c4:	83 ec 18             	sub    $0x18,%esp
  int eflags;

  eflags = readeflags();
801050c7:	e8 30 fe ff ff       	call   80104efc <readeflags>
801050cc:	89 45 f4             	mov    %eax,-0xc(%ebp)
  cli();
801050cf:	e8 38 fe ff ff       	call   80104f0c <cli>
  if(mycpu()->ncli == 0)
801050d4:	e8 37 f1 ff ff       	call   80104210 <mycpu>
801050d9:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
801050df:	85 c0                	test   %eax,%eax
801050e1:	75 15                	jne    801050f8 <pushcli+0x37>
    mycpu()->intena = eflags & FL_IF;
801050e3:	e8 28 f1 ff ff       	call   80104210 <mycpu>
801050e8:	89 c2                	mov    %eax,%edx
801050ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801050ed:	25 00 02 00 00       	and    $0x200,%eax
801050f2:	89 82 a8 00 00 00    	mov    %eax,0xa8(%edx)
  mycpu()->ncli += 1;
801050f8:	e8 13 f1 ff ff       	call   80104210 <mycpu>
801050fd:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
80105103:	83 c2 01             	add    $0x1,%edx
80105106:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
}
8010510c:	90                   	nop
8010510d:	c9                   	leave  
8010510e:	c3                   	ret    

8010510f <popcli>:

void
popcli(void)
{
8010510f:	55                   	push   %ebp
80105110:	89 e5                	mov    %esp,%ebp
80105112:	83 ec 08             	sub    $0x8,%esp
  if(readeflags()&FL_IF)
80105115:	e8 e2 fd ff ff       	call   80104efc <readeflags>
8010511a:	25 00 02 00 00       	and    $0x200,%eax
8010511f:	85 c0                	test   %eax,%eax
80105121:	74 0d                	je     80105130 <popcli+0x21>
    panic("popcli - interruptible");
80105123:	83 ec 0c             	sub    $0xc,%esp
80105126:	68 de 88 10 80       	push   $0x801088de
8010512b:	e8 70 b4 ff ff       	call   801005a0 <panic>
  if(--mycpu()->ncli < 0)
80105130:	e8 db f0 ff ff       	call   80104210 <mycpu>
80105135:	8b 90 a4 00 00 00    	mov    0xa4(%eax),%edx
8010513b:	83 ea 01             	sub    $0x1,%edx
8010513e:	89 90 a4 00 00 00    	mov    %edx,0xa4(%eax)
80105144:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
8010514a:	85 c0                	test   %eax,%eax
8010514c:	79 0d                	jns    8010515b <popcli+0x4c>
    panic("popcli");
8010514e:	83 ec 0c             	sub    $0xc,%esp
80105151:	68 f5 88 10 80       	push   $0x801088f5
80105156:	e8 45 b4 ff ff       	call   801005a0 <panic>
  if(mycpu()->ncli == 0 && mycpu()->intena)
8010515b:	e8 b0 f0 ff ff       	call   80104210 <mycpu>
80105160:	8b 80 a4 00 00 00    	mov    0xa4(%eax),%eax
80105166:	85 c0                	test   %eax,%eax
80105168:	75 14                	jne    8010517e <popcli+0x6f>
8010516a:	e8 a1 f0 ff ff       	call   80104210 <mycpu>
8010516f:	8b 80 a8 00 00 00    	mov    0xa8(%eax),%eax
80105175:	85 c0                	test   %eax,%eax
80105177:	74 05                	je     8010517e <popcli+0x6f>
    sti();
80105179:	e8 95 fd ff ff       	call   80104f13 <sti>
}
8010517e:	90                   	nop
8010517f:	c9                   	leave  
80105180:	c3                   	ret    

80105181 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
80105181:	55                   	push   %ebp
80105182:	89 e5                	mov    %esp,%ebp
80105184:	57                   	push   %edi
80105185:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
80105186:	8b 4d 08             	mov    0x8(%ebp),%ecx
80105189:	8b 55 10             	mov    0x10(%ebp),%edx
8010518c:	8b 45 0c             	mov    0xc(%ebp),%eax
8010518f:	89 cb                	mov    %ecx,%ebx
80105191:	89 df                	mov    %ebx,%edi
80105193:	89 d1                	mov    %edx,%ecx
80105195:	fc                   	cld    
80105196:	f3 aa                	rep stos %al,%es:(%edi)
80105198:	89 ca                	mov    %ecx,%edx
8010519a:	89 fb                	mov    %edi,%ebx
8010519c:	89 5d 08             	mov    %ebx,0x8(%ebp)
8010519f:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801051a2:	90                   	nop
801051a3:	5b                   	pop    %ebx
801051a4:	5f                   	pop    %edi
801051a5:	5d                   	pop    %ebp
801051a6:	c3                   	ret    

801051a7 <stosl>:

static inline void
stosl(void *addr, int data, int cnt)
{
801051a7:	55                   	push   %ebp
801051a8:	89 e5                	mov    %esp,%ebp
801051aa:	57                   	push   %edi
801051ab:	53                   	push   %ebx
  asm volatile("cld; rep stosl" :
801051ac:	8b 4d 08             	mov    0x8(%ebp),%ecx
801051af:	8b 55 10             	mov    0x10(%ebp),%edx
801051b2:	8b 45 0c             	mov    0xc(%ebp),%eax
801051b5:	89 cb                	mov    %ecx,%ebx
801051b7:	89 df                	mov    %ebx,%edi
801051b9:	89 d1                	mov    %edx,%ecx
801051bb:	fc                   	cld    
801051bc:	f3 ab                	rep stos %eax,%es:(%edi)
801051be:	89 ca                	mov    %ecx,%edx
801051c0:	89 fb                	mov    %edi,%ebx
801051c2:	89 5d 08             	mov    %ebx,0x8(%ebp)
801051c5:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
801051c8:	90                   	nop
801051c9:	5b                   	pop    %ebx
801051ca:	5f                   	pop    %edi
801051cb:	5d                   	pop    %ebp
801051cc:	c3                   	ret    

801051cd <memset>:
#include "types.h"
#include "x86.h"

void*
memset(void *dst, int c, uint n)
{
801051cd:	55                   	push   %ebp
801051ce:	89 e5                	mov    %esp,%ebp
  if ((int)dst%4 == 0 && n%4 == 0){
801051d0:	8b 45 08             	mov    0x8(%ebp),%eax
801051d3:	83 e0 03             	and    $0x3,%eax
801051d6:	85 c0                	test   %eax,%eax
801051d8:	75 43                	jne    8010521d <memset+0x50>
801051da:	8b 45 10             	mov    0x10(%ebp),%eax
801051dd:	83 e0 03             	and    $0x3,%eax
801051e0:	85 c0                	test   %eax,%eax
801051e2:	75 39                	jne    8010521d <memset+0x50>
    c &= 0xFF;
801051e4:	81 65 0c ff 00 00 00 	andl   $0xff,0xc(%ebp)
    stosl(dst, (c<<24)|(c<<16)|(c<<8)|c, n/4);
801051eb:	8b 45 10             	mov    0x10(%ebp),%eax
801051ee:	c1 e8 02             	shr    $0x2,%eax
801051f1:	89 c1                	mov    %eax,%ecx
801051f3:	8b 45 0c             	mov    0xc(%ebp),%eax
801051f6:	c1 e0 18             	shl    $0x18,%eax
801051f9:	89 c2                	mov    %eax,%edx
801051fb:	8b 45 0c             	mov    0xc(%ebp),%eax
801051fe:	c1 e0 10             	shl    $0x10,%eax
80105201:	09 c2                	or     %eax,%edx
80105203:	8b 45 0c             	mov    0xc(%ebp),%eax
80105206:	c1 e0 08             	shl    $0x8,%eax
80105209:	09 d0                	or     %edx,%eax
8010520b:	0b 45 0c             	or     0xc(%ebp),%eax
8010520e:	51                   	push   %ecx
8010520f:	50                   	push   %eax
80105210:	ff 75 08             	pushl  0x8(%ebp)
80105213:	e8 8f ff ff ff       	call   801051a7 <stosl>
80105218:	83 c4 0c             	add    $0xc,%esp
8010521b:	eb 12                	jmp    8010522f <memset+0x62>
  } else
    stosb(dst, c, n);
8010521d:	8b 45 10             	mov    0x10(%ebp),%eax
80105220:	50                   	push   %eax
80105221:	ff 75 0c             	pushl  0xc(%ebp)
80105224:	ff 75 08             	pushl  0x8(%ebp)
80105227:	e8 55 ff ff ff       	call   80105181 <stosb>
8010522c:	83 c4 0c             	add    $0xc,%esp
  return dst;
8010522f:	8b 45 08             	mov    0x8(%ebp),%eax
}
80105232:	c9                   	leave  
80105233:	c3                   	ret    

80105234 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
80105234:	55                   	push   %ebp
80105235:	89 e5                	mov    %esp,%ebp
80105237:	83 ec 10             	sub    $0x10,%esp
  const uchar *s1, *s2;

  s1 = v1;
8010523a:	8b 45 08             	mov    0x8(%ebp),%eax
8010523d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  s2 = v2;
80105240:	8b 45 0c             	mov    0xc(%ebp),%eax
80105243:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0){
80105246:	eb 30                	jmp    80105278 <memcmp+0x44>
    if(*s1 != *s2)
80105248:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010524b:	0f b6 10             	movzbl (%eax),%edx
8010524e:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105251:	0f b6 00             	movzbl (%eax),%eax
80105254:	38 c2                	cmp    %al,%dl
80105256:	74 18                	je     80105270 <memcmp+0x3c>
      return *s1 - *s2;
80105258:	8b 45 fc             	mov    -0x4(%ebp),%eax
8010525b:	0f b6 00             	movzbl (%eax),%eax
8010525e:	0f b6 d0             	movzbl %al,%edx
80105261:	8b 45 f8             	mov    -0x8(%ebp),%eax
80105264:	0f b6 00             	movzbl (%eax),%eax
80105267:	0f b6 c0             	movzbl %al,%eax
8010526a:	29 c2                	sub    %eax,%edx
8010526c:	89 d0                	mov    %edx,%eax
8010526e:	eb 1a                	jmp    8010528a <memcmp+0x56>
    s1++, s2++;
80105270:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
80105274:	83 45 f8 01          	addl   $0x1,-0x8(%ebp)
{
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
80105278:	8b 45 10             	mov    0x10(%ebp),%eax
8010527b:	8d 50 ff             	lea    -0x1(%eax),%edx
8010527e:	89 55 10             	mov    %edx,0x10(%ebp)
80105281:	85 c0                	test   %eax,%eax
80105283:	75 c3                	jne    80105248 <memcmp+0x14>
    if(*s1 != *s2)
      return *s1 - *s2;
    s1++, s2++;
  }

  return 0;
80105285:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010528a:	c9                   	leave  
8010528b:	c3                   	ret    

8010528c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
8010528c:	55                   	push   %ebp
8010528d:	89 e5                	mov    %esp,%ebp
8010528f:	83 ec 10             	sub    $0x10,%esp
  const char *s;
  char *d;

  s = src;
80105292:	8b 45 0c             	mov    0xc(%ebp),%eax
80105295:	89 45 fc             	mov    %eax,-0x4(%ebp)
  d = dst;
80105298:	8b 45 08             	mov    0x8(%ebp),%eax
8010529b:	89 45 f8             	mov    %eax,-0x8(%ebp)
  if(s < d && s + n > d){
8010529e:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052a1:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801052a4:	73 54                	jae    801052fa <memmove+0x6e>
801052a6:	8b 55 fc             	mov    -0x4(%ebp),%edx
801052a9:	8b 45 10             	mov    0x10(%ebp),%eax
801052ac:	01 d0                	add    %edx,%eax
801052ae:	3b 45 f8             	cmp    -0x8(%ebp),%eax
801052b1:	76 47                	jbe    801052fa <memmove+0x6e>
    s += n;
801052b3:	8b 45 10             	mov    0x10(%ebp),%eax
801052b6:	01 45 fc             	add    %eax,-0x4(%ebp)
    d += n;
801052b9:	8b 45 10             	mov    0x10(%ebp),%eax
801052bc:	01 45 f8             	add    %eax,-0x8(%ebp)
    while(n-- > 0)
801052bf:	eb 13                	jmp    801052d4 <memmove+0x48>
      *--d = *--s;
801052c1:	83 6d f8 01          	subl   $0x1,-0x8(%ebp)
801052c5:	83 6d fc 01          	subl   $0x1,-0x4(%ebp)
801052c9:	8b 45 fc             	mov    -0x4(%ebp),%eax
801052cc:	0f b6 10             	movzbl (%eax),%edx
801052cf:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052d2:	88 10                	mov    %dl,(%eax)
  s = src;
  d = dst;
  if(s < d && s + n > d){
    s += n;
    d += n;
    while(n-- > 0)
801052d4:	8b 45 10             	mov    0x10(%ebp),%eax
801052d7:	8d 50 ff             	lea    -0x1(%eax),%edx
801052da:	89 55 10             	mov    %edx,0x10(%ebp)
801052dd:	85 c0                	test   %eax,%eax
801052df:	75 e0                	jne    801052c1 <memmove+0x35>
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
801052e1:	eb 24                	jmp    80105307 <memmove+0x7b>
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
      *d++ = *s++;
801052e3:	8b 45 f8             	mov    -0x8(%ebp),%eax
801052e6:	8d 50 01             	lea    0x1(%eax),%edx
801052e9:	89 55 f8             	mov    %edx,-0x8(%ebp)
801052ec:	8b 55 fc             	mov    -0x4(%ebp),%edx
801052ef:	8d 4a 01             	lea    0x1(%edx),%ecx
801052f2:	89 4d fc             	mov    %ecx,-0x4(%ebp)
801052f5:	0f b6 12             	movzbl (%edx),%edx
801052f8:	88 10                	mov    %dl,(%eax)
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
801052fa:	8b 45 10             	mov    0x10(%ebp),%eax
801052fd:	8d 50 ff             	lea    -0x1(%eax),%edx
80105300:	89 55 10             	mov    %edx,0x10(%ebp)
80105303:	85 c0                	test   %eax,%eax
80105305:	75 dc                	jne    801052e3 <memmove+0x57>
      *d++ = *s++;

  return dst;
80105307:	8b 45 08             	mov    0x8(%ebp),%eax
}
8010530a:	c9                   	leave  
8010530b:	c3                   	ret    

8010530c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
8010530c:	55                   	push   %ebp
8010530d:	89 e5                	mov    %esp,%ebp
  return memmove(dst, src, n);
8010530f:	ff 75 10             	pushl  0x10(%ebp)
80105312:	ff 75 0c             	pushl  0xc(%ebp)
80105315:	ff 75 08             	pushl  0x8(%ebp)
80105318:	e8 6f ff ff ff       	call   8010528c <memmove>
8010531d:	83 c4 0c             	add    $0xc,%esp
}
80105320:	c9                   	leave  
80105321:	c3                   	ret    

80105322 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
80105322:	55                   	push   %ebp
80105323:	89 e5                	mov    %esp,%ebp
  while(n > 0 && *p && *p == *q)
80105325:	eb 0c                	jmp    80105333 <strncmp+0x11>
    n--, p++, q++;
80105327:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
8010532b:	83 45 08 01          	addl   $0x1,0x8(%ebp)
8010532f:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strncmp(const char *p, const char *q, uint n)
{
  while(n > 0 && *p && *p == *q)
80105333:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105337:	74 1a                	je     80105353 <strncmp+0x31>
80105339:	8b 45 08             	mov    0x8(%ebp),%eax
8010533c:	0f b6 00             	movzbl (%eax),%eax
8010533f:	84 c0                	test   %al,%al
80105341:	74 10                	je     80105353 <strncmp+0x31>
80105343:	8b 45 08             	mov    0x8(%ebp),%eax
80105346:	0f b6 10             	movzbl (%eax),%edx
80105349:	8b 45 0c             	mov    0xc(%ebp),%eax
8010534c:	0f b6 00             	movzbl (%eax),%eax
8010534f:	38 c2                	cmp    %al,%dl
80105351:	74 d4                	je     80105327 <strncmp+0x5>
    n--, p++, q++;
  if(n == 0)
80105353:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105357:	75 07                	jne    80105360 <strncmp+0x3e>
    return 0;
80105359:	b8 00 00 00 00       	mov    $0x0,%eax
8010535e:	eb 16                	jmp    80105376 <strncmp+0x54>
  return (uchar)*p - (uchar)*q;
80105360:	8b 45 08             	mov    0x8(%ebp),%eax
80105363:	0f b6 00             	movzbl (%eax),%eax
80105366:	0f b6 d0             	movzbl %al,%edx
80105369:	8b 45 0c             	mov    0xc(%ebp),%eax
8010536c:	0f b6 00             	movzbl (%eax),%eax
8010536f:	0f b6 c0             	movzbl %al,%eax
80105372:	29 c2                	sub    %eax,%edx
80105374:	89 d0                	mov    %edx,%eax
}
80105376:	5d                   	pop    %ebp
80105377:	c3                   	ret    

80105378 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
80105378:	55                   	push   %ebp
80105379:	89 e5                	mov    %esp,%ebp
8010537b:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
8010537e:	8b 45 08             	mov    0x8(%ebp),%eax
80105381:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while(n-- > 0 && (*s++ = *t++) != 0)
80105384:	90                   	nop
80105385:	8b 45 10             	mov    0x10(%ebp),%eax
80105388:	8d 50 ff             	lea    -0x1(%eax),%edx
8010538b:	89 55 10             	mov    %edx,0x10(%ebp)
8010538e:	85 c0                	test   %eax,%eax
80105390:	7e 2c                	jle    801053be <strncpy+0x46>
80105392:	8b 45 08             	mov    0x8(%ebp),%eax
80105395:	8d 50 01             	lea    0x1(%eax),%edx
80105398:	89 55 08             	mov    %edx,0x8(%ebp)
8010539b:	8b 55 0c             	mov    0xc(%ebp),%edx
8010539e:	8d 4a 01             	lea    0x1(%edx),%ecx
801053a1:	89 4d 0c             	mov    %ecx,0xc(%ebp)
801053a4:	0f b6 12             	movzbl (%edx),%edx
801053a7:	88 10                	mov    %dl,(%eax)
801053a9:	0f b6 00             	movzbl (%eax),%eax
801053ac:	84 c0                	test   %al,%al
801053ae:	75 d5                	jne    80105385 <strncpy+0xd>
    ;
  while(n-- > 0)
801053b0:	eb 0c                	jmp    801053be <strncpy+0x46>
    *s++ = 0;
801053b2:	8b 45 08             	mov    0x8(%ebp),%eax
801053b5:	8d 50 01             	lea    0x1(%eax),%edx
801053b8:	89 55 08             	mov    %edx,0x8(%ebp)
801053bb:	c6 00 00             	movb   $0x0,(%eax)
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    ;
  while(n-- > 0)
801053be:	8b 45 10             	mov    0x10(%ebp),%eax
801053c1:	8d 50 ff             	lea    -0x1(%eax),%edx
801053c4:	89 55 10             	mov    %edx,0x10(%ebp)
801053c7:	85 c0                	test   %eax,%eax
801053c9:	7f e7                	jg     801053b2 <strncpy+0x3a>
    *s++ = 0;
  return os;
801053cb:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
801053ce:	c9                   	leave  
801053cf:	c3                   	ret    

801053d0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
801053d0:	55                   	push   %ebp
801053d1:	89 e5                	mov    %esp,%ebp
801053d3:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
801053d6:	8b 45 08             	mov    0x8(%ebp),%eax
801053d9:	89 45 fc             	mov    %eax,-0x4(%ebp)
  if(n <= 0)
801053dc:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053e0:	7f 05                	jg     801053e7 <safestrcpy+0x17>
    return os;
801053e2:	8b 45 fc             	mov    -0x4(%ebp),%eax
801053e5:	eb 31                	jmp    80105418 <safestrcpy+0x48>
  while(--n > 0 && (*s++ = *t++) != 0)
801053e7:	83 6d 10 01          	subl   $0x1,0x10(%ebp)
801053eb:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801053ef:	7e 1e                	jle    8010540f <safestrcpy+0x3f>
801053f1:	8b 45 08             	mov    0x8(%ebp),%eax
801053f4:	8d 50 01             	lea    0x1(%eax),%edx
801053f7:	89 55 08             	mov    %edx,0x8(%ebp)
801053fa:	8b 55 0c             	mov    0xc(%ebp),%edx
801053fd:	8d 4a 01             	lea    0x1(%edx),%ecx
80105400:	89 4d 0c             	mov    %ecx,0xc(%ebp)
80105403:	0f b6 12             	movzbl (%edx),%edx
80105406:	88 10                	mov    %dl,(%eax)
80105408:	0f b6 00             	movzbl (%eax),%eax
8010540b:	84 c0                	test   %al,%al
8010540d:	75 d8                	jne    801053e7 <safestrcpy+0x17>
    ;
  *s = 0;
8010540f:	8b 45 08             	mov    0x8(%ebp),%eax
80105412:	c6 00 00             	movb   $0x0,(%eax)
  return os;
80105415:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80105418:	c9                   	leave  
80105419:	c3                   	ret    

8010541a <strlen>:

int
strlen(const char *s)
{
8010541a:	55                   	push   %ebp
8010541b:	89 e5                	mov    %esp,%ebp
8010541d:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
80105420:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
80105427:	eb 04                	jmp    8010542d <strlen+0x13>
80105429:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
8010542d:	8b 55 fc             	mov    -0x4(%ebp),%edx
80105430:	8b 45 08             	mov    0x8(%ebp),%eax
80105433:	01 d0                	add    %edx,%eax
80105435:	0f b6 00             	movzbl (%eax),%eax
80105438:	84 c0                	test   %al,%al
8010543a:	75 ed                	jne    80105429 <strlen+0xf>
    ;
  return n;
8010543c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
8010543f:	c9                   	leave  
80105440:	c3                   	ret    

80105441 <swtch>:
# Save current register context in old
# and then load register context from new.

.globl swtch
swtch:
  movl 4(%esp), %eax
80105441:	8b 44 24 04          	mov    0x4(%esp),%eax
  movl 8(%esp), %edx
80105445:	8b 54 24 08          	mov    0x8(%esp),%edx

  # Save old callee-save registers
  pushl %ebp
80105449:	55                   	push   %ebp
  pushl %ebx
8010544a:	53                   	push   %ebx
  pushl %esi
8010544b:	56                   	push   %esi
  pushl %edi
8010544c:	57                   	push   %edi

  # Switch stacks
  movl %esp, (%eax)
8010544d:	89 20                	mov    %esp,(%eax)
  movl %edx, %esp
8010544f:	89 d4                	mov    %edx,%esp

  # Load new callee-save registers
  popl %edi
80105451:	5f                   	pop    %edi
  popl %esi
80105452:	5e                   	pop    %esi
  popl %ebx
80105453:	5b                   	pop    %ebx
  popl %ebp
80105454:	5d                   	pop    %ebp
  ret
80105455:	c3                   	ret    

80105456 <fetchint>:
// to a saved program counter, and then the first argument.

// Fetch the int at addr from the current process.
int
fetchint(uint addr, int *ip)
{
80105456:	55                   	push   %ebp
80105457:	89 e5                	mov    %esp,%ebp
80105459:	83 ec 18             	sub    $0x18,%esp
  struct proc *curproc = myproc();
8010545c:	e8 27 ee ff ff       	call   80104288 <myproc>
80105461:	89 45 f4             	mov    %eax,-0xc(%ebp)

  if(addr >= curproc->sz || addr+4 > curproc->sz)
80105464:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105467:	8b 00                	mov    (%eax),%eax
80105469:	3b 45 08             	cmp    0x8(%ebp),%eax
8010546c:	76 0f                	jbe    8010547d <fetchint+0x27>
8010546e:	8b 45 08             	mov    0x8(%ebp),%eax
80105471:	8d 50 04             	lea    0x4(%eax),%edx
80105474:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105477:	8b 00                	mov    (%eax),%eax
80105479:	39 c2                	cmp    %eax,%edx
8010547b:	76 07                	jbe    80105484 <fetchint+0x2e>
    return -1;
8010547d:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105482:	eb 0f                	jmp    80105493 <fetchint+0x3d>
  *ip = *(int*)(addr);
80105484:	8b 45 08             	mov    0x8(%ebp),%eax
80105487:	8b 10                	mov    (%eax),%edx
80105489:	8b 45 0c             	mov    0xc(%ebp),%eax
8010548c:	89 10                	mov    %edx,(%eax)
  return 0;
8010548e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105493:	c9                   	leave  
80105494:	c3                   	ret    

80105495 <fetchstr>:
// Fetch the nul-terminated string at addr from the current process.
// Doesn't actually copy the string - just sets *pp to point at it.
// Returns length of string, not including nul.
int
fetchstr(uint addr, char **pp)
{
80105495:	55                   	push   %ebp
80105496:	89 e5                	mov    %esp,%ebp
80105498:	83 ec 18             	sub    $0x18,%esp
  char *s, *ep;
  struct proc *curproc = myproc();
8010549b:	e8 e8 ed ff ff       	call   80104288 <myproc>
801054a0:	89 45 f0             	mov    %eax,-0x10(%ebp)

  if(addr >= curproc->sz)
801054a3:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054a6:	8b 00                	mov    (%eax),%eax
801054a8:	3b 45 08             	cmp    0x8(%ebp),%eax
801054ab:	77 07                	ja     801054b4 <fetchstr+0x1f>
    return -1;
801054ad:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801054b2:	eb 43                	jmp    801054f7 <fetchstr+0x62>
  *pp = (char*)addr;
801054b4:	8b 55 08             	mov    0x8(%ebp),%edx
801054b7:	8b 45 0c             	mov    0xc(%ebp),%eax
801054ba:	89 10                	mov    %edx,(%eax)
  ep = (char*)curproc->sz;
801054bc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801054bf:	8b 00                	mov    (%eax),%eax
801054c1:	89 45 ec             	mov    %eax,-0x14(%ebp)
  for(s = *pp; s < ep; s++){
801054c4:	8b 45 0c             	mov    0xc(%ebp),%eax
801054c7:	8b 00                	mov    (%eax),%eax
801054c9:	89 45 f4             	mov    %eax,-0xc(%ebp)
801054cc:	eb 1c                	jmp    801054ea <fetchstr+0x55>
    if(*s == 0)
801054ce:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054d1:	0f b6 00             	movzbl (%eax),%eax
801054d4:	84 c0                	test   %al,%al
801054d6:	75 0e                	jne    801054e6 <fetchstr+0x51>
      return s - *pp;
801054d8:	8b 55 f4             	mov    -0xc(%ebp),%edx
801054db:	8b 45 0c             	mov    0xc(%ebp),%eax
801054de:	8b 00                	mov    (%eax),%eax
801054e0:	29 c2                	sub    %eax,%edx
801054e2:	89 d0                	mov    %edx,%eax
801054e4:	eb 11                	jmp    801054f7 <fetchstr+0x62>

  if(addr >= curproc->sz)
    return -1;
  *pp = (char*)addr;
  ep = (char*)curproc->sz;
  for(s = *pp; s < ep; s++){
801054e6:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801054ea:	8b 45 f4             	mov    -0xc(%ebp),%eax
801054ed:	3b 45 ec             	cmp    -0x14(%ebp),%eax
801054f0:	72 dc                	jb     801054ce <fetchstr+0x39>
    if(*s == 0)
      return s - *pp;
  }
  return -1;
801054f2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
801054f7:	c9                   	leave  
801054f8:	c3                   	ret    

801054f9 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
801054f9:	55                   	push   %ebp
801054fa:	89 e5                	mov    %esp,%ebp
801054fc:	83 ec 08             	sub    $0x8,%esp
  return fetchint((myproc()->tf->esp) + 4 + 4*n, ip);
801054ff:	e8 84 ed ff ff       	call   80104288 <myproc>
80105504:	8b 40 18             	mov    0x18(%eax),%eax
80105507:	8b 40 44             	mov    0x44(%eax),%eax
8010550a:	8b 55 08             	mov    0x8(%ebp),%edx
8010550d:	c1 e2 02             	shl    $0x2,%edx
80105510:	01 d0                	add    %edx,%eax
80105512:	83 c0 04             	add    $0x4,%eax
80105515:	83 ec 08             	sub    $0x8,%esp
80105518:	ff 75 0c             	pushl  0xc(%ebp)
8010551b:	50                   	push   %eax
8010551c:	e8 35 ff ff ff       	call   80105456 <fetchint>
80105521:	83 c4 10             	add    $0x10,%esp
}
80105524:	c9                   	leave  
80105525:	c3                   	ret    

80105526 <argptr>:
// Fetch the nth word-sized system call argument as a pointer
// to a block of memory of size bytes.  Check that the pointer
// lies within the process address space.
int
argptr(int n, char **pp, int size)
{
80105526:	55                   	push   %ebp
80105527:	89 e5                	mov    %esp,%ebp
80105529:	83 ec 18             	sub    $0x18,%esp
  int i;
  struct proc *curproc = myproc();
8010552c:	e8 57 ed ff ff       	call   80104288 <myproc>
80105531:	89 45 f4             	mov    %eax,-0xc(%ebp)
 
  if(argint(n, &i) < 0)
80105534:	83 ec 08             	sub    $0x8,%esp
80105537:	8d 45 f0             	lea    -0x10(%ebp),%eax
8010553a:	50                   	push   %eax
8010553b:	ff 75 08             	pushl  0x8(%ebp)
8010553e:	e8 b6 ff ff ff       	call   801054f9 <argint>
80105543:	83 c4 10             	add    $0x10,%esp
80105546:	85 c0                	test   %eax,%eax
80105548:	79 07                	jns    80105551 <argptr+0x2b>
    return -1;
8010554a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010554f:	eb 3b                	jmp    8010558c <argptr+0x66>
  if(size < 0 || (uint)i >= curproc->sz || (uint)i+size > curproc->sz)
80105551:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80105555:	78 1f                	js     80105576 <argptr+0x50>
80105557:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010555a:	8b 00                	mov    (%eax),%eax
8010555c:	8b 55 f0             	mov    -0x10(%ebp),%edx
8010555f:	39 d0                	cmp    %edx,%eax
80105561:	76 13                	jbe    80105576 <argptr+0x50>
80105563:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105566:	89 c2                	mov    %eax,%edx
80105568:	8b 45 10             	mov    0x10(%ebp),%eax
8010556b:	01 c2                	add    %eax,%edx
8010556d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105570:	8b 00                	mov    (%eax),%eax
80105572:	39 c2                	cmp    %eax,%edx
80105574:	76 07                	jbe    8010557d <argptr+0x57>
    return -1;
80105576:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010557b:	eb 0f                	jmp    8010558c <argptr+0x66>
  *pp = (char*)i;
8010557d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105580:	89 c2                	mov    %eax,%edx
80105582:	8b 45 0c             	mov    0xc(%ebp),%eax
80105585:	89 10                	mov    %edx,(%eax)
  return 0;
80105587:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010558c:	c9                   	leave  
8010558d:	c3                   	ret    

8010558e <argstr>:
// Check that the pointer is valid and the string is nul-terminated.
// (There is no shared writable memory, so the string can't change
// between this check and being used by the kernel.)
int
argstr(int n, char **pp)
{
8010558e:	55                   	push   %ebp
8010558f:	89 e5                	mov    %esp,%ebp
80105591:	83 ec 18             	sub    $0x18,%esp
  int addr;
  if(argint(n, &addr) < 0)
80105594:	83 ec 08             	sub    $0x8,%esp
80105597:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010559a:	50                   	push   %eax
8010559b:	ff 75 08             	pushl  0x8(%ebp)
8010559e:	e8 56 ff ff ff       	call   801054f9 <argint>
801055a3:	83 c4 10             	add    $0x10,%esp
801055a6:	85 c0                	test   %eax,%eax
801055a8:	79 07                	jns    801055b1 <argstr+0x23>
    return -1;
801055aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801055af:	eb 12                	jmp    801055c3 <argstr+0x35>
  return fetchstr(addr, pp);
801055b1:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055b4:	83 ec 08             	sub    $0x8,%esp
801055b7:	ff 75 0c             	pushl  0xc(%ebp)
801055ba:	50                   	push   %eax
801055bb:	e8 d5 fe ff ff       	call   80105495 <fetchstr>
801055c0:	83 c4 10             	add    $0x10,%esp
}
801055c3:	c9                   	leave  
801055c4:	c3                   	ret    

801055c5 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
801055c5:	55                   	push   %ebp
801055c6:	89 e5                	mov    %esp,%ebp
801055c8:	53                   	push   %ebx
801055c9:	83 ec 14             	sub    $0x14,%esp
  int num;
  struct proc *curproc = myproc();
801055cc:	e8 b7 ec ff ff       	call   80104288 <myproc>
801055d1:	89 45 f4             	mov    %eax,-0xc(%ebp)

  num = curproc->tf->eax;
801055d4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055d7:	8b 40 18             	mov    0x18(%eax),%eax
801055da:	8b 40 1c             	mov    0x1c(%eax),%eax
801055dd:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
801055e0:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801055e4:	7e 2d                	jle    80105613 <syscall+0x4e>
801055e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055e9:	83 f8 15             	cmp    $0x15,%eax
801055ec:	77 25                	ja     80105613 <syscall+0x4e>
801055ee:	8b 45 f0             	mov    -0x10(%ebp),%eax
801055f1:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
801055f8:	85 c0                	test   %eax,%eax
801055fa:	74 17                	je     80105613 <syscall+0x4e>
    curproc->tf->eax = syscalls[num]();
801055fc:	8b 45 f4             	mov    -0xc(%ebp),%eax
801055ff:	8b 58 18             	mov    0x18(%eax),%ebx
80105602:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105605:	8b 04 85 20 b0 10 80 	mov    -0x7fef4fe0(,%eax,4),%eax
8010560c:	ff d0                	call   *%eax
8010560e:	89 43 1c             	mov    %eax,0x1c(%ebx)
80105611:	eb 2b                	jmp    8010563e <syscall+0x79>
  } else {
    cprintf("%d %s: unknown sys call %d\n",
            curproc->pid, curproc->name, num);
80105613:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105616:	8d 50 6c             	lea    0x6c(%eax),%edx

  num = curproc->tf->eax;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    curproc->tf->eax = syscalls[num]();
  } else {
    cprintf("%d %s: unknown sys call %d\n",
80105619:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010561c:	8b 40 10             	mov    0x10(%eax),%eax
8010561f:	ff 75 f0             	pushl  -0x10(%ebp)
80105622:	52                   	push   %edx
80105623:	50                   	push   %eax
80105624:	68 fc 88 10 80       	push   $0x801088fc
80105629:	e8 d2 ad ff ff       	call   80100400 <cprintf>
8010562e:	83 c4 10             	add    $0x10,%esp
            curproc->pid, curproc->name, num);
    curproc->tf->eax = -1;
80105631:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105634:	8b 40 18             	mov    0x18(%eax),%eax
80105637:	c7 40 1c ff ff ff ff 	movl   $0xffffffff,0x1c(%eax)
  }
}
8010563e:	90                   	nop
8010563f:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80105642:	c9                   	leave  
80105643:	c3                   	ret    

80105644 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
80105644:	55                   	push   %ebp
80105645:	89 e5                	mov    %esp,%ebp
80105647:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
8010564a:	83 ec 08             	sub    $0x8,%esp
8010564d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105650:	50                   	push   %eax
80105651:	ff 75 08             	pushl  0x8(%ebp)
80105654:	e8 a0 fe ff ff       	call   801054f9 <argint>
80105659:	83 c4 10             	add    $0x10,%esp
8010565c:	85 c0                	test   %eax,%eax
8010565e:	79 07                	jns    80105667 <argfd+0x23>
    return -1;
80105660:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105665:	eb 51                	jmp    801056b8 <argfd+0x74>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
80105667:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010566a:	85 c0                	test   %eax,%eax
8010566c:	78 22                	js     80105690 <argfd+0x4c>
8010566e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105671:	83 f8 0f             	cmp    $0xf,%eax
80105674:	7f 1a                	jg     80105690 <argfd+0x4c>
80105676:	e8 0d ec ff ff       	call   80104288 <myproc>
8010567b:	89 c2                	mov    %eax,%edx
8010567d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105680:	83 c0 08             	add    $0x8,%eax
80105683:	8b 44 82 08          	mov    0x8(%edx,%eax,4),%eax
80105687:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010568a:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010568e:	75 07                	jne    80105697 <argfd+0x53>
    return -1;
80105690:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105695:	eb 21                	jmp    801056b8 <argfd+0x74>
  if(pfd)
80105697:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
8010569b:	74 08                	je     801056a5 <argfd+0x61>
    *pfd = fd;
8010569d:	8b 55 f0             	mov    -0x10(%ebp),%edx
801056a0:	8b 45 0c             	mov    0xc(%ebp),%eax
801056a3:	89 10                	mov    %edx,(%eax)
  if(pf)
801056a5:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
801056a9:	74 08                	je     801056b3 <argfd+0x6f>
    *pf = f;
801056ab:	8b 45 10             	mov    0x10(%ebp),%eax
801056ae:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056b1:	89 10                	mov    %edx,(%eax)
  return 0;
801056b3:	b8 00 00 00 00       	mov    $0x0,%eax
}
801056b8:	c9                   	leave  
801056b9:	c3                   	ret    

801056ba <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
801056ba:	55                   	push   %ebp
801056bb:	89 e5                	mov    %esp,%ebp
801056bd:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct proc *curproc = myproc();
801056c0:	e8 c3 eb ff ff       	call   80104288 <myproc>
801056c5:	89 45 f0             	mov    %eax,-0x10(%ebp)

  for(fd = 0; fd < NOFILE; fd++){
801056c8:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801056cf:	eb 2a                	jmp    801056fb <fdalloc+0x41>
    if(curproc->ofile[fd] == 0){
801056d1:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056d4:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056d7:	83 c2 08             	add    $0x8,%edx
801056da:	8b 44 90 08          	mov    0x8(%eax,%edx,4),%eax
801056de:	85 c0                	test   %eax,%eax
801056e0:	75 15                	jne    801056f7 <fdalloc+0x3d>
      curproc->ofile[fd] = f;
801056e2:	8b 45 f0             	mov    -0x10(%ebp),%eax
801056e5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801056e8:	8d 4a 08             	lea    0x8(%edx),%ecx
801056eb:	8b 55 08             	mov    0x8(%ebp),%edx
801056ee:	89 54 88 08          	mov    %edx,0x8(%eax,%ecx,4)
      return fd;
801056f2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801056f5:	eb 0f                	jmp    80105706 <fdalloc+0x4c>
fdalloc(struct file *f)
{
  int fd;
  struct proc *curproc = myproc();

  for(fd = 0; fd < NOFILE; fd++){
801056f7:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
801056fb:	83 7d f4 0f          	cmpl   $0xf,-0xc(%ebp)
801056ff:	7e d0                	jle    801056d1 <fdalloc+0x17>
    if(curproc->ofile[fd] == 0){
      curproc->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
80105701:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105706:	c9                   	leave  
80105707:	c3                   	ret    

80105708 <sys_dup>:

int
sys_dup(void)
{
80105708:	55                   	push   %ebp
80105709:	89 e5                	mov    %esp,%ebp
8010570b:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int fd;

  if(argfd(0, 0, &f) < 0)
8010570e:	83 ec 04             	sub    $0x4,%esp
80105711:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105714:	50                   	push   %eax
80105715:	6a 00                	push   $0x0
80105717:	6a 00                	push   $0x0
80105719:	e8 26 ff ff ff       	call   80105644 <argfd>
8010571e:	83 c4 10             	add    $0x10,%esp
80105721:	85 c0                	test   %eax,%eax
80105723:	79 07                	jns    8010572c <sys_dup+0x24>
    return -1;
80105725:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010572a:	eb 31                	jmp    8010575d <sys_dup+0x55>
  if((fd=fdalloc(f)) < 0)
8010572c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010572f:	83 ec 0c             	sub    $0xc,%esp
80105732:	50                   	push   %eax
80105733:	e8 82 ff ff ff       	call   801056ba <fdalloc>
80105738:	83 c4 10             	add    $0x10,%esp
8010573b:	89 45 f4             	mov    %eax,-0xc(%ebp)
8010573e:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105742:	79 07                	jns    8010574b <sys_dup+0x43>
    return -1;
80105744:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105749:	eb 12                	jmp    8010575d <sys_dup+0x55>
  filedup(f);
8010574b:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010574e:	83 ec 0c             	sub    $0xc,%esp
80105751:	50                   	push   %eax
80105752:	e8 09 b9 ff ff       	call   80101060 <filedup>
80105757:	83 c4 10             	add    $0x10,%esp
  return fd;
8010575a:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
8010575d:	c9                   	leave  
8010575e:	c3                   	ret    

8010575f <sys_read>:

int
sys_read(void)
{
8010575f:	55                   	push   %ebp
80105760:	89 e5                	mov    %esp,%ebp
80105762:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
80105765:	83 ec 04             	sub    $0x4,%esp
80105768:	8d 45 f4             	lea    -0xc(%ebp),%eax
8010576b:	50                   	push   %eax
8010576c:	6a 00                	push   $0x0
8010576e:	6a 00                	push   $0x0
80105770:	e8 cf fe ff ff       	call   80105644 <argfd>
80105775:	83 c4 10             	add    $0x10,%esp
80105778:	85 c0                	test   %eax,%eax
8010577a:	78 2e                	js     801057aa <sys_read+0x4b>
8010577c:	83 ec 08             	sub    $0x8,%esp
8010577f:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105782:	50                   	push   %eax
80105783:	6a 02                	push   $0x2
80105785:	e8 6f fd ff ff       	call   801054f9 <argint>
8010578a:	83 c4 10             	add    $0x10,%esp
8010578d:	85 c0                	test   %eax,%eax
8010578f:	78 19                	js     801057aa <sys_read+0x4b>
80105791:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105794:	83 ec 04             	sub    $0x4,%esp
80105797:	50                   	push   %eax
80105798:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010579b:	50                   	push   %eax
8010579c:	6a 01                	push   $0x1
8010579e:	e8 83 fd ff ff       	call   80105526 <argptr>
801057a3:	83 c4 10             	add    $0x10,%esp
801057a6:	85 c0                	test   %eax,%eax
801057a8:	79 07                	jns    801057b1 <sys_read+0x52>
    return -1;
801057aa:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801057af:	eb 17                	jmp    801057c8 <sys_read+0x69>
  return fileread(f, p, n);
801057b1:	8b 4d f0             	mov    -0x10(%ebp),%ecx
801057b4:	8b 55 ec             	mov    -0x14(%ebp),%edx
801057b7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801057ba:	83 ec 04             	sub    $0x4,%esp
801057bd:	51                   	push   %ecx
801057be:	52                   	push   %edx
801057bf:	50                   	push   %eax
801057c0:	e8 2b ba ff ff       	call   801011f0 <fileread>
801057c5:	83 c4 10             	add    $0x10,%esp
}
801057c8:	c9                   	leave  
801057c9:	c3                   	ret    

801057ca <sys_write>:

int
sys_write(void)
{
801057ca:	55                   	push   %ebp
801057cb:	89 e5                	mov    %esp,%ebp
801057cd:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  int n;
  char *p;

  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argptr(1, &p, n) < 0)
801057d0:	83 ec 04             	sub    $0x4,%esp
801057d3:	8d 45 f4             	lea    -0xc(%ebp),%eax
801057d6:	50                   	push   %eax
801057d7:	6a 00                	push   $0x0
801057d9:	6a 00                	push   $0x0
801057db:	e8 64 fe ff ff       	call   80105644 <argfd>
801057e0:	83 c4 10             	add    $0x10,%esp
801057e3:	85 c0                	test   %eax,%eax
801057e5:	78 2e                	js     80105815 <sys_write+0x4b>
801057e7:	83 ec 08             	sub    $0x8,%esp
801057ea:	8d 45 f0             	lea    -0x10(%ebp),%eax
801057ed:	50                   	push   %eax
801057ee:	6a 02                	push   $0x2
801057f0:	e8 04 fd ff ff       	call   801054f9 <argint>
801057f5:	83 c4 10             	add    $0x10,%esp
801057f8:	85 c0                	test   %eax,%eax
801057fa:	78 19                	js     80105815 <sys_write+0x4b>
801057fc:	8b 45 f0             	mov    -0x10(%ebp),%eax
801057ff:	83 ec 04             	sub    $0x4,%esp
80105802:	50                   	push   %eax
80105803:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105806:	50                   	push   %eax
80105807:	6a 01                	push   $0x1
80105809:	e8 18 fd ff ff       	call   80105526 <argptr>
8010580e:	83 c4 10             	add    $0x10,%esp
80105811:	85 c0                	test   %eax,%eax
80105813:	79 07                	jns    8010581c <sys_write+0x52>
    return -1;
80105815:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010581a:	eb 17                	jmp    80105833 <sys_write+0x69>
  return filewrite(f, p, n);
8010581c:	8b 4d f0             	mov    -0x10(%ebp),%ecx
8010581f:	8b 55 ec             	mov    -0x14(%ebp),%edx
80105822:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105825:	83 ec 04             	sub    $0x4,%esp
80105828:	51                   	push   %ecx
80105829:	52                   	push   %edx
8010582a:	50                   	push   %eax
8010582b:	e8 78 ba ff ff       	call   801012a8 <filewrite>
80105830:	83 c4 10             	add    $0x10,%esp
}
80105833:	c9                   	leave  
80105834:	c3                   	ret    

80105835 <sys_close>:

int
sys_close(void)
{
80105835:	55                   	push   %ebp
80105836:	89 e5                	mov    %esp,%ebp
80105838:	83 ec 18             	sub    $0x18,%esp
  int fd;
  struct file *f;

  if(argfd(0, &fd, &f) < 0)
8010583b:	83 ec 04             	sub    $0x4,%esp
8010583e:	8d 45 f0             	lea    -0x10(%ebp),%eax
80105841:	50                   	push   %eax
80105842:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105845:	50                   	push   %eax
80105846:	6a 00                	push   $0x0
80105848:	e8 f7 fd ff ff       	call   80105644 <argfd>
8010584d:	83 c4 10             	add    $0x10,%esp
80105850:	85 c0                	test   %eax,%eax
80105852:	79 07                	jns    8010585b <sys_close+0x26>
    return -1;
80105854:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105859:	eb 29                	jmp    80105884 <sys_close+0x4f>
  myproc()->ofile[fd] = 0;
8010585b:	e8 28 ea ff ff       	call   80104288 <myproc>
80105860:	89 c2                	mov    %eax,%edx
80105862:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105865:	83 c0 08             	add    $0x8,%eax
80105868:	c7 44 82 08 00 00 00 	movl   $0x0,0x8(%edx,%eax,4)
8010586f:	00 
  fileclose(f);
80105870:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105873:	83 ec 0c             	sub    $0xc,%esp
80105876:	50                   	push   %eax
80105877:	e8 35 b8 ff ff       	call   801010b1 <fileclose>
8010587c:	83 c4 10             	add    $0x10,%esp
  return 0;
8010587f:	b8 00 00 00 00       	mov    $0x0,%eax
}
80105884:	c9                   	leave  
80105885:	c3                   	ret    

80105886 <sys_fstat>:

int
sys_fstat(void)
{
80105886:	55                   	push   %ebp
80105887:	89 e5                	mov    %esp,%ebp
80105889:	83 ec 18             	sub    $0x18,%esp
  struct file *f;
  struct stat *st;

  if(argfd(0, 0, &f) < 0 || argptr(1, (void*)&st, sizeof(*st)) < 0)
8010588c:	83 ec 04             	sub    $0x4,%esp
8010588f:	8d 45 f4             	lea    -0xc(%ebp),%eax
80105892:	50                   	push   %eax
80105893:	6a 00                	push   $0x0
80105895:	6a 00                	push   $0x0
80105897:	e8 a8 fd ff ff       	call   80105644 <argfd>
8010589c:	83 c4 10             	add    $0x10,%esp
8010589f:	85 c0                	test   %eax,%eax
801058a1:	78 17                	js     801058ba <sys_fstat+0x34>
801058a3:	83 ec 04             	sub    $0x4,%esp
801058a6:	6a 14                	push   $0x14
801058a8:	8d 45 f0             	lea    -0x10(%ebp),%eax
801058ab:	50                   	push   %eax
801058ac:	6a 01                	push   $0x1
801058ae:	e8 73 fc ff ff       	call   80105526 <argptr>
801058b3:	83 c4 10             	add    $0x10,%esp
801058b6:	85 c0                	test   %eax,%eax
801058b8:	79 07                	jns    801058c1 <sys_fstat+0x3b>
    return -1;
801058ba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801058bf:	eb 13                	jmp    801058d4 <sys_fstat+0x4e>
  return filestat(f, st);
801058c1:	8b 55 f0             	mov    -0x10(%ebp),%edx
801058c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801058c7:	83 ec 08             	sub    $0x8,%esp
801058ca:	52                   	push   %edx
801058cb:	50                   	push   %eax
801058cc:	e8 c8 b8 ff ff       	call   80101199 <filestat>
801058d1:	83 c4 10             	add    $0x10,%esp
}
801058d4:	c9                   	leave  
801058d5:	c3                   	ret    

801058d6 <sys_link>:

// Create the path new as a link to the same inode as old.
int
sys_link(void)
{
801058d6:	55                   	push   %ebp
801058d7:	89 e5                	mov    %esp,%ebp
801058d9:	83 ec 28             	sub    $0x28,%esp
  char name[DIRSIZ], *new, *old;
  struct inode *dp, *ip;

  if(argstr(0, &old) < 0 || argstr(1, &new) < 0)
801058dc:	83 ec 08             	sub    $0x8,%esp
801058df:	8d 45 d8             	lea    -0x28(%ebp),%eax
801058e2:	50                   	push   %eax
801058e3:	6a 00                	push   $0x0
801058e5:	e8 a4 fc ff ff       	call   8010558e <argstr>
801058ea:	83 c4 10             	add    $0x10,%esp
801058ed:	85 c0                	test   %eax,%eax
801058ef:	78 15                	js     80105906 <sys_link+0x30>
801058f1:	83 ec 08             	sub    $0x8,%esp
801058f4:	8d 45 dc             	lea    -0x24(%ebp),%eax
801058f7:	50                   	push   %eax
801058f8:	6a 01                	push   $0x1
801058fa:	e8 8f fc ff ff       	call   8010558e <argstr>
801058ff:	83 c4 10             	add    $0x10,%esp
80105902:	85 c0                	test   %eax,%eax
80105904:	79 0a                	jns    80105910 <sys_link+0x3a>
    return -1;
80105906:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010590b:	e9 68 01 00 00       	jmp    80105a78 <sys_link+0x1a2>

  begin_op();
80105910:	e8 20 dc ff ff       	call   80103535 <begin_op>
  if((ip = namei(old)) == 0){
80105915:	8b 45 d8             	mov    -0x28(%ebp),%eax
80105918:	83 ec 0c             	sub    $0xc,%esp
8010591b:	50                   	push   %eax
8010591c:	e8 2f cc ff ff       	call   80102550 <namei>
80105921:	83 c4 10             	add    $0x10,%esp
80105924:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105927:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
8010592b:	75 0f                	jne    8010593c <sys_link+0x66>
    end_op();
8010592d:	e8 8f dc ff ff       	call   801035c1 <end_op>
    return -1;
80105932:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105937:	e9 3c 01 00 00       	jmp    80105a78 <sys_link+0x1a2>
  }

  ilock(ip);
8010593c:	83 ec 0c             	sub    $0xc,%esp
8010593f:	ff 75 f4             	pushl  -0xc(%ebp)
80105942:	e8 c9 c0 ff ff       	call   80101a10 <ilock>
80105947:	83 c4 10             	add    $0x10,%esp
  if(ip->type == T_DIR){
8010594a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010594d:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105951:	66 83 f8 01          	cmp    $0x1,%ax
80105955:	75 1d                	jne    80105974 <sys_link+0x9e>
    iunlockput(ip);
80105957:	83 ec 0c             	sub    $0xc,%esp
8010595a:	ff 75 f4             	pushl  -0xc(%ebp)
8010595d:	e8 df c2 ff ff       	call   80101c41 <iunlockput>
80105962:	83 c4 10             	add    $0x10,%esp
    end_op();
80105965:	e8 57 dc ff ff       	call   801035c1 <end_op>
    return -1;
8010596a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010596f:	e9 04 01 00 00       	jmp    80105a78 <sys_link+0x1a2>
  }

  ip->nlink++;
80105974:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105977:	0f b7 40 56          	movzwl 0x56(%eax),%eax
8010597b:	83 c0 01             	add    $0x1,%eax
8010597e:	89 c2                	mov    %eax,%edx
80105980:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105983:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105987:	83 ec 0c             	sub    $0xc,%esp
8010598a:	ff 75 f4             	pushl  -0xc(%ebp)
8010598d:	e8 a1 be ff ff       	call   80101833 <iupdate>
80105992:	83 c4 10             	add    $0x10,%esp
  iunlock(ip);
80105995:	83 ec 0c             	sub    $0xc,%esp
80105998:	ff 75 f4             	pushl  -0xc(%ebp)
8010599b:	e8 83 c1 ff ff       	call   80101b23 <iunlock>
801059a0:	83 c4 10             	add    $0x10,%esp

  if((dp = nameiparent(new, name)) == 0)
801059a3:	8b 45 dc             	mov    -0x24(%ebp),%eax
801059a6:	83 ec 08             	sub    $0x8,%esp
801059a9:	8d 55 e2             	lea    -0x1e(%ebp),%edx
801059ac:	52                   	push   %edx
801059ad:	50                   	push   %eax
801059ae:	e8 b9 cb ff ff       	call   8010256c <nameiparent>
801059b3:	83 c4 10             	add    $0x10,%esp
801059b6:	89 45 f0             	mov    %eax,-0x10(%ebp)
801059b9:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
801059bd:	74 71                	je     80105a30 <sys_link+0x15a>
    goto bad;
  ilock(dp);
801059bf:	83 ec 0c             	sub    $0xc,%esp
801059c2:	ff 75 f0             	pushl  -0x10(%ebp)
801059c5:	e8 46 c0 ff ff       	call   80101a10 <ilock>
801059ca:	83 c4 10             	add    $0x10,%esp
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
801059cd:	8b 45 f0             	mov    -0x10(%ebp),%eax
801059d0:	8b 10                	mov    (%eax),%edx
801059d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059d5:	8b 00                	mov    (%eax),%eax
801059d7:	39 c2                	cmp    %eax,%edx
801059d9:	75 1d                	jne    801059f8 <sys_link+0x122>
801059db:	8b 45 f4             	mov    -0xc(%ebp),%eax
801059de:	8b 40 04             	mov    0x4(%eax),%eax
801059e1:	83 ec 04             	sub    $0x4,%esp
801059e4:	50                   	push   %eax
801059e5:	8d 45 e2             	lea    -0x1e(%ebp),%eax
801059e8:	50                   	push   %eax
801059e9:	ff 75 f0             	pushl  -0x10(%ebp)
801059ec:	e8 c4 c8 ff ff       	call   801022b5 <dirlink>
801059f1:	83 c4 10             	add    $0x10,%esp
801059f4:	85 c0                	test   %eax,%eax
801059f6:	79 10                	jns    80105a08 <sys_link+0x132>
    iunlockput(dp);
801059f8:	83 ec 0c             	sub    $0xc,%esp
801059fb:	ff 75 f0             	pushl  -0x10(%ebp)
801059fe:	e8 3e c2 ff ff       	call   80101c41 <iunlockput>
80105a03:	83 c4 10             	add    $0x10,%esp
    goto bad;
80105a06:	eb 29                	jmp    80105a31 <sys_link+0x15b>
  }
  iunlockput(dp);
80105a08:	83 ec 0c             	sub    $0xc,%esp
80105a0b:	ff 75 f0             	pushl  -0x10(%ebp)
80105a0e:	e8 2e c2 ff ff       	call   80101c41 <iunlockput>
80105a13:	83 c4 10             	add    $0x10,%esp
  iput(ip);
80105a16:	83 ec 0c             	sub    $0xc,%esp
80105a19:	ff 75 f4             	pushl  -0xc(%ebp)
80105a1c:	e8 50 c1 ff ff       	call   80101b71 <iput>
80105a21:	83 c4 10             	add    $0x10,%esp

  end_op();
80105a24:	e8 98 db ff ff       	call   801035c1 <end_op>

  return 0;
80105a29:	b8 00 00 00 00       	mov    $0x0,%eax
80105a2e:	eb 48                	jmp    80105a78 <sys_link+0x1a2>
  ip->nlink++;
  iupdate(ip);
  iunlock(ip);

  if((dp = nameiparent(new, name)) == 0)
    goto bad;
80105a30:	90                   	nop
  end_op();

  return 0;

bad:
  ilock(ip);
80105a31:	83 ec 0c             	sub    $0xc,%esp
80105a34:	ff 75 f4             	pushl  -0xc(%ebp)
80105a37:	e8 d4 bf ff ff       	call   80101a10 <ilock>
80105a3c:	83 c4 10             	add    $0x10,%esp
  ip->nlink--;
80105a3f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a42:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105a46:	83 e8 01             	sub    $0x1,%eax
80105a49:	89 c2                	mov    %eax,%edx
80105a4b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a4e:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105a52:	83 ec 0c             	sub    $0xc,%esp
80105a55:	ff 75 f4             	pushl  -0xc(%ebp)
80105a58:	e8 d6 bd ff ff       	call   80101833 <iupdate>
80105a5d:	83 c4 10             	add    $0x10,%esp
  iunlockput(ip);
80105a60:	83 ec 0c             	sub    $0xc,%esp
80105a63:	ff 75 f4             	pushl  -0xc(%ebp)
80105a66:	e8 d6 c1 ff ff       	call   80101c41 <iunlockput>
80105a6b:	83 c4 10             	add    $0x10,%esp
  end_op();
80105a6e:	e8 4e db ff ff       	call   801035c1 <end_op>
  return -1;
80105a73:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105a78:	c9                   	leave  
80105a79:	c3                   	ret    

80105a7a <isdirempty>:

// Is the directory dp empty except for "." and ".." ?
static int
isdirempty(struct inode *dp)
{
80105a7a:	55                   	push   %ebp
80105a7b:	89 e5                	mov    %esp,%ebp
80105a7d:	83 ec 28             	sub    $0x28,%esp
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105a80:	c7 45 f4 20 00 00 00 	movl   $0x20,-0xc(%ebp)
80105a87:	eb 40                	jmp    80105ac9 <isdirempty+0x4f>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105a89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105a8c:	6a 10                	push   $0x10
80105a8e:	50                   	push   %eax
80105a8f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105a92:	50                   	push   %eax
80105a93:	ff 75 08             	pushl  0x8(%ebp)
80105a96:	e8 66 c4 ff ff       	call   80101f01 <readi>
80105a9b:	83 c4 10             	add    $0x10,%esp
80105a9e:	83 f8 10             	cmp    $0x10,%eax
80105aa1:	74 0d                	je     80105ab0 <isdirempty+0x36>
      panic("isdirempty: readi");
80105aa3:	83 ec 0c             	sub    $0xc,%esp
80105aa6:	68 18 89 10 80       	push   $0x80108918
80105aab:	e8 f0 aa ff ff       	call   801005a0 <panic>
    if(de.inum != 0)
80105ab0:	0f b7 45 e4          	movzwl -0x1c(%ebp),%eax
80105ab4:	66 85 c0             	test   %ax,%ax
80105ab7:	74 07                	je     80105ac0 <isdirempty+0x46>
      return 0;
80105ab9:	b8 00 00 00 00       	mov    $0x0,%eax
80105abe:	eb 1b                	jmp    80105adb <isdirempty+0x61>
isdirempty(struct inode *dp)
{
  int off;
  struct dirent de;

  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
80105ac0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ac3:	83 c0 10             	add    $0x10,%eax
80105ac6:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105ac9:	8b 45 08             	mov    0x8(%ebp),%eax
80105acc:	8b 50 58             	mov    0x58(%eax),%edx
80105acf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105ad2:	39 c2                	cmp    %eax,%edx
80105ad4:	77 b3                	ja     80105a89 <isdirempty+0xf>
    if(readi(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
      panic("isdirempty: readi");
    if(de.inum != 0)
      return 0;
  }
  return 1;
80105ad6:	b8 01 00 00 00       	mov    $0x1,%eax
}
80105adb:	c9                   	leave  
80105adc:	c3                   	ret    

80105add <sys_unlink>:

//PAGEBREAK!
int
sys_unlink(void)
{
80105add:	55                   	push   %ebp
80105ade:	89 e5                	mov    %esp,%ebp
80105ae0:	83 ec 38             	sub    $0x38,%esp
  struct inode *ip, *dp;
  struct dirent de;
  char name[DIRSIZ], *path;
  uint off;

  if(argstr(0, &path) < 0)
80105ae3:	83 ec 08             	sub    $0x8,%esp
80105ae6:	8d 45 cc             	lea    -0x34(%ebp),%eax
80105ae9:	50                   	push   %eax
80105aea:	6a 00                	push   $0x0
80105aec:	e8 9d fa ff ff       	call   8010558e <argstr>
80105af1:	83 c4 10             	add    $0x10,%esp
80105af4:	85 c0                	test   %eax,%eax
80105af6:	79 0a                	jns    80105b02 <sys_unlink+0x25>
    return -1;
80105af8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105afd:	e9 bc 01 00 00       	jmp    80105cbe <sys_unlink+0x1e1>

  begin_op();
80105b02:	e8 2e da ff ff       	call   80103535 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
80105b07:	8b 45 cc             	mov    -0x34(%ebp),%eax
80105b0a:	83 ec 08             	sub    $0x8,%esp
80105b0d:	8d 55 d2             	lea    -0x2e(%ebp),%edx
80105b10:	52                   	push   %edx
80105b11:	50                   	push   %eax
80105b12:	e8 55 ca ff ff       	call   8010256c <nameiparent>
80105b17:	83 c4 10             	add    $0x10,%esp
80105b1a:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105b1d:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105b21:	75 0f                	jne    80105b32 <sys_unlink+0x55>
    end_op();
80105b23:	e8 99 da ff ff       	call   801035c1 <end_op>
    return -1;
80105b28:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105b2d:	e9 8c 01 00 00       	jmp    80105cbe <sys_unlink+0x1e1>
  }

  ilock(dp);
80105b32:	83 ec 0c             	sub    $0xc,%esp
80105b35:	ff 75 f4             	pushl  -0xc(%ebp)
80105b38:	e8 d3 be ff ff       	call   80101a10 <ilock>
80105b3d:	83 c4 10             	add    $0x10,%esp

  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
80105b40:	83 ec 08             	sub    $0x8,%esp
80105b43:	68 2a 89 10 80       	push   $0x8010892a
80105b48:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b4b:	50                   	push   %eax
80105b4c:	e8 8f c6 ff ff       	call   801021e0 <namecmp>
80105b51:	83 c4 10             	add    $0x10,%esp
80105b54:	85 c0                	test   %eax,%eax
80105b56:	0f 84 4a 01 00 00    	je     80105ca6 <sys_unlink+0x1c9>
80105b5c:	83 ec 08             	sub    $0x8,%esp
80105b5f:	68 2c 89 10 80       	push   $0x8010892c
80105b64:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b67:	50                   	push   %eax
80105b68:	e8 73 c6 ff ff       	call   801021e0 <namecmp>
80105b6d:	83 c4 10             	add    $0x10,%esp
80105b70:	85 c0                	test   %eax,%eax
80105b72:	0f 84 2e 01 00 00    	je     80105ca6 <sys_unlink+0x1c9>
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
80105b78:	83 ec 04             	sub    $0x4,%esp
80105b7b:	8d 45 c8             	lea    -0x38(%ebp),%eax
80105b7e:	50                   	push   %eax
80105b7f:	8d 45 d2             	lea    -0x2e(%ebp),%eax
80105b82:	50                   	push   %eax
80105b83:	ff 75 f4             	pushl  -0xc(%ebp)
80105b86:	e8 70 c6 ff ff       	call   801021fb <dirlookup>
80105b8b:	83 c4 10             	add    $0x10,%esp
80105b8e:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105b91:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105b95:	0f 84 0a 01 00 00    	je     80105ca5 <sys_unlink+0x1c8>
    goto bad;
  ilock(ip);
80105b9b:	83 ec 0c             	sub    $0xc,%esp
80105b9e:	ff 75 f0             	pushl  -0x10(%ebp)
80105ba1:	e8 6a be ff ff       	call   80101a10 <ilock>
80105ba6:	83 c4 10             	add    $0x10,%esp

  if(ip->nlink < 1)
80105ba9:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bac:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105bb0:	66 85 c0             	test   %ax,%ax
80105bb3:	7f 0d                	jg     80105bc2 <sys_unlink+0xe5>
    panic("unlink: nlink < 1");
80105bb5:	83 ec 0c             	sub    $0xc,%esp
80105bb8:	68 2f 89 10 80       	push   $0x8010892f
80105bbd:	e8 de a9 ff ff       	call   801005a0 <panic>
  if(ip->type == T_DIR && !isdirempty(ip)){
80105bc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105bc5:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105bc9:	66 83 f8 01          	cmp    $0x1,%ax
80105bcd:	75 25                	jne    80105bf4 <sys_unlink+0x117>
80105bcf:	83 ec 0c             	sub    $0xc,%esp
80105bd2:	ff 75 f0             	pushl  -0x10(%ebp)
80105bd5:	e8 a0 fe ff ff       	call   80105a7a <isdirempty>
80105bda:	83 c4 10             	add    $0x10,%esp
80105bdd:	85 c0                	test   %eax,%eax
80105bdf:	75 13                	jne    80105bf4 <sys_unlink+0x117>
    iunlockput(ip);
80105be1:	83 ec 0c             	sub    $0xc,%esp
80105be4:	ff 75 f0             	pushl  -0x10(%ebp)
80105be7:	e8 55 c0 ff ff       	call   80101c41 <iunlockput>
80105bec:	83 c4 10             	add    $0x10,%esp
    goto bad;
80105bef:	e9 b2 00 00 00       	jmp    80105ca6 <sys_unlink+0x1c9>
  }

  memset(&de, 0, sizeof(de));
80105bf4:	83 ec 04             	sub    $0x4,%esp
80105bf7:	6a 10                	push   $0x10
80105bf9:	6a 00                	push   $0x0
80105bfb:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105bfe:	50                   	push   %eax
80105bff:	e8 c9 f5 ff ff       	call   801051cd <memset>
80105c04:	83 c4 10             	add    $0x10,%esp
  if(writei(dp, (char*)&de, off, sizeof(de)) != sizeof(de))
80105c07:	8b 45 c8             	mov    -0x38(%ebp),%eax
80105c0a:	6a 10                	push   $0x10
80105c0c:	50                   	push   %eax
80105c0d:	8d 45 e0             	lea    -0x20(%ebp),%eax
80105c10:	50                   	push   %eax
80105c11:	ff 75 f4             	pushl  -0xc(%ebp)
80105c14:	e8 3f c4 ff ff       	call   80102058 <writei>
80105c19:	83 c4 10             	add    $0x10,%esp
80105c1c:	83 f8 10             	cmp    $0x10,%eax
80105c1f:	74 0d                	je     80105c2e <sys_unlink+0x151>
    panic("unlink: writei");
80105c21:	83 ec 0c             	sub    $0xc,%esp
80105c24:	68 41 89 10 80       	push   $0x80108941
80105c29:	e8 72 a9 ff ff       	call   801005a0 <panic>
  if(ip->type == T_DIR){
80105c2e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c31:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105c35:	66 83 f8 01          	cmp    $0x1,%ax
80105c39:	75 21                	jne    80105c5c <sys_unlink+0x17f>
    dp->nlink--;
80105c3b:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c3e:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105c42:	83 e8 01             	sub    $0x1,%eax
80105c45:	89 c2                	mov    %eax,%edx
80105c47:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105c4a:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105c4e:	83 ec 0c             	sub    $0xc,%esp
80105c51:	ff 75 f4             	pushl  -0xc(%ebp)
80105c54:	e8 da bb ff ff       	call   80101833 <iupdate>
80105c59:	83 c4 10             	add    $0x10,%esp
  }
  iunlockput(dp);
80105c5c:	83 ec 0c             	sub    $0xc,%esp
80105c5f:	ff 75 f4             	pushl  -0xc(%ebp)
80105c62:	e8 da bf ff ff       	call   80101c41 <iunlockput>
80105c67:	83 c4 10             	add    $0x10,%esp

  ip->nlink--;
80105c6a:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c6d:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105c71:	83 e8 01             	sub    $0x1,%eax
80105c74:	89 c2                	mov    %eax,%edx
80105c76:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105c79:	66 89 50 56          	mov    %dx,0x56(%eax)
  iupdate(ip);
80105c7d:	83 ec 0c             	sub    $0xc,%esp
80105c80:	ff 75 f0             	pushl  -0x10(%ebp)
80105c83:	e8 ab bb ff ff       	call   80101833 <iupdate>
80105c88:	83 c4 10             	add    $0x10,%esp
  iunlockput(ip);
80105c8b:	83 ec 0c             	sub    $0xc,%esp
80105c8e:	ff 75 f0             	pushl  -0x10(%ebp)
80105c91:	e8 ab bf ff ff       	call   80101c41 <iunlockput>
80105c96:	83 c4 10             	add    $0x10,%esp

  end_op();
80105c99:	e8 23 d9 ff ff       	call   801035c1 <end_op>

  return 0;
80105c9e:	b8 00 00 00 00       	mov    $0x0,%eax
80105ca3:	eb 19                	jmp    80105cbe <sys_unlink+0x1e1>
  // Cannot unlink "." or "..".
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    goto bad;

  if((ip = dirlookup(dp, name, &off)) == 0)
    goto bad;
80105ca5:	90                   	nop
  end_op();

  return 0;

bad:
  iunlockput(dp);
80105ca6:	83 ec 0c             	sub    $0xc,%esp
80105ca9:	ff 75 f4             	pushl  -0xc(%ebp)
80105cac:	e8 90 bf ff ff       	call   80101c41 <iunlockput>
80105cb1:	83 c4 10             	add    $0x10,%esp
  end_op();
80105cb4:	e8 08 d9 ff ff       	call   801035c1 <end_op>
  return -1;
80105cb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
}
80105cbe:	c9                   	leave  
80105cbf:	c3                   	ret    

80105cc0 <create>:

static struct inode*
create(char *path, short type, short major, short minor)
{
80105cc0:	55                   	push   %ebp
80105cc1:	89 e5                	mov    %esp,%ebp
80105cc3:	83 ec 38             	sub    $0x38,%esp
80105cc6:	8b 4d 0c             	mov    0xc(%ebp),%ecx
80105cc9:	8b 55 10             	mov    0x10(%ebp),%edx
80105ccc:	8b 45 14             	mov    0x14(%ebp),%eax
80105ccf:	66 89 4d d4          	mov    %cx,-0x2c(%ebp)
80105cd3:	66 89 55 d0          	mov    %dx,-0x30(%ebp)
80105cd7:	66 89 45 cc          	mov    %ax,-0x34(%ebp)
  uint off;
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
80105cdb:	83 ec 08             	sub    $0x8,%esp
80105cde:	8d 45 de             	lea    -0x22(%ebp),%eax
80105ce1:	50                   	push   %eax
80105ce2:	ff 75 08             	pushl  0x8(%ebp)
80105ce5:	e8 82 c8 ff ff       	call   8010256c <nameiparent>
80105cea:	83 c4 10             	add    $0x10,%esp
80105ced:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105cf0:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105cf4:	75 0a                	jne    80105d00 <create+0x40>
    return 0;
80105cf6:	b8 00 00 00 00       	mov    $0x0,%eax
80105cfb:	e9 90 01 00 00       	jmp    80105e90 <create+0x1d0>
  ilock(dp);
80105d00:	83 ec 0c             	sub    $0xc,%esp
80105d03:	ff 75 f4             	pushl  -0xc(%ebp)
80105d06:	e8 05 bd ff ff       	call   80101a10 <ilock>
80105d0b:	83 c4 10             	add    $0x10,%esp

  if((ip = dirlookup(dp, name, &off)) != 0){
80105d0e:	83 ec 04             	sub    $0x4,%esp
80105d11:	8d 45 ec             	lea    -0x14(%ebp),%eax
80105d14:	50                   	push   %eax
80105d15:	8d 45 de             	lea    -0x22(%ebp),%eax
80105d18:	50                   	push   %eax
80105d19:	ff 75 f4             	pushl  -0xc(%ebp)
80105d1c:	e8 da c4 ff ff       	call   801021fb <dirlookup>
80105d21:	83 c4 10             	add    $0x10,%esp
80105d24:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d27:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d2b:	74 50                	je     80105d7d <create+0xbd>
    iunlockput(dp);
80105d2d:	83 ec 0c             	sub    $0xc,%esp
80105d30:	ff 75 f4             	pushl  -0xc(%ebp)
80105d33:	e8 09 bf ff ff       	call   80101c41 <iunlockput>
80105d38:	83 c4 10             	add    $0x10,%esp
    ilock(ip);
80105d3b:	83 ec 0c             	sub    $0xc,%esp
80105d3e:	ff 75 f0             	pushl  -0x10(%ebp)
80105d41:	e8 ca bc ff ff       	call   80101a10 <ilock>
80105d46:	83 c4 10             	add    $0x10,%esp
    if(type == T_FILE && ip->type == T_FILE)
80105d49:	66 83 7d d4 02       	cmpw   $0x2,-0x2c(%ebp)
80105d4e:	75 15                	jne    80105d65 <create+0xa5>
80105d50:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d53:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105d57:	66 83 f8 02          	cmp    $0x2,%ax
80105d5b:	75 08                	jne    80105d65 <create+0xa5>
      return ip;
80105d5d:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105d60:	e9 2b 01 00 00       	jmp    80105e90 <create+0x1d0>
    iunlockput(ip);
80105d65:	83 ec 0c             	sub    $0xc,%esp
80105d68:	ff 75 f0             	pushl  -0x10(%ebp)
80105d6b:	e8 d1 be ff ff       	call   80101c41 <iunlockput>
80105d70:	83 c4 10             	add    $0x10,%esp
    return 0;
80105d73:	b8 00 00 00 00       	mov    $0x0,%eax
80105d78:	e9 13 01 00 00       	jmp    80105e90 <create+0x1d0>
  }

  if((ip = ialloc(dp->dev, type)) == 0)
80105d7d:	0f bf 55 d4          	movswl -0x2c(%ebp),%edx
80105d81:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105d84:	8b 00                	mov    (%eax),%eax
80105d86:	83 ec 08             	sub    $0x8,%esp
80105d89:	52                   	push   %edx
80105d8a:	50                   	push   %eax
80105d8b:	e8 cc b9 ff ff       	call   8010175c <ialloc>
80105d90:	83 c4 10             	add    $0x10,%esp
80105d93:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105d96:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105d9a:	75 0d                	jne    80105da9 <create+0xe9>
    panic("create: ialloc");
80105d9c:	83 ec 0c             	sub    $0xc,%esp
80105d9f:	68 50 89 10 80       	push   $0x80108950
80105da4:	e8 f7 a7 ff ff       	call   801005a0 <panic>

  ilock(ip);
80105da9:	83 ec 0c             	sub    $0xc,%esp
80105dac:	ff 75 f0             	pushl  -0x10(%ebp)
80105daf:	e8 5c bc ff ff       	call   80101a10 <ilock>
80105db4:	83 c4 10             	add    $0x10,%esp
  ip->major = major;
80105db7:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dba:	0f b7 55 d0          	movzwl -0x30(%ebp),%edx
80105dbe:	66 89 50 52          	mov    %dx,0x52(%eax)
  ip->minor = minor;
80105dc2:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dc5:	0f b7 55 cc          	movzwl -0x34(%ebp),%edx
80105dc9:	66 89 50 54          	mov    %dx,0x54(%eax)
  ip->nlink = 1;
80105dcd:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105dd0:	66 c7 40 56 01 00    	movw   $0x1,0x56(%eax)
  iupdate(ip);
80105dd6:	83 ec 0c             	sub    $0xc,%esp
80105dd9:	ff 75 f0             	pushl  -0x10(%ebp)
80105ddc:	e8 52 ba ff ff       	call   80101833 <iupdate>
80105de1:	83 c4 10             	add    $0x10,%esp

  if(type == T_DIR){  // Create . and .. entries.
80105de4:	66 83 7d d4 01       	cmpw   $0x1,-0x2c(%ebp)
80105de9:	75 6a                	jne    80105e55 <create+0x195>
    dp->nlink++;  // for ".."
80105deb:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dee:	0f b7 40 56          	movzwl 0x56(%eax),%eax
80105df2:	83 c0 01             	add    $0x1,%eax
80105df5:	89 c2                	mov    %eax,%edx
80105df7:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105dfa:	66 89 50 56          	mov    %dx,0x56(%eax)
    iupdate(dp);
80105dfe:	83 ec 0c             	sub    $0xc,%esp
80105e01:	ff 75 f4             	pushl  -0xc(%ebp)
80105e04:	e8 2a ba ff ff       	call   80101833 <iupdate>
80105e09:	83 c4 10             	add    $0x10,%esp
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
80105e0c:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e0f:	8b 40 04             	mov    0x4(%eax),%eax
80105e12:	83 ec 04             	sub    $0x4,%esp
80105e15:	50                   	push   %eax
80105e16:	68 2a 89 10 80       	push   $0x8010892a
80105e1b:	ff 75 f0             	pushl  -0x10(%ebp)
80105e1e:	e8 92 c4 ff ff       	call   801022b5 <dirlink>
80105e23:	83 c4 10             	add    $0x10,%esp
80105e26:	85 c0                	test   %eax,%eax
80105e28:	78 1e                	js     80105e48 <create+0x188>
80105e2a:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105e2d:	8b 40 04             	mov    0x4(%eax),%eax
80105e30:	83 ec 04             	sub    $0x4,%esp
80105e33:	50                   	push   %eax
80105e34:	68 2c 89 10 80       	push   $0x8010892c
80105e39:	ff 75 f0             	pushl  -0x10(%ebp)
80105e3c:	e8 74 c4 ff ff       	call   801022b5 <dirlink>
80105e41:	83 c4 10             	add    $0x10,%esp
80105e44:	85 c0                	test   %eax,%eax
80105e46:	79 0d                	jns    80105e55 <create+0x195>
      panic("create dots");
80105e48:	83 ec 0c             	sub    $0xc,%esp
80105e4b:	68 5f 89 10 80       	push   $0x8010895f
80105e50:	e8 4b a7 ff ff       	call   801005a0 <panic>
  }

  if(dirlink(dp, name, ip->inum) < 0)
80105e55:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105e58:	8b 40 04             	mov    0x4(%eax),%eax
80105e5b:	83 ec 04             	sub    $0x4,%esp
80105e5e:	50                   	push   %eax
80105e5f:	8d 45 de             	lea    -0x22(%ebp),%eax
80105e62:	50                   	push   %eax
80105e63:	ff 75 f4             	pushl  -0xc(%ebp)
80105e66:	e8 4a c4 ff ff       	call   801022b5 <dirlink>
80105e6b:	83 c4 10             	add    $0x10,%esp
80105e6e:	85 c0                	test   %eax,%eax
80105e70:	79 0d                	jns    80105e7f <create+0x1bf>
    panic("create: dirlink");
80105e72:	83 ec 0c             	sub    $0xc,%esp
80105e75:	68 6b 89 10 80       	push   $0x8010896b
80105e7a:	e8 21 a7 ff ff       	call   801005a0 <panic>

  iunlockput(dp);
80105e7f:	83 ec 0c             	sub    $0xc,%esp
80105e82:	ff 75 f4             	pushl  -0xc(%ebp)
80105e85:	e8 b7 bd ff ff       	call   80101c41 <iunlockput>
80105e8a:	83 c4 10             	add    $0x10,%esp

  return ip;
80105e8d:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80105e90:	c9                   	leave  
80105e91:	c3                   	ret    

80105e92 <sys_open>:

int
sys_open(void)
{
80105e92:	55                   	push   %ebp
80105e93:	89 e5                	mov    %esp,%ebp
80105e95:	83 ec 28             	sub    $0x28,%esp
  char *path;
  int fd, omode;
  struct file *f;
  struct inode *ip;

  if(argstr(0, &path) < 0 || argint(1, &omode) < 0)
80105e98:	83 ec 08             	sub    $0x8,%esp
80105e9b:	8d 45 e8             	lea    -0x18(%ebp),%eax
80105e9e:	50                   	push   %eax
80105e9f:	6a 00                	push   $0x0
80105ea1:	e8 e8 f6 ff ff       	call   8010558e <argstr>
80105ea6:	83 c4 10             	add    $0x10,%esp
80105ea9:	85 c0                	test   %eax,%eax
80105eab:	78 15                	js     80105ec2 <sys_open+0x30>
80105ead:	83 ec 08             	sub    $0x8,%esp
80105eb0:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80105eb3:	50                   	push   %eax
80105eb4:	6a 01                	push   $0x1
80105eb6:	e8 3e f6 ff ff       	call   801054f9 <argint>
80105ebb:	83 c4 10             	add    $0x10,%esp
80105ebe:	85 c0                	test   %eax,%eax
80105ec0:	79 0a                	jns    80105ecc <sys_open+0x3a>
    return -1;
80105ec2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105ec7:	e9 61 01 00 00       	jmp    8010602d <sys_open+0x19b>

  begin_op();
80105ecc:	e8 64 d6 ff ff       	call   80103535 <begin_op>

  if(omode & O_CREATE){
80105ed1:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ed4:	25 00 02 00 00       	and    $0x200,%eax
80105ed9:	85 c0                	test   %eax,%eax
80105edb:	74 2a                	je     80105f07 <sys_open+0x75>
    ip = create(path, T_FILE, 0, 0);
80105edd:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105ee0:	6a 00                	push   $0x0
80105ee2:	6a 00                	push   $0x0
80105ee4:	6a 02                	push   $0x2
80105ee6:	50                   	push   %eax
80105ee7:	e8 d4 fd ff ff       	call   80105cc0 <create>
80105eec:	83 c4 10             	add    $0x10,%esp
80105eef:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(ip == 0){
80105ef2:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105ef6:	75 75                	jne    80105f6d <sys_open+0xdb>
      end_op();
80105ef8:	e8 c4 d6 ff ff       	call   801035c1 <end_op>
      return -1;
80105efd:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f02:	e9 26 01 00 00       	jmp    8010602d <sys_open+0x19b>
    }
  } else {
    if((ip = namei(path)) == 0){
80105f07:	8b 45 e8             	mov    -0x18(%ebp),%eax
80105f0a:	83 ec 0c             	sub    $0xc,%esp
80105f0d:	50                   	push   %eax
80105f0e:	e8 3d c6 ff ff       	call   80102550 <namei>
80105f13:	83 c4 10             	add    $0x10,%esp
80105f16:	89 45 f4             	mov    %eax,-0xc(%ebp)
80105f19:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80105f1d:	75 0f                	jne    80105f2e <sys_open+0x9c>
      end_op();
80105f1f:	e8 9d d6 ff ff       	call   801035c1 <end_op>
      return -1;
80105f24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f29:	e9 ff 00 00 00       	jmp    8010602d <sys_open+0x19b>
    }
    ilock(ip);
80105f2e:	83 ec 0c             	sub    $0xc,%esp
80105f31:	ff 75 f4             	pushl  -0xc(%ebp)
80105f34:	e8 d7 ba ff ff       	call   80101a10 <ilock>
80105f39:	83 c4 10             	add    $0x10,%esp
    if(ip->type == T_DIR && omode != O_RDONLY){
80105f3c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80105f3f:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80105f43:	66 83 f8 01          	cmp    $0x1,%ax
80105f47:	75 24                	jne    80105f6d <sys_open+0xdb>
80105f49:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105f4c:	85 c0                	test   %eax,%eax
80105f4e:	74 1d                	je     80105f6d <sys_open+0xdb>
      iunlockput(ip);
80105f50:	83 ec 0c             	sub    $0xc,%esp
80105f53:	ff 75 f4             	pushl  -0xc(%ebp)
80105f56:	e8 e6 bc ff ff       	call   80101c41 <iunlockput>
80105f5b:	83 c4 10             	add    $0x10,%esp
      end_op();
80105f5e:	e8 5e d6 ff ff       	call   801035c1 <end_op>
      return -1;
80105f63:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105f68:	e9 c0 00 00 00       	jmp    8010602d <sys_open+0x19b>
    }
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
80105f6d:	e8 81 b0 ff ff       	call   80100ff3 <filealloc>
80105f72:	89 45 f0             	mov    %eax,-0x10(%ebp)
80105f75:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f79:	74 17                	je     80105f92 <sys_open+0x100>
80105f7b:	83 ec 0c             	sub    $0xc,%esp
80105f7e:	ff 75 f0             	pushl  -0x10(%ebp)
80105f81:	e8 34 f7 ff ff       	call   801056ba <fdalloc>
80105f86:	83 c4 10             	add    $0x10,%esp
80105f89:	89 45 ec             	mov    %eax,-0x14(%ebp)
80105f8c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80105f90:	79 2e                	jns    80105fc0 <sys_open+0x12e>
    if(f)
80105f92:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80105f96:	74 0e                	je     80105fa6 <sys_open+0x114>
      fileclose(f);
80105f98:	83 ec 0c             	sub    $0xc,%esp
80105f9b:	ff 75 f0             	pushl  -0x10(%ebp)
80105f9e:	e8 0e b1 ff ff       	call   801010b1 <fileclose>
80105fa3:	83 c4 10             	add    $0x10,%esp
    iunlockput(ip);
80105fa6:	83 ec 0c             	sub    $0xc,%esp
80105fa9:	ff 75 f4             	pushl  -0xc(%ebp)
80105fac:	e8 90 bc ff ff       	call   80101c41 <iunlockput>
80105fb1:	83 c4 10             	add    $0x10,%esp
    end_op();
80105fb4:	e8 08 d6 ff ff       	call   801035c1 <end_op>
    return -1;
80105fb9:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80105fbe:	eb 6d                	jmp    8010602d <sys_open+0x19b>
  }
  iunlock(ip);
80105fc0:	83 ec 0c             	sub    $0xc,%esp
80105fc3:	ff 75 f4             	pushl  -0xc(%ebp)
80105fc6:	e8 58 bb ff ff       	call   80101b23 <iunlock>
80105fcb:	83 c4 10             	add    $0x10,%esp
  end_op();
80105fce:	e8 ee d5 ff ff       	call   801035c1 <end_op>

  f->type = FD_INODE;
80105fd3:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fd6:	c7 00 02 00 00 00    	movl   $0x2,(%eax)
  f->ip = ip;
80105fdc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fdf:	8b 55 f4             	mov    -0xc(%ebp),%edx
80105fe2:	89 50 10             	mov    %edx,0x10(%eax)
  f->off = 0;
80105fe5:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fe8:	c7 40 14 00 00 00 00 	movl   $0x0,0x14(%eax)
  f->readable = !(omode & O_WRONLY);
80105fef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80105ff2:	83 e0 01             	and    $0x1,%eax
80105ff5:	85 c0                	test   %eax,%eax
80105ff7:	0f 94 c0             	sete   %al
80105ffa:	89 c2                	mov    %eax,%edx
80105ffc:	8b 45 f0             	mov    -0x10(%ebp),%eax
80105fff:	88 50 08             	mov    %dl,0x8(%eax)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
80106002:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106005:	83 e0 01             	and    $0x1,%eax
80106008:	85 c0                	test   %eax,%eax
8010600a:	75 0a                	jne    80106016 <sys_open+0x184>
8010600c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010600f:	83 e0 02             	and    $0x2,%eax
80106012:	85 c0                	test   %eax,%eax
80106014:	74 07                	je     8010601d <sys_open+0x18b>
80106016:	b8 01 00 00 00       	mov    $0x1,%eax
8010601b:	eb 05                	jmp    80106022 <sys_open+0x190>
8010601d:	b8 00 00 00 00       	mov    $0x0,%eax
80106022:	89 c2                	mov    %eax,%edx
80106024:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106027:	88 50 09             	mov    %dl,0x9(%eax)
  return fd;
8010602a:	8b 45 ec             	mov    -0x14(%ebp),%eax
}
8010602d:	c9                   	leave  
8010602e:	c3                   	ret    

8010602f <sys_mkdir>:

int
sys_mkdir(void)
{
8010602f:	55                   	push   %ebp
80106030:	89 e5                	mov    %esp,%ebp
80106032:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;

  begin_op();
80106035:	e8 fb d4 ff ff       	call   80103535 <begin_op>
  if(argstr(0, &path) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
8010603a:	83 ec 08             	sub    $0x8,%esp
8010603d:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106040:	50                   	push   %eax
80106041:	6a 00                	push   $0x0
80106043:	e8 46 f5 ff ff       	call   8010558e <argstr>
80106048:	83 c4 10             	add    $0x10,%esp
8010604b:	85 c0                	test   %eax,%eax
8010604d:	78 1b                	js     8010606a <sys_mkdir+0x3b>
8010604f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106052:	6a 00                	push   $0x0
80106054:	6a 00                	push   $0x0
80106056:	6a 01                	push   $0x1
80106058:	50                   	push   %eax
80106059:	e8 62 fc ff ff       	call   80105cc0 <create>
8010605e:	83 c4 10             	add    $0x10,%esp
80106061:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106064:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106068:	75 0c                	jne    80106076 <sys_mkdir+0x47>
    end_op();
8010606a:	e8 52 d5 ff ff       	call   801035c1 <end_op>
    return -1;
8010606f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106074:	eb 18                	jmp    8010608e <sys_mkdir+0x5f>
  }
  iunlockput(ip);
80106076:	83 ec 0c             	sub    $0xc,%esp
80106079:	ff 75 f4             	pushl  -0xc(%ebp)
8010607c:	e8 c0 bb ff ff       	call   80101c41 <iunlockput>
80106081:	83 c4 10             	add    $0x10,%esp
  end_op();
80106084:	e8 38 d5 ff ff       	call   801035c1 <end_op>
  return 0;
80106089:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010608e:	c9                   	leave  
8010608f:	c3                   	ret    

80106090 <sys_mknod>:

int
sys_mknod(void)
{
80106090:	55                   	push   %ebp
80106091:	89 e5                	mov    %esp,%ebp
80106093:	83 ec 18             	sub    $0x18,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
80106096:	e8 9a d4 ff ff       	call   80103535 <begin_op>
  if((argstr(0, &path)) < 0 ||
8010609b:	83 ec 08             	sub    $0x8,%esp
8010609e:	8d 45 f0             	lea    -0x10(%ebp),%eax
801060a1:	50                   	push   %eax
801060a2:	6a 00                	push   $0x0
801060a4:	e8 e5 f4 ff ff       	call   8010558e <argstr>
801060a9:	83 c4 10             	add    $0x10,%esp
801060ac:	85 c0                	test   %eax,%eax
801060ae:	78 4f                	js     801060ff <sys_mknod+0x6f>
     argint(1, &major) < 0 ||
801060b0:	83 ec 08             	sub    $0x8,%esp
801060b3:	8d 45 ec             	lea    -0x14(%ebp),%eax
801060b6:	50                   	push   %eax
801060b7:	6a 01                	push   $0x1
801060b9:	e8 3b f4 ff ff       	call   801054f9 <argint>
801060be:	83 c4 10             	add    $0x10,%esp
  struct inode *ip;
  char *path;
  int major, minor;

  begin_op();
  if((argstr(0, &path)) < 0 ||
801060c1:	85 c0                	test   %eax,%eax
801060c3:	78 3a                	js     801060ff <sys_mknod+0x6f>
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801060c5:	83 ec 08             	sub    $0x8,%esp
801060c8:	8d 45 e8             	lea    -0x18(%ebp),%eax
801060cb:	50                   	push   %eax
801060cc:	6a 02                	push   $0x2
801060ce:	e8 26 f4 ff ff       	call   801054f9 <argint>
801060d3:	83 c4 10             	add    $0x10,%esp
  char *path;
  int major, minor;

  begin_op();
  if((argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
801060d6:	85 c0                	test   %eax,%eax
801060d8:	78 25                	js     801060ff <sys_mknod+0x6f>
     argint(2, &minor) < 0 ||
     (ip = create(path, T_DEV, major, minor)) == 0){
801060da:	8b 45 e8             	mov    -0x18(%ebp),%eax
801060dd:	0f bf c8             	movswl %ax,%ecx
801060e0:	8b 45 ec             	mov    -0x14(%ebp),%eax
801060e3:	0f bf d0             	movswl %ax,%edx
801060e6:	8b 45 f0             	mov    -0x10(%ebp),%eax
  int major, minor;

  begin_op();
  if((argstr(0, &path)) < 0 ||
     argint(1, &major) < 0 ||
     argint(2, &minor) < 0 ||
801060e9:	51                   	push   %ecx
801060ea:	52                   	push   %edx
801060eb:	6a 03                	push   $0x3
801060ed:	50                   	push   %eax
801060ee:	e8 cd fb ff ff       	call   80105cc0 <create>
801060f3:	83 c4 10             	add    $0x10,%esp
801060f6:	89 45 f4             	mov    %eax,-0xc(%ebp)
801060f9:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
801060fd:	75 0c                	jne    8010610b <sys_mknod+0x7b>
     (ip = create(path, T_DEV, major, minor)) == 0){
    end_op();
801060ff:	e8 bd d4 ff ff       	call   801035c1 <end_op>
    return -1;
80106104:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106109:	eb 18                	jmp    80106123 <sys_mknod+0x93>
  }
  iunlockput(ip);
8010610b:	83 ec 0c             	sub    $0xc,%esp
8010610e:	ff 75 f4             	pushl  -0xc(%ebp)
80106111:	e8 2b bb ff ff       	call   80101c41 <iunlockput>
80106116:	83 c4 10             	add    $0x10,%esp
  end_op();
80106119:	e8 a3 d4 ff ff       	call   801035c1 <end_op>
  return 0;
8010611e:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106123:	c9                   	leave  
80106124:	c3                   	ret    

80106125 <sys_chdir>:

int
sys_chdir(void)
{
80106125:	55                   	push   %ebp
80106126:	89 e5                	mov    %esp,%ebp
80106128:	83 ec 18             	sub    $0x18,%esp
  char *path;
  struct inode *ip;
  struct proc *curproc = myproc();
8010612b:	e8 58 e1 ff ff       	call   80104288 <myproc>
80106130:	89 45 f4             	mov    %eax,-0xc(%ebp)
  
  begin_op();
80106133:	e8 fd d3 ff ff       	call   80103535 <begin_op>
  if(argstr(0, &path) < 0 || (ip = namei(path)) == 0){
80106138:	83 ec 08             	sub    $0x8,%esp
8010613b:	8d 45 ec             	lea    -0x14(%ebp),%eax
8010613e:	50                   	push   %eax
8010613f:	6a 00                	push   $0x0
80106141:	e8 48 f4 ff ff       	call   8010558e <argstr>
80106146:	83 c4 10             	add    $0x10,%esp
80106149:	85 c0                	test   %eax,%eax
8010614b:	78 18                	js     80106165 <sys_chdir+0x40>
8010614d:	8b 45 ec             	mov    -0x14(%ebp),%eax
80106150:	83 ec 0c             	sub    $0xc,%esp
80106153:	50                   	push   %eax
80106154:	e8 f7 c3 ff ff       	call   80102550 <namei>
80106159:	83 c4 10             	add    $0x10,%esp
8010615c:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010615f:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106163:	75 0c                	jne    80106171 <sys_chdir+0x4c>
    end_op();
80106165:	e8 57 d4 ff ff       	call   801035c1 <end_op>
    return -1;
8010616a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010616f:	eb 68                	jmp    801061d9 <sys_chdir+0xb4>
  }
  ilock(ip);
80106171:	83 ec 0c             	sub    $0xc,%esp
80106174:	ff 75 f0             	pushl  -0x10(%ebp)
80106177:	e8 94 b8 ff ff       	call   80101a10 <ilock>
8010617c:	83 c4 10             	add    $0x10,%esp
  if(ip->type != T_DIR){
8010617f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106182:	0f b7 40 50          	movzwl 0x50(%eax),%eax
80106186:	66 83 f8 01          	cmp    $0x1,%ax
8010618a:	74 1a                	je     801061a6 <sys_chdir+0x81>
    iunlockput(ip);
8010618c:	83 ec 0c             	sub    $0xc,%esp
8010618f:	ff 75 f0             	pushl  -0x10(%ebp)
80106192:	e8 aa ba ff ff       	call   80101c41 <iunlockput>
80106197:	83 c4 10             	add    $0x10,%esp
    end_op();
8010619a:	e8 22 d4 ff ff       	call   801035c1 <end_op>
    return -1;
8010619f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801061a4:	eb 33                	jmp    801061d9 <sys_chdir+0xb4>
  }
  iunlock(ip);
801061a6:	83 ec 0c             	sub    $0xc,%esp
801061a9:	ff 75 f0             	pushl  -0x10(%ebp)
801061ac:	e8 72 b9 ff ff       	call   80101b23 <iunlock>
801061b1:	83 c4 10             	add    $0x10,%esp
  iput(curproc->cwd);
801061b4:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061b7:	8b 40 68             	mov    0x68(%eax),%eax
801061ba:	83 ec 0c             	sub    $0xc,%esp
801061bd:	50                   	push   %eax
801061be:	e8 ae b9 ff ff       	call   80101b71 <iput>
801061c3:	83 c4 10             	add    $0x10,%esp
  end_op();
801061c6:	e8 f6 d3 ff ff       	call   801035c1 <end_op>
  curproc->cwd = ip;
801061cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801061ce:	8b 55 f0             	mov    -0x10(%ebp),%edx
801061d1:	89 50 68             	mov    %edx,0x68(%eax)
  return 0;
801061d4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801061d9:	c9                   	leave  
801061da:	c3                   	ret    

801061db <sys_exec>:

int
sys_exec(void)
{
801061db:	55                   	push   %ebp
801061dc:	89 e5                	mov    %esp,%ebp
801061de:	81 ec 98 00 00 00    	sub    $0x98,%esp
  char *path, *argv[MAXARG];
  int i;
  uint uargv, uarg;

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
801061e4:	83 ec 08             	sub    $0x8,%esp
801061e7:	8d 45 f0             	lea    -0x10(%ebp),%eax
801061ea:	50                   	push   %eax
801061eb:	6a 00                	push   $0x0
801061ed:	e8 9c f3 ff ff       	call   8010558e <argstr>
801061f2:	83 c4 10             	add    $0x10,%esp
801061f5:	85 c0                	test   %eax,%eax
801061f7:	78 18                	js     80106211 <sys_exec+0x36>
801061f9:	83 ec 08             	sub    $0x8,%esp
801061fc:	8d 85 6c ff ff ff    	lea    -0x94(%ebp),%eax
80106202:	50                   	push   %eax
80106203:	6a 01                	push   $0x1
80106205:	e8 ef f2 ff ff       	call   801054f9 <argint>
8010620a:	83 c4 10             	add    $0x10,%esp
8010620d:	85 c0                	test   %eax,%eax
8010620f:	79 0a                	jns    8010621b <sys_exec+0x40>
    return -1;
80106211:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106216:	e9 c6 00 00 00       	jmp    801062e1 <sys_exec+0x106>
  }
  memset(argv, 0, sizeof(argv));
8010621b:	83 ec 04             	sub    $0x4,%esp
8010621e:	68 80 00 00 00       	push   $0x80
80106223:	6a 00                	push   $0x0
80106225:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
8010622b:	50                   	push   %eax
8010622c:	e8 9c ef ff ff       	call   801051cd <memset>
80106231:	83 c4 10             	add    $0x10,%esp
  for(i=0;; i++){
80106234:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
    if(i >= NELEM(argv))
8010623b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010623e:	83 f8 1f             	cmp    $0x1f,%eax
80106241:	76 0a                	jbe    8010624d <sys_exec+0x72>
      return -1;
80106243:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106248:	e9 94 00 00 00       	jmp    801062e1 <sys_exec+0x106>
    if(fetchint(uargv+4*i, (int*)&uarg) < 0)
8010624d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106250:	c1 e0 02             	shl    $0x2,%eax
80106253:	89 c2                	mov    %eax,%edx
80106255:	8b 85 6c ff ff ff    	mov    -0x94(%ebp),%eax
8010625b:	01 c2                	add    %eax,%edx
8010625d:	83 ec 08             	sub    $0x8,%esp
80106260:	8d 85 68 ff ff ff    	lea    -0x98(%ebp),%eax
80106266:	50                   	push   %eax
80106267:	52                   	push   %edx
80106268:	e8 e9 f1 ff ff       	call   80105456 <fetchint>
8010626d:	83 c4 10             	add    $0x10,%esp
80106270:	85 c0                	test   %eax,%eax
80106272:	79 07                	jns    8010627b <sys_exec+0xa0>
      return -1;
80106274:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106279:	eb 66                	jmp    801062e1 <sys_exec+0x106>
    if(uarg == 0){
8010627b:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
80106281:	85 c0                	test   %eax,%eax
80106283:	75 27                	jne    801062ac <sys_exec+0xd1>
      argv[i] = 0;
80106285:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106288:	c7 84 85 70 ff ff ff 	movl   $0x0,-0x90(%ebp,%eax,4)
8010628f:	00 00 00 00 
      break;
80106293:	90                   	nop
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
  return exec(path, argv);
80106294:	8b 45 f0             	mov    -0x10(%ebp),%eax
80106297:	83 ec 08             	sub    $0x8,%esp
8010629a:	8d 95 70 ff ff ff    	lea    -0x90(%ebp),%edx
801062a0:	52                   	push   %edx
801062a1:	50                   	push   %eax
801062a2:	e8 ef a8 ff ff       	call   80100b96 <exec>
801062a7:	83 c4 10             	add    $0x10,%esp
801062aa:	eb 35                	jmp    801062e1 <sys_exec+0x106>
      return -1;
    if(uarg == 0){
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
801062ac:	8d 85 70 ff ff ff    	lea    -0x90(%ebp),%eax
801062b2:	8b 55 f4             	mov    -0xc(%ebp),%edx
801062b5:	c1 e2 02             	shl    $0x2,%edx
801062b8:	01 c2                	add    %eax,%edx
801062ba:	8b 85 68 ff ff ff    	mov    -0x98(%ebp),%eax
801062c0:	83 ec 08             	sub    $0x8,%esp
801062c3:	52                   	push   %edx
801062c4:	50                   	push   %eax
801062c5:	e8 cb f1 ff ff       	call   80105495 <fetchstr>
801062ca:	83 c4 10             	add    $0x10,%esp
801062cd:	85 c0                	test   %eax,%eax
801062cf:	79 07                	jns    801062d8 <sys_exec+0xfd>
      return -1;
801062d1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801062d6:	eb 09                	jmp    801062e1 <sys_exec+0x106>

  if(argstr(0, &path) < 0 || argint(1, (int*)&uargv) < 0){
    return -1;
  }
  memset(argv, 0, sizeof(argv));
  for(i=0;; i++){
801062d8:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      argv[i] = 0;
      break;
    }
    if(fetchstr(uarg, &argv[i]) < 0)
      return -1;
  }
801062dc:	e9 5a ff ff ff       	jmp    8010623b <sys_exec+0x60>
  return exec(path, argv);
}
801062e1:	c9                   	leave  
801062e2:	c3                   	ret    

801062e3 <sys_pipe>:

int
sys_pipe(void)
{
801062e3:	55                   	push   %ebp
801062e4:	89 e5                	mov    %esp,%ebp
801062e6:	83 ec 28             	sub    $0x28,%esp
  int *fd;
  struct file *rf, *wf;
  int fd0, fd1;

  if(argptr(0, (void*)&fd, 2*sizeof(fd[0])) < 0)
801062e9:	83 ec 04             	sub    $0x4,%esp
801062ec:	6a 08                	push   $0x8
801062ee:	8d 45 ec             	lea    -0x14(%ebp),%eax
801062f1:	50                   	push   %eax
801062f2:	6a 00                	push   $0x0
801062f4:	e8 2d f2 ff ff       	call   80105526 <argptr>
801062f9:	83 c4 10             	add    $0x10,%esp
801062fc:	85 c0                	test   %eax,%eax
801062fe:	79 0a                	jns    8010630a <sys_pipe+0x27>
    return -1;
80106300:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106305:	e9 b0 00 00 00       	jmp    801063ba <sys_pipe+0xd7>
  if(pipealloc(&rf, &wf) < 0)
8010630a:	83 ec 08             	sub    $0x8,%esp
8010630d:	8d 45 e4             	lea    -0x1c(%ebp),%eax
80106310:	50                   	push   %eax
80106311:	8d 45 e8             	lea    -0x18(%ebp),%eax
80106314:	50                   	push   %eax
80106315:	e8 a5 da ff ff       	call   80103dbf <pipealloc>
8010631a:	83 c4 10             	add    $0x10,%esp
8010631d:	85 c0                	test   %eax,%eax
8010631f:	79 0a                	jns    8010632b <sys_pipe+0x48>
    return -1;
80106321:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106326:	e9 8f 00 00 00       	jmp    801063ba <sys_pipe+0xd7>
  fd0 = -1;
8010632b:	c7 45 f4 ff ff ff ff 	movl   $0xffffffff,-0xc(%ebp)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
80106332:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106335:	83 ec 0c             	sub    $0xc,%esp
80106338:	50                   	push   %eax
80106339:	e8 7c f3 ff ff       	call   801056ba <fdalloc>
8010633e:	83 c4 10             	add    $0x10,%esp
80106341:	89 45 f4             	mov    %eax,-0xc(%ebp)
80106344:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106348:	78 18                	js     80106362 <sys_pipe+0x7f>
8010634a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010634d:	83 ec 0c             	sub    $0xc,%esp
80106350:	50                   	push   %eax
80106351:	e8 64 f3 ff ff       	call   801056ba <fdalloc>
80106356:	83 c4 10             	add    $0x10,%esp
80106359:	89 45 f0             	mov    %eax,-0x10(%ebp)
8010635c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80106360:	79 40                	jns    801063a2 <sys_pipe+0xbf>
    if(fd0 >= 0)
80106362:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80106366:	78 15                	js     8010637d <sys_pipe+0x9a>
      myproc()->ofile[fd0] = 0;
80106368:	e8 1b df ff ff       	call   80104288 <myproc>
8010636d:	89 c2                	mov    %eax,%edx
8010636f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106372:	83 c0 08             	add    $0x8,%eax
80106375:	c7 44 82 08 00 00 00 	movl   $0x0,0x8(%edx,%eax,4)
8010637c:	00 
    fileclose(rf);
8010637d:	8b 45 e8             	mov    -0x18(%ebp),%eax
80106380:	83 ec 0c             	sub    $0xc,%esp
80106383:	50                   	push   %eax
80106384:	e8 28 ad ff ff       	call   801010b1 <fileclose>
80106389:	83 c4 10             	add    $0x10,%esp
    fileclose(wf);
8010638c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
8010638f:	83 ec 0c             	sub    $0xc,%esp
80106392:	50                   	push   %eax
80106393:	e8 19 ad ff ff       	call   801010b1 <fileclose>
80106398:	83 c4 10             	add    $0x10,%esp
    return -1;
8010639b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801063a0:	eb 18                	jmp    801063ba <sys_pipe+0xd7>
  }
  fd[0] = fd0;
801063a2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063a5:	8b 55 f4             	mov    -0xc(%ebp),%edx
801063a8:	89 10                	mov    %edx,(%eax)
  fd[1] = fd1;
801063aa:	8b 45 ec             	mov    -0x14(%ebp),%eax
801063ad:	8d 50 04             	lea    0x4(%eax),%edx
801063b0:	8b 45 f0             	mov    -0x10(%ebp),%eax
801063b3:	89 02                	mov    %eax,(%edx)
  return 0;
801063b5:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063ba:	c9                   	leave  
801063bb:	c3                   	ret    

801063bc <sys_fork>:
#include "mmu.h"
#include "proc.h"

int
sys_fork(void)
{
801063bc:	55                   	push   %ebp
801063bd:	89 e5                	mov    %esp,%ebp
801063bf:	83 ec 08             	sub    $0x8,%esp
  return fork();
801063c2:	e8 c6 e1 ff ff       	call   8010458d <fork>
}
801063c7:	c9                   	leave  
801063c8:	c3                   	ret    

801063c9 <sys_exit>:

int
sys_exit(void)
{
801063c9:	55                   	push   %ebp
801063ca:	89 e5                	mov    %esp,%ebp
801063cc:	83 ec 08             	sub    $0x8,%esp
  exit();
801063cf:	e8 36 e3 ff ff       	call   8010470a <exit>
  return 0;  // not reached
801063d4:	b8 00 00 00 00       	mov    $0x0,%eax
}
801063d9:	c9                   	leave  
801063da:	c3                   	ret    

801063db <sys_wait>:

int
sys_wait(void)
{
801063db:	55                   	push   %ebp
801063dc:	89 e5                	mov    %esp,%ebp
801063de:	83 ec 08             	sub    $0x8,%esp
  return wait();
801063e1:	e8 44 e4 ff ff       	call   8010482a <wait>
}
801063e6:	c9                   	leave  
801063e7:	c3                   	ret    

801063e8 <sys_kill>:

int
sys_kill(void)
{
801063e8:	55                   	push   %ebp
801063e9:	89 e5                	mov    %esp,%ebp
801063eb:	83 ec 18             	sub    $0x18,%esp
  int pid;

  if(argint(0, &pid) < 0)
801063ee:	83 ec 08             	sub    $0x8,%esp
801063f1:	8d 45 f4             	lea    -0xc(%ebp),%eax
801063f4:	50                   	push   %eax
801063f5:	6a 00                	push   $0x0
801063f7:	e8 fd f0 ff ff       	call   801054f9 <argint>
801063fc:	83 c4 10             	add    $0x10,%esp
801063ff:	85 c0                	test   %eax,%eax
80106401:	79 07                	jns    8010640a <sys_kill+0x22>
    return -1;
80106403:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106408:	eb 0f                	jmp    80106419 <sys_kill+0x31>
  return kill(pid);
8010640a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010640d:	83 ec 0c             	sub    $0xc,%esp
80106410:	50                   	push   %eax
80106411:	e8 44 e8 ff ff       	call   80104c5a <kill>
80106416:	83 c4 10             	add    $0x10,%esp
}
80106419:	c9                   	leave  
8010641a:	c3                   	ret    

8010641b <sys_getpid>:

int
sys_getpid(void)
{
8010641b:	55                   	push   %ebp
8010641c:	89 e5                	mov    %esp,%ebp
8010641e:	83 ec 08             	sub    $0x8,%esp
  return myproc()->pid;
80106421:	e8 62 de ff ff       	call   80104288 <myproc>
80106426:	8b 40 10             	mov    0x10(%eax),%eax
}
80106429:	c9                   	leave  
8010642a:	c3                   	ret    

8010642b <sys_sbrk>:

int
sys_sbrk(void)
{
8010642b:	55                   	push   %ebp
8010642c:	89 e5                	mov    %esp,%ebp
8010642e:	83 ec 18             	sub    $0x18,%esp
  int addr;
  int n;

  if(argint(0, &n) < 0)
80106431:	83 ec 08             	sub    $0x8,%esp
80106434:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106437:	50                   	push   %eax
80106438:	6a 00                	push   $0x0
8010643a:	e8 ba f0 ff ff       	call   801054f9 <argint>
8010643f:	83 c4 10             	add    $0x10,%esp
80106442:	85 c0                	test   %eax,%eax
80106444:	79 07                	jns    8010644d <sys_sbrk+0x22>
    return -1;
80106446:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010644b:	eb 1b                	jmp    80106468 <sys_sbrk+0x3d>
  addr = myproc()->sz; // valor actual del tamaño del proceso
8010644d:	e8 36 de ff ff       	call   80104288 <myproc>
80106452:	8b 00                	mov    (%eax),%eax
80106454:	89 45 f4             	mov    %eax,-0xc(%ebp)
  myproc()->sz+=n;
80106457:	e8 2c de ff ff       	call   80104288 <myproc>
8010645c:	8b 10                	mov    (%eax),%edx
8010645e:	8b 4d f0             	mov    -0x10(%ebp),%ecx
80106461:	01 ca                	add    %ecx,%edx
80106463:	89 10                	mov    %edx,(%eax)

  //if(growproc(n) < 0)
    //return -1;
  return addr;
80106465:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106468:	c9                   	leave  
80106469:	c3                   	ret    

8010646a <sys_sleep>:

int
sys_sleep(void)
{
8010646a:	55                   	push   %ebp
8010646b:	89 e5                	mov    %esp,%ebp
8010646d:	83 ec 18             	sub    $0x18,%esp
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
80106470:	83 ec 08             	sub    $0x8,%esp
80106473:	8d 45 f0             	lea    -0x10(%ebp),%eax
80106476:	50                   	push   %eax
80106477:	6a 00                	push   $0x0
80106479:	e8 7b f0 ff ff       	call   801054f9 <argint>
8010647e:	83 c4 10             	add    $0x10,%esp
80106481:	85 c0                	test   %eax,%eax
80106483:	79 07                	jns    8010648c <sys_sleep+0x22>
    return -1;
80106485:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010648a:	eb 76                	jmp    80106502 <sys_sleep+0x98>
  acquire(&tickslock);
8010648c:	83 ec 0c             	sub    $0xc,%esp
8010648f:	68 e0 5c 11 80       	push   $0x80115ce0
80106494:	e8 bd ea ff ff       	call   80104f56 <acquire>
80106499:	83 c4 10             	add    $0x10,%esp
  ticks0 = ticks;
8010649c:	a1 20 65 11 80       	mov    0x80116520,%eax
801064a1:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(ticks - ticks0 < n){
801064a4:	eb 38                	jmp    801064de <sys_sleep+0x74>
    if(myproc()->killed){
801064a6:	e8 dd dd ff ff       	call   80104288 <myproc>
801064ab:	8b 40 24             	mov    0x24(%eax),%eax
801064ae:	85 c0                	test   %eax,%eax
801064b0:	74 17                	je     801064c9 <sys_sleep+0x5f>
      release(&tickslock);
801064b2:	83 ec 0c             	sub    $0xc,%esp
801064b5:	68 e0 5c 11 80       	push   $0x80115ce0
801064ba:	e8 05 eb ff ff       	call   80104fc4 <release>
801064bf:	83 c4 10             	add    $0x10,%esp
      return -1;
801064c2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
801064c7:	eb 39                	jmp    80106502 <sys_sleep+0x98>
    }
    sleep(&ticks, &tickslock);
801064c9:	83 ec 08             	sub    $0x8,%esp
801064cc:	68 e0 5c 11 80       	push   $0x80115ce0
801064d1:	68 20 65 11 80       	push   $0x80116520
801064d6:	e8 62 e6 ff ff       	call   80104b3d <sleep>
801064db:	83 c4 10             	add    $0x10,%esp

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
801064de:	a1 20 65 11 80       	mov    0x80116520,%eax
801064e3:	2b 45 f4             	sub    -0xc(%ebp),%eax
801064e6:	8b 55 f0             	mov    -0x10(%ebp),%edx
801064e9:	39 d0                	cmp    %edx,%eax
801064eb:	72 b9                	jb     801064a6 <sys_sleep+0x3c>
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
801064ed:	83 ec 0c             	sub    $0xc,%esp
801064f0:	68 e0 5c 11 80       	push   $0x80115ce0
801064f5:	e8 ca ea ff ff       	call   80104fc4 <release>
801064fa:	83 c4 10             	add    $0x10,%esp
  return 0;
801064fd:	b8 00 00 00 00       	mov    $0x0,%eax
}
80106502:	c9                   	leave  
80106503:	c3                   	ret    

80106504 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
int
sys_uptime(void)
{
80106504:	55                   	push   %ebp
80106505:	89 e5                	mov    %esp,%ebp
80106507:	83 ec 18             	sub    $0x18,%esp
  uint xticks;

  acquire(&tickslock);
8010650a:	83 ec 0c             	sub    $0xc,%esp
8010650d:	68 e0 5c 11 80       	push   $0x80115ce0
80106512:	e8 3f ea ff ff       	call   80104f56 <acquire>
80106517:	83 c4 10             	add    $0x10,%esp
  xticks = ticks;
8010651a:	a1 20 65 11 80       	mov    0x80116520,%eax
8010651f:	89 45 f4             	mov    %eax,-0xc(%ebp)
  release(&tickslock);
80106522:	83 ec 0c             	sub    $0xc,%esp
80106525:	68 e0 5c 11 80       	push   $0x80115ce0
8010652a:	e8 95 ea ff ff       	call   80104fc4 <release>
8010652f:	83 c4 10             	add    $0x10,%esp
  return xticks;
80106532:	8b 45 f4             	mov    -0xc(%ebp),%eax
}
80106535:	c9                   	leave  
80106536:	c3                   	ret    

80106537 <alltraps>:

  # vectors.S sends all traps here.
.globl alltraps
alltraps:
  # Build trap frame.
  pushl %ds
80106537:	1e                   	push   %ds
  pushl %es
80106538:	06                   	push   %es
  pushl %fs
80106539:	0f a0                	push   %fs
  pushl %gs
8010653b:	0f a8                	push   %gs
  pushal
8010653d:	60                   	pusha  
  
  # Set up data segments.
  movw $(SEG_KDATA<<3), %ax
8010653e:	66 b8 10 00          	mov    $0x10,%ax
  movw %ax, %ds
80106542:	8e d8                	mov    %eax,%ds
  movw %ax, %es
80106544:	8e c0                	mov    %eax,%es

  # Call trap(tf), where tf=%esp
  pushl %esp
80106546:	54                   	push   %esp
  call trap
80106547:	e8 d7 01 00 00       	call   80106723 <trap>
  addl $4, %esp
8010654c:	83 c4 04             	add    $0x4,%esp

8010654f <trapret>:

  # Return falls through to trapret...
.globl trapret
trapret:
  popal
8010654f:	61                   	popa   
  popl %gs
80106550:	0f a9                	pop    %gs
  popl %fs
80106552:	0f a1                	pop    %fs
  popl %es
80106554:	07                   	pop    %es
  popl %ds
80106555:	1f                   	pop    %ds
  addl $0x8, %esp  # trapno and errcode
80106556:	83 c4 08             	add    $0x8,%esp
  iret
80106559:	cf                   	iret   

8010655a <lidt>:

struct gatedesc;

static inline void
lidt(struct gatedesc *p, int size)
{
8010655a:	55                   	push   %ebp
8010655b:	89 e5                	mov    %esp,%ebp
8010655d:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
80106560:	8b 45 0c             	mov    0xc(%ebp),%eax
80106563:	83 e8 01             	sub    $0x1,%eax
80106566:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
8010656a:	8b 45 08             	mov    0x8(%ebp),%eax
8010656d:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
80106571:	8b 45 08             	mov    0x8(%ebp),%eax
80106574:	c1 e8 10             	shr    $0x10,%eax
80106577:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lidt (%0)" : : "r" (pd));
8010657b:	8d 45 fa             	lea    -0x6(%ebp),%eax
8010657e:	0f 01 18             	lidtl  (%eax)
}
80106581:	90                   	nop
80106582:	c9                   	leave  
80106583:	c3                   	ret    

80106584 <rcr2>:
  return result;
}

static inline uint
rcr2(void)
{
80106584:	55                   	push   %ebp
80106585:	89 e5                	mov    %esp,%ebp
80106587:	83 ec 10             	sub    $0x10,%esp
  uint val;
  asm volatile("movl %%cr2,%0" : "=r" (val));
8010658a:	0f 20 d0             	mov    %cr2,%eax
8010658d:	89 45 fc             	mov    %eax,-0x4(%ebp)
  return val;
80106590:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
80106593:	c9                   	leave  
80106594:	c3                   	ret    

80106595 <tvinit>:
struct spinlock tickslock;
uint ticks;

void
tvinit(void)
{
80106595:	55                   	push   %ebp
80106596:	89 e5                	mov    %esp,%ebp
80106598:	83 ec 18             	sub    $0x18,%esp
  int i;

  for(i = 0; i < 256; i++)
8010659b:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801065a2:	e9 c3 00 00 00       	jmp    8010666a <tvinit+0xd5>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
801065a7:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065aa:	8b 04 85 78 b0 10 80 	mov    -0x7fef4f88(,%eax,4),%eax
801065b1:	89 c2                	mov    %eax,%edx
801065b3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065b6:	66 89 14 c5 20 5d 11 	mov    %dx,-0x7feea2e0(,%eax,8)
801065bd:	80 
801065be:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065c1:	66 c7 04 c5 22 5d 11 	movw   $0x8,-0x7feea2de(,%eax,8)
801065c8:	80 08 00 
801065cb:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065ce:	0f b6 14 c5 24 5d 11 	movzbl -0x7feea2dc(,%eax,8),%edx
801065d5:	80 
801065d6:	83 e2 e0             	and    $0xffffffe0,%edx
801065d9:	88 14 c5 24 5d 11 80 	mov    %dl,-0x7feea2dc(,%eax,8)
801065e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065e3:	0f b6 14 c5 24 5d 11 	movzbl -0x7feea2dc(,%eax,8),%edx
801065ea:	80 
801065eb:	83 e2 1f             	and    $0x1f,%edx
801065ee:	88 14 c5 24 5d 11 80 	mov    %dl,-0x7feea2dc(,%eax,8)
801065f5:	8b 45 f4             	mov    -0xc(%ebp),%eax
801065f8:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
801065ff:	80 
80106600:	83 e2 f0             	and    $0xfffffff0,%edx
80106603:	83 ca 0e             	or     $0xe,%edx
80106606:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
8010660d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106610:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
80106617:	80 
80106618:	83 e2 ef             	and    $0xffffffef,%edx
8010661b:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
80106622:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106625:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
8010662c:	80 
8010662d:	83 e2 9f             	and    $0xffffff9f,%edx
80106630:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
80106637:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010663a:	0f b6 14 c5 25 5d 11 	movzbl -0x7feea2db(,%eax,8),%edx
80106641:	80 
80106642:	83 ca 80             	or     $0xffffff80,%edx
80106645:	88 14 c5 25 5d 11 80 	mov    %dl,-0x7feea2db(,%eax,8)
8010664c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010664f:	8b 04 85 78 b0 10 80 	mov    -0x7fef4f88(,%eax,4),%eax
80106656:	c1 e8 10             	shr    $0x10,%eax
80106659:	89 c2                	mov    %eax,%edx
8010665b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010665e:	66 89 14 c5 26 5d 11 	mov    %dx,-0x7feea2da(,%eax,8)
80106665:	80 
void
tvinit(void)
{
  int i;

  for(i = 0; i < 256; i++)
80106666:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010666a:	81 7d f4 ff 00 00 00 	cmpl   $0xff,-0xc(%ebp)
80106671:	0f 8e 30 ff ff ff    	jle    801065a7 <tvinit+0x12>
    SETGATE(idt[i], 0, SEG_KCODE<<3, vectors[i], 0);
  SETGATE(idt[T_SYSCALL], 1, SEG_KCODE<<3, vectors[T_SYSCALL], DPL_USER);
80106677:	a1 78 b1 10 80       	mov    0x8010b178,%eax
8010667c:	66 a3 20 5f 11 80    	mov    %ax,0x80115f20
80106682:	66 c7 05 22 5f 11 80 	movw   $0x8,0x80115f22
80106689:	08 00 
8010668b:	0f b6 05 24 5f 11 80 	movzbl 0x80115f24,%eax
80106692:	83 e0 e0             	and    $0xffffffe0,%eax
80106695:	a2 24 5f 11 80       	mov    %al,0x80115f24
8010669a:	0f b6 05 24 5f 11 80 	movzbl 0x80115f24,%eax
801066a1:	83 e0 1f             	and    $0x1f,%eax
801066a4:	a2 24 5f 11 80       	mov    %al,0x80115f24
801066a9:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
801066b0:	83 c8 0f             	or     $0xf,%eax
801066b3:	a2 25 5f 11 80       	mov    %al,0x80115f25
801066b8:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
801066bf:	83 e0 ef             	and    $0xffffffef,%eax
801066c2:	a2 25 5f 11 80       	mov    %al,0x80115f25
801066c7:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
801066ce:	83 c8 60             	or     $0x60,%eax
801066d1:	a2 25 5f 11 80       	mov    %al,0x80115f25
801066d6:	0f b6 05 25 5f 11 80 	movzbl 0x80115f25,%eax
801066dd:	83 c8 80             	or     $0xffffff80,%eax
801066e0:	a2 25 5f 11 80       	mov    %al,0x80115f25
801066e5:	a1 78 b1 10 80       	mov    0x8010b178,%eax
801066ea:	c1 e8 10             	shr    $0x10,%eax
801066ed:	66 a3 26 5f 11 80    	mov    %ax,0x80115f26

  initlock(&tickslock, "time");
801066f3:	83 ec 08             	sub    $0x8,%esp
801066f6:	68 7c 89 10 80       	push   $0x8010897c
801066fb:	68 e0 5c 11 80       	push   $0x80115ce0
80106700:	e8 2f e8 ff ff       	call   80104f34 <initlock>
80106705:	83 c4 10             	add    $0x10,%esp
}
80106708:	90                   	nop
80106709:	c9                   	leave  
8010670a:	c3                   	ret    

8010670b <idtinit>:

void
idtinit(void)
{
8010670b:	55                   	push   %ebp
8010670c:	89 e5                	mov    %esp,%ebp
  lidt(idt, sizeof(idt));
8010670e:	68 00 08 00 00       	push   $0x800
80106713:	68 20 5d 11 80       	push   $0x80115d20
80106718:	e8 3d fe ff ff       	call   8010655a <lidt>
8010671d:	83 c4 08             	add    $0x8,%esp
}
80106720:	90                   	nop
80106721:	c9                   	leave  
80106722:	c3                   	ret    

80106723 <trap>:

//PAGEBREAK: 41
void
trap(struct trapframe *tf)
{
80106723:	55                   	push   %ebp
80106724:	89 e5                	mov    %esp,%ebp
80106726:	57                   	push   %edi
80106727:	56                   	push   %esi
80106728:	53                   	push   %ebx
80106729:	83 ec 2c             	sub    $0x2c,%esp
	char *mem;
    uint addr;

  if(tf->trapno == T_SYSCALL){
8010672c:	8b 45 08             	mov    0x8(%ebp),%eax
8010672f:	8b 40 30             	mov    0x30(%eax),%eax
80106732:	83 f8 40             	cmp    $0x40,%eax
80106735:	75 3d                	jne    80106774 <trap+0x51>
    if(myproc()->killed)
80106737:	e8 4c db ff ff       	call   80104288 <myproc>
8010673c:	8b 40 24             	mov    0x24(%eax),%eax
8010673f:	85 c0                	test   %eax,%eax
80106741:	74 05                	je     80106748 <trap+0x25>
      exit();
80106743:	e8 c2 df ff ff       	call   8010470a <exit>
    myproc()->tf = tf;
80106748:	e8 3b db ff ff       	call   80104288 <myproc>
8010674d:	89 c2                	mov    %eax,%edx
8010674f:	8b 45 08             	mov    0x8(%ebp),%eax
80106752:	89 42 18             	mov    %eax,0x18(%edx)
    syscall();
80106755:	e8 6b ee ff ff       	call   801055c5 <syscall>
    if(myproc()->killed)
8010675a:	e8 29 db ff ff       	call   80104288 <myproc>
8010675f:	8b 40 24             	mov    0x24(%eax),%eax
80106762:	85 c0                	test   %eax,%eax
80106764:	0f 84 ab 03 00 00    	je     80106b15 <trap+0x3f2>
      exit();
8010676a:	e8 9b df ff ff       	call   8010470a <exit>
    return;
8010676f:	e9 a1 03 00 00       	jmp    80106b15 <trap+0x3f2>
  }

  switch(tf->trapno){
80106774:	8b 45 08             	mov    0x8(%ebp),%eax
80106777:	8b 40 30             	mov    0x30(%eax),%eax
8010677a:	83 e8 0e             	sub    $0xe,%eax
8010677d:	83 f8 31             	cmp    $0x31,%eax
80106780:	0f 87 59 02 00 00    	ja     801069df <trap+0x2bc>
80106786:	8b 04 85 f8 8a 10 80 	mov    -0x7fef7508(,%eax,4),%eax
8010678d:	ff e0                	jmp    *%eax
  case T_IRQ0 + IRQ_TIMER:
    if(cpuid() == 0){
8010678f:	e8 5b da ff ff       	call   801041ef <cpuid>
80106794:	85 c0                	test   %eax,%eax
80106796:	75 3d                	jne    801067d5 <trap+0xb2>
      acquire(&tickslock);
80106798:	83 ec 0c             	sub    $0xc,%esp
8010679b:	68 e0 5c 11 80       	push   $0x80115ce0
801067a0:	e8 b1 e7 ff ff       	call   80104f56 <acquire>
801067a5:	83 c4 10             	add    $0x10,%esp
      ticks++;
801067a8:	a1 20 65 11 80       	mov    0x80116520,%eax
801067ad:	83 c0 01             	add    $0x1,%eax
801067b0:	a3 20 65 11 80       	mov    %eax,0x80116520
      wakeup(&ticks);
801067b5:	83 ec 0c             	sub    $0xc,%esp
801067b8:	68 20 65 11 80       	push   $0x80116520
801067bd:	e8 61 e4 ff ff       	call   80104c23 <wakeup>
801067c2:	83 c4 10             	add    $0x10,%esp
      release(&tickslock);
801067c5:	83 ec 0c             	sub    $0xc,%esp
801067c8:	68 e0 5c 11 80       	push   $0x80115ce0
801067cd:	e8 f2 e7 ff ff       	call   80104fc4 <release>
801067d2:	83 c4 10             	add    $0x10,%esp
    }
    lapiceoi();
801067d5:	e8 33 c8 ff ff       	call   8010300d <lapiceoi>
    break;
801067da:	e9 b6 02 00 00       	jmp    80106a95 <trap+0x372>
  case T_IRQ0 + IRQ_IDE:
    ideintr();
801067df:	e8 a3 c0 ff ff       	call   80102887 <ideintr>
    lapiceoi();
801067e4:	e8 24 c8 ff ff       	call   8010300d <lapiceoi>
    break;
801067e9:	e9 a7 02 00 00       	jmp    80106a95 <trap+0x372>
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
  case T_IRQ0 + IRQ_KBD:
    kbdintr();
801067ee:	e8 63 c6 ff ff       	call   80102e56 <kbdintr>
    lapiceoi();
801067f3:	e8 15 c8 ff ff       	call   8010300d <lapiceoi>
    break;
801067f8:	e9 98 02 00 00       	jmp    80106a95 <trap+0x372>
  case T_IRQ0 + IRQ_COM1:
    uartintr();
801067fd:	e8 e7 04 00 00       	call   80106ce9 <uartintr>
    lapiceoi();
80106802:	e8 06 c8 ff ff       	call   8010300d <lapiceoi>
    break;
80106807:	e9 89 02 00 00       	jmp    80106a95 <trap+0x372>
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
8010680c:	8b 45 08             	mov    0x8(%ebp),%eax
8010680f:	8b 70 38             	mov    0x38(%eax),%esi
            cpuid(), tf->cs, tf->eip);
80106812:	8b 45 08             	mov    0x8(%ebp),%eax
80106815:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
    uartintr();
    lapiceoi();
    break;
  case T_IRQ0 + 7:
  case T_IRQ0 + IRQ_SPURIOUS:
    cprintf("cpu%d: spurious interrupt at %x:%x\n",
80106819:	0f b7 d8             	movzwl %ax,%ebx
8010681c:	e8 ce d9 ff ff       	call   801041ef <cpuid>
80106821:	56                   	push   %esi
80106822:	53                   	push   %ebx
80106823:	50                   	push   %eax
80106824:	68 84 89 10 80       	push   $0x80108984
80106829:	e8 d2 9b ff ff       	call   80100400 <cprintf>
8010682e:	83 c4 10             	add    $0x10,%esp
            cpuid(), tf->cs, tf->eip);
    lapiceoi();
80106831:	e8 d7 c7 ff ff       	call   8010300d <lapiceoi>
    break;
80106836:	e9 5a 02 00 00       	jmp    80106a95 <trap+0x372>

  case T_PGFLT:
	//esto es para comprobar que el fallo de pagina no ocurre en modo kernel
    if(myproc() == 0 || (tf->cs&3) == 0){
8010683b:	e8 48 da ff ff       	call   80104288 <myproc>
80106840:	85 c0                	test   %eax,%eax
80106842:	74 11                	je     80106855 <trap+0x132>
80106844:	8b 45 08             	mov    0x8(%ebp),%eax
80106847:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
8010684b:	0f b7 c0             	movzwl %ax,%eax
8010684e:	83 e0 03             	and    $0x3,%eax
80106851:	85 c0                	test   %eax,%eax
80106853:	75 3b                	jne    80106890 <trap+0x16d>
      // In kernel, it must be our mistake.
      cprintf("unexpected page fault (%d) from cpu %d eip %x (cr2=0x%x)\n",
80106855:	e8 2a fd ff ff       	call   80106584 <rcr2>
8010685a:	89 c6                	mov    %eax,%esi
8010685c:	8b 45 08             	mov    0x8(%ebp),%eax
8010685f:	8b 58 38             	mov    0x38(%eax),%ebx
80106862:	e8 88 d9 ff ff       	call   801041ef <cpuid>
80106867:	89 c2                	mov    %eax,%edx
80106869:	8b 45 08             	mov    0x8(%ebp),%eax
8010686c:	8b 40 30             	mov    0x30(%eax),%eax
8010686f:	83 ec 0c             	sub    $0xc,%esp
80106872:	56                   	push   %esi
80106873:	53                   	push   %ebx
80106874:	52                   	push   %edx
80106875:	50                   	push   %eax
80106876:	68 a8 89 10 80       	push   $0x801089a8
8010687b:	e8 80 9b ff ff       	call   80100400 <cprintf>
80106880:	83 c4 20             	add    $0x20,%esp
              tf->trapno, cpuid(), tf->eip, rcr2());
      panic("page fault in kernel");
80106883:	83 ec 0c             	sub    $0xc,%esp
80106886:	68 e2 89 10 80       	push   $0x801089e2
8010688b:	e8 10 9d ff ff       	call   801005a0 <panic>
    }
    //En espacio de usuario, creamos una nueba pagina fisica.
	//registro rcr2 es la direccion que ha generado la pagina
	//hay que comprobar que la addr que genera el fallo esta dentro del espacio del proceso
	mem = kalloc();
80106890:	e8 00 c4 ff ff       	call   80102c95 <kalloc>
80106895:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(mem == 0){
80106898:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
8010689c:	75 70                	jne    8010690e <trap+0x1eb>
	  cprintf("page fault out of memory\n");
8010689e:	83 ec 0c             	sub    $0xc,%esp
801068a1:	68 f7 89 10 80       	push   $0x801089f7
801068a6:	e8 55 9b ff ff       	call   80100400 <cprintf>
801068ab:	83 c4 10             	add    $0x10,%esp
      cprintf("pid %d %s: page fault %d err %d on cpu %d "
801068ae:	e8 d1 fc ff ff       	call   80106584 <rcr2>
801068b3:	89 45 d4             	mov    %eax,-0x2c(%ebp)
801068b6:	8b 45 08             	mov    0x8(%ebp),%eax
801068b9:	8b 78 38             	mov    0x38(%eax),%edi
801068bc:	e8 2e d9 ff ff       	call   801041ef <cpuid>
801068c1:	89 45 d0             	mov    %eax,-0x30(%ebp)
801068c4:	8b 45 08             	mov    0x8(%ebp),%eax
801068c7:	8b 70 34             	mov    0x34(%eax),%esi
801068ca:	8b 45 08             	mov    0x8(%ebp),%eax
801068cd:	8b 58 30             	mov    0x30(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
801068d0:	e8 b3 d9 ff ff       	call   80104288 <myproc>
801068d5:	8d 48 6c             	lea    0x6c(%eax),%ecx
801068d8:	89 4d cc             	mov    %ecx,-0x34(%ebp)
801068db:	e8 a8 d9 ff ff       	call   80104288 <myproc>
	//registro rcr2 es la direccion que ha generado la pagina
	//hay que comprobar que la addr que genera el fallo esta dentro del espacio del proceso
	mem = kalloc();
    if(mem == 0){
	  cprintf("page fault out of memory\n");
      cprintf("pid %d %s: page fault %d err %d on cpu %d "
801068e0:	8b 40 10             	mov    0x10(%eax),%eax
801068e3:	ff 75 d4             	pushl  -0x2c(%ebp)
801068e6:	57                   	push   %edi
801068e7:	ff 75 d0             	pushl  -0x30(%ebp)
801068ea:	56                   	push   %esi
801068eb:	53                   	push   %ebx
801068ec:	ff 75 cc             	pushl  -0x34(%ebp)
801068ef:	50                   	push   %eax
801068f0:	68 14 8a 10 80       	push   $0x80108a14
801068f5:	e8 06 9b ff ff       	call   80100400 <cprintf>
801068fa:	83 c4 20             	add    $0x20,%esp
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
            tf->err, cpuid(), tf->eip, rcr2());
      myproc()->killed = 1;
801068fd:	e8 86 d9 ff ff       	call   80104288 <myproc>
80106902:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
					myproc()->pid, myproc()->name, tf->trapno,
					tf->err, cpuid(), tf->eip, rcr2());
      		myproc()->killed = 1;
    	}
  	}
    break;
80106909:	e9 86 01 00 00       	jmp    80106a94 <trap+0x371>
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
            tf->err, cpuid(), tf->eip, rcr2());
      myproc()->killed = 1;
    }else{
    	memset(mem, 0, PGSIZE);// rellenamos la pagina de 0
8010690e:	83 ec 04             	sub    $0x4,%esp
80106911:	68 00 10 00 00       	push   $0x1000
80106916:	6a 00                	push   $0x0
80106918:	ff 75 e4             	pushl  -0x1c(%ebp)
8010691b:	e8 ad e8 ff ff       	call   801051cd <memset>
80106920:	83 c4 10             	add    $0x10,%esp
		addr=PGROUNDDOWN(rcr2()); //redondeamos hacia abajo para obtener la direccion de memoria de la pagina
80106923:	e8 5c fc ff ff       	call   80106584 <rcr2>
80106928:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010692d:	89 45 e0             	mov    %eax,-0x20(%ebp)
    	if(mappages(myproc()->pgdir, (char*)addr, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
80106930:	8b 45 e4             	mov    -0x1c(%ebp),%eax
80106933:	8d b0 00 00 00 80    	lea    -0x80000000(%eax),%esi
80106939:	8b 5d e0             	mov    -0x20(%ebp),%ebx
8010693c:	e8 47 d9 ff ff       	call   80104288 <myproc>
80106941:	8b 40 04             	mov    0x4(%eax),%eax
80106944:	83 ec 0c             	sub    $0xc,%esp
80106947:	6a 06                	push   $0x6
80106949:	56                   	push   %esi
8010694a:	68 00 10 00 00       	push   $0x1000
8010694f:	53                   	push   %ebx
80106950:	50                   	push   %eax
80106951:	e8 57 12 00 00       	call   80107bad <mappages>
80106956:	83 c4 20             	add    $0x20,%esp
80106959:	85 c0                	test   %eax,%eax
8010695b:	0f 89 33 01 00 00    	jns    80106a94 <trap+0x371>
	      	cprintf("page fault out of memory (2)\n");
80106961:	83 ec 0c             	sub    $0xc,%esp
80106964:	68 5d 8a 10 80       	push   $0x80108a5d
80106969:	e8 92 9a ff ff       	call   80100400 <cprintf>
8010696e:	83 c4 10             	add    $0x10,%esp
      		kfree(mem);
80106971:	83 ec 0c             	sub    $0xc,%esp
80106974:	ff 75 e4             	pushl  -0x1c(%ebp)
80106977:	e8 7f c2 ff ff       	call   80102bfb <kfree>
8010697c:	83 c4 10             	add    $0x10,%esp
			cprintf("pid %d %s: page fault %d err %d on cpu %d "
8010697f:	e8 00 fc ff ff       	call   80106584 <rcr2>
80106984:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80106987:	8b 45 08             	mov    0x8(%ebp),%eax
8010698a:	8b 78 38             	mov    0x38(%eax),%edi
8010698d:	e8 5d d8 ff ff       	call   801041ef <cpuid>
80106992:	89 45 d0             	mov    %eax,-0x30(%ebp)
80106995:	8b 45 08             	mov    0x8(%ebp),%eax
80106998:	8b 70 34             	mov    0x34(%eax),%esi
8010699b:	8b 45 08             	mov    0x8(%ebp),%eax
8010699e:	8b 58 30             	mov    0x30(%eax),%ebx
					"eip 0x%x addr 0x%x--kill proc\n",
					myproc()->pid, myproc()->name, tf->trapno,
801069a1:	e8 e2 d8 ff ff       	call   80104288 <myproc>
801069a6:	8d 48 6c             	lea    0x6c(%eax),%ecx
801069a9:	89 4d cc             	mov    %ecx,-0x34(%ebp)
801069ac:	e8 d7 d8 ff ff       	call   80104288 <myproc>
    	memset(mem, 0, PGSIZE);// rellenamos la pagina de 0
		addr=PGROUNDDOWN(rcr2()); //redondeamos hacia abajo para obtener la direccion de memoria de la pagina
    	if(mappages(myproc()->pgdir, (char*)addr, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
	      	cprintf("page fault out of memory (2)\n");
      		kfree(mem);
			cprintf("pid %d %s: page fault %d err %d on cpu %d "
801069b1:	8b 40 10             	mov    0x10(%eax),%eax
801069b4:	ff 75 d4             	pushl  -0x2c(%ebp)
801069b7:	57                   	push   %edi
801069b8:	ff 75 d0             	pushl  -0x30(%ebp)
801069bb:	56                   	push   %esi
801069bc:	53                   	push   %ebx
801069bd:	ff 75 cc             	pushl  -0x34(%ebp)
801069c0:	50                   	push   %eax
801069c1:	68 14 8a 10 80       	push   $0x80108a14
801069c6:	e8 35 9a ff ff       	call   80100400 <cprintf>
801069cb:	83 c4 20             	add    $0x20,%esp
					"eip 0x%x addr 0x%x--kill proc\n",
					myproc()->pid, myproc()->name, tf->trapno,
					tf->err, cpuid(), tf->eip, rcr2());
      		myproc()->killed = 1;
801069ce:	e8 b5 d8 ff ff       	call   80104288 <myproc>
801069d3:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
    	}
  	}
    break;
801069da:	e9 b5 00 00 00       	jmp    80106a94 <trap+0x371>

  //PAGEBREAK: 13
  default:
    if(myproc() == 0 || (tf->cs&3) == 0){
801069df:	e8 a4 d8 ff ff       	call   80104288 <myproc>
801069e4:	85 c0                	test   %eax,%eax
801069e6:	74 11                	je     801069f9 <trap+0x2d6>
801069e8:	8b 45 08             	mov    0x8(%ebp),%eax
801069eb:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
801069ef:	0f b7 c0             	movzwl %ax,%eax
801069f2:	83 e0 03             	and    $0x3,%eax
801069f5:	85 c0                	test   %eax,%eax
801069f7:	75 3b                	jne    80106a34 <trap+0x311>
      // In kernel, it must be our mistake.
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
801069f9:	e8 86 fb ff ff       	call   80106584 <rcr2>
801069fe:	89 c6                	mov    %eax,%esi
80106a00:	8b 45 08             	mov    0x8(%ebp),%eax
80106a03:	8b 58 38             	mov    0x38(%eax),%ebx
80106a06:	e8 e4 d7 ff ff       	call   801041ef <cpuid>
80106a0b:	89 c2                	mov    %eax,%edx
80106a0d:	8b 45 08             	mov    0x8(%ebp),%eax
80106a10:	8b 40 30             	mov    0x30(%eax),%eax
80106a13:	83 ec 0c             	sub    $0xc,%esp
80106a16:	56                   	push   %esi
80106a17:	53                   	push   %ebx
80106a18:	52                   	push   %edx
80106a19:	50                   	push   %eax
80106a1a:	68 7c 8a 10 80       	push   $0x80108a7c
80106a1f:	e8 dc 99 ff ff       	call   80100400 <cprintf>
80106a24:	83 c4 20             	add    $0x20,%esp
              tf->trapno, cpuid(), tf->eip, rcr2());
      panic("trap");
80106a27:	83 ec 0c             	sub    $0xc,%esp
80106a2a:	68 ae 8a 10 80       	push   $0x80108aae
80106a2f:	e8 6c 9b ff ff       	call   801005a0 <panic>
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106a34:	e8 4b fb ff ff       	call   80106584 <rcr2>
80106a39:	89 45 d4             	mov    %eax,-0x2c(%ebp)
80106a3c:	8b 45 08             	mov    0x8(%ebp),%eax
80106a3f:	8b 78 38             	mov    0x38(%eax),%edi
80106a42:	e8 a8 d7 ff ff       	call   801041ef <cpuid>
80106a47:	89 45 d0             	mov    %eax,-0x30(%ebp)
80106a4a:	8b 45 08             	mov    0x8(%ebp),%eax
80106a4d:	8b 70 34             	mov    0x34(%eax),%esi
80106a50:	8b 45 08             	mov    0x8(%ebp),%eax
80106a53:	8b 58 30             	mov    0x30(%eax),%ebx
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
80106a56:	e8 2d d8 ff ff       	call   80104288 <myproc>
80106a5b:	8d 48 6c             	lea    0x6c(%eax),%ecx
80106a5e:	89 4d cc             	mov    %ecx,-0x34(%ebp)
80106a61:	e8 22 d8 ff ff       	call   80104288 <myproc>
      cprintf("unexpected trap %d from cpu %d eip %x (cr2=0x%x)\n",
              tf->trapno, cpuid(), tf->eip, rcr2());
      panic("trap");
    }
    // In user space, assume process misbehaved.
    cprintf("pid %d %s: trap %d err %d on cpu %d "
80106a66:	8b 40 10             	mov    0x10(%eax),%eax
80106a69:	ff 75 d4             	pushl  -0x2c(%ebp)
80106a6c:	57                   	push   %edi
80106a6d:	ff 75 d0             	pushl  -0x30(%ebp)
80106a70:	56                   	push   %esi
80106a71:	53                   	push   %ebx
80106a72:	ff 75 cc             	pushl  -0x34(%ebp)
80106a75:	50                   	push   %eax
80106a76:	68 b4 8a 10 80       	push   $0x80108ab4
80106a7b:	e8 80 99 ff ff       	call   80100400 <cprintf>
80106a80:	83 c4 20             	add    $0x20,%esp
            "eip 0x%x addr 0x%x--kill proc\n",
            myproc()->pid, myproc()->name, tf->trapno,
            tf->err, cpuid(), tf->eip, rcr2());
    myproc()->killed = 1;
80106a83:	e8 00 d8 ff ff       	call   80104288 <myproc>
80106a88:	c7 40 24 01 00 00 00 	movl   $0x1,0x24(%eax)
80106a8f:	eb 04                	jmp    80106a95 <trap+0x372>
    ideintr();
    lapiceoi();
    break;
  case T_IRQ0 + IRQ_IDE+1:
    // Bochs generates spurious IDE1 interrupts.
    break;
80106a91:	90                   	nop
80106a92:	eb 01                	jmp    80106a95 <trap+0x372>
					myproc()->pid, myproc()->name, tf->trapno,
					tf->err, cpuid(), tf->eip, rcr2());
      		myproc()->killed = 1;
    	}
  	}
    break;
80106a94:	90                   	nop
  }

  // Force process exit if it has been killed and is in user space.
  // (If it is still executing in the kernel, let it keep running
  // until it gets to the regular system call return.)
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80106a95:	e8 ee d7 ff ff       	call   80104288 <myproc>
80106a9a:	85 c0                	test   %eax,%eax
80106a9c:	74 23                	je     80106ac1 <trap+0x39e>
80106a9e:	e8 e5 d7 ff ff       	call   80104288 <myproc>
80106aa3:	8b 40 24             	mov    0x24(%eax),%eax
80106aa6:	85 c0                	test   %eax,%eax
80106aa8:	74 17                	je     80106ac1 <trap+0x39e>
80106aaa:	8b 45 08             	mov    0x8(%ebp),%eax
80106aad:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106ab1:	0f b7 c0             	movzwl %ax,%eax
80106ab4:	83 e0 03             	and    $0x3,%eax
80106ab7:	83 f8 03             	cmp    $0x3,%eax
80106aba:	75 05                	jne    80106ac1 <trap+0x39e>
    exit();
80106abc:	e8 49 dc ff ff       	call   8010470a <exit>

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80106ac1:	e8 c2 d7 ff ff       	call   80104288 <myproc>
80106ac6:	85 c0                	test   %eax,%eax
80106ac8:	74 1d                	je     80106ae7 <trap+0x3c4>
80106aca:	e8 b9 d7 ff ff       	call   80104288 <myproc>
80106acf:	8b 40 0c             	mov    0xc(%eax),%eax
80106ad2:	83 f8 04             	cmp    $0x4,%eax
80106ad5:	75 10                	jne    80106ae7 <trap+0x3c4>
     tf->trapno == T_IRQ0+IRQ_TIMER)
80106ad7:	8b 45 08             	mov    0x8(%ebp),%eax
80106ada:	8b 40 30             	mov    0x30(%eax),%eax
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
    exit();

  // Force process to give up CPU on clock tick.
  // If interrupts were on while locks held, would need to check nlock.
  if(myproc() && myproc()->state == RUNNING &&
80106add:	83 f8 20             	cmp    $0x20,%eax
80106ae0:	75 05                	jne    80106ae7 <trap+0x3c4>
     tf->trapno == T_IRQ0+IRQ_TIMER)
    yield();
80106ae2:	e8 d6 df ff ff       	call   80104abd <yield>

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
80106ae7:	e8 9c d7 ff ff       	call   80104288 <myproc>
80106aec:	85 c0                	test   %eax,%eax
80106aee:	74 26                	je     80106b16 <trap+0x3f3>
80106af0:	e8 93 d7 ff ff       	call   80104288 <myproc>
80106af5:	8b 40 24             	mov    0x24(%eax),%eax
80106af8:	85 c0                	test   %eax,%eax
80106afa:	74 1a                	je     80106b16 <trap+0x3f3>
80106afc:	8b 45 08             	mov    0x8(%ebp),%eax
80106aff:	0f b7 40 3c          	movzwl 0x3c(%eax),%eax
80106b03:	0f b7 c0             	movzwl %ax,%eax
80106b06:	83 e0 03             	and    $0x3,%eax
80106b09:	83 f8 03             	cmp    $0x3,%eax
80106b0c:	75 08                	jne    80106b16 <trap+0x3f3>
    exit();
80106b0e:	e8 f7 db ff ff       	call   8010470a <exit>
80106b13:	eb 01                	jmp    80106b16 <trap+0x3f3>
      exit();
    myproc()->tf = tf;
    syscall();
    if(myproc()->killed)
      exit();
    return;
80106b15:	90                   	nop
    yield();

  // Check if the process has been killed since we yielded
  if(myproc() && myproc()->killed && (tf->cs&3) == DPL_USER)
    exit();
}
80106b16:	8d 65 f4             	lea    -0xc(%ebp),%esp
80106b19:	5b                   	pop    %ebx
80106b1a:	5e                   	pop    %esi
80106b1b:	5f                   	pop    %edi
80106b1c:	5d                   	pop    %ebp
80106b1d:	c3                   	ret    

80106b1e <inb>:
// Routines to let C code use special x86 instructions.

static inline uchar
inb(ushort port)
{
80106b1e:	55                   	push   %ebp
80106b1f:	89 e5                	mov    %esp,%ebp
80106b21:	83 ec 14             	sub    $0x14,%esp
80106b24:	8b 45 08             	mov    0x8(%ebp),%eax
80106b27:	66 89 45 ec          	mov    %ax,-0x14(%ebp)
  uchar data;

  asm volatile("in %1,%0" : "=a" (data) : "d" (port));
80106b2b:	0f b7 45 ec          	movzwl -0x14(%ebp),%eax
80106b2f:	89 c2                	mov    %eax,%edx
80106b31:	ec                   	in     (%dx),%al
80106b32:	88 45 ff             	mov    %al,-0x1(%ebp)
  return data;
80106b35:	0f b6 45 ff          	movzbl -0x1(%ebp),%eax
}
80106b39:	c9                   	leave  
80106b3a:	c3                   	ret    

80106b3b <outb>:
               "memory", "cc");
}

static inline void
outb(ushort port, uchar data)
{
80106b3b:	55                   	push   %ebp
80106b3c:	89 e5                	mov    %esp,%ebp
80106b3e:	83 ec 08             	sub    $0x8,%esp
80106b41:	8b 55 08             	mov    0x8(%ebp),%edx
80106b44:	8b 45 0c             	mov    0xc(%ebp),%eax
80106b47:	66 89 55 fc          	mov    %dx,-0x4(%ebp)
80106b4b:	88 45 f8             	mov    %al,-0x8(%ebp)
  asm volatile("out %0,%1" : : "a" (data), "d" (port));
80106b4e:	0f b6 45 f8          	movzbl -0x8(%ebp),%eax
80106b52:	0f b7 55 fc          	movzwl -0x4(%ebp),%edx
80106b56:	ee                   	out    %al,(%dx)
}
80106b57:	90                   	nop
80106b58:	c9                   	leave  
80106b59:	c3                   	ret    

80106b5a <uartinit>:

static int uart;    // is there a uart?

void
uartinit(void)
{
80106b5a:	55                   	push   %ebp
80106b5b:	89 e5                	mov    %esp,%ebp
80106b5d:	83 ec 18             	sub    $0x18,%esp
  char *p;

  // Turn off the FIFO
  outb(COM1+2, 0);
80106b60:	6a 00                	push   $0x0
80106b62:	68 fa 03 00 00       	push   $0x3fa
80106b67:	e8 cf ff ff ff       	call   80106b3b <outb>
80106b6c:	83 c4 08             	add    $0x8,%esp

  // 9600 baud, 8 data bits, 1 stop bit, parity off.
  outb(COM1+3, 0x80);    // Unlock divisor
80106b6f:	68 80 00 00 00       	push   $0x80
80106b74:	68 fb 03 00 00       	push   $0x3fb
80106b79:	e8 bd ff ff ff       	call   80106b3b <outb>
80106b7e:	83 c4 08             	add    $0x8,%esp
  outb(COM1+0, 115200/9600);
80106b81:	6a 0c                	push   $0xc
80106b83:	68 f8 03 00 00       	push   $0x3f8
80106b88:	e8 ae ff ff ff       	call   80106b3b <outb>
80106b8d:	83 c4 08             	add    $0x8,%esp
  outb(COM1+1, 0);
80106b90:	6a 00                	push   $0x0
80106b92:	68 f9 03 00 00       	push   $0x3f9
80106b97:	e8 9f ff ff ff       	call   80106b3b <outb>
80106b9c:	83 c4 08             	add    $0x8,%esp
  outb(COM1+3, 0x03);    // Lock divisor, 8 data bits.
80106b9f:	6a 03                	push   $0x3
80106ba1:	68 fb 03 00 00       	push   $0x3fb
80106ba6:	e8 90 ff ff ff       	call   80106b3b <outb>
80106bab:	83 c4 08             	add    $0x8,%esp
  outb(COM1+4, 0);
80106bae:	6a 00                	push   $0x0
80106bb0:	68 fc 03 00 00       	push   $0x3fc
80106bb5:	e8 81 ff ff ff       	call   80106b3b <outb>
80106bba:	83 c4 08             	add    $0x8,%esp
  outb(COM1+1, 0x01);    // Enable receive interrupts.
80106bbd:	6a 01                	push   $0x1
80106bbf:	68 f9 03 00 00       	push   $0x3f9
80106bc4:	e8 72 ff ff ff       	call   80106b3b <outb>
80106bc9:	83 c4 08             	add    $0x8,%esp

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
80106bcc:	68 fd 03 00 00       	push   $0x3fd
80106bd1:	e8 48 ff ff ff       	call   80106b1e <inb>
80106bd6:	83 c4 04             	add    $0x4,%esp
80106bd9:	3c ff                	cmp    $0xff,%al
80106bdb:	74 61                	je     80106c3e <uartinit+0xe4>
    return;
  uart = 1;
80106bdd:	c7 05 24 b6 10 80 01 	movl   $0x1,0x8010b624
80106be4:	00 00 00 

  // Acknowledge pre-existing interrupt conditions;
  // enable interrupts.
  inb(COM1+2);
80106be7:	68 fa 03 00 00       	push   $0x3fa
80106bec:	e8 2d ff ff ff       	call   80106b1e <inb>
80106bf1:	83 c4 04             	add    $0x4,%esp
  inb(COM1+0);
80106bf4:	68 f8 03 00 00       	push   $0x3f8
80106bf9:	e8 20 ff ff ff       	call   80106b1e <inb>
80106bfe:	83 c4 04             	add    $0x4,%esp
  ioapicenable(IRQ_COM1, 0);
80106c01:	83 ec 08             	sub    $0x8,%esp
80106c04:	6a 00                	push   $0x0
80106c06:	6a 04                	push   $0x4
80106c08:	e8 17 bf ff ff       	call   80102b24 <ioapicenable>
80106c0d:	83 c4 10             	add    $0x10,%esp

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106c10:	c7 45 f4 c0 8b 10 80 	movl   $0x80108bc0,-0xc(%ebp)
80106c17:	eb 19                	jmp    80106c32 <uartinit+0xd8>
    uartputc(*p);
80106c19:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c1c:	0f b6 00             	movzbl (%eax),%eax
80106c1f:	0f be c0             	movsbl %al,%eax
80106c22:	83 ec 0c             	sub    $0xc,%esp
80106c25:	50                   	push   %eax
80106c26:	e8 16 00 00 00       	call   80106c41 <uartputc>
80106c2b:	83 c4 10             	add    $0x10,%esp
  inb(COM1+2);
  inb(COM1+0);
  ioapicenable(IRQ_COM1, 0);

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
80106c2e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80106c35:	0f b6 00             	movzbl (%eax),%eax
80106c38:	84 c0                	test   %al,%al
80106c3a:	75 dd                	jne    80106c19 <uartinit+0xbf>
80106c3c:	eb 01                	jmp    80106c3f <uartinit+0xe5>
  outb(COM1+4, 0);
  outb(COM1+1, 0x01);    // Enable receive interrupts.

  // If status is 0xFF, no serial port.
  if(inb(COM1+5) == 0xFF)
    return;
80106c3e:	90                   	nop
  ioapicenable(IRQ_COM1, 0);

  // Announce that we're here.
  for(p="xv6...\n"; *p; p++)
    uartputc(*p);
}
80106c3f:	c9                   	leave  
80106c40:	c3                   	ret    

80106c41 <uartputc>:

void
uartputc(int c)
{
80106c41:	55                   	push   %ebp
80106c42:	89 e5                	mov    %esp,%ebp
80106c44:	83 ec 18             	sub    $0x18,%esp
  int i;

  if(!uart)
80106c47:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106c4c:	85 c0                	test   %eax,%eax
80106c4e:	74 53                	je     80106ca3 <uartputc+0x62>
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c50:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80106c57:	eb 11                	jmp    80106c6a <uartputc+0x29>
    microdelay(10);
80106c59:	83 ec 0c             	sub    $0xc,%esp
80106c5c:	6a 0a                	push   $0xa
80106c5e:	e8 c5 c3 ff ff       	call   80103028 <microdelay>
80106c63:	83 c4 10             	add    $0x10,%esp
{
  int i;

  if(!uart)
    return;
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
80106c66:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
80106c6a:	83 7d f4 7f          	cmpl   $0x7f,-0xc(%ebp)
80106c6e:	7f 1a                	jg     80106c8a <uartputc+0x49>
80106c70:	83 ec 0c             	sub    $0xc,%esp
80106c73:	68 fd 03 00 00       	push   $0x3fd
80106c78:	e8 a1 fe ff ff       	call   80106b1e <inb>
80106c7d:	83 c4 10             	add    $0x10,%esp
80106c80:	0f b6 c0             	movzbl %al,%eax
80106c83:	83 e0 20             	and    $0x20,%eax
80106c86:	85 c0                	test   %eax,%eax
80106c88:	74 cf                	je     80106c59 <uartputc+0x18>
    microdelay(10);
  outb(COM1+0, c);
80106c8a:	8b 45 08             	mov    0x8(%ebp),%eax
80106c8d:	0f b6 c0             	movzbl %al,%eax
80106c90:	83 ec 08             	sub    $0x8,%esp
80106c93:	50                   	push   %eax
80106c94:	68 f8 03 00 00       	push   $0x3f8
80106c99:	e8 9d fe ff ff       	call   80106b3b <outb>
80106c9e:	83 c4 10             	add    $0x10,%esp
80106ca1:	eb 01                	jmp    80106ca4 <uartputc+0x63>
uartputc(int c)
{
  int i;

  if(!uart)
    return;
80106ca3:	90                   	nop
  for(i = 0; i < 128 && !(inb(COM1+5) & 0x20); i++)
    microdelay(10);
  outb(COM1+0, c);
}
80106ca4:	c9                   	leave  
80106ca5:	c3                   	ret    

80106ca6 <uartgetc>:

static int
uartgetc(void)
{
80106ca6:	55                   	push   %ebp
80106ca7:	89 e5                	mov    %esp,%ebp
  if(!uart)
80106ca9:	a1 24 b6 10 80       	mov    0x8010b624,%eax
80106cae:	85 c0                	test   %eax,%eax
80106cb0:	75 07                	jne    80106cb9 <uartgetc+0x13>
    return -1;
80106cb2:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cb7:	eb 2e                	jmp    80106ce7 <uartgetc+0x41>
  if(!(inb(COM1+5) & 0x01))
80106cb9:	68 fd 03 00 00       	push   $0x3fd
80106cbe:	e8 5b fe ff ff       	call   80106b1e <inb>
80106cc3:	83 c4 04             	add    $0x4,%esp
80106cc6:	0f b6 c0             	movzbl %al,%eax
80106cc9:	83 e0 01             	and    $0x1,%eax
80106ccc:	85 c0                	test   %eax,%eax
80106cce:	75 07                	jne    80106cd7 <uartgetc+0x31>
    return -1;
80106cd0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80106cd5:	eb 10                	jmp    80106ce7 <uartgetc+0x41>
  return inb(COM1+0);
80106cd7:	68 f8 03 00 00       	push   $0x3f8
80106cdc:	e8 3d fe ff ff       	call   80106b1e <inb>
80106ce1:	83 c4 04             	add    $0x4,%esp
80106ce4:	0f b6 c0             	movzbl %al,%eax
}
80106ce7:	c9                   	leave  
80106ce8:	c3                   	ret    

80106ce9 <uartintr>:

void
uartintr(void)
{
80106ce9:	55                   	push   %ebp
80106cea:	89 e5                	mov    %esp,%ebp
80106cec:	83 ec 08             	sub    $0x8,%esp
  consoleintr(uartgetc);
80106cef:	83 ec 0c             	sub    $0xc,%esp
80106cf2:	68 a6 6c 10 80       	push   $0x80106ca6
80106cf7:	e8 30 9b ff ff       	call   8010082c <consoleintr>
80106cfc:	83 c4 10             	add    $0x10,%esp
}
80106cff:	90                   	nop
80106d00:	c9                   	leave  
80106d01:	c3                   	ret    

80106d02 <vector0>:
# generated by vectors.pl - do not edit
# handlers
.globl alltraps
.globl vector0
vector0:
  pushl $0
80106d02:	6a 00                	push   $0x0
  pushl $0
80106d04:	6a 00                	push   $0x0
  jmp alltraps
80106d06:	e9 2c f8 ff ff       	jmp    80106537 <alltraps>

80106d0b <vector1>:
.globl vector1
vector1:
  pushl $0
80106d0b:	6a 00                	push   $0x0
  pushl $1
80106d0d:	6a 01                	push   $0x1
  jmp alltraps
80106d0f:	e9 23 f8 ff ff       	jmp    80106537 <alltraps>

80106d14 <vector2>:
.globl vector2
vector2:
  pushl $0
80106d14:	6a 00                	push   $0x0
  pushl $2
80106d16:	6a 02                	push   $0x2
  jmp alltraps
80106d18:	e9 1a f8 ff ff       	jmp    80106537 <alltraps>

80106d1d <vector3>:
.globl vector3
vector3:
  pushl $0
80106d1d:	6a 00                	push   $0x0
  pushl $3
80106d1f:	6a 03                	push   $0x3
  jmp alltraps
80106d21:	e9 11 f8 ff ff       	jmp    80106537 <alltraps>

80106d26 <vector4>:
.globl vector4
vector4:
  pushl $0
80106d26:	6a 00                	push   $0x0
  pushl $4
80106d28:	6a 04                	push   $0x4
  jmp alltraps
80106d2a:	e9 08 f8 ff ff       	jmp    80106537 <alltraps>

80106d2f <vector5>:
.globl vector5
vector5:
  pushl $0
80106d2f:	6a 00                	push   $0x0
  pushl $5
80106d31:	6a 05                	push   $0x5
  jmp alltraps
80106d33:	e9 ff f7 ff ff       	jmp    80106537 <alltraps>

80106d38 <vector6>:
.globl vector6
vector6:
  pushl $0
80106d38:	6a 00                	push   $0x0
  pushl $6
80106d3a:	6a 06                	push   $0x6
  jmp alltraps
80106d3c:	e9 f6 f7 ff ff       	jmp    80106537 <alltraps>

80106d41 <vector7>:
.globl vector7
vector7:
  pushl $0
80106d41:	6a 00                	push   $0x0
  pushl $7
80106d43:	6a 07                	push   $0x7
  jmp alltraps
80106d45:	e9 ed f7 ff ff       	jmp    80106537 <alltraps>

80106d4a <vector8>:
.globl vector8
vector8:
  pushl $8
80106d4a:	6a 08                	push   $0x8
  jmp alltraps
80106d4c:	e9 e6 f7 ff ff       	jmp    80106537 <alltraps>

80106d51 <vector9>:
.globl vector9
vector9:
  pushl $0
80106d51:	6a 00                	push   $0x0
  pushl $9
80106d53:	6a 09                	push   $0x9
  jmp alltraps
80106d55:	e9 dd f7 ff ff       	jmp    80106537 <alltraps>

80106d5a <vector10>:
.globl vector10
vector10:
  pushl $10
80106d5a:	6a 0a                	push   $0xa
  jmp alltraps
80106d5c:	e9 d6 f7 ff ff       	jmp    80106537 <alltraps>

80106d61 <vector11>:
.globl vector11
vector11:
  pushl $11
80106d61:	6a 0b                	push   $0xb
  jmp alltraps
80106d63:	e9 cf f7 ff ff       	jmp    80106537 <alltraps>

80106d68 <vector12>:
.globl vector12
vector12:
  pushl $12
80106d68:	6a 0c                	push   $0xc
  jmp alltraps
80106d6a:	e9 c8 f7 ff ff       	jmp    80106537 <alltraps>

80106d6f <vector13>:
.globl vector13
vector13:
  pushl $13
80106d6f:	6a 0d                	push   $0xd
  jmp alltraps
80106d71:	e9 c1 f7 ff ff       	jmp    80106537 <alltraps>

80106d76 <vector14>:
.globl vector14
vector14:
  pushl $14
80106d76:	6a 0e                	push   $0xe
  jmp alltraps
80106d78:	e9 ba f7 ff ff       	jmp    80106537 <alltraps>

80106d7d <vector15>:
.globl vector15
vector15:
  pushl $0
80106d7d:	6a 00                	push   $0x0
  pushl $15
80106d7f:	6a 0f                	push   $0xf
  jmp alltraps
80106d81:	e9 b1 f7 ff ff       	jmp    80106537 <alltraps>

80106d86 <vector16>:
.globl vector16
vector16:
  pushl $0
80106d86:	6a 00                	push   $0x0
  pushl $16
80106d88:	6a 10                	push   $0x10
  jmp alltraps
80106d8a:	e9 a8 f7 ff ff       	jmp    80106537 <alltraps>

80106d8f <vector17>:
.globl vector17
vector17:
  pushl $17
80106d8f:	6a 11                	push   $0x11
  jmp alltraps
80106d91:	e9 a1 f7 ff ff       	jmp    80106537 <alltraps>

80106d96 <vector18>:
.globl vector18
vector18:
  pushl $0
80106d96:	6a 00                	push   $0x0
  pushl $18
80106d98:	6a 12                	push   $0x12
  jmp alltraps
80106d9a:	e9 98 f7 ff ff       	jmp    80106537 <alltraps>

80106d9f <vector19>:
.globl vector19
vector19:
  pushl $0
80106d9f:	6a 00                	push   $0x0
  pushl $19
80106da1:	6a 13                	push   $0x13
  jmp alltraps
80106da3:	e9 8f f7 ff ff       	jmp    80106537 <alltraps>

80106da8 <vector20>:
.globl vector20
vector20:
  pushl $0
80106da8:	6a 00                	push   $0x0
  pushl $20
80106daa:	6a 14                	push   $0x14
  jmp alltraps
80106dac:	e9 86 f7 ff ff       	jmp    80106537 <alltraps>

80106db1 <vector21>:
.globl vector21
vector21:
  pushl $0
80106db1:	6a 00                	push   $0x0
  pushl $21
80106db3:	6a 15                	push   $0x15
  jmp alltraps
80106db5:	e9 7d f7 ff ff       	jmp    80106537 <alltraps>

80106dba <vector22>:
.globl vector22
vector22:
  pushl $0
80106dba:	6a 00                	push   $0x0
  pushl $22
80106dbc:	6a 16                	push   $0x16
  jmp alltraps
80106dbe:	e9 74 f7 ff ff       	jmp    80106537 <alltraps>

80106dc3 <vector23>:
.globl vector23
vector23:
  pushl $0
80106dc3:	6a 00                	push   $0x0
  pushl $23
80106dc5:	6a 17                	push   $0x17
  jmp alltraps
80106dc7:	e9 6b f7 ff ff       	jmp    80106537 <alltraps>

80106dcc <vector24>:
.globl vector24
vector24:
  pushl $0
80106dcc:	6a 00                	push   $0x0
  pushl $24
80106dce:	6a 18                	push   $0x18
  jmp alltraps
80106dd0:	e9 62 f7 ff ff       	jmp    80106537 <alltraps>

80106dd5 <vector25>:
.globl vector25
vector25:
  pushl $0
80106dd5:	6a 00                	push   $0x0
  pushl $25
80106dd7:	6a 19                	push   $0x19
  jmp alltraps
80106dd9:	e9 59 f7 ff ff       	jmp    80106537 <alltraps>

80106dde <vector26>:
.globl vector26
vector26:
  pushl $0
80106dde:	6a 00                	push   $0x0
  pushl $26
80106de0:	6a 1a                	push   $0x1a
  jmp alltraps
80106de2:	e9 50 f7 ff ff       	jmp    80106537 <alltraps>

80106de7 <vector27>:
.globl vector27
vector27:
  pushl $0
80106de7:	6a 00                	push   $0x0
  pushl $27
80106de9:	6a 1b                	push   $0x1b
  jmp alltraps
80106deb:	e9 47 f7 ff ff       	jmp    80106537 <alltraps>

80106df0 <vector28>:
.globl vector28
vector28:
  pushl $0
80106df0:	6a 00                	push   $0x0
  pushl $28
80106df2:	6a 1c                	push   $0x1c
  jmp alltraps
80106df4:	e9 3e f7 ff ff       	jmp    80106537 <alltraps>

80106df9 <vector29>:
.globl vector29
vector29:
  pushl $0
80106df9:	6a 00                	push   $0x0
  pushl $29
80106dfb:	6a 1d                	push   $0x1d
  jmp alltraps
80106dfd:	e9 35 f7 ff ff       	jmp    80106537 <alltraps>

80106e02 <vector30>:
.globl vector30
vector30:
  pushl $0
80106e02:	6a 00                	push   $0x0
  pushl $30
80106e04:	6a 1e                	push   $0x1e
  jmp alltraps
80106e06:	e9 2c f7 ff ff       	jmp    80106537 <alltraps>

80106e0b <vector31>:
.globl vector31
vector31:
  pushl $0
80106e0b:	6a 00                	push   $0x0
  pushl $31
80106e0d:	6a 1f                	push   $0x1f
  jmp alltraps
80106e0f:	e9 23 f7 ff ff       	jmp    80106537 <alltraps>

80106e14 <vector32>:
.globl vector32
vector32:
  pushl $0
80106e14:	6a 00                	push   $0x0
  pushl $32
80106e16:	6a 20                	push   $0x20
  jmp alltraps
80106e18:	e9 1a f7 ff ff       	jmp    80106537 <alltraps>

80106e1d <vector33>:
.globl vector33
vector33:
  pushl $0
80106e1d:	6a 00                	push   $0x0
  pushl $33
80106e1f:	6a 21                	push   $0x21
  jmp alltraps
80106e21:	e9 11 f7 ff ff       	jmp    80106537 <alltraps>

80106e26 <vector34>:
.globl vector34
vector34:
  pushl $0
80106e26:	6a 00                	push   $0x0
  pushl $34
80106e28:	6a 22                	push   $0x22
  jmp alltraps
80106e2a:	e9 08 f7 ff ff       	jmp    80106537 <alltraps>

80106e2f <vector35>:
.globl vector35
vector35:
  pushl $0
80106e2f:	6a 00                	push   $0x0
  pushl $35
80106e31:	6a 23                	push   $0x23
  jmp alltraps
80106e33:	e9 ff f6 ff ff       	jmp    80106537 <alltraps>

80106e38 <vector36>:
.globl vector36
vector36:
  pushl $0
80106e38:	6a 00                	push   $0x0
  pushl $36
80106e3a:	6a 24                	push   $0x24
  jmp alltraps
80106e3c:	e9 f6 f6 ff ff       	jmp    80106537 <alltraps>

80106e41 <vector37>:
.globl vector37
vector37:
  pushl $0
80106e41:	6a 00                	push   $0x0
  pushl $37
80106e43:	6a 25                	push   $0x25
  jmp alltraps
80106e45:	e9 ed f6 ff ff       	jmp    80106537 <alltraps>

80106e4a <vector38>:
.globl vector38
vector38:
  pushl $0
80106e4a:	6a 00                	push   $0x0
  pushl $38
80106e4c:	6a 26                	push   $0x26
  jmp alltraps
80106e4e:	e9 e4 f6 ff ff       	jmp    80106537 <alltraps>

80106e53 <vector39>:
.globl vector39
vector39:
  pushl $0
80106e53:	6a 00                	push   $0x0
  pushl $39
80106e55:	6a 27                	push   $0x27
  jmp alltraps
80106e57:	e9 db f6 ff ff       	jmp    80106537 <alltraps>

80106e5c <vector40>:
.globl vector40
vector40:
  pushl $0
80106e5c:	6a 00                	push   $0x0
  pushl $40
80106e5e:	6a 28                	push   $0x28
  jmp alltraps
80106e60:	e9 d2 f6 ff ff       	jmp    80106537 <alltraps>

80106e65 <vector41>:
.globl vector41
vector41:
  pushl $0
80106e65:	6a 00                	push   $0x0
  pushl $41
80106e67:	6a 29                	push   $0x29
  jmp alltraps
80106e69:	e9 c9 f6 ff ff       	jmp    80106537 <alltraps>

80106e6e <vector42>:
.globl vector42
vector42:
  pushl $0
80106e6e:	6a 00                	push   $0x0
  pushl $42
80106e70:	6a 2a                	push   $0x2a
  jmp alltraps
80106e72:	e9 c0 f6 ff ff       	jmp    80106537 <alltraps>

80106e77 <vector43>:
.globl vector43
vector43:
  pushl $0
80106e77:	6a 00                	push   $0x0
  pushl $43
80106e79:	6a 2b                	push   $0x2b
  jmp alltraps
80106e7b:	e9 b7 f6 ff ff       	jmp    80106537 <alltraps>

80106e80 <vector44>:
.globl vector44
vector44:
  pushl $0
80106e80:	6a 00                	push   $0x0
  pushl $44
80106e82:	6a 2c                	push   $0x2c
  jmp alltraps
80106e84:	e9 ae f6 ff ff       	jmp    80106537 <alltraps>

80106e89 <vector45>:
.globl vector45
vector45:
  pushl $0
80106e89:	6a 00                	push   $0x0
  pushl $45
80106e8b:	6a 2d                	push   $0x2d
  jmp alltraps
80106e8d:	e9 a5 f6 ff ff       	jmp    80106537 <alltraps>

80106e92 <vector46>:
.globl vector46
vector46:
  pushl $0
80106e92:	6a 00                	push   $0x0
  pushl $46
80106e94:	6a 2e                	push   $0x2e
  jmp alltraps
80106e96:	e9 9c f6 ff ff       	jmp    80106537 <alltraps>

80106e9b <vector47>:
.globl vector47
vector47:
  pushl $0
80106e9b:	6a 00                	push   $0x0
  pushl $47
80106e9d:	6a 2f                	push   $0x2f
  jmp alltraps
80106e9f:	e9 93 f6 ff ff       	jmp    80106537 <alltraps>

80106ea4 <vector48>:
.globl vector48
vector48:
  pushl $0
80106ea4:	6a 00                	push   $0x0
  pushl $48
80106ea6:	6a 30                	push   $0x30
  jmp alltraps
80106ea8:	e9 8a f6 ff ff       	jmp    80106537 <alltraps>

80106ead <vector49>:
.globl vector49
vector49:
  pushl $0
80106ead:	6a 00                	push   $0x0
  pushl $49
80106eaf:	6a 31                	push   $0x31
  jmp alltraps
80106eb1:	e9 81 f6 ff ff       	jmp    80106537 <alltraps>

80106eb6 <vector50>:
.globl vector50
vector50:
  pushl $0
80106eb6:	6a 00                	push   $0x0
  pushl $50
80106eb8:	6a 32                	push   $0x32
  jmp alltraps
80106eba:	e9 78 f6 ff ff       	jmp    80106537 <alltraps>

80106ebf <vector51>:
.globl vector51
vector51:
  pushl $0
80106ebf:	6a 00                	push   $0x0
  pushl $51
80106ec1:	6a 33                	push   $0x33
  jmp alltraps
80106ec3:	e9 6f f6 ff ff       	jmp    80106537 <alltraps>

80106ec8 <vector52>:
.globl vector52
vector52:
  pushl $0
80106ec8:	6a 00                	push   $0x0
  pushl $52
80106eca:	6a 34                	push   $0x34
  jmp alltraps
80106ecc:	e9 66 f6 ff ff       	jmp    80106537 <alltraps>

80106ed1 <vector53>:
.globl vector53
vector53:
  pushl $0
80106ed1:	6a 00                	push   $0x0
  pushl $53
80106ed3:	6a 35                	push   $0x35
  jmp alltraps
80106ed5:	e9 5d f6 ff ff       	jmp    80106537 <alltraps>

80106eda <vector54>:
.globl vector54
vector54:
  pushl $0
80106eda:	6a 00                	push   $0x0
  pushl $54
80106edc:	6a 36                	push   $0x36
  jmp alltraps
80106ede:	e9 54 f6 ff ff       	jmp    80106537 <alltraps>

80106ee3 <vector55>:
.globl vector55
vector55:
  pushl $0
80106ee3:	6a 00                	push   $0x0
  pushl $55
80106ee5:	6a 37                	push   $0x37
  jmp alltraps
80106ee7:	e9 4b f6 ff ff       	jmp    80106537 <alltraps>

80106eec <vector56>:
.globl vector56
vector56:
  pushl $0
80106eec:	6a 00                	push   $0x0
  pushl $56
80106eee:	6a 38                	push   $0x38
  jmp alltraps
80106ef0:	e9 42 f6 ff ff       	jmp    80106537 <alltraps>

80106ef5 <vector57>:
.globl vector57
vector57:
  pushl $0
80106ef5:	6a 00                	push   $0x0
  pushl $57
80106ef7:	6a 39                	push   $0x39
  jmp alltraps
80106ef9:	e9 39 f6 ff ff       	jmp    80106537 <alltraps>

80106efe <vector58>:
.globl vector58
vector58:
  pushl $0
80106efe:	6a 00                	push   $0x0
  pushl $58
80106f00:	6a 3a                	push   $0x3a
  jmp alltraps
80106f02:	e9 30 f6 ff ff       	jmp    80106537 <alltraps>

80106f07 <vector59>:
.globl vector59
vector59:
  pushl $0
80106f07:	6a 00                	push   $0x0
  pushl $59
80106f09:	6a 3b                	push   $0x3b
  jmp alltraps
80106f0b:	e9 27 f6 ff ff       	jmp    80106537 <alltraps>

80106f10 <vector60>:
.globl vector60
vector60:
  pushl $0
80106f10:	6a 00                	push   $0x0
  pushl $60
80106f12:	6a 3c                	push   $0x3c
  jmp alltraps
80106f14:	e9 1e f6 ff ff       	jmp    80106537 <alltraps>

80106f19 <vector61>:
.globl vector61
vector61:
  pushl $0
80106f19:	6a 00                	push   $0x0
  pushl $61
80106f1b:	6a 3d                	push   $0x3d
  jmp alltraps
80106f1d:	e9 15 f6 ff ff       	jmp    80106537 <alltraps>

80106f22 <vector62>:
.globl vector62
vector62:
  pushl $0
80106f22:	6a 00                	push   $0x0
  pushl $62
80106f24:	6a 3e                	push   $0x3e
  jmp alltraps
80106f26:	e9 0c f6 ff ff       	jmp    80106537 <alltraps>

80106f2b <vector63>:
.globl vector63
vector63:
  pushl $0
80106f2b:	6a 00                	push   $0x0
  pushl $63
80106f2d:	6a 3f                	push   $0x3f
  jmp alltraps
80106f2f:	e9 03 f6 ff ff       	jmp    80106537 <alltraps>

80106f34 <vector64>:
.globl vector64
vector64:
  pushl $0
80106f34:	6a 00                	push   $0x0
  pushl $64
80106f36:	6a 40                	push   $0x40
  jmp alltraps
80106f38:	e9 fa f5 ff ff       	jmp    80106537 <alltraps>

80106f3d <vector65>:
.globl vector65
vector65:
  pushl $0
80106f3d:	6a 00                	push   $0x0
  pushl $65
80106f3f:	6a 41                	push   $0x41
  jmp alltraps
80106f41:	e9 f1 f5 ff ff       	jmp    80106537 <alltraps>

80106f46 <vector66>:
.globl vector66
vector66:
  pushl $0
80106f46:	6a 00                	push   $0x0
  pushl $66
80106f48:	6a 42                	push   $0x42
  jmp alltraps
80106f4a:	e9 e8 f5 ff ff       	jmp    80106537 <alltraps>

80106f4f <vector67>:
.globl vector67
vector67:
  pushl $0
80106f4f:	6a 00                	push   $0x0
  pushl $67
80106f51:	6a 43                	push   $0x43
  jmp alltraps
80106f53:	e9 df f5 ff ff       	jmp    80106537 <alltraps>

80106f58 <vector68>:
.globl vector68
vector68:
  pushl $0
80106f58:	6a 00                	push   $0x0
  pushl $68
80106f5a:	6a 44                	push   $0x44
  jmp alltraps
80106f5c:	e9 d6 f5 ff ff       	jmp    80106537 <alltraps>

80106f61 <vector69>:
.globl vector69
vector69:
  pushl $0
80106f61:	6a 00                	push   $0x0
  pushl $69
80106f63:	6a 45                	push   $0x45
  jmp alltraps
80106f65:	e9 cd f5 ff ff       	jmp    80106537 <alltraps>

80106f6a <vector70>:
.globl vector70
vector70:
  pushl $0
80106f6a:	6a 00                	push   $0x0
  pushl $70
80106f6c:	6a 46                	push   $0x46
  jmp alltraps
80106f6e:	e9 c4 f5 ff ff       	jmp    80106537 <alltraps>

80106f73 <vector71>:
.globl vector71
vector71:
  pushl $0
80106f73:	6a 00                	push   $0x0
  pushl $71
80106f75:	6a 47                	push   $0x47
  jmp alltraps
80106f77:	e9 bb f5 ff ff       	jmp    80106537 <alltraps>

80106f7c <vector72>:
.globl vector72
vector72:
  pushl $0
80106f7c:	6a 00                	push   $0x0
  pushl $72
80106f7e:	6a 48                	push   $0x48
  jmp alltraps
80106f80:	e9 b2 f5 ff ff       	jmp    80106537 <alltraps>

80106f85 <vector73>:
.globl vector73
vector73:
  pushl $0
80106f85:	6a 00                	push   $0x0
  pushl $73
80106f87:	6a 49                	push   $0x49
  jmp alltraps
80106f89:	e9 a9 f5 ff ff       	jmp    80106537 <alltraps>

80106f8e <vector74>:
.globl vector74
vector74:
  pushl $0
80106f8e:	6a 00                	push   $0x0
  pushl $74
80106f90:	6a 4a                	push   $0x4a
  jmp alltraps
80106f92:	e9 a0 f5 ff ff       	jmp    80106537 <alltraps>

80106f97 <vector75>:
.globl vector75
vector75:
  pushl $0
80106f97:	6a 00                	push   $0x0
  pushl $75
80106f99:	6a 4b                	push   $0x4b
  jmp alltraps
80106f9b:	e9 97 f5 ff ff       	jmp    80106537 <alltraps>

80106fa0 <vector76>:
.globl vector76
vector76:
  pushl $0
80106fa0:	6a 00                	push   $0x0
  pushl $76
80106fa2:	6a 4c                	push   $0x4c
  jmp alltraps
80106fa4:	e9 8e f5 ff ff       	jmp    80106537 <alltraps>

80106fa9 <vector77>:
.globl vector77
vector77:
  pushl $0
80106fa9:	6a 00                	push   $0x0
  pushl $77
80106fab:	6a 4d                	push   $0x4d
  jmp alltraps
80106fad:	e9 85 f5 ff ff       	jmp    80106537 <alltraps>

80106fb2 <vector78>:
.globl vector78
vector78:
  pushl $0
80106fb2:	6a 00                	push   $0x0
  pushl $78
80106fb4:	6a 4e                	push   $0x4e
  jmp alltraps
80106fb6:	e9 7c f5 ff ff       	jmp    80106537 <alltraps>

80106fbb <vector79>:
.globl vector79
vector79:
  pushl $0
80106fbb:	6a 00                	push   $0x0
  pushl $79
80106fbd:	6a 4f                	push   $0x4f
  jmp alltraps
80106fbf:	e9 73 f5 ff ff       	jmp    80106537 <alltraps>

80106fc4 <vector80>:
.globl vector80
vector80:
  pushl $0
80106fc4:	6a 00                	push   $0x0
  pushl $80
80106fc6:	6a 50                	push   $0x50
  jmp alltraps
80106fc8:	e9 6a f5 ff ff       	jmp    80106537 <alltraps>

80106fcd <vector81>:
.globl vector81
vector81:
  pushl $0
80106fcd:	6a 00                	push   $0x0
  pushl $81
80106fcf:	6a 51                	push   $0x51
  jmp alltraps
80106fd1:	e9 61 f5 ff ff       	jmp    80106537 <alltraps>

80106fd6 <vector82>:
.globl vector82
vector82:
  pushl $0
80106fd6:	6a 00                	push   $0x0
  pushl $82
80106fd8:	6a 52                	push   $0x52
  jmp alltraps
80106fda:	e9 58 f5 ff ff       	jmp    80106537 <alltraps>

80106fdf <vector83>:
.globl vector83
vector83:
  pushl $0
80106fdf:	6a 00                	push   $0x0
  pushl $83
80106fe1:	6a 53                	push   $0x53
  jmp alltraps
80106fe3:	e9 4f f5 ff ff       	jmp    80106537 <alltraps>

80106fe8 <vector84>:
.globl vector84
vector84:
  pushl $0
80106fe8:	6a 00                	push   $0x0
  pushl $84
80106fea:	6a 54                	push   $0x54
  jmp alltraps
80106fec:	e9 46 f5 ff ff       	jmp    80106537 <alltraps>

80106ff1 <vector85>:
.globl vector85
vector85:
  pushl $0
80106ff1:	6a 00                	push   $0x0
  pushl $85
80106ff3:	6a 55                	push   $0x55
  jmp alltraps
80106ff5:	e9 3d f5 ff ff       	jmp    80106537 <alltraps>

80106ffa <vector86>:
.globl vector86
vector86:
  pushl $0
80106ffa:	6a 00                	push   $0x0
  pushl $86
80106ffc:	6a 56                	push   $0x56
  jmp alltraps
80106ffe:	e9 34 f5 ff ff       	jmp    80106537 <alltraps>

80107003 <vector87>:
.globl vector87
vector87:
  pushl $0
80107003:	6a 00                	push   $0x0
  pushl $87
80107005:	6a 57                	push   $0x57
  jmp alltraps
80107007:	e9 2b f5 ff ff       	jmp    80106537 <alltraps>

8010700c <vector88>:
.globl vector88
vector88:
  pushl $0
8010700c:	6a 00                	push   $0x0
  pushl $88
8010700e:	6a 58                	push   $0x58
  jmp alltraps
80107010:	e9 22 f5 ff ff       	jmp    80106537 <alltraps>

80107015 <vector89>:
.globl vector89
vector89:
  pushl $0
80107015:	6a 00                	push   $0x0
  pushl $89
80107017:	6a 59                	push   $0x59
  jmp alltraps
80107019:	e9 19 f5 ff ff       	jmp    80106537 <alltraps>

8010701e <vector90>:
.globl vector90
vector90:
  pushl $0
8010701e:	6a 00                	push   $0x0
  pushl $90
80107020:	6a 5a                	push   $0x5a
  jmp alltraps
80107022:	e9 10 f5 ff ff       	jmp    80106537 <alltraps>

80107027 <vector91>:
.globl vector91
vector91:
  pushl $0
80107027:	6a 00                	push   $0x0
  pushl $91
80107029:	6a 5b                	push   $0x5b
  jmp alltraps
8010702b:	e9 07 f5 ff ff       	jmp    80106537 <alltraps>

80107030 <vector92>:
.globl vector92
vector92:
  pushl $0
80107030:	6a 00                	push   $0x0
  pushl $92
80107032:	6a 5c                	push   $0x5c
  jmp alltraps
80107034:	e9 fe f4 ff ff       	jmp    80106537 <alltraps>

80107039 <vector93>:
.globl vector93
vector93:
  pushl $0
80107039:	6a 00                	push   $0x0
  pushl $93
8010703b:	6a 5d                	push   $0x5d
  jmp alltraps
8010703d:	e9 f5 f4 ff ff       	jmp    80106537 <alltraps>

80107042 <vector94>:
.globl vector94
vector94:
  pushl $0
80107042:	6a 00                	push   $0x0
  pushl $94
80107044:	6a 5e                	push   $0x5e
  jmp alltraps
80107046:	e9 ec f4 ff ff       	jmp    80106537 <alltraps>

8010704b <vector95>:
.globl vector95
vector95:
  pushl $0
8010704b:	6a 00                	push   $0x0
  pushl $95
8010704d:	6a 5f                	push   $0x5f
  jmp alltraps
8010704f:	e9 e3 f4 ff ff       	jmp    80106537 <alltraps>

80107054 <vector96>:
.globl vector96
vector96:
  pushl $0
80107054:	6a 00                	push   $0x0
  pushl $96
80107056:	6a 60                	push   $0x60
  jmp alltraps
80107058:	e9 da f4 ff ff       	jmp    80106537 <alltraps>

8010705d <vector97>:
.globl vector97
vector97:
  pushl $0
8010705d:	6a 00                	push   $0x0
  pushl $97
8010705f:	6a 61                	push   $0x61
  jmp alltraps
80107061:	e9 d1 f4 ff ff       	jmp    80106537 <alltraps>

80107066 <vector98>:
.globl vector98
vector98:
  pushl $0
80107066:	6a 00                	push   $0x0
  pushl $98
80107068:	6a 62                	push   $0x62
  jmp alltraps
8010706a:	e9 c8 f4 ff ff       	jmp    80106537 <alltraps>

8010706f <vector99>:
.globl vector99
vector99:
  pushl $0
8010706f:	6a 00                	push   $0x0
  pushl $99
80107071:	6a 63                	push   $0x63
  jmp alltraps
80107073:	e9 bf f4 ff ff       	jmp    80106537 <alltraps>

80107078 <vector100>:
.globl vector100
vector100:
  pushl $0
80107078:	6a 00                	push   $0x0
  pushl $100
8010707a:	6a 64                	push   $0x64
  jmp alltraps
8010707c:	e9 b6 f4 ff ff       	jmp    80106537 <alltraps>

80107081 <vector101>:
.globl vector101
vector101:
  pushl $0
80107081:	6a 00                	push   $0x0
  pushl $101
80107083:	6a 65                	push   $0x65
  jmp alltraps
80107085:	e9 ad f4 ff ff       	jmp    80106537 <alltraps>

8010708a <vector102>:
.globl vector102
vector102:
  pushl $0
8010708a:	6a 00                	push   $0x0
  pushl $102
8010708c:	6a 66                	push   $0x66
  jmp alltraps
8010708e:	e9 a4 f4 ff ff       	jmp    80106537 <alltraps>

80107093 <vector103>:
.globl vector103
vector103:
  pushl $0
80107093:	6a 00                	push   $0x0
  pushl $103
80107095:	6a 67                	push   $0x67
  jmp alltraps
80107097:	e9 9b f4 ff ff       	jmp    80106537 <alltraps>

8010709c <vector104>:
.globl vector104
vector104:
  pushl $0
8010709c:	6a 00                	push   $0x0
  pushl $104
8010709e:	6a 68                	push   $0x68
  jmp alltraps
801070a0:	e9 92 f4 ff ff       	jmp    80106537 <alltraps>

801070a5 <vector105>:
.globl vector105
vector105:
  pushl $0
801070a5:	6a 00                	push   $0x0
  pushl $105
801070a7:	6a 69                	push   $0x69
  jmp alltraps
801070a9:	e9 89 f4 ff ff       	jmp    80106537 <alltraps>

801070ae <vector106>:
.globl vector106
vector106:
  pushl $0
801070ae:	6a 00                	push   $0x0
  pushl $106
801070b0:	6a 6a                	push   $0x6a
  jmp alltraps
801070b2:	e9 80 f4 ff ff       	jmp    80106537 <alltraps>

801070b7 <vector107>:
.globl vector107
vector107:
  pushl $0
801070b7:	6a 00                	push   $0x0
  pushl $107
801070b9:	6a 6b                	push   $0x6b
  jmp alltraps
801070bb:	e9 77 f4 ff ff       	jmp    80106537 <alltraps>

801070c0 <vector108>:
.globl vector108
vector108:
  pushl $0
801070c0:	6a 00                	push   $0x0
  pushl $108
801070c2:	6a 6c                	push   $0x6c
  jmp alltraps
801070c4:	e9 6e f4 ff ff       	jmp    80106537 <alltraps>

801070c9 <vector109>:
.globl vector109
vector109:
  pushl $0
801070c9:	6a 00                	push   $0x0
  pushl $109
801070cb:	6a 6d                	push   $0x6d
  jmp alltraps
801070cd:	e9 65 f4 ff ff       	jmp    80106537 <alltraps>

801070d2 <vector110>:
.globl vector110
vector110:
  pushl $0
801070d2:	6a 00                	push   $0x0
  pushl $110
801070d4:	6a 6e                	push   $0x6e
  jmp alltraps
801070d6:	e9 5c f4 ff ff       	jmp    80106537 <alltraps>

801070db <vector111>:
.globl vector111
vector111:
  pushl $0
801070db:	6a 00                	push   $0x0
  pushl $111
801070dd:	6a 6f                	push   $0x6f
  jmp alltraps
801070df:	e9 53 f4 ff ff       	jmp    80106537 <alltraps>

801070e4 <vector112>:
.globl vector112
vector112:
  pushl $0
801070e4:	6a 00                	push   $0x0
  pushl $112
801070e6:	6a 70                	push   $0x70
  jmp alltraps
801070e8:	e9 4a f4 ff ff       	jmp    80106537 <alltraps>

801070ed <vector113>:
.globl vector113
vector113:
  pushl $0
801070ed:	6a 00                	push   $0x0
  pushl $113
801070ef:	6a 71                	push   $0x71
  jmp alltraps
801070f1:	e9 41 f4 ff ff       	jmp    80106537 <alltraps>

801070f6 <vector114>:
.globl vector114
vector114:
  pushl $0
801070f6:	6a 00                	push   $0x0
  pushl $114
801070f8:	6a 72                	push   $0x72
  jmp alltraps
801070fa:	e9 38 f4 ff ff       	jmp    80106537 <alltraps>

801070ff <vector115>:
.globl vector115
vector115:
  pushl $0
801070ff:	6a 00                	push   $0x0
  pushl $115
80107101:	6a 73                	push   $0x73
  jmp alltraps
80107103:	e9 2f f4 ff ff       	jmp    80106537 <alltraps>

80107108 <vector116>:
.globl vector116
vector116:
  pushl $0
80107108:	6a 00                	push   $0x0
  pushl $116
8010710a:	6a 74                	push   $0x74
  jmp alltraps
8010710c:	e9 26 f4 ff ff       	jmp    80106537 <alltraps>

80107111 <vector117>:
.globl vector117
vector117:
  pushl $0
80107111:	6a 00                	push   $0x0
  pushl $117
80107113:	6a 75                	push   $0x75
  jmp alltraps
80107115:	e9 1d f4 ff ff       	jmp    80106537 <alltraps>

8010711a <vector118>:
.globl vector118
vector118:
  pushl $0
8010711a:	6a 00                	push   $0x0
  pushl $118
8010711c:	6a 76                	push   $0x76
  jmp alltraps
8010711e:	e9 14 f4 ff ff       	jmp    80106537 <alltraps>

80107123 <vector119>:
.globl vector119
vector119:
  pushl $0
80107123:	6a 00                	push   $0x0
  pushl $119
80107125:	6a 77                	push   $0x77
  jmp alltraps
80107127:	e9 0b f4 ff ff       	jmp    80106537 <alltraps>

8010712c <vector120>:
.globl vector120
vector120:
  pushl $0
8010712c:	6a 00                	push   $0x0
  pushl $120
8010712e:	6a 78                	push   $0x78
  jmp alltraps
80107130:	e9 02 f4 ff ff       	jmp    80106537 <alltraps>

80107135 <vector121>:
.globl vector121
vector121:
  pushl $0
80107135:	6a 00                	push   $0x0
  pushl $121
80107137:	6a 79                	push   $0x79
  jmp alltraps
80107139:	e9 f9 f3 ff ff       	jmp    80106537 <alltraps>

8010713e <vector122>:
.globl vector122
vector122:
  pushl $0
8010713e:	6a 00                	push   $0x0
  pushl $122
80107140:	6a 7a                	push   $0x7a
  jmp alltraps
80107142:	e9 f0 f3 ff ff       	jmp    80106537 <alltraps>

80107147 <vector123>:
.globl vector123
vector123:
  pushl $0
80107147:	6a 00                	push   $0x0
  pushl $123
80107149:	6a 7b                	push   $0x7b
  jmp alltraps
8010714b:	e9 e7 f3 ff ff       	jmp    80106537 <alltraps>

80107150 <vector124>:
.globl vector124
vector124:
  pushl $0
80107150:	6a 00                	push   $0x0
  pushl $124
80107152:	6a 7c                	push   $0x7c
  jmp alltraps
80107154:	e9 de f3 ff ff       	jmp    80106537 <alltraps>

80107159 <vector125>:
.globl vector125
vector125:
  pushl $0
80107159:	6a 00                	push   $0x0
  pushl $125
8010715b:	6a 7d                	push   $0x7d
  jmp alltraps
8010715d:	e9 d5 f3 ff ff       	jmp    80106537 <alltraps>

80107162 <vector126>:
.globl vector126
vector126:
  pushl $0
80107162:	6a 00                	push   $0x0
  pushl $126
80107164:	6a 7e                	push   $0x7e
  jmp alltraps
80107166:	e9 cc f3 ff ff       	jmp    80106537 <alltraps>

8010716b <vector127>:
.globl vector127
vector127:
  pushl $0
8010716b:	6a 00                	push   $0x0
  pushl $127
8010716d:	6a 7f                	push   $0x7f
  jmp alltraps
8010716f:	e9 c3 f3 ff ff       	jmp    80106537 <alltraps>

80107174 <vector128>:
.globl vector128
vector128:
  pushl $0
80107174:	6a 00                	push   $0x0
  pushl $128
80107176:	68 80 00 00 00       	push   $0x80
  jmp alltraps
8010717b:	e9 b7 f3 ff ff       	jmp    80106537 <alltraps>

80107180 <vector129>:
.globl vector129
vector129:
  pushl $0
80107180:	6a 00                	push   $0x0
  pushl $129
80107182:	68 81 00 00 00       	push   $0x81
  jmp alltraps
80107187:	e9 ab f3 ff ff       	jmp    80106537 <alltraps>

8010718c <vector130>:
.globl vector130
vector130:
  pushl $0
8010718c:	6a 00                	push   $0x0
  pushl $130
8010718e:	68 82 00 00 00       	push   $0x82
  jmp alltraps
80107193:	e9 9f f3 ff ff       	jmp    80106537 <alltraps>

80107198 <vector131>:
.globl vector131
vector131:
  pushl $0
80107198:	6a 00                	push   $0x0
  pushl $131
8010719a:	68 83 00 00 00       	push   $0x83
  jmp alltraps
8010719f:	e9 93 f3 ff ff       	jmp    80106537 <alltraps>

801071a4 <vector132>:
.globl vector132
vector132:
  pushl $0
801071a4:	6a 00                	push   $0x0
  pushl $132
801071a6:	68 84 00 00 00       	push   $0x84
  jmp alltraps
801071ab:	e9 87 f3 ff ff       	jmp    80106537 <alltraps>

801071b0 <vector133>:
.globl vector133
vector133:
  pushl $0
801071b0:	6a 00                	push   $0x0
  pushl $133
801071b2:	68 85 00 00 00       	push   $0x85
  jmp alltraps
801071b7:	e9 7b f3 ff ff       	jmp    80106537 <alltraps>

801071bc <vector134>:
.globl vector134
vector134:
  pushl $0
801071bc:	6a 00                	push   $0x0
  pushl $134
801071be:	68 86 00 00 00       	push   $0x86
  jmp alltraps
801071c3:	e9 6f f3 ff ff       	jmp    80106537 <alltraps>

801071c8 <vector135>:
.globl vector135
vector135:
  pushl $0
801071c8:	6a 00                	push   $0x0
  pushl $135
801071ca:	68 87 00 00 00       	push   $0x87
  jmp alltraps
801071cf:	e9 63 f3 ff ff       	jmp    80106537 <alltraps>

801071d4 <vector136>:
.globl vector136
vector136:
  pushl $0
801071d4:	6a 00                	push   $0x0
  pushl $136
801071d6:	68 88 00 00 00       	push   $0x88
  jmp alltraps
801071db:	e9 57 f3 ff ff       	jmp    80106537 <alltraps>

801071e0 <vector137>:
.globl vector137
vector137:
  pushl $0
801071e0:	6a 00                	push   $0x0
  pushl $137
801071e2:	68 89 00 00 00       	push   $0x89
  jmp alltraps
801071e7:	e9 4b f3 ff ff       	jmp    80106537 <alltraps>

801071ec <vector138>:
.globl vector138
vector138:
  pushl $0
801071ec:	6a 00                	push   $0x0
  pushl $138
801071ee:	68 8a 00 00 00       	push   $0x8a
  jmp alltraps
801071f3:	e9 3f f3 ff ff       	jmp    80106537 <alltraps>

801071f8 <vector139>:
.globl vector139
vector139:
  pushl $0
801071f8:	6a 00                	push   $0x0
  pushl $139
801071fa:	68 8b 00 00 00       	push   $0x8b
  jmp alltraps
801071ff:	e9 33 f3 ff ff       	jmp    80106537 <alltraps>

80107204 <vector140>:
.globl vector140
vector140:
  pushl $0
80107204:	6a 00                	push   $0x0
  pushl $140
80107206:	68 8c 00 00 00       	push   $0x8c
  jmp alltraps
8010720b:	e9 27 f3 ff ff       	jmp    80106537 <alltraps>

80107210 <vector141>:
.globl vector141
vector141:
  pushl $0
80107210:	6a 00                	push   $0x0
  pushl $141
80107212:	68 8d 00 00 00       	push   $0x8d
  jmp alltraps
80107217:	e9 1b f3 ff ff       	jmp    80106537 <alltraps>

8010721c <vector142>:
.globl vector142
vector142:
  pushl $0
8010721c:	6a 00                	push   $0x0
  pushl $142
8010721e:	68 8e 00 00 00       	push   $0x8e
  jmp alltraps
80107223:	e9 0f f3 ff ff       	jmp    80106537 <alltraps>

80107228 <vector143>:
.globl vector143
vector143:
  pushl $0
80107228:	6a 00                	push   $0x0
  pushl $143
8010722a:	68 8f 00 00 00       	push   $0x8f
  jmp alltraps
8010722f:	e9 03 f3 ff ff       	jmp    80106537 <alltraps>

80107234 <vector144>:
.globl vector144
vector144:
  pushl $0
80107234:	6a 00                	push   $0x0
  pushl $144
80107236:	68 90 00 00 00       	push   $0x90
  jmp alltraps
8010723b:	e9 f7 f2 ff ff       	jmp    80106537 <alltraps>

80107240 <vector145>:
.globl vector145
vector145:
  pushl $0
80107240:	6a 00                	push   $0x0
  pushl $145
80107242:	68 91 00 00 00       	push   $0x91
  jmp alltraps
80107247:	e9 eb f2 ff ff       	jmp    80106537 <alltraps>

8010724c <vector146>:
.globl vector146
vector146:
  pushl $0
8010724c:	6a 00                	push   $0x0
  pushl $146
8010724e:	68 92 00 00 00       	push   $0x92
  jmp alltraps
80107253:	e9 df f2 ff ff       	jmp    80106537 <alltraps>

80107258 <vector147>:
.globl vector147
vector147:
  pushl $0
80107258:	6a 00                	push   $0x0
  pushl $147
8010725a:	68 93 00 00 00       	push   $0x93
  jmp alltraps
8010725f:	e9 d3 f2 ff ff       	jmp    80106537 <alltraps>

80107264 <vector148>:
.globl vector148
vector148:
  pushl $0
80107264:	6a 00                	push   $0x0
  pushl $148
80107266:	68 94 00 00 00       	push   $0x94
  jmp alltraps
8010726b:	e9 c7 f2 ff ff       	jmp    80106537 <alltraps>

80107270 <vector149>:
.globl vector149
vector149:
  pushl $0
80107270:	6a 00                	push   $0x0
  pushl $149
80107272:	68 95 00 00 00       	push   $0x95
  jmp alltraps
80107277:	e9 bb f2 ff ff       	jmp    80106537 <alltraps>

8010727c <vector150>:
.globl vector150
vector150:
  pushl $0
8010727c:	6a 00                	push   $0x0
  pushl $150
8010727e:	68 96 00 00 00       	push   $0x96
  jmp alltraps
80107283:	e9 af f2 ff ff       	jmp    80106537 <alltraps>

80107288 <vector151>:
.globl vector151
vector151:
  pushl $0
80107288:	6a 00                	push   $0x0
  pushl $151
8010728a:	68 97 00 00 00       	push   $0x97
  jmp alltraps
8010728f:	e9 a3 f2 ff ff       	jmp    80106537 <alltraps>

80107294 <vector152>:
.globl vector152
vector152:
  pushl $0
80107294:	6a 00                	push   $0x0
  pushl $152
80107296:	68 98 00 00 00       	push   $0x98
  jmp alltraps
8010729b:	e9 97 f2 ff ff       	jmp    80106537 <alltraps>

801072a0 <vector153>:
.globl vector153
vector153:
  pushl $0
801072a0:	6a 00                	push   $0x0
  pushl $153
801072a2:	68 99 00 00 00       	push   $0x99
  jmp alltraps
801072a7:	e9 8b f2 ff ff       	jmp    80106537 <alltraps>

801072ac <vector154>:
.globl vector154
vector154:
  pushl $0
801072ac:	6a 00                	push   $0x0
  pushl $154
801072ae:	68 9a 00 00 00       	push   $0x9a
  jmp alltraps
801072b3:	e9 7f f2 ff ff       	jmp    80106537 <alltraps>

801072b8 <vector155>:
.globl vector155
vector155:
  pushl $0
801072b8:	6a 00                	push   $0x0
  pushl $155
801072ba:	68 9b 00 00 00       	push   $0x9b
  jmp alltraps
801072bf:	e9 73 f2 ff ff       	jmp    80106537 <alltraps>

801072c4 <vector156>:
.globl vector156
vector156:
  pushl $0
801072c4:	6a 00                	push   $0x0
  pushl $156
801072c6:	68 9c 00 00 00       	push   $0x9c
  jmp alltraps
801072cb:	e9 67 f2 ff ff       	jmp    80106537 <alltraps>

801072d0 <vector157>:
.globl vector157
vector157:
  pushl $0
801072d0:	6a 00                	push   $0x0
  pushl $157
801072d2:	68 9d 00 00 00       	push   $0x9d
  jmp alltraps
801072d7:	e9 5b f2 ff ff       	jmp    80106537 <alltraps>

801072dc <vector158>:
.globl vector158
vector158:
  pushl $0
801072dc:	6a 00                	push   $0x0
  pushl $158
801072de:	68 9e 00 00 00       	push   $0x9e
  jmp alltraps
801072e3:	e9 4f f2 ff ff       	jmp    80106537 <alltraps>

801072e8 <vector159>:
.globl vector159
vector159:
  pushl $0
801072e8:	6a 00                	push   $0x0
  pushl $159
801072ea:	68 9f 00 00 00       	push   $0x9f
  jmp alltraps
801072ef:	e9 43 f2 ff ff       	jmp    80106537 <alltraps>

801072f4 <vector160>:
.globl vector160
vector160:
  pushl $0
801072f4:	6a 00                	push   $0x0
  pushl $160
801072f6:	68 a0 00 00 00       	push   $0xa0
  jmp alltraps
801072fb:	e9 37 f2 ff ff       	jmp    80106537 <alltraps>

80107300 <vector161>:
.globl vector161
vector161:
  pushl $0
80107300:	6a 00                	push   $0x0
  pushl $161
80107302:	68 a1 00 00 00       	push   $0xa1
  jmp alltraps
80107307:	e9 2b f2 ff ff       	jmp    80106537 <alltraps>

8010730c <vector162>:
.globl vector162
vector162:
  pushl $0
8010730c:	6a 00                	push   $0x0
  pushl $162
8010730e:	68 a2 00 00 00       	push   $0xa2
  jmp alltraps
80107313:	e9 1f f2 ff ff       	jmp    80106537 <alltraps>

80107318 <vector163>:
.globl vector163
vector163:
  pushl $0
80107318:	6a 00                	push   $0x0
  pushl $163
8010731a:	68 a3 00 00 00       	push   $0xa3
  jmp alltraps
8010731f:	e9 13 f2 ff ff       	jmp    80106537 <alltraps>

80107324 <vector164>:
.globl vector164
vector164:
  pushl $0
80107324:	6a 00                	push   $0x0
  pushl $164
80107326:	68 a4 00 00 00       	push   $0xa4
  jmp alltraps
8010732b:	e9 07 f2 ff ff       	jmp    80106537 <alltraps>

80107330 <vector165>:
.globl vector165
vector165:
  pushl $0
80107330:	6a 00                	push   $0x0
  pushl $165
80107332:	68 a5 00 00 00       	push   $0xa5
  jmp alltraps
80107337:	e9 fb f1 ff ff       	jmp    80106537 <alltraps>

8010733c <vector166>:
.globl vector166
vector166:
  pushl $0
8010733c:	6a 00                	push   $0x0
  pushl $166
8010733e:	68 a6 00 00 00       	push   $0xa6
  jmp alltraps
80107343:	e9 ef f1 ff ff       	jmp    80106537 <alltraps>

80107348 <vector167>:
.globl vector167
vector167:
  pushl $0
80107348:	6a 00                	push   $0x0
  pushl $167
8010734a:	68 a7 00 00 00       	push   $0xa7
  jmp alltraps
8010734f:	e9 e3 f1 ff ff       	jmp    80106537 <alltraps>

80107354 <vector168>:
.globl vector168
vector168:
  pushl $0
80107354:	6a 00                	push   $0x0
  pushl $168
80107356:	68 a8 00 00 00       	push   $0xa8
  jmp alltraps
8010735b:	e9 d7 f1 ff ff       	jmp    80106537 <alltraps>

80107360 <vector169>:
.globl vector169
vector169:
  pushl $0
80107360:	6a 00                	push   $0x0
  pushl $169
80107362:	68 a9 00 00 00       	push   $0xa9
  jmp alltraps
80107367:	e9 cb f1 ff ff       	jmp    80106537 <alltraps>

8010736c <vector170>:
.globl vector170
vector170:
  pushl $0
8010736c:	6a 00                	push   $0x0
  pushl $170
8010736e:	68 aa 00 00 00       	push   $0xaa
  jmp alltraps
80107373:	e9 bf f1 ff ff       	jmp    80106537 <alltraps>

80107378 <vector171>:
.globl vector171
vector171:
  pushl $0
80107378:	6a 00                	push   $0x0
  pushl $171
8010737a:	68 ab 00 00 00       	push   $0xab
  jmp alltraps
8010737f:	e9 b3 f1 ff ff       	jmp    80106537 <alltraps>

80107384 <vector172>:
.globl vector172
vector172:
  pushl $0
80107384:	6a 00                	push   $0x0
  pushl $172
80107386:	68 ac 00 00 00       	push   $0xac
  jmp alltraps
8010738b:	e9 a7 f1 ff ff       	jmp    80106537 <alltraps>

80107390 <vector173>:
.globl vector173
vector173:
  pushl $0
80107390:	6a 00                	push   $0x0
  pushl $173
80107392:	68 ad 00 00 00       	push   $0xad
  jmp alltraps
80107397:	e9 9b f1 ff ff       	jmp    80106537 <alltraps>

8010739c <vector174>:
.globl vector174
vector174:
  pushl $0
8010739c:	6a 00                	push   $0x0
  pushl $174
8010739e:	68 ae 00 00 00       	push   $0xae
  jmp alltraps
801073a3:	e9 8f f1 ff ff       	jmp    80106537 <alltraps>

801073a8 <vector175>:
.globl vector175
vector175:
  pushl $0
801073a8:	6a 00                	push   $0x0
  pushl $175
801073aa:	68 af 00 00 00       	push   $0xaf
  jmp alltraps
801073af:	e9 83 f1 ff ff       	jmp    80106537 <alltraps>

801073b4 <vector176>:
.globl vector176
vector176:
  pushl $0
801073b4:	6a 00                	push   $0x0
  pushl $176
801073b6:	68 b0 00 00 00       	push   $0xb0
  jmp alltraps
801073bb:	e9 77 f1 ff ff       	jmp    80106537 <alltraps>

801073c0 <vector177>:
.globl vector177
vector177:
  pushl $0
801073c0:	6a 00                	push   $0x0
  pushl $177
801073c2:	68 b1 00 00 00       	push   $0xb1
  jmp alltraps
801073c7:	e9 6b f1 ff ff       	jmp    80106537 <alltraps>

801073cc <vector178>:
.globl vector178
vector178:
  pushl $0
801073cc:	6a 00                	push   $0x0
  pushl $178
801073ce:	68 b2 00 00 00       	push   $0xb2
  jmp alltraps
801073d3:	e9 5f f1 ff ff       	jmp    80106537 <alltraps>

801073d8 <vector179>:
.globl vector179
vector179:
  pushl $0
801073d8:	6a 00                	push   $0x0
  pushl $179
801073da:	68 b3 00 00 00       	push   $0xb3
  jmp alltraps
801073df:	e9 53 f1 ff ff       	jmp    80106537 <alltraps>

801073e4 <vector180>:
.globl vector180
vector180:
  pushl $0
801073e4:	6a 00                	push   $0x0
  pushl $180
801073e6:	68 b4 00 00 00       	push   $0xb4
  jmp alltraps
801073eb:	e9 47 f1 ff ff       	jmp    80106537 <alltraps>

801073f0 <vector181>:
.globl vector181
vector181:
  pushl $0
801073f0:	6a 00                	push   $0x0
  pushl $181
801073f2:	68 b5 00 00 00       	push   $0xb5
  jmp alltraps
801073f7:	e9 3b f1 ff ff       	jmp    80106537 <alltraps>

801073fc <vector182>:
.globl vector182
vector182:
  pushl $0
801073fc:	6a 00                	push   $0x0
  pushl $182
801073fe:	68 b6 00 00 00       	push   $0xb6
  jmp alltraps
80107403:	e9 2f f1 ff ff       	jmp    80106537 <alltraps>

80107408 <vector183>:
.globl vector183
vector183:
  pushl $0
80107408:	6a 00                	push   $0x0
  pushl $183
8010740a:	68 b7 00 00 00       	push   $0xb7
  jmp alltraps
8010740f:	e9 23 f1 ff ff       	jmp    80106537 <alltraps>

80107414 <vector184>:
.globl vector184
vector184:
  pushl $0
80107414:	6a 00                	push   $0x0
  pushl $184
80107416:	68 b8 00 00 00       	push   $0xb8
  jmp alltraps
8010741b:	e9 17 f1 ff ff       	jmp    80106537 <alltraps>

80107420 <vector185>:
.globl vector185
vector185:
  pushl $0
80107420:	6a 00                	push   $0x0
  pushl $185
80107422:	68 b9 00 00 00       	push   $0xb9
  jmp alltraps
80107427:	e9 0b f1 ff ff       	jmp    80106537 <alltraps>

8010742c <vector186>:
.globl vector186
vector186:
  pushl $0
8010742c:	6a 00                	push   $0x0
  pushl $186
8010742e:	68 ba 00 00 00       	push   $0xba
  jmp alltraps
80107433:	e9 ff f0 ff ff       	jmp    80106537 <alltraps>

80107438 <vector187>:
.globl vector187
vector187:
  pushl $0
80107438:	6a 00                	push   $0x0
  pushl $187
8010743a:	68 bb 00 00 00       	push   $0xbb
  jmp alltraps
8010743f:	e9 f3 f0 ff ff       	jmp    80106537 <alltraps>

80107444 <vector188>:
.globl vector188
vector188:
  pushl $0
80107444:	6a 00                	push   $0x0
  pushl $188
80107446:	68 bc 00 00 00       	push   $0xbc
  jmp alltraps
8010744b:	e9 e7 f0 ff ff       	jmp    80106537 <alltraps>

80107450 <vector189>:
.globl vector189
vector189:
  pushl $0
80107450:	6a 00                	push   $0x0
  pushl $189
80107452:	68 bd 00 00 00       	push   $0xbd
  jmp alltraps
80107457:	e9 db f0 ff ff       	jmp    80106537 <alltraps>

8010745c <vector190>:
.globl vector190
vector190:
  pushl $0
8010745c:	6a 00                	push   $0x0
  pushl $190
8010745e:	68 be 00 00 00       	push   $0xbe
  jmp alltraps
80107463:	e9 cf f0 ff ff       	jmp    80106537 <alltraps>

80107468 <vector191>:
.globl vector191
vector191:
  pushl $0
80107468:	6a 00                	push   $0x0
  pushl $191
8010746a:	68 bf 00 00 00       	push   $0xbf
  jmp alltraps
8010746f:	e9 c3 f0 ff ff       	jmp    80106537 <alltraps>

80107474 <vector192>:
.globl vector192
vector192:
  pushl $0
80107474:	6a 00                	push   $0x0
  pushl $192
80107476:	68 c0 00 00 00       	push   $0xc0
  jmp alltraps
8010747b:	e9 b7 f0 ff ff       	jmp    80106537 <alltraps>

80107480 <vector193>:
.globl vector193
vector193:
  pushl $0
80107480:	6a 00                	push   $0x0
  pushl $193
80107482:	68 c1 00 00 00       	push   $0xc1
  jmp alltraps
80107487:	e9 ab f0 ff ff       	jmp    80106537 <alltraps>

8010748c <vector194>:
.globl vector194
vector194:
  pushl $0
8010748c:	6a 00                	push   $0x0
  pushl $194
8010748e:	68 c2 00 00 00       	push   $0xc2
  jmp alltraps
80107493:	e9 9f f0 ff ff       	jmp    80106537 <alltraps>

80107498 <vector195>:
.globl vector195
vector195:
  pushl $0
80107498:	6a 00                	push   $0x0
  pushl $195
8010749a:	68 c3 00 00 00       	push   $0xc3
  jmp alltraps
8010749f:	e9 93 f0 ff ff       	jmp    80106537 <alltraps>

801074a4 <vector196>:
.globl vector196
vector196:
  pushl $0
801074a4:	6a 00                	push   $0x0
  pushl $196
801074a6:	68 c4 00 00 00       	push   $0xc4
  jmp alltraps
801074ab:	e9 87 f0 ff ff       	jmp    80106537 <alltraps>

801074b0 <vector197>:
.globl vector197
vector197:
  pushl $0
801074b0:	6a 00                	push   $0x0
  pushl $197
801074b2:	68 c5 00 00 00       	push   $0xc5
  jmp alltraps
801074b7:	e9 7b f0 ff ff       	jmp    80106537 <alltraps>

801074bc <vector198>:
.globl vector198
vector198:
  pushl $0
801074bc:	6a 00                	push   $0x0
  pushl $198
801074be:	68 c6 00 00 00       	push   $0xc6
  jmp alltraps
801074c3:	e9 6f f0 ff ff       	jmp    80106537 <alltraps>

801074c8 <vector199>:
.globl vector199
vector199:
  pushl $0
801074c8:	6a 00                	push   $0x0
  pushl $199
801074ca:	68 c7 00 00 00       	push   $0xc7
  jmp alltraps
801074cf:	e9 63 f0 ff ff       	jmp    80106537 <alltraps>

801074d4 <vector200>:
.globl vector200
vector200:
  pushl $0
801074d4:	6a 00                	push   $0x0
  pushl $200
801074d6:	68 c8 00 00 00       	push   $0xc8
  jmp alltraps
801074db:	e9 57 f0 ff ff       	jmp    80106537 <alltraps>

801074e0 <vector201>:
.globl vector201
vector201:
  pushl $0
801074e0:	6a 00                	push   $0x0
  pushl $201
801074e2:	68 c9 00 00 00       	push   $0xc9
  jmp alltraps
801074e7:	e9 4b f0 ff ff       	jmp    80106537 <alltraps>

801074ec <vector202>:
.globl vector202
vector202:
  pushl $0
801074ec:	6a 00                	push   $0x0
  pushl $202
801074ee:	68 ca 00 00 00       	push   $0xca
  jmp alltraps
801074f3:	e9 3f f0 ff ff       	jmp    80106537 <alltraps>

801074f8 <vector203>:
.globl vector203
vector203:
  pushl $0
801074f8:	6a 00                	push   $0x0
  pushl $203
801074fa:	68 cb 00 00 00       	push   $0xcb
  jmp alltraps
801074ff:	e9 33 f0 ff ff       	jmp    80106537 <alltraps>

80107504 <vector204>:
.globl vector204
vector204:
  pushl $0
80107504:	6a 00                	push   $0x0
  pushl $204
80107506:	68 cc 00 00 00       	push   $0xcc
  jmp alltraps
8010750b:	e9 27 f0 ff ff       	jmp    80106537 <alltraps>

80107510 <vector205>:
.globl vector205
vector205:
  pushl $0
80107510:	6a 00                	push   $0x0
  pushl $205
80107512:	68 cd 00 00 00       	push   $0xcd
  jmp alltraps
80107517:	e9 1b f0 ff ff       	jmp    80106537 <alltraps>

8010751c <vector206>:
.globl vector206
vector206:
  pushl $0
8010751c:	6a 00                	push   $0x0
  pushl $206
8010751e:	68 ce 00 00 00       	push   $0xce
  jmp alltraps
80107523:	e9 0f f0 ff ff       	jmp    80106537 <alltraps>

80107528 <vector207>:
.globl vector207
vector207:
  pushl $0
80107528:	6a 00                	push   $0x0
  pushl $207
8010752a:	68 cf 00 00 00       	push   $0xcf
  jmp alltraps
8010752f:	e9 03 f0 ff ff       	jmp    80106537 <alltraps>

80107534 <vector208>:
.globl vector208
vector208:
  pushl $0
80107534:	6a 00                	push   $0x0
  pushl $208
80107536:	68 d0 00 00 00       	push   $0xd0
  jmp alltraps
8010753b:	e9 f7 ef ff ff       	jmp    80106537 <alltraps>

80107540 <vector209>:
.globl vector209
vector209:
  pushl $0
80107540:	6a 00                	push   $0x0
  pushl $209
80107542:	68 d1 00 00 00       	push   $0xd1
  jmp alltraps
80107547:	e9 eb ef ff ff       	jmp    80106537 <alltraps>

8010754c <vector210>:
.globl vector210
vector210:
  pushl $0
8010754c:	6a 00                	push   $0x0
  pushl $210
8010754e:	68 d2 00 00 00       	push   $0xd2
  jmp alltraps
80107553:	e9 df ef ff ff       	jmp    80106537 <alltraps>

80107558 <vector211>:
.globl vector211
vector211:
  pushl $0
80107558:	6a 00                	push   $0x0
  pushl $211
8010755a:	68 d3 00 00 00       	push   $0xd3
  jmp alltraps
8010755f:	e9 d3 ef ff ff       	jmp    80106537 <alltraps>

80107564 <vector212>:
.globl vector212
vector212:
  pushl $0
80107564:	6a 00                	push   $0x0
  pushl $212
80107566:	68 d4 00 00 00       	push   $0xd4
  jmp alltraps
8010756b:	e9 c7 ef ff ff       	jmp    80106537 <alltraps>

80107570 <vector213>:
.globl vector213
vector213:
  pushl $0
80107570:	6a 00                	push   $0x0
  pushl $213
80107572:	68 d5 00 00 00       	push   $0xd5
  jmp alltraps
80107577:	e9 bb ef ff ff       	jmp    80106537 <alltraps>

8010757c <vector214>:
.globl vector214
vector214:
  pushl $0
8010757c:	6a 00                	push   $0x0
  pushl $214
8010757e:	68 d6 00 00 00       	push   $0xd6
  jmp alltraps
80107583:	e9 af ef ff ff       	jmp    80106537 <alltraps>

80107588 <vector215>:
.globl vector215
vector215:
  pushl $0
80107588:	6a 00                	push   $0x0
  pushl $215
8010758a:	68 d7 00 00 00       	push   $0xd7
  jmp alltraps
8010758f:	e9 a3 ef ff ff       	jmp    80106537 <alltraps>

80107594 <vector216>:
.globl vector216
vector216:
  pushl $0
80107594:	6a 00                	push   $0x0
  pushl $216
80107596:	68 d8 00 00 00       	push   $0xd8
  jmp alltraps
8010759b:	e9 97 ef ff ff       	jmp    80106537 <alltraps>

801075a0 <vector217>:
.globl vector217
vector217:
  pushl $0
801075a0:	6a 00                	push   $0x0
  pushl $217
801075a2:	68 d9 00 00 00       	push   $0xd9
  jmp alltraps
801075a7:	e9 8b ef ff ff       	jmp    80106537 <alltraps>

801075ac <vector218>:
.globl vector218
vector218:
  pushl $0
801075ac:	6a 00                	push   $0x0
  pushl $218
801075ae:	68 da 00 00 00       	push   $0xda
  jmp alltraps
801075b3:	e9 7f ef ff ff       	jmp    80106537 <alltraps>

801075b8 <vector219>:
.globl vector219
vector219:
  pushl $0
801075b8:	6a 00                	push   $0x0
  pushl $219
801075ba:	68 db 00 00 00       	push   $0xdb
  jmp alltraps
801075bf:	e9 73 ef ff ff       	jmp    80106537 <alltraps>

801075c4 <vector220>:
.globl vector220
vector220:
  pushl $0
801075c4:	6a 00                	push   $0x0
  pushl $220
801075c6:	68 dc 00 00 00       	push   $0xdc
  jmp alltraps
801075cb:	e9 67 ef ff ff       	jmp    80106537 <alltraps>

801075d0 <vector221>:
.globl vector221
vector221:
  pushl $0
801075d0:	6a 00                	push   $0x0
  pushl $221
801075d2:	68 dd 00 00 00       	push   $0xdd
  jmp alltraps
801075d7:	e9 5b ef ff ff       	jmp    80106537 <alltraps>

801075dc <vector222>:
.globl vector222
vector222:
  pushl $0
801075dc:	6a 00                	push   $0x0
  pushl $222
801075de:	68 de 00 00 00       	push   $0xde
  jmp alltraps
801075e3:	e9 4f ef ff ff       	jmp    80106537 <alltraps>

801075e8 <vector223>:
.globl vector223
vector223:
  pushl $0
801075e8:	6a 00                	push   $0x0
  pushl $223
801075ea:	68 df 00 00 00       	push   $0xdf
  jmp alltraps
801075ef:	e9 43 ef ff ff       	jmp    80106537 <alltraps>

801075f4 <vector224>:
.globl vector224
vector224:
  pushl $0
801075f4:	6a 00                	push   $0x0
  pushl $224
801075f6:	68 e0 00 00 00       	push   $0xe0
  jmp alltraps
801075fb:	e9 37 ef ff ff       	jmp    80106537 <alltraps>

80107600 <vector225>:
.globl vector225
vector225:
  pushl $0
80107600:	6a 00                	push   $0x0
  pushl $225
80107602:	68 e1 00 00 00       	push   $0xe1
  jmp alltraps
80107607:	e9 2b ef ff ff       	jmp    80106537 <alltraps>

8010760c <vector226>:
.globl vector226
vector226:
  pushl $0
8010760c:	6a 00                	push   $0x0
  pushl $226
8010760e:	68 e2 00 00 00       	push   $0xe2
  jmp alltraps
80107613:	e9 1f ef ff ff       	jmp    80106537 <alltraps>

80107618 <vector227>:
.globl vector227
vector227:
  pushl $0
80107618:	6a 00                	push   $0x0
  pushl $227
8010761a:	68 e3 00 00 00       	push   $0xe3
  jmp alltraps
8010761f:	e9 13 ef ff ff       	jmp    80106537 <alltraps>

80107624 <vector228>:
.globl vector228
vector228:
  pushl $0
80107624:	6a 00                	push   $0x0
  pushl $228
80107626:	68 e4 00 00 00       	push   $0xe4
  jmp alltraps
8010762b:	e9 07 ef ff ff       	jmp    80106537 <alltraps>

80107630 <vector229>:
.globl vector229
vector229:
  pushl $0
80107630:	6a 00                	push   $0x0
  pushl $229
80107632:	68 e5 00 00 00       	push   $0xe5
  jmp alltraps
80107637:	e9 fb ee ff ff       	jmp    80106537 <alltraps>

8010763c <vector230>:
.globl vector230
vector230:
  pushl $0
8010763c:	6a 00                	push   $0x0
  pushl $230
8010763e:	68 e6 00 00 00       	push   $0xe6
  jmp alltraps
80107643:	e9 ef ee ff ff       	jmp    80106537 <alltraps>

80107648 <vector231>:
.globl vector231
vector231:
  pushl $0
80107648:	6a 00                	push   $0x0
  pushl $231
8010764a:	68 e7 00 00 00       	push   $0xe7
  jmp alltraps
8010764f:	e9 e3 ee ff ff       	jmp    80106537 <alltraps>

80107654 <vector232>:
.globl vector232
vector232:
  pushl $0
80107654:	6a 00                	push   $0x0
  pushl $232
80107656:	68 e8 00 00 00       	push   $0xe8
  jmp alltraps
8010765b:	e9 d7 ee ff ff       	jmp    80106537 <alltraps>

80107660 <vector233>:
.globl vector233
vector233:
  pushl $0
80107660:	6a 00                	push   $0x0
  pushl $233
80107662:	68 e9 00 00 00       	push   $0xe9
  jmp alltraps
80107667:	e9 cb ee ff ff       	jmp    80106537 <alltraps>

8010766c <vector234>:
.globl vector234
vector234:
  pushl $0
8010766c:	6a 00                	push   $0x0
  pushl $234
8010766e:	68 ea 00 00 00       	push   $0xea
  jmp alltraps
80107673:	e9 bf ee ff ff       	jmp    80106537 <alltraps>

80107678 <vector235>:
.globl vector235
vector235:
  pushl $0
80107678:	6a 00                	push   $0x0
  pushl $235
8010767a:	68 eb 00 00 00       	push   $0xeb
  jmp alltraps
8010767f:	e9 b3 ee ff ff       	jmp    80106537 <alltraps>

80107684 <vector236>:
.globl vector236
vector236:
  pushl $0
80107684:	6a 00                	push   $0x0
  pushl $236
80107686:	68 ec 00 00 00       	push   $0xec
  jmp alltraps
8010768b:	e9 a7 ee ff ff       	jmp    80106537 <alltraps>

80107690 <vector237>:
.globl vector237
vector237:
  pushl $0
80107690:	6a 00                	push   $0x0
  pushl $237
80107692:	68 ed 00 00 00       	push   $0xed
  jmp alltraps
80107697:	e9 9b ee ff ff       	jmp    80106537 <alltraps>

8010769c <vector238>:
.globl vector238
vector238:
  pushl $0
8010769c:	6a 00                	push   $0x0
  pushl $238
8010769e:	68 ee 00 00 00       	push   $0xee
  jmp alltraps
801076a3:	e9 8f ee ff ff       	jmp    80106537 <alltraps>

801076a8 <vector239>:
.globl vector239
vector239:
  pushl $0
801076a8:	6a 00                	push   $0x0
  pushl $239
801076aa:	68 ef 00 00 00       	push   $0xef
  jmp alltraps
801076af:	e9 83 ee ff ff       	jmp    80106537 <alltraps>

801076b4 <vector240>:
.globl vector240
vector240:
  pushl $0
801076b4:	6a 00                	push   $0x0
  pushl $240
801076b6:	68 f0 00 00 00       	push   $0xf0
  jmp alltraps
801076bb:	e9 77 ee ff ff       	jmp    80106537 <alltraps>

801076c0 <vector241>:
.globl vector241
vector241:
  pushl $0
801076c0:	6a 00                	push   $0x0
  pushl $241
801076c2:	68 f1 00 00 00       	push   $0xf1
  jmp alltraps
801076c7:	e9 6b ee ff ff       	jmp    80106537 <alltraps>

801076cc <vector242>:
.globl vector242
vector242:
  pushl $0
801076cc:	6a 00                	push   $0x0
  pushl $242
801076ce:	68 f2 00 00 00       	push   $0xf2
  jmp alltraps
801076d3:	e9 5f ee ff ff       	jmp    80106537 <alltraps>

801076d8 <vector243>:
.globl vector243
vector243:
  pushl $0
801076d8:	6a 00                	push   $0x0
  pushl $243
801076da:	68 f3 00 00 00       	push   $0xf3
  jmp alltraps
801076df:	e9 53 ee ff ff       	jmp    80106537 <alltraps>

801076e4 <vector244>:
.globl vector244
vector244:
  pushl $0
801076e4:	6a 00                	push   $0x0
  pushl $244
801076e6:	68 f4 00 00 00       	push   $0xf4
  jmp alltraps
801076eb:	e9 47 ee ff ff       	jmp    80106537 <alltraps>

801076f0 <vector245>:
.globl vector245
vector245:
  pushl $0
801076f0:	6a 00                	push   $0x0
  pushl $245
801076f2:	68 f5 00 00 00       	push   $0xf5
  jmp alltraps
801076f7:	e9 3b ee ff ff       	jmp    80106537 <alltraps>

801076fc <vector246>:
.globl vector246
vector246:
  pushl $0
801076fc:	6a 00                	push   $0x0
  pushl $246
801076fe:	68 f6 00 00 00       	push   $0xf6
  jmp alltraps
80107703:	e9 2f ee ff ff       	jmp    80106537 <alltraps>

80107708 <vector247>:
.globl vector247
vector247:
  pushl $0
80107708:	6a 00                	push   $0x0
  pushl $247
8010770a:	68 f7 00 00 00       	push   $0xf7
  jmp alltraps
8010770f:	e9 23 ee ff ff       	jmp    80106537 <alltraps>

80107714 <vector248>:
.globl vector248
vector248:
  pushl $0
80107714:	6a 00                	push   $0x0
  pushl $248
80107716:	68 f8 00 00 00       	push   $0xf8
  jmp alltraps
8010771b:	e9 17 ee ff ff       	jmp    80106537 <alltraps>

80107720 <vector249>:
.globl vector249
vector249:
  pushl $0
80107720:	6a 00                	push   $0x0
  pushl $249
80107722:	68 f9 00 00 00       	push   $0xf9
  jmp alltraps
80107727:	e9 0b ee ff ff       	jmp    80106537 <alltraps>

8010772c <vector250>:
.globl vector250
vector250:
  pushl $0
8010772c:	6a 00                	push   $0x0
  pushl $250
8010772e:	68 fa 00 00 00       	push   $0xfa
  jmp alltraps
80107733:	e9 ff ed ff ff       	jmp    80106537 <alltraps>

80107738 <vector251>:
.globl vector251
vector251:
  pushl $0
80107738:	6a 00                	push   $0x0
  pushl $251
8010773a:	68 fb 00 00 00       	push   $0xfb
  jmp alltraps
8010773f:	e9 f3 ed ff ff       	jmp    80106537 <alltraps>

80107744 <vector252>:
.globl vector252
vector252:
  pushl $0
80107744:	6a 00                	push   $0x0
  pushl $252
80107746:	68 fc 00 00 00       	push   $0xfc
  jmp alltraps
8010774b:	e9 e7 ed ff ff       	jmp    80106537 <alltraps>

80107750 <vector253>:
.globl vector253
vector253:
  pushl $0
80107750:	6a 00                	push   $0x0
  pushl $253
80107752:	68 fd 00 00 00       	push   $0xfd
  jmp alltraps
80107757:	e9 db ed ff ff       	jmp    80106537 <alltraps>

8010775c <vector254>:
.globl vector254
vector254:
  pushl $0
8010775c:	6a 00                	push   $0x0
  pushl $254
8010775e:	68 fe 00 00 00       	push   $0xfe
  jmp alltraps
80107763:	e9 cf ed ff ff       	jmp    80106537 <alltraps>

80107768 <vector255>:
.globl vector255
vector255:
  pushl $0
80107768:	6a 00                	push   $0x0
  pushl $255
8010776a:	68 ff 00 00 00       	push   $0xff
  jmp alltraps
8010776f:	e9 c3 ed ff ff       	jmp    80106537 <alltraps>

80107774 <lgdt>:

struct segdesc;

static inline void
lgdt(struct segdesc *p, int size)
{
80107774:	55                   	push   %ebp
80107775:	89 e5                	mov    %esp,%ebp
80107777:	83 ec 10             	sub    $0x10,%esp
  volatile ushort pd[3];

  pd[0] = size-1;
8010777a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010777d:	83 e8 01             	sub    $0x1,%eax
80107780:	66 89 45 fa          	mov    %ax,-0x6(%ebp)
  pd[1] = (uint)p;
80107784:	8b 45 08             	mov    0x8(%ebp),%eax
80107787:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  pd[2] = (uint)p >> 16;
8010778b:	8b 45 08             	mov    0x8(%ebp),%eax
8010778e:	c1 e8 10             	shr    $0x10,%eax
80107791:	66 89 45 fe          	mov    %ax,-0x2(%ebp)

  asm volatile("lgdt (%0)" : : "r" (pd));
80107795:	8d 45 fa             	lea    -0x6(%ebp),%eax
80107798:	0f 01 10             	lgdtl  (%eax)
}
8010779b:	90                   	nop
8010779c:	c9                   	leave  
8010779d:	c3                   	ret    

8010779e <ltr>:
  asm volatile("lidt (%0)" : : "r" (pd));
}

static inline void
ltr(ushort sel)
{
8010779e:	55                   	push   %ebp
8010779f:	89 e5                	mov    %esp,%ebp
801077a1:	83 ec 04             	sub    $0x4,%esp
801077a4:	8b 45 08             	mov    0x8(%ebp),%eax
801077a7:	66 89 45 fc          	mov    %ax,-0x4(%ebp)
  asm volatile("ltr %0" : : "r" (sel));
801077ab:	0f b7 45 fc          	movzwl -0x4(%ebp),%eax
801077af:	0f 00 d8             	ltr    %ax
}
801077b2:	90                   	nop
801077b3:	c9                   	leave  
801077b4:	c3                   	ret    

801077b5 <lcr3>:
  return val;
}

static inline void
lcr3(uint val)
{
801077b5:	55                   	push   %ebp
801077b6:	89 e5                	mov    %esp,%ebp
  asm volatile("movl %0,%%cr3" : : "r" (val));
801077b8:	8b 45 08             	mov    0x8(%ebp),%eax
801077bb:	0f 22 d8             	mov    %eax,%cr3
}
801077be:	90                   	nop
801077bf:	5d                   	pop    %ebp
801077c0:	c3                   	ret    

801077c1 <seginit>:

// Set up CPU's kernel segment descriptors.
// Run once on entry on each CPU.
void
seginit(void)
{
801077c1:	55                   	push   %ebp
801077c2:	89 e5                	mov    %esp,%ebp
801077c4:	83 ec 18             	sub    $0x18,%esp

  // Map "logical" addresses to virtual addresses using identity map.
  // Cannot share a CODE descriptor for both kernel and user
  // because it would have to have DPL_USR, but the CPU forbids
  // an interrupt from CPL=0 to DPL=3.
  c = &cpus[cpuid()];
801077c7:	e8 23 ca ff ff       	call   801041ef <cpuid>
801077cc:	69 c0 b0 00 00 00    	imul   $0xb0,%eax,%eax
801077d2:	05 00 38 11 80       	add    $0x80113800,%eax
801077d7:	89 45 f4             	mov    %eax,-0xc(%ebp)
  c->gdt[SEG_KCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, 0);
801077da:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077dd:	66 c7 40 78 ff ff    	movw   $0xffff,0x78(%eax)
801077e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077e6:	66 c7 40 7a 00 00    	movw   $0x0,0x7a(%eax)
801077ec:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077ef:	c6 40 7c 00          	movb   $0x0,0x7c(%eax)
801077f3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801077f6:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
801077fa:	83 e2 f0             	and    $0xfffffff0,%edx
801077fd:	83 ca 0a             	or     $0xa,%edx
80107800:	88 50 7d             	mov    %dl,0x7d(%eax)
80107803:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107806:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
8010780a:	83 ca 10             	or     $0x10,%edx
8010780d:	88 50 7d             	mov    %dl,0x7d(%eax)
80107810:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107813:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107817:	83 e2 9f             	and    $0xffffff9f,%edx
8010781a:	88 50 7d             	mov    %dl,0x7d(%eax)
8010781d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107820:	0f b6 50 7d          	movzbl 0x7d(%eax),%edx
80107824:	83 ca 80             	or     $0xffffff80,%edx
80107827:	88 50 7d             	mov    %dl,0x7d(%eax)
8010782a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010782d:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107831:	83 ca 0f             	or     $0xf,%edx
80107834:	88 50 7e             	mov    %dl,0x7e(%eax)
80107837:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010783a:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010783e:	83 e2 ef             	and    $0xffffffef,%edx
80107841:	88 50 7e             	mov    %dl,0x7e(%eax)
80107844:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107847:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
8010784b:	83 e2 df             	and    $0xffffffdf,%edx
8010784e:	88 50 7e             	mov    %dl,0x7e(%eax)
80107851:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107854:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107858:	83 ca 40             	or     $0x40,%edx
8010785b:	88 50 7e             	mov    %dl,0x7e(%eax)
8010785e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107861:	0f b6 50 7e          	movzbl 0x7e(%eax),%edx
80107865:	83 ca 80             	or     $0xffffff80,%edx
80107868:	88 50 7e             	mov    %dl,0x7e(%eax)
8010786b:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010786e:	c6 40 7f 00          	movb   $0x0,0x7f(%eax)
  c->gdt[SEG_KDATA] = SEG(STA_W, 0, 0xffffffff, 0);
80107872:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107875:	66 c7 80 80 00 00 00 	movw   $0xffff,0x80(%eax)
8010787c:	ff ff 
8010787e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107881:	66 c7 80 82 00 00 00 	movw   $0x0,0x82(%eax)
80107888:	00 00 
8010788a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010788d:	c6 80 84 00 00 00 00 	movb   $0x0,0x84(%eax)
80107894:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107897:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
8010789e:	83 e2 f0             	and    $0xfffffff0,%edx
801078a1:	83 ca 02             	or     $0x2,%edx
801078a4:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078ad:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078b4:	83 ca 10             	or     $0x10,%edx
801078b7:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078c0:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078c7:	83 e2 9f             	and    $0xffffff9f,%edx
801078ca:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078d3:	0f b6 90 85 00 00 00 	movzbl 0x85(%eax),%edx
801078da:	83 ca 80             	or     $0xffffff80,%edx
801078dd:	88 90 85 00 00 00    	mov    %dl,0x85(%eax)
801078e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078e6:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
801078ed:	83 ca 0f             	or     $0xf,%edx
801078f0:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
801078f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801078f9:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107900:	83 e2 ef             	and    $0xffffffef,%edx
80107903:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107909:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010790c:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107913:	83 e2 df             	and    $0xffffffdf,%edx
80107916:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010791c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010791f:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107926:	83 ca 40             	or     $0x40,%edx
80107929:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
8010792f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107932:	0f b6 90 86 00 00 00 	movzbl 0x86(%eax),%edx
80107939:	83 ca 80             	or     $0xffffff80,%edx
8010793c:	88 90 86 00 00 00    	mov    %dl,0x86(%eax)
80107942:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107945:	c6 80 87 00 00 00 00 	movb   $0x0,0x87(%eax)
  c->gdt[SEG_UCODE] = SEG(STA_X|STA_R, 0, 0xffffffff, DPL_USER);
8010794c:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010794f:	66 c7 80 88 00 00 00 	movw   $0xffff,0x88(%eax)
80107956:	ff ff 
80107958:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010795b:	66 c7 80 8a 00 00 00 	movw   $0x0,0x8a(%eax)
80107962:	00 00 
80107964:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107967:	c6 80 8c 00 00 00 00 	movb   $0x0,0x8c(%eax)
8010796e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107971:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
80107978:	83 e2 f0             	and    $0xfffffff0,%edx
8010797b:	83 ca 0a             	or     $0xa,%edx
8010797e:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
80107984:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107987:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
8010798e:	83 ca 10             	or     $0x10,%edx
80107991:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
80107997:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010799a:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
801079a1:	83 ca 60             	or     $0x60,%edx
801079a4:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
801079aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079ad:	0f b6 90 8d 00 00 00 	movzbl 0x8d(%eax),%edx
801079b4:	83 ca 80             	or     $0xffffff80,%edx
801079b7:	88 90 8d 00 00 00    	mov    %dl,0x8d(%eax)
801079bd:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079c0:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801079c7:	83 ca 0f             	or     $0xf,%edx
801079ca:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801079d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079d3:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801079da:	83 e2 ef             	and    $0xffffffef,%edx
801079dd:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801079e3:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079e6:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
801079ed:	83 e2 df             	and    $0xffffffdf,%edx
801079f0:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
801079f6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801079f9:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107a00:	83 ca 40             	or     $0x40,%edx
80107a03:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
80107a09:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a0c:	0f b6 90 8e 00 00 00 	movzbl 0x8e(%eax),%edx
80107a13:	83 ca 80             	or     $0xffffff80,%edx
80107a16:	88 90 8e 00 00 00    	mov    %dl,0x8e(%eax)
80107a1c:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a1f:	c6 80 8f 00 00 00 00 	movb   $0x0,0x8f(%eax)
  c->gdt[SEG_UDATA] = SEG(STA_W, 0, 0xffffffff, DPL_USER);
80107a26:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a29:	66 c7 80 90 00 00 00 	movw   $0xffff,0x90(%eax)
80107a30:	ff ff 
80107a32:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a35:	66 c7 80 92 00 00 00 	movw   $0x0,0x92(%eax)
80107a3c:	00 00 
80107a3e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a41:	c6 80 94 00 00 00 00 	movb   $0x0,0x94(%eax)
80107a48:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a4b:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107a52:	83 e2 f0             	and    $0xfffffff0,%edx
80107a55:	83 ca 02             	or     $0x2,%edx
80107a58:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107a5e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a61:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107a68:	83 ca 10             	or     $0x10,%edx
80107a6b:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107a71:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a74:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107a7b:	83 ca 60             	or     $0x60,%edx
80107a7e:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107a84:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a87:	0f b6 90 95 00 00 00 	movzbl 0x95(%eax),%edx
80107a8e:	83 ca 80             	or     $0xffffff80,%edx
80107a91:	88 90 95 00 00 00    	mov    %dl,0x95(%eax)
80107a97:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107a9a:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107aa1:	83 ca 0f             	or     $0xf,%edx
80107aa4:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107aaa:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107aad:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107ab4:	83 e2 ef             	and    $0xffffffef,%edx
80107ab7:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107abd:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ac0:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107ac7:	83 e2 df             	and    $0xffffffdf,%edx
80107aca:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ad0:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ad3:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107ada:	83 ca 40             	or     $0x40,%edx
80107add:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107ae3:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ae6:	0f b6 90 96 00 00 00 	movzbl 0x96(%eax),%edx
80107aed:	83 ca 80             	or     $0xffffff80,%edx
80107af0:	88 90 96 00 00 00    	mov    %dl,0x96(%eax)
80107af6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107af9:	c6 80 97 00 00 00 00 	movb   $0x0,0x97(%eax)
  lgdt(c->gdt, sizeof(c->gdt));
80107b00:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b03:	83 c0 70             	add    $0x70,%eax
80107b06:	83 ec 08             	sub    $0x8,%esp
80107b09:	6a 30                	push   $0x30
80107b0b:	50                   	push   %eax
80107b0c:	e8 63 fc ff ff       	call   80107774 <lgdt>
80107b11:	83 c4 10             	add    $0x10,%esp
}
80107b14:	90                   	nop
80107b15:	c9                   	leave  
80107b16:	c3                   	ret    

80107b17 <walkpgdir>:
// Return the address of the PTE in page table pgdir
// that corresponds to virtual address va.  If alloc!=0,
// create any required page table pages.
static pte_t *
walkpgdir(pde_t *pgdir, const void *va, int alloc)
{
80107b17:	55                   	push   %ebp
80107b18:	89 e5                	mov    %esp,%ebp
80107b1a:	83 ec 18             	sub    $0x18,%esp
  pde_t *pde;
  pte_t *pgtab;

  pde = &pgdir[PDX(va)];
80107b1d:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b20:	c1 e8 16             	shr    $0x16,%eax
80107b23:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107b2a:	8b 45 08             	mov    0x8(%ebp),%eax
80107b2d:	01 d0                	add    %edx,%eax
80107b2f:	89 45 f0             	mov    %eax,-0x10(%ebp)
  if(*pde & PTE_P){
80107b32:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107b35:	8b 00                	mov    (%eax),%eax
80107b37:	83 e0 01             	and    $0x1,%eax
80107b3a:	85 c0                	test   %eax,%eax
80107b3c:	74 14                	je     80107b52 <walkpgdir+0x3b>
    pgtab = (pte_t*)P2V(PTE_ADDR(*pde));
80107b3e:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107b41:	8b 00                	mov    (%eax),%eax
80107b43:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107b48:	05 00 00 00 80       	add    $0x80000000,%eax
80107b4d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107b50:	eb 42                	jmp    80107b94 <walkpgdir+0x7d>
  } else {
    if(!alloc || (pgtab = (pte_t*)kalloc()) == 0)
80107b52:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
80107b56:	74 0e                	je     80107b66 <walkpgdir+0x4f>
80107b58:	e8 38 b1 ff ff       	call   80102c95 <kalloc>
80107b5d:	89 45 f4             	mov    %eax,-0xc(%ebp)
80107b60:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80107b64:	75 07                	jne    80107b6d <walkpgdir+0x56>
      return 0;
80107b66:	b8 00 00 00 00       	mov    $0x0,%eax
80107b6b:	eb 3e                	jmp    80107bab <walkpgdir+0x94>
    // Make sure all those PTE_P bits are zero.
    memset(pgtab, 0, PGSIZE);
80107b6d:	83 ec 04             	sub    $0x4,%esp
80107b70:	68 00 10 00 00       	push   $0x1000
80107b75:	6a 00                	push   $0x0
80107b77:	ff 75 f4             	pushl  -0xc(%ebp)
80107b7a:	e8 4e d6 ff ff       	call   801051cd <memset>
80107b7f:	83 c4 10             	add    $0x10,%esp
    // The permissions here are overly generous, but they can
    // be further restricted by the permissions in the page table
    // entries, if necessary.
    *pde = V2P(pgtab) | PTE_P | PTE_W | PTE_U;
80107b82:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107b85:	05 00 00 00 80       	add    $0x80000000,%eax
80107b8a:	83 c8 07             	or     $0x7,%eax
80107b8d:	89 c2                	mov    %eax,%edx
80107b8f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80107b92:	89 10                	mov    %edx,(%eax)
  }
  return &pgtab[PTX(va)];
80107b94:	8b 45 0c             	mov    0xc(%ebp),%eax
80107b97:	c1 e8 0c             	shr    $0xc,%eax
80107b9a:	25 ff 03 00 00       	and    $0x3ff,%eax
80107b9f:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80107ba6:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ba9:	01 d0                	add    %edx,%eax
}
80107bab:	c9                   	leave  
80107bac:	c3                   	ret    

80107bad <mappages>:

// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned.
int mappages(pde_t *pgdir, void *va, uint size, uint pa, int perm)
{
80107bad:	55                   	push   %ebp
80107bae:	89 e5                	mov    %esp,%ebp
80107bb0:	83 ec 18             	sub    $0x18,%esp
  char *a, *last;
  pte_t *pte;

  a = (char*)PGROUNDDOWN((uint)va);
80107bb3:	8b 45 0c             	mov    0xc(%ebp),%eax
80107bb6:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107bbb:	89 45 f4             	mov    %eax,-0xc(%ebp)
  last = (char*)PGROUNDDOWN(((uint)va) + size - 1);
80107bbe:	8b 55 0c             	mov    0xc(%ebp),%edx
80107bc1:	8b 45 10             	mov    0x10(%ebp),%eax
80107bc4:	01 d0                	add    %edx,%eax
80107bc6:	83 e8 01             	sub    $0x1,%eax
80107bc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107bce:	89 45 f0             	mov    %eax,-0x10(%ebp)
  for(;;){
    if((pte = walkpgdir(pgdir, a, 1)) == 0)
80107bd1:	83 ec 04             	sub    $0x4,%esp
80107bd4:	6a 01                	push   $0x1
80107bd6:	ff 75 f4             	pushl  -0xc(%ebp)
80107bd9:	ff 75 08             	pushl  0x8(%ebp)
80107bdc:	e8 36 ff ff ff       	call   80107b17 <walkpgdir>
80107be1:	83 c4 10             	add    $0x10,%esp
80107be4:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107be7:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107beb:	75 07                	jne    80107bf4 <mappages+0x47>
      return -1;
80107bed:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107bf2:	eb 47                	jmp    80107c3b <mappages+0x8e>
    if(*pte & PTE_P)
80107bf4:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107bf7:	8b 00                	mov    (%eax),%eax
80107bf9:	83 e0 01             	and    $0x1,%eax
80107bfc:	85 c0                	test   %eax,%eax
80107bfe:	74 0d                	je     80107c0d <mappages+0x60>
      panic("remap");
80107c00:	83 ec 0c             	sub    $0xc,%esp
80107c03:	68 c8 8b 10 80       	push   $0x80108bc8
80107c08:	e8 93 89 ff ff       	call   801005a0 <panic>
    *pte = pa | perm | PTE_P;
80107c0d:	8b 45 18             	mov    0x18(%ebp),%eax
80107c10:	0b 45 14             	or     0x14(%ebp),%eax
80107c13:	83 c8 01             	or     $0x1,%eax
80107c16:	89 c2                	mov    %eax,%edx
80107c18:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107c1b:	89 10                	mov    %edx,(%eax)
    if(a == last)
80107c1d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c20:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107c23:	74 10                	je     80107c35 <mappages+0x88>
      break;
    a += PGSIZE;
80107c25:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
    pa += PGSIZE;
80107c2c:	81 45 14 00 10 00 00 	addl   $0x1000,0x14(%ebp)
  }
80107c33:	eb 9c                	jmp    80107bd1 <mappages+0x24>
      return -1;
    if(*pte & PTE_P)
      panic("remap");
    *pte = pa | perm | PTE_P;
    if(a == last)
      break;
80107c35:	90                   	nop
    a += PGSIZE;
    pa += PGSIZE;
  }
  return 0;
80107c36:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107c3b:	c9                   	leave  
80107c3c:	c3                   	ret    

80107c3d <setupkvm>:
};

// Set up kernel part of a page table.
pde_t*
setupkvm(void)
{
80107c3d:	55                   	push   %ebp
80107c3e:	89 e5                	mov    %esp,%ebp
80107c40:	53                   	push   %ebx
80107c41:	83 ec 14             	sub    $0x14,%esp
  pde_t *pgdir;
  struct kmap *k;

  if((pgdir = (pde_t*)kalloc()) == 0)
80107c44:	e8 4c b0 ff ff       	call   80102c95 <kalloc>
80107c49:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107c4c:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80107c50:	75 07                	jne    80107c59 <setupkvm+0x1c>
    return 0;
80107c52:	b8 00 00 00 00       	mov    $0x0,%eax
80107c57:	eb 78                	jmp    80107cd1 <setupkvm+0x94>
  memset(pgdir, 0, PGSIZE);
80107c59:	83 ec 04             	sub    $0x4,%esp
80107c5c:	68 00 10 00 00       	push   $0x1000
80107c61:	6a 00                	push   $0x0
80107c63:	ff 75 f0             	pushl  -0x10(%ebp)
80107c66:	e8 62 d5 ff ff       	call   801051cd <memset>
80107c6b:	83 c4 10             	add    $0x10,%esp
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107c6e:	c7 45 f4 80 b4 10 80 	movl   $0x8010b480,-0xc(%ebp)
80107c75:	eb 4e                	jmp    80107cc5 <setupkvm+0x88>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80107c77:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c7a:	8b 48 0c             	mov    0xc(%eax),%ecx
                (uint)k->phys_start, k->perm) < 0) {
80107c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c80:	8b 50 04             	mov    0x4(%eax),%edx
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
80107c83:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c86:	8b 58 08             	mov    0x8(%eax),%ebx
80107c89:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c8c:	8b 40 04             	mov    0x4(%eax),%eax
80107c8f:	29 c3                	sub    %eax,%ebx
80107c91:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107c94:	8b 00                	mov    (%eax),%eax
80107c96:	83 ec 0c             	sub    $0xc,%esp
80107c99:	51                   	push   %ecx
80107c9a:	52                   	push   %edx
80107c9b:	53                   	push   %ebx
80107c9c:	50                   	push   %eax
80107c9d:	ff 75 f0             	pushl  -0x10(%ebp)
80107ca0:	e8 08 ff ff ff       	call   80107bad <mappages>
80107ca5:	83 c4 20             	add    $0x20,%esp
80107ca8:	85 c0                	test   %eax,%eax
80107caa:	79 15                	jns    80107cc1 <setupkvm+0x84>
                (uint)k->phys_start, k->perm) < 0) {
      freevm(pgdir);
80107cac:	83 ec 0c             	sub    $0xc,%esp
80107caf:	ff 75 f0             	pushl  -0x10(%ebp)
80107cb2:	e8 f4 04 00 00       	call   801081ab <freevm>
80107cb7:	83 c4 10             	add    $0x10,%esp
      return 0;
80107cba:	b8 00 00 00 00       	mov    $0x0,%eax
80107cbf:	eb 10                	jmp    80107cd1 <setupkvm+0x94>
  if((pgdir = (pde_t*)kalloc()) == 0)
    return 0;
  memset(pgdir, 0, PGSIZE);
  if (P2V(PHYSTOP) > (void*)DEVSPACE)
    panic("PHYSTOP too high");
  for(k = kmap; k < &kmap[NELEM(kmap)]; k++)
80107cc1:	83 45 f4 10          	addl   $0x10,-0xc(%ebp)
80107cc5:	81 7d f4 c0 b4 10 80 	cmpl   $0x8010b4c0,-0xc(%ebp)
80107ccc:	72 a9                	jb     80107c77 <setupkvm+0x3a>
    if(mappages(pgdir, k->virt, k->phys_end - k->phys_start,
                (uint)k->phys_start, k->perm) < 0) {
      freevm(pgdir);
      return 0;
    }
  return pgdir;
80107cce:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
80107cd1:	8b 5d fc             	mov    -0x4(%ebp),%ebx
80107cd4:	c9                   	leave  
80107cd5:	c3                   	ret    

80107cd6 <kvmalloc>:

// Allocate one page table for the machine for the kernel address
// space for scheduler processes.
void
kvmalloc(void)
{
80107cd6:	55                   	push   %ebp
80107cd7:	89 e5                	mov    %esp,%ebp
80107cd9:	83 ec 08             	sub    $0x8,%esp
  kpgdir = setupkvm();
80107cdc:	e8 5c ff ff ff       	call   80107c3d <setupkvm>
80107ce1:	a3 24 65 11 80       	mov    %eax,0x80116524
  switchkvm();
80107ce6:	e8 03 00 00 00       	call   80107cee <switchkvm>
}
80107ceb:	90                   	nop
80107cec:	c9                   	leave  
80107ced:	c3                   	ret    

80107cee <switchkvm>:

// Switch h/w page table register to the kernel-only page table,
// for when no process is running.
void
switchkvm(void)
{
80107cee:	55                   	push   %ebp
80107cef:	89 e5                	mov    %esp,%ebp
  lcr3(V2P(kpgdir));   // switch to the kernel page table
80107cf1:	a1 24 65 11 80       	mov    0x80116524,%eax
80107cf6:	05 00 00 00 80       	add    $0x80000000,%eax
80107cfb:	50                   	push   %eax
80107cfc:	e8 b4 fa ff ff       	call   801077b5 <lcr3>
80107d01:	83 c4 04             	add    $0x4,%esp
}
80107d04:	90                   	nop
80107d05:	c9                   	leave  
80107d06:	c3                   	ret    

80107d07 <switchuvm>:

// Switch TSS and h/w page table to correspond to process p.
void
switchuvm(struct proc *p)
{
80107d07:	55                   	push   %ebp
80107d08:	89 e5                	mov    %esp,%ebp
80107d0a:	56                   	push   %esi
80107d0b:	53                   	push   %ebx
80107d0c:	83 ec 10             	sub    $0x10,%esp
  if(p == 0)
80107d0f:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
80107d13:	75 0d                	jne    80107d22 <switchuvm+0x1b>
    panic("switchuvm: no process");
80107d15:	83 ec 0c             	sub    $0xc,%esp
80107d18:	68 ce 8b 10 80       	push   $0x80108bce
80107d1d:	e8 7e 88 ff ff       	call   801005a0 <panic>
  if(p->kstack == 0)
80107d22:	8b 45 08             	mov    0x8(%ebp),%eax
80107d25:	8b 40 08             	mov    0x8(%eax),%eax
80107d28:	85 c0                	test   %eax,%eax
80107d2a:	75 0d                	jne    80107d39 <switchuvm+0x32>
    panic("switchuvm: no kstack");
80107d2c:	83 ec 0c             	sub    $0xc,%esp
80107d2f:	68 e4 8b 10 80       	push   $0x80108be4
80107d34:	e8 67 88 ff ff       	call   801005a0 <panic>
  if(p->pgdir == 0)
80107d39:	8b 45 08             	mov    0x8(%ebp),%eax
80107d3c:	8b 40 04             	mov    0x4(%eax),%eax
80107d3f:	85 c0                	test   %eax,%eax
80107d41:	75 0d                	jne    80107d50 <switchuvm+0x49>
    panic("switchuvm: no pgdir");
80107d43:	83 ec 0c             	sub    $0xc,%esp
80107d46:	68 f9 8b 10 80       	push   $0x80108bf9
80107d4b:	e8 50 88 ff ff       	call   801005a0 <panic>

  pushcli();
80107d50:	e8 6c d3 ff ff       	call   801050c1 <pushcli>
  mycpu()->gdt[SEG_TSS] = SEG16(STS_T32A, &mycpu()->ts,
80107d55:	e8 b6 c4 ff ff       	call   80104210 <mycpu>
80107d5a:	89 c3                	mov    %eax,%ebx
80107d5c:	e8 af c4 ff ff       	call   80104210 <mycpu>
80107d61:	83 c0 08             	add    $0x8,%eax
80107d64:	89 c6                	mov    %eax,%esi
80107d66:	e8 a5 c4 ff ff       	call   80104210 <mycpu>
80107d6b:	83 c0 08             	add    $0x8,%eax
80107d6e:	c1 e8 10             	shr    $0x10,%eax
80107d71:	88 45 f7             	mov    %al,-0x9(%ebp)
80107d74:	e8 97 c4 ff ff       	call   80104210 <mycpu>
80107d79:	83 c0 08             	add    $0x8,%eax
80107d7c:	c1 e8 18             	shr    $0x18,%eax
80107d7f:	89 c2                	mov    %eax,%edx
80107d81:	66 c7 83 98 00 00 00 	movw   $0x67,0x98(%ebx)
80107d88:	67 00 
80107d8a:	66 89 b3 9a 00 00 00 	mov    %si,0x9a(%ebx)
80107d91:	0f b6 45 f7          	movzbl -0x9(%ebp),%eax
80107d95:	88 83 9c 00 00 00    	mov    %al,0x9c(%ebx)
80107d9b:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107da2:	83 e0 f0             	and    $0xfffffff0,%eax
80107da5:	83 c8 09             	or     $0x9,%eax
80107da8:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107dae:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107db5:	83 c8 10             	or     $0x10,%eax
80107db8:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107dbe:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107dc5:	83 e0 9f             	and    $0xffffff9f,%eax
80107dc8:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107dce:	0f b6 83 9d 00 00 00 	movzbl 0x9d(%ebx),%eax
80107dd5:	83 c8 80             	or     $0xffffff80,%eax
80107dd8:	88 83 9d 00 00 00    	mov    %al,0x9d(%ebx)
80107dde:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107de5:	83 e0 f0             	and    $0xfffffff0,%eax
80107de8:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107dee:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107df5:	83 e0 ef             	and    $0xffffffef,%eax
80107df8:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107dfe:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107e05:	83 e0 df             	and    $0xffffffdf,%eax
80107e08:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107e0e:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107e15:	83 c8 40             	or     $0x40,%eax
80107e18:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107e1e:	0f b6 83 9e 00 00 00 	movzbl 0x9e(%ebx),%eax
80107e25:	83 e0 7f             	and    $0x7f,%eax
80107e28:	88 83 9e 00 00 00    	mov    %al,0x9e(%ebx)
80107e2e:	88 93 9f 00 00 00    	mov    %dl,0x9f(%ebx)
                                sizeof(mycpu()->ts)-1, 0);
  mycpu()->gdt[SEG_TSS].s = 0;
80107e34:	e8 d7 c3 ff ff       	call   80104210 <mycpu>
80107e39:	0f b6 90 9d 00 00 00 	movzbl 0x9d(%eax),%edx
80107e40:	83 e2 ef             	and    $0xffffffef,%edx
80107e43:	88 90 9d 00 00 00    	mov    %dl,0x9d(%eax)
  mycpu()->ts.ss0 = SEG_KDATA << 3;
80107e49:	e8 c2 c3 ff ff       	call   80104210 <mycpu>
80107e4e:	66 c7 40 10 10 00    	movw   $0x10,0x10(%eax)
  mycpu()->ts.esp0 = (uint)p->kstack + KSTACKSIZE;
80107e54:	e8 b7 c3 ff ff       	call   80104210 <mycpu>
80107e59:	89 c2                	mov    %eax,%edx
80107e5b:	8b 45 08             	mov    0x8(%ebp),%eax
80107e5e:	8b 40 08             	mov    0x8(%eax),%eax
80107e61:	05 00 10 00 00       	add    $0x1000,%eax
80107e66:	89 42 0c             	mov    %eax,0xc(%edx)
  // setting IOPL=0 in eflags *and* iomb beyond the tss segment limit
  // forbids I/O instructions (e.g., inb and outb) from user space
  mycpu()->ts.iomb = (ushort) 0xFFFF;
80107e69:	e8 a2 c3 ff ff       	call   80104210 <mycpu>
80107e6e:	66 c7 40 6e ff ff    	movw   $0xffff,0x6e(%eax)
  ltr(SEG_TSS << 3);
80107e74:	83 ec 0c             	sub    $0xc,%esp
80107e77:	6a 28                	push   $0x28
80107e79:	e8 20 f9 ff ff       	call   8010779e <ltr>
80107e7e:	83 c4 10             	add    $0x10,%esp
  lcr3(V2P(p->pgdir));  // switch to process's address space
80107e81:	8b 45 08             	mov    0x8(%ebp),%eax
80107e84:	8b 40 04             	mov    0x4(%eax),%eax
80107e87:	05 00 00 00 80       	add    $0x80000000,%eax
80107e8c:	83 ec 0c             	sub    $0xc,%esp
80107e8f:	50                   	push   %eax
80107e90:	e8 20 f9 ff ff       	call   801077b5 <lcr3>
80107e95:	83 c4 10             	add    $0x10,%esp
  popcli();
80107e98:	e8 72 d2 ff ff       	call   8010510f <popcli>
}
80107e9d:	90                   	nop
80107e9e:	8d 65 f8             	lea    -0x8(%ebp),%esp
80107ea1:	5b                   	pop    %ebx
80107ea2:	5e                   	pop    %esi
80107ea3:	5d                   	pop    %ebp
80107ea4:	c3                   	ret    

80107ea5 <inituvm>:

// Load the initcode into address 0 of pgdir.
// sz must be less than a page.
void
inituvm(pde_t *pgdir, char *init, uint sz)
{
80107ea5:	55                   	push   %ebp
80107ea6:	89 e5                	mov    %esp,%ebp
80107ea8:	83 ec 18             	sub    $0x18,%esp
  char *mem;

  if(sz >= PGSIZE)
80107eab:	81 7d 10 ff 0f 00 00 	cmpl   $0xfff,0x10(%ebp)
80107eb2:	76 0d                	jbe    80107ec1 <inituvm+0x1c>
    panic("inituvm: more than a page");
80107eb4:	83 ec 0c             	sub    $0xc,%esp
80107eb7:	68 0d 8c 10 80       	push   $0x80108c0d
80107ebc:	e8 df 86 ff ff       	call   801005a0 <panic>
  mem = kalloc();
80107ec1:	e8 cf ad ff ff       	call   80102c95 <kalloc>
80107ec6:	89 45 f4             	mov    %eax,-0xc(%ebp)
  memset(mem, 0, PGSIZE);
80107ec9:	83 ec 04             	sub    $0x4,%esp
80107ecc:	68 00 10 00 00       	push   $0x1000
80107ed1:	6a 00                	push   $0x0
80107ed3:	ff 75 f4             	pushl  -0xc(%ebp)
80107ed6:	e8 f2 d2 ff ff       	call   801051cd <memset>
80107edb:	83 c4 10             	add    $0x10,%esp
  mappages(pgdir, 0, PGSIZE, V2P(mem), PTE_W|PTE_U);
80107ede:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107ee1:	05 00 00 00 80       	add    $0x80000000,%eax
80107ee6:	83 ec 0c             	sub    $0xc,%esp
80107ee9:	6a 06                	push   $0x6
80107eeb:	50                   	push   %eax
80107eec:	68 00 10 00 00       	push   $0x1000
80107ef1:	6a 00                	push   $0x0
80107ef3:	ff 75 08             	pushl  0x8(%ebp)
80107ef6:	e8 b2 fc ff ff       	call   80107bad <mappages>
80107efb:	83 c4 20             	add    $0x20,%esp
  memmove(mem, init, sz);
80107efe:	83 ec 04             	sub    $0x4,%esp
80107f01:	ff 75 10             	pushl  0x10(%ebp)
80107f04:	ff 75 0c             	pushl  0xc(%ebp)
80107f07:	ff 75 f4             	pushl  -0xc(%ebp)
80107f0a:	e8 7d d3 ff ff       	call   8010528c <memmove>
80107f0f:	83 c4 10             	add    $0x10,%esp
}
80107f12:	90                   	nop
80107f13:	c9                   	leave  
80107f14:	c3                   	ret    

80107f15 <loaduvm>:

// Load a program segment into pgdir.  addr must be page-aligned
// and the pages from addr to addr+sz must already be mapped.
int
loaduvm(pde_t *pgdir, char *addr, struct inode *ip, uint offset, uint sz)
{
80107f15:	55                   	push   %ebp
80107f16:	89 e5                	mov    %esp,%ebp
80107f18:	83 ec 18             	sub    $0x18,%esp
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
80107f1b:	8b 45 0c             	mov    0xc(%ebp),%eax
80107f1e:	25 ff 0f 00 00       	and    $0xfff,%eax
80107f23:	85 c0                	test   %eax,%eax
80107f25:	74 0d                	je     80107f34 <loaduvm+0x1f>
    panic("loaduvm: addr must be page aligned");
80107f27:	83 ec 0c             	sub    $0xc,%esp
80107f2a:	68 28 8c 10 80       	push   $0x80108c28
80107f2f:	e8 6c 86 ff ff       	call   801005a0 <panic>
  for(i = 0; i < sz; i += PGSIZE){
80107f34:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
80107f3b:	e9 8f 00 00 00       	jmp    80107fcf <loaduvm+0xba>
    if((pte = walkpgdir(pgdir, addr+i, 0)) == 0)
80107f40:	8b 55 0c             	mov    0xc(%ebp),%edx
80107f43:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107f46:	01 d0                	add    %edx,%eax
80107f48:	83 ec 04             	sub    $0x4,%esp
80107f4b:	6a 00                	push   $0x0
80107f4d:	50                   	push   %eax
80107f4e:	ff 75 08             	pushl  0x8(%ebp)
80107f51:	e8 c1 fb ff ff       	call   80107b17 <walkpgdir>
80107f56:	83 c4 10             	add    $0x10,%esp
80107f59:	89 45 ec             	mov    %eax,-0x14(%ebp)
80107f5c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80107f60:	75 0d                	jne    80107f6f <loaduvm+0x5a>
      panic("loaduvm: address should exist");
80107f62:	83 ec 0c             	sub    $0xc,%esp
80107f65:	68 4b 8c 10 80       	push   $0x80108c4b
80107f6a:	e8 31 86 ff ff       	call   801005a0 <panic>
    pa = PTE_ADDR(*pte);
80107f6f:	8b 45 ec             	mov    -0x14(%ebp),%eax
80107f72:	8b 00                	mov    (%eax),%eax
80107f74:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80107f79:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(sz - i < PGSIZE)
80107f7c:	8b 45 18             	mov    0x18(%ebp),%eax
80107f7f:	2b 45 f4             	sub    -0xc(%ebp),%eax
80107f82:	3d ff 0f 00 00       	cmp    $0xfff,%eax
80107f87:	77 0b                	ja     80107f94 <loaduvm+0x7f>
      n = sz - i;
80107f89:	8b 45 18             	mov    0x18(%ebp),%eax
80107f8c:	2b 45 f4             	sub    -0xc(%ebp),%eax
80107f8f:	89 45 f0             	mov    %eax,-0x10(%ebp)
80107f92:	eb 07                	jmp    80107f9b <loaduvm+0x86>
    else
      n = PGSIZE;
80107f94:	c7 45 f0 00 10 00 00 	movl   $0x1000,-0x10(%ebp)
    if(readi(ip, P2V(pa), offset+i, n) != n)
80107f9b:	8b 55 14             	mov    0x14(%ebp),%edx
80107f9e:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fa1:	01 d0                	add    %edx,%eax
80107fa3:	8b 55 e8             	mov    -0x18(%ebp),%edx
80107fa6:	81 c2 00 00 00 80    	add    $0x80000000,%edx
80107fac:	ff 75 f0             	pushl  -0x10(%ebp)
80107faf:	50                   	push   %eax
80107fb0:	52                   	push   %edx
80107fb1:	ff 75 10             	pushl  0x10(%ebp)
80107fb4:	e8 48 9f ff ff       	call   80101f01 <readi>
80107fb9:	83 c4 10             	add    $0x10,%esp
80107fbc:	3b 45 f0             	cmp    -0x10(%ebp),%eax
80107fbf:	74 07                	je     80107fc8 <loaduvm+0xb3>
      return -1;
80107fc1:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
80107fc6:	eb 18                	jmp    80107fe0 <loaduvm+0xcb>
  uint i, pa, n;
  pte_t *pte;

  if((uint) addr % PGSIZE != 0)
    panic("loaduvm: addr must be page aligned");
  for(i = 0; i < sz; i += PGSIZE){
80107fc8:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80107fcf:	8b 45 f4             	mov    -0xc(%ebp),%eax
80107fd2:	3b 45 18             	cmp    0x18(%ebp),%eax
80107fd5:	0f 82 65 ff ff ff    	jb     80107f40 <loaduvm+0x2b>
    else
      n = PGSIZE;
    if(readi(ip, P2V(pa), offset+i, n) != n)
      return -1;
  }
  return 0;
80107fdb:	b8 00 00 00 00       	mov    $0x0,%eax
}
80107fe0:	c9                   	leave  
80107fe1:	c3                   	ret    

80107fe2 <allocuvm>:

// Allocate page tables and physical memory to grow process from oldsz to
// newsz, which need not be page aligned.  Returns new size or 0 on error.
int
allocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
80107fe2:	55                   	push   %ebp
80107fe3:	89 e5                	mov    %esp,%ebp
80107fe5:	83 ec 18             	sub    $0x18,%esp
  char *mem;
  uint a;

  if(newsz >= KERNBASE)
80107fe8:	8b 45 10             	mov    0x10(%ebp),%eax
80107feb:	85 c0                	test   %eax,%eax
80107fed:	79 0a                	jns    80107ff9 <allocuvm+0x17>
    return 0;
80107fef:	b8 00 00 00 00       	mov    $0x0,%eax
80107ff4:	e9 ec 00 00 00       	jmp    801080e5 <allocuvm+0x103>
  if(newsz < oldsz)
80107ff9:	8b 45 10             	mov    0x10(%ebp),%eax
80107ffc:	3b 45 0c             	cmp    0xc(%ebp),%eax
80107fff:	73 08                	jae    80108009 <allocuvm+0x27>
    return oldsz;
80108001:	8b 45 0c             	mov    0xc(%ebp),%eax
80108004:	e9 dc 00 00 00       	jmp    801080e5 <allocuvm+0x103>

  a = PGROUNDUP(oldsz);
80108009:	8b 45 0c             	mov    0xc(%ebp),%eax
8010800c:	05 ff 0f 00 00       	add    $0xfff,%eax
80108011:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108016:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a < newsz; a += PGSIZE){
80108019:	e9 b8 00 00 00       	jmp    801080d6 <allocuvm+0xf4>
    mem = kalloc();
8010801e:	e8 72 ac ff ff       	call   80102c95 <kalloc>
80108023:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(mem == 0){
80108026:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010802a:	75 2e                	jne    8010805a <allocuvm+0x78>
      cprintf("allocuvm out of memory\n");
8010802c:	83 ec 0c             	sub    $0xc,%esp
8010802f:	68 69 8c 10 80       	push   $0x80108c69
80108034:	e8 c7 83 ff ff       	call   80100400 <cprintf>
80108039:	83 c4 10             	add    $0x10,%esp
      deallocuvm(pgdir, newsz, oldsz);
8010803c:	83 ec 04             	sub    $0x4,%esp
8010803f:	ff 75 0c             	pushl  0xc(%ebp)
80108042:	ff 75 10             	pushl  0x10(%ebp)
80108045:	ff 75 08             	pushl  0x8(%ebp)
80108048:	e8 9a 00 00 00       	call   801080e7 <deallocuvm>
8010804d:	83 c4 10             	add    $0x10,%esp
      return 0;
80108050:	b8 00 00 00 00       	mov    $0x0,%eax
80108055:	e9 8b 00 00 00       	jmp    801080e5 <allocuvm+0x103>
    }
    memset(mem, 0, PGSIZE);
8010805a:	83 ec 04             	sub    $0x4,%esp
8010805d:	68 00 10 00 00       	push   $0x1000
80108062:	6a 00                	push   $0x0
80108064:	ff 75 f0             	pushl  -0x10(%ebp)
80108067:	e8 61 d1 ff ff       	call   801051cd <memset>
8010806c:	83 c4 10             	add    $0x10,%esp
    if(mappages(pgdir, (char*)a, PGSIZE, V2P(mem), PTE_W|PTE_U) < 0){
8010806f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108072:	8d 90 00 00 00 80    	lea    -0x80000000(%eax),%edx
80108078:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010807b:	83 ec 0c             	sub    $0xc,%esp
8010807e:	6a 06                	push   $0x6
80108080:	52                   	push   %edx
80108081:	68 00 10 00 00       	push   $0x1000
80108086:	50                   	push   %eax
80108087:	ff 75 08             	pushl  0x8(%ebp)
8010808a:	e8 1e fb ff ff       	call   80107bad <mappages>
8010808f:	83 c4 20             	add    $0x20,%esp
80108092:	85 c0                	test   %eax,%eax
80108094:	79 39                	jns    801080cf <allocuvm+0xed>
      cprintf("allocuvm out of memory (2)\n");
80108096:	83 ec 0c             	sub    $0xc,%esp
80108099:	68 81 8c 10 80       	push   $0x80108c81
8010809e:	e8 5d 83 ff ff       	call   80100400 <cprintf>
801080a3:	83 c4 10             	add    $0x10,%esp
      deallocuvm(pgdir, newsz, oldsz);
801080a6:	83 ec 04             	sub    $0x4,%esp
801080a9:	ff 75 0c             	pushl  0xc(%ebp)
801080ac:	ff 75 10             	pushl  0x10(%ebp)
801080af:	ff 75 08             	pushl  0x8(%ebp)
801080b2:	e8 30 00 00 00       	call   801080e7 <deallocuvm>
801080b7:	83 c4 10             	add    $0x10,%esp
      kfree(mem);
801080ba:	83 ec 0c             	sub    $0xc,%esp
801080bd:	ff 75 f0             	pushl  -0x10(%ebp)
801080c0:	e8 36 ab ff ff       	call   80102bfb <kfree>
801080c5:	83 c4 10             	add    $0x10,%esp
      return 0;
801080c8:	b8 00 00 00 00       	mov    $0x0,%eax
801080cd:	eb 16                	jmp    801080e5 <allocuvm+0x103>
    return 0;
  if(newsz < oldsz)
    return oldsz;

  a = PGROUNDUP(oldsz);
  for(; a < newsz; a += PGSIZE){
801080cf:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
801080d6:	8b 45 f4             	mov    -0xc(%ebp),%eax
801080d9:	3b 45 10             	cmp    0x10(%ebp),%eax
801080dc:	0f 82 3c ff ff ff    	jb     8010801e <allocuvm+0x3c>
      deallocuvm(pgdir, newsz, oldsz);
      kfree(mem);
      return 0;
    }
  }
  return newsz;
801080e2:	8b 45 10             	mov    0x10(%ebp),%eax
}
801080e5:	c9                   	leave  
801080e6:	c3                   	ret    

801080e7 <deallocuvm>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
int
deallocuvm(pde_t *pgdir, uint oldsz, uint newsz)
{
801080e7:	55                   	push   %ebp
801080e8:	89 e5                	mov    %esp,%ebp
801080ea:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;
  uint a, pa;

  if(newsz >= oldsz)
801080ed:	8b 45 10             	mov    0x10(%ebp),%eax
801080f0:	3b 45 0c             	cmp    0xc(%ebp),%eax
801080f3:	72 08                	jb     801080fd <deallocuvm+0x16>
    return oldsz;
801080f5:	8b 45 0c             	mov    0xc(%ebp),%eax
801080f8:	e9 ac 00 00 00       	jmp    801081a9 <deallocuvm+0xc2>

  a = PGROUNDUP(newsz);
801080fd:	8b 45 10             	mov    0x10(%ebp),%eax
80108100:	05 ff 0f 00 00       	add    $0xfff,%eax
80108105:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010810a:	89 45 f4             	mov    %eax,-0xc(%ebp)
  for(; a  < oldsz; a += PGSIZE){
8010810d:	e9 88 00 00 00       	jmp    8010819a <deallocuvm+0xb3>
    pte = walkpgdir(pgdir, (char*)a, 0);
80108112:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108115:	83 ec 04             	sub    $0x4,%esp
80108118:	6a 00                	push   $0x0
8010811a:	50                   	push   %eax
8010811b:	ff 75 08             	pushl  0x8(%ebp)
8010811e:	e8 f4 f9 ff ff       	call   80107b17 <walkpgdir>
80108123:	83 c4 10             	add    $0x10,%esp
80108126:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(!pte)
80108129:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
8010812d:	75 16                	jne    80108145 <deallocuvm+0x5e>
      a = PGADDR(PDX(a) + 1, 0, 0) - PGSIZE;
8010812f:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108132:	c1 e8 16             	shr    $0x16,%eax
80108135:	83 c0 01             	add    $0x1,%eax
80108138:	c1 e0 16             	shl    $0x16,%eax
8010813b:	2d 00 10 00 00       	sub    $0x1000,%eax
80108140:	89 45 f4             	mov    %eax,-0xc(%ebp)
80108143:	eb 4e                	jmp    80108193 <deallocuvm+0xac>
    else if((*pte & PTE_P) != 0){
80108145:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108148:	8b 00                	mov    (%eax),%eax
8010814a:	83 e0 01             	and    $0x1,%eax
8010814d:	85 c0                	test   %eax,%eax
8010814f:	74 42                	je     80108193 <deallocuvm+0xac>
      pa = PTE_ADDR(*pte);
80108151:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108154:	8b 00                	mov    (%eax),%eax
80108156:	25 00 f0 ff ff       	and    $0xfffff000,%eax
8010815b:	89 45 ec             	mov    %eax,-0x14(%ebp)
      if(pa == 0)
8010815e:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
80108162:	75 0d                	jne    80108171 <deallocuvm+0x8a>
        panic("kfree");
80108164:	83 ec 0c             	sub    $0xc,%esp
80108167:	68 9d 8c 10 80       	push   $0x80108c9d
8010816c:	e8 2f 84 ff ff       	call   801005a0 <panic>
      char *v = P2V(pa);
80108171:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108174:	05 00 00 00 80       	add    $0x80000000,%eax
80108179:	89 45 e8             	mov    %eax,-0x18(%ebp)
      kfree(v);
8010817c:	83 ec 0c             	sub    $0xc,%esp
8010817f:	ff 75 e8             	pushl  -0x18(%ebp)
80108182:	e8 74 aa ff ff       	call   80102bfb <kfree>
80108187:	83 c4 10             	add    $0x10,%esp
      *pte = 0;
8010818a:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010818d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)

  if(newsz >= oldsz)
    return oldsz;

  a = PGROUNDUP(newsz);
  for(; a  < oldsz; a += PGSIZE){
80108193:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
8010819a:	8b 45 f4             	mov    -0xc(%ebp),%eax
8010819d:	3b 45 0c             	cmp    0xc(%ebp),%eax
801081a0:	0f 82 6c ff ff ff    	jb     80108112 <deallocuvm+0x2b>
      char *v = P2V(pa);
      kfree(v);
      *pte = 0;
    }
  }
  return newsz;
801081a6:	8b 45 10             	mov    0x10(%ebp),%eax
}
801081a9:	c9                   	leave  
801081aa:	c3                   	ret    

801081ab <freevm>:

// Free a page table and all the physical memory pages
// in the user part.
void
freevm(pde_t *pgdir)
{
801081ab:	55                   	push   %ebp
801081ac:	89 e5                	mov    %esp,%ebp
801081ae:	83 ec 18             	sub    $0x18,%esp
  uint i;

  if(pgdir == 0)
801081b1:	83 7d 08 00          	cmpl   $0x0,0x8(%ebp)
801081b5:	75 0d                	jne    801081c4 <freevm+0x19>
    panic("freevm: no pgdir");
801081b7:	83 ec 0c             	sub    $0xc,%esp
801081ba:	68 a3 8c 10 80       	push   $0x80108ca3
801081bf:	e8 dc 83 ff ff       	call   801005a0 <panic>
  deallocuvm(pgdir, KERNBASE, 0);
801081c4:	83 ec 04             	sub    $0x4,%esp
801081c7:	6a 00                	push   $0x0
801081c9:	68 00 00 00 80       	push   $0x80000000
801081ce:	ff 75 08             	pushl  0x8(%ebp)
801081d1:	e8 11 ff ff ff       	call   801080e7 <deallocuvm>
801081d6:	83 c4 10             	add    $0x10,%esp
  for(i = 0; i < NPDENTRIES; i++){
801081d9:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801081e0:	eb 48                	jmp    8010822a <freevm+0x7f>
    if(pgdir[i] & PTE_P){
801081e2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081e5:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
801081ec:	8b 45 08             	mov    0x8(%ebp),%eax
801081ef:	01 d0                	add    %edx,%eax
801081f1:	8b 00                	mov    (%eax),%eax
801081f3:	83 e0 01             	and    $0x1,%eax
801081f6:	85 c0                	test   %eax,%eax
801081f8:	74 2c                	je     80108226 <freevm+0x7b>
      char * v = P2V(PTE_ADDR(pgdir[i]));
801081fa:	8b 45 f4             	mov    -0xc(%ebp),%eax
801081fd:	8d 14 85 00 00 00 00 	lea    0x0(,%eax,4),%edx
80108204:	8b 45 08             	mov    0x8(%ebp),%eax
80108207:	01 d0                	add    %edx,%eax
80108209:	8b 00                	mov    (%eax),%eax
8010820b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
80108210:	05 00 00 00 80       	add    $0x80000000,%eax
80108215:	89 45 f0             	mov    %eax,-0x10(%ebp)
      kfree(v);
80108218:	83 ec 0c             	sub    $0xc,%esp
8010821b:	ff 75 f0             	pushl  -0x10(%ebp)
8010821e:	e8 d8 a9 ff ff       	call   80102bfb <kfree>
80108223:	83 c4 10             	add    $0x10,%esp
  uint i;

  if(pgdir == 0)
    panic("freevm: no pgdir");
  deallocuvm(pgdir, KERNBASE, 0);
  for(i = 0; i < NPDENTRIES; i++){
80108226:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
8010822a:	81 7d f4 ff 03 00 00 	cmpl   $0x3ff,-0xc(%ebp)
80108231:	76 af                	jbe    801081e2 <freevm+0x37>
    if(pgdir[i] & PTE_P){
      char * v = P2V(PTE_ADDR(pgdir[i]));
      kfree(v);
    }
  }
  kfree((char*)pgdir);
80108233:	83 ec 0c             	sub    $0xc,%esp
80108236:	ff 75 08             	pushl  0x8(%ebp)
80108239:	e8 bd a9 ff ff       	call   80102bfb <kfree>
8010823e:	83 c4 10             	add    $0x10,%esp
}
80108241:	90                   	nop
80108242:	c9                   	leave  
80108243:	c3                   	ret    

80108244 <clearpteu>:

// Clear PTE_U on a page. Used to create an inaccessible
// page beneath the user stack.
void
clearpteu(pde_t *pgdir, char *uva)
{
80108244:	55                   	push   %ebp
80108245:	89 e5                	mov    %esp,%ebp
80108247:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
8010824a:	83 ec 04             	sub    $0x4,%esp
8010824d:	6a 00                	push   $0x0
8010824f:	ff 75 0c             	pushl  0xc(%ebp)
80108252:	ff 75 08             	pushl  0x8(%ebp)
80108255:	e8 bd f8 ff ff       	call   80107b17 <walkpgdir>
8010825a:	83 c4 10             	add    $0x10,%esp
8010825d:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(pte == 0)
80108260:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
80108264:	75 0d                	jne    80108273 <clearpteu+0x2f>
    panic("clearpteu");
80108266:	83 ec 0c             	sub    $0xc,%esp
80108269:	68 b4 8c 10 80       	push   $0x80108cb4
8010826e:	e8 2d 83 ff ff       	call   801005a0 <panic>
  *pte &= ~PTE_U;
80108273:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108276:	8b 00                	mov    (%eax),%eax
80108278:	83 e0 fb             	and    $0xfffffffb,%eax
8010827b:	89 c2                	mov    %eax,%edx
8010827d:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108280:	89 10                	mov    %edx,(%eax)
}
80108282:	90                   	nop
80108283:	c9                   	leave  
80108284:	c3                   	ret    

80108285 <copyuvm>:

// Given a parent process's page table, create a copy
// of it for a child.
pde_t*
copyuvm(pde_t *pgdir, uint sz)
{
80108285:	55                   	push   %ebp
80108286:	89 e5                	mov    %esp,%ebp
80108288:	83 ec 28             	sub    $0x28,%esp
  pde_t *d;
  pte_t *pte;
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
8010828b:	e8 ad f9 ff ff       	call   80107c3d <setupkvm>
80108290:	89 45 f0             	mov    %eax,-0x10(%ebp)
80108293:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
80108297:	75 0a                	jne    801082a3 <copyuvm+0x1e>
    return 0;
80108299:	b8 00 00 00 00       	mov    $0x0,%eax
8010829e:	e9 eb 00 00 00       	jmp    8010838e <copyuvm+0x109>
  for(i = 0; i < sz; i += PGSIZE){
801082a3:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
801082aa:	e9 b7 00 00 00       	jmp    80108366 <copyuvm+0xe1>
    if((pte = walkpgdir(pgdir, (void *) i, 0)) == 0)
801082af:	8b 45 f4             	mov    -0xc(%ebp),%eax
801082b2:	83 ec 04             	sub    $0x4,%esp
801082b5:	6a 00                	push   $0x0
801082b7:	50                   	push   %eax
801082b8:	ff 75 08             	pushl  0x8(%ebp)
801082bb:	e8 57 f8 ff ff       	call   80107b17 <walkpgdir>
801082c0:	83 c4 10             	add    $0x10,%esp
801082c3:	89 45 ec             	mov    %eax,-0x14(%ebp)
801082c6:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
801082ca:	75 0d                	jne    801082d9 <copyuvm+0x54>
      panic("copyuvm: pte should exist");
801082cc:	83 ec 0c             	sub    $0xc,%esp
801082cf:	68 be 8c 10 80       	push   $0x80108cbe
801082d4:	e8 c7 82 ff ff       	call   801005a0 <panic>
    if(!(*pte & PTE_P))
801082d9:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082dc:	8b 00                	mov    (%eax),%eax
801082de:	83 e0 01             	and    $0x1,%eax
801082e1:	85 c0                	test   %eax,%eax
801082e3:	75 0d                	jne    801082f2 <copyuvm+0x6d>
      panic("copyuvm: page not present");
801082e5:	83 ec 0c             	sub    $0xc,%esp
801082e8:	68 d8 8c 10 80       	push   $0x80108cd8
801082ed:	e8 ae 82 ff ff       	call   801005a0 <panic>
    pa = PTE_ADDR(*pte);
801082f2:	8b 45 ec             	mov    -0x14(%ebp),%eax
801082f5:	8b 00                	mov    (%eax),%eax
801082f7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801082fc:	89 45 e8             	mov    %eax,-0x18(%ebp)
    flags = PTE_FLAGS(*pte);
801082ff:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108302:	8b 00                	mov    (%eax),%eax
80108304:	25 ff 0f 00 00       	and    $0xfff,%eax
80108309:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if((mem = kalloc()) == 0)
8010830c:	e8 84 a9 ff ff       	call   80102c95 <kalloc>
80108311:	89 45 e0             	mov    %eax,-0x20(%ebp)
80108314:	83 7d e0 00          	cmpl   $0x0,-0x20(%ebp)
80108318:	74 5d                	je     80108377 <copyuvm+0xf2>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
8010831a:	8b 45 e8             	mov    -0x18(%ebp),%eax
8010831d:	05 00 00 00 80       	add    $0x80000000,%eax
80108322:	83 ec 04             	sub    $0x4,%esp
80108325:	68 00 10 00 00       	push   $0x1000
8010832a:	50                   	push   %eax
8010832b:	ff 75 e0             	pushl  -0x20(%ebp)
8010832e:	e8 59 cf ff ff       	call   8010528c <memmove>
80108333:	83 c4 10             	add    $0x10,%esp
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
80108336:	8b 55 e4             	mov    -0x1c(%ebp),%edx
80108339:	8b 45 e0             	mov    -0x20(%ebp),%eax
8010833c:	8d 88 00 00 00 80    	lea    -0x80000000(%eax),%ecx
80108342:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108345:	83 ec 0c             	sub    $0xc,%esp
80108348:	52                   	push   %edx
80108349:	51                   	push   %ecx
8010834a:	68 00 10 00 00       	push   $0x1000
8010834f:	50                   	push   %eax
80108350:	ff 75 f0             	pushl  -0x10(%ebp)
80108353:	e8 55 f8 ff ff       	call   80107bad <mappages>
80108358:	83 c4 20             	add    $0x20,%esp
8010835b:	85 c0                	test   %eax,%eax
8010835d:	78 1b                	js     8010837a <copyuvm+0xf5>
  uint pa, i, flags;
  char *mem;

  if((d = setupkvm()) == 0)
    return 0;
  for(i = 0; i < sz; i += PGSIZE){
8010835f:	81 45 f4 00 10 00 00 	addl   $0x1000,-0xc(%ebp)
80108366:	8b 45 f4             	mov    -0xc(%ebp),%eax
80108369:	3b 45 0c             	cmp    0xc(%ebp),%eax
8010836c:	0f 82 3d ff ff ff    	jb     801082af <copyuvm+0x2a>
      goto bad;
    memmove(mem, (char*)P2V(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
      goto bad;
  }
  return d;
80108372:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108375:	eb 17                	jmp    8010838e <copyuvm+0x109>
    if(!(*pte & PTE_P))
      panic("copyuvm: page not present");
    pa = PTE_ADDR(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto bad;
80108377:	90                   	nop
80108378:	eb 01                	jmp    8010837b <copyuvm+0xf6>
    memmove(mem, (char*)P2V(pa), PGSIZE);
    if(mappages(d, (void*)i, PGSIZE, V2P(mem), flags) < 0)
      goto bad;
8010837a:	90                   	nop
  }
  return d;

bad:
  freevm(d);
8010837b:	83 ec 0c             	sub    $0xc,%esp
8010837e:	ff 75 f0             	pushl  -0x10(%ebp)
80108381:	e8 25 fe ff ff       	call   801081ab <freevm>
80108386:	83 c4 10             	add    $0x10,%esp
  return 0;
80108389:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010838e:	c9                   	leave  
8010838f:	c3                   	ret    

80108390 <uva2ka>:

//PAGEBREAK!
// Map user virtual address to kernel address.
char*
uva2ka(pde_t *pgdir, char *uva)
{
80108390:	55                   	push   %ebp
80108391:	89 e5                	mov    %esp,%ebp
80108393:	83 ec 18             	sub    $0x18,%esp
  pte_t *pte;

  pte = walkpgdir(pgdir, uva, 0);
80108396:	83 ec 04             	sub    $0x4,%esp
80108399:	6a 00                	push   $0x0
8010839b:	ff 75 0c             	pushl  0xc(%ebp)
8010839e:	ff 75 08             	pushl  0x8(%ebp)
801083a1:	e8 71 f7 ff ff       	call   80107b17 <walkpgdir>
801083a6:	83 c4 10             	add    $0x10,%esp
801083a9:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if((*pte & PTE_P) == 0)
801083ac:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083af:	8b 00                	mov    (%eax),%eax
801083b1:	83 e0 01             	and    $0x1,%eax
801083b4:	85 c0                	test   %eax,%eax
801083b6:	75 07                	jne    801083bf <uva2ka+0x2f>
    return 0;
801083b8:	b8 00 00 00 00       	mov    $0x0,%eax
801083bd:	eb 22                	jmp    801083e1 <uva2ka+0x51>
  if((*pte & PTE_U) == 0)
801083bf:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083c2:	8b 00                	mov    (%eax),%eax
801083c4:	83 e0 04             	and    $0x4,%eax
801083c7:	85 c0                	test   %eax,%eax
801083c9:	75 07                	jne    801083d2 <uva2ka+0x42>
    return 0;
801083cb:	b8 00 00 00 00       	mov    $0x0,%eax
801083d0:	eb 0f                	jmp    801083e1 <uva2ka+0x51>
  return (char*)P2V(PTE_ADDR(*pte));
801083d2:	8b 45 f4             	mov    -0xc(%ebp),%eax
801083d5:	8b 00                	mov    (%eax),%eax
801083d7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083dc:	05 00 00 00 80       	add    $0x80000000,%eax
}
801083e1:	c9                   	leave  
801083e2:	c3                   	ret    

801083e3 <copyout>:
// Copy len bytes from p to user address va in page table pgdir.
// Most useful when pgdir is not the current page table.
// uva2ka ensures this only works for PTE_U pages.
int
copyout(pde_t *pgdir, uint va, void *p, uint len)
{
801083e3:	55                   	push   %ebp
801083e4:	89 e5                	mov    %esp,%ebp
801083e6:	83 ec 18             	sub    $0x18,%esp
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
801083e9:	8b 45 10             	mov    0x10(%ebp),%eax
801083ec:	89 45 f4             	mov    %eax,-0xc(%ebp)
  while(len > 0){
801083ef:	eb 7f                	jmp    80108470 <copyout+0x8d>
    va0 = (uint)PGROUNDDOWN(va);
801083f1:	8b 45 0c             	mov    0xc(%ebp),%eax
801083f4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
801083f9:	89 45 ec             	mov    %eax,-0x14(%ebp)
    pa0 = uva2ka(pgdir, (char*)va0);
801083fc:	8b 45 ec             	mov    -0x14(%ebp),%eax
801083ff:	83 ec 08             	sub    $0x8,%esp
80108402:	50                   	push   %eax
80108403:	ff 75 08             	pushl  0x8(%ebp)
80108406:	e8 85 ff ff ff       	call   80108390 <uva2ka>
8010840b:	83 c4 10             	add    $0x10,%esp
8010840e:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(pa0 == 0)
80108411:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
80108415:	75 07                	jne    8010841e <copyout+0x3b>
      return -1;
80108417:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
8010841c:	eb 61                	jmp    8010847f <copyout+0x9c>
    n = PGSIZE - (va - va0);
8010841e:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108421:	2b 45 0c             	sub    0xc(%ebp),%eax
80108424:	05 00 10 00 00       	add    $0x1000,%eax
80108429:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(n > len)
8010842c:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010842f:	3b 45 14             	cmp    0x14(%ebp),%eax
80108432:	76 06                	jbe    8010843a <copyout+0x57>
      n = len;
80108434:	8b 45 14             	mov    0x14(%ebp),%eax
80108437:	89 45 f0             	mov    %eax,-0x10(%ebp)
    memmove(pa0 + (va - va0), buf, n);
8010843a:	8b 45 0c             	mov    0xc(%ebp),%eax
8010843d:	2b 45 ec             	sub    -0x14(%ebp),%eax
80108440:	89 c2                	mov    %eax,%edx
80108442:	8b 45 e8             	mov    -0x18(%ebp),%eax
80108445:	01 d0                	add    %edx,%eax
80108447:	83 ec 04             	sub    $0x4,%esp
8010844a:	ff 75 f0             	pushl  -0x10(%ebp)
8010844d:	ff 75 f4             	pushl  -0xc(%ebp)
80108450:	50                   	push   %eax
80108451:	e8 36 ce ff ff       	call   8010528c <memmove>
80108456:	83 c4 10             	add    $0x10,%esp
    len -= n;
80108459:	8b 45 f0             	mov    -0x10(%ebp),%eax
8010845c:	29 45 14             	sub    %eax,0x14(%ebp)
    buf += n;
8010845f:	8b 45 f0             	mov    -0x10(%ebp),%eax
80108462:	01 45 f4             	add    %eax,-0xc(%ebp)
    va = va0 + PGSIZE;
80108465:	8b 45 ec             	mov    -0x14(%ebp),%eax
80108468:	05 00 10 00 00       	add    $0x1000,%eax
8010846d:	89 45 0c             	mov    %eax,0xc(%ebp)
{
  char *buf, *pa0;
  uint n, va0;

  buf = (char*)p;
  while(len > 0){
80108470:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
80108474:	0f 85 77 ff ff ff    	jne    801083f1 <copyout+0xe>
    memmove(pa0 + (va - va0), buf, n);
    len -= n;
    buf += n;
    va = va0 + PGSIZE;
  }
  return 0;
8010847a:	b8 00 00 00 00       	mov    $0x0,%eax
}
8010847f:	c9                   	leave  
80108480:	c3                   	ret    
