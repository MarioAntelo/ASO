
_big:     formato del fichero elf32-i386


Desensamblado de la sección .text:

00000000 <main>:
#include "user.h"
#include "fcntl.h"

int
main()
{
   0:	8d 4c 24 04          	lea    0x4(%esp),%ecx
   4:	83 e4 f0             	and    $0xfffffff0,%esp
   7:	ff 71 fc             	pushl  -0x4(%ecx)
   a:	55                   	push   %ebp
   b:	89 e5                	mov    %esp,%ebp
   d:	51                   	push   %ecx
   e:	81 ec 24 02 00 00    	sub    $0x224,%esp
  char buf[512];
  int fd, i, sectors;

  fd = open("big.file", O_CREATE | O_WRONLY);
  14:	83 ec 08             	sub    $0x8,%esp
  17:	68 01 02 00 00       	push   $0x201
  1c:	68 2c 09 00 00       	push   $0x92c
  21:	e8 16 04 00 00       	call   43c <open>
  26:	83 c4 10             	add    $0x10,%esp
  29:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(fd < 0){
  2c:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  30:	79 17                	jns    49 <main+0x49>
    printf(2, "big: cannot open big.file for writing\n");
  32:	83 ec 08             	sub    $0x8,%esp
  35:	68 38 09 00 00       	push   $0x938
  3a:	6a 02                	push   $0x2
  3c:	e8 32 05 00 00       	call   573 <printf>
  41:	83 c4 10             	add    $0x10,%esp
    exit();
  44:	e8 b3 03 00 00       	call   3fc <exit>
  }

  sectors = 0;
  49:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  while(1){
    *(int*)buf = sectors;
  50:	8d 85 e4 fd ff ff    	lea    -0x21c(%ebp),%eax
  56:	8b 55 f0             	mov    -0x10(%ebp),%edx
  59:	89 10                	mov    %edx,(%eax)
    int cc = write(fd, buf, sizeof(buf));
  5b:	83 ec 04             	sub    $0x4,%esp
  5e:	68 00 02 00 00       	push   $0x200
  63:	8d 85 e4 fd ff ff    	lea    -0x21c(%ebp),%eax
  69:	50                   	push   %eax
  6a:	ff 75 ec             	pushl  -0x14(%ebp)
  6d:	e8 aa 03 00 00       	call   41c <write>
  72:	83 c4 10             	add    $0x10,%esp
  75:	89 45 e8             	mov    %eax,-0x18(%ebp)
    if(cc <= 0)
  78:	83 7d e8 00          	cmpl   $0x0,-0x18(%ebp)
  7c:	7e 3b                	jle    b9 <main+0xb9>
      break;
    sectors++;
  7e:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
	if (sectors % 100 == 0)
  82:	8b 4d f0             	mov    -0x10(%ebp),%ecx
  85:	ba 1f 85 eb 51       	mov    $0x51eb851f,%edx
  8a:	89 c8                	mov    %ecx,%eax
  8c:	f7 ea                	imul   %edx
  8e:	c1 fa 05             	sar    $0x5,%edx
  91:	89 c8                	mov    %ecx,%eax
  93:	c1 f8 1f             	sar    $0x1f,%eax
  96:	29 c2                	sub    %eax,%edx
  98:	89 d0                	mov    %edx,%eax
  9a:	6b c0 64             	imul   $0x64,%eax,%eax
  9d:	29 c1                	sub    %eax,%ecx
  9f:	89 c8                	mov    %ecx,%eax
  a1:	85 c0                	test   %eax,%eax
  a3:	75 ab                	jne    50 <main+0x50>
		printf(2, ".");
  a5:	83 ec 08             	sub    $0x8,%esp
  a8:	68 5f 09 00 00       	push   $0x95f
  ad:	6a 02                	push   $0x2
  af:	e8 bf 04 00 00       	call   573 <printf>
  b4:	83 c4 10             	add    $0x10,%esp
  }
  b7:	eb 97                	jmp    50 <main+0x50>
  sectors = 0;
  while(1){
    *(int*)buf = sectors;
    int cc = write(fd, buf, sizeof(buf));
    if(cc <= 0)
      break;
  b9:	90                   	nop
    sectors++;
	if (sectors % 100 == 0)
		printf(2, ".");
  }

  printf(1, "\nwrote %d sectors\n", sectors);
  ba:	83 ec 04             	sub    $0x4,%esp
  bd:	ff 75 f0             	pushl  -0x10(%ebp)
  c0:	68 61 09 00 00       	push   $0x961
  c5:	6a 01                	push   $0x1
  c7:	e8 a7 04 00 00       	call   573 <printf>
  cc:	83 c4 10             	add    $0x10,%esp

  close(fd);
  cf:	83 ec 0c             	sub    $0xc,%esp
  d2:	ff 75 ec             	pushl  -0x14(%ebp)
  d5:	e8 4a 03 00 00       	call   424 <close>
  da:	83 c4 10             	add    $0x10,%esp
  fd = open("big.file", O_RDONLY);
  dd:	83 ec 08             	sub    $0x8,%esp
  e0:	6a 00                	push   $0x0
  e2:	68 2c 09 00 00       	push   $0x92c
  e7:	e8 50 03 00 00       	call   43c <open>
  ec:	83 c4 10             	add    $0x10,%esp
  ef:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if(fd < 0){
  f2:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
  f6:	79 17                	jns    10f <main+0x10f>
    printf(2, "big: cannot re-open big.file for reading\n");
  f8:	83 ec 08             	sub    $0x8,%esp
  fb:	68 74 09 00 00       	push   $0x974
 100:	6a 02                	push   $0x2
 102:	e8 6c 04 00 00       	call   573 <printf>
 107:	83 c4 10             	add    $0x10,%esp
    exit();
 10a:	e8 ed 02 00 00       	call   3fc <exit>
  }
  for(i = 0; i < sectors; i++){
 10f:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 116:	eb 6e                	jmp    186 <main+0x186>
    int cc = read(fd, buf, sizeof(buf));
 118:	83 ec 04             	sub    $0x4,%esp
 11b:	68 00 02 00 00       	push   $0x200
 120:	8d 85 e4 fd ff ff    	lea    -0x21c(%ebp),%eax
 126:	50                   	push   %eax
 127:	ff 75 ec             	pushl  -0x14(%ebp)
 12a:	e8 e5 02 00 00       	call   414 <read>
 12f:	83 c4 10             	add    $0x10,%esp
 132:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(cc <= 0){
 135:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
 139:	7f 1a                	jg     155 <main+0x155>
      printf(2, "big: read error at sector %d\n", i);
 13b:	83 ec 04             	sub    $0x4,%esp
 13e:	ff 75 f4             	pushl  -0xc(%ebp)
 141:	68 9e 09 00 00       	push   $0x99e
 146:	6a 02                	push   $0x2
 148:	e8 26 04 00 00       	call   573 <printf>
 14d:	83 c4 10             	add    $0x10,%esp
      exit();
 150:	e8 a7 02 00 00       	call   3fc <exit>
    }
    if(*(int*)buf != i){
 155:	8d 85 e4 fd ff ff    	lea    -0x21c(%ebp),%eax
 15b:	8b 00                	mov    (%eax),%eax
 15d:	3b 45 f4             	cmp    -0xc(%ebp),%eax
 160:	74 20                	je     182 <main+0x182>
      printf(2, "big: read the wrong data (%d) for sector %d\n",
             *(int*)buf, i);
 162:	8d 85 e4 fd ff ff    	lea    -0x21c(%ebp),%eax
    if(cc <= 0){
      printf(2, "big: read error at sector %d\n", i);
      exit();
    }
    if(*(int*)buf != i){
      printf(2, "big: read the wrong data (%d) for sector %d\n",
 168:	8b 00                	mov    (%eax),%eax
 16a:	ff 75 f4             	pushl  -0xc(%ebp)
 16d:	50                   	push   %eax
 16e:	68 bc 09 00 00       	push   $0x9bc
 173:	6a 02                	push   $0x2
 175:	e8 f9 03 00 00       	call   573 <printf>
 17a:	83 c4 10             	add    $0x10,%esp
             *(int*)buf, i);
      exit();
 17d:	e8 7a 02 00 00       	call   3fc <exit>
  fd = open("big.file", O_RDONLY);
  if(fd < 0){
    printf(2, "big: cannot re-open big.file for reading\n");
    exit();
  }
  for(i = 0; i < sectors; i++){
 182:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
 186:	8b 45 f4             	mov    -0xc(%ebp),%eax
 189:	3b 45 f0             	cmp    -0x10(%ebp),%eax
 18c:	7c 8a                	jl     118 <main+0x118>
             *(int*)buf, i);
      exit();
    }
  }

  printf(1, "done; ok\n"); 
 18e:	83 ec 08             	sub    $0x8,%esp
 191:	68 e9 09 00 00       	push   $0x9e9
 196:	6a 01                	push   $0x1
 198:	e8 d6 03 00 00       	call   573 <printf>
 19d:	83 c4 10             	add    $0x10,%esp

  exit();
 1a0:	e8 57 02 00 00       	call   3fc <exit>

000001a5 <stosb>:
               "cc");
}

static inline void
stosb(void *addr, int data, int cnt)
{
 1a5:	55                   	push   %ebp
 1a6:	89 e5                	mov    %esp,%ebp
 1a8:	57                   	push   %edi
 1a9:	53                   	push   %ebx
  asm volatile("cld; rep stosb" :
 1aa:	8b 4d 08             	mov    0x8(%ebp),%ecx
 1ad:	8b 55 10             	mov    0x10(%ebp),%edx
 1b0:	8b 45 0c             	mov    0xc(%ebp),%eax
 1b3:	89 cb                	mov    %ecx,%ebx
 1b5:	89 df                	mov    %ebx,%edi
 1b7:	89 d1                	mov    %edx,%ecx
 1b9:	fc                   	cld    
 1ba:	f3 aa                	rep stos %al,%es:(%edi)
 1bc:	89 ca                	mov    %ecx,%edx
 1be:	89 fb                	mov    %edi,%ebx
 1c0:	89 5d 08             	mov    %ebx,0x8(%ebp)
 1c3:	89 55 10             	mov    %edx,0x10(%ebp)
               "=D" (addr), "=c" (cnt) :
               "0" (addr), "1" (cnt), "a" (data) :
               "memory", "cc");
}
 1c6:	90                   	nop
 1c7:	5b                   	pop    %ebx
 1c8:	5f                   	pop    %edi
 1c9:	5d                   	pop    %ebp
 1ca:	c3                   	ret    

000001cb <strcpy>:
#include "user.h"
#include "x86.h"

char*
strcpy(char *s, char *t)
{
 1cb:	55                   	push   %ebp
 1cc:	89 e5                	mov    %esp,%ebp
 1ce:	83 ec 10             	sub    $0x10,%esp
  char *os;

  os = s;
 1d1:	8b 45 08             	mov    0x8(%ebp),%eax
 1d4:	89 45 fc             	mov    %eax,-0x4(%ebp)
  while((*s++ = *t++) != 0)
 1d7:	90                   	nop
 1d8:	8b 45 08             	mov    0x8(%ebp),%eax
 1db:	8d 50 01             	lea    0x1(%eax),%edx
 1de:	89 55 08             	mov    %edx,0x8(%ebp)
 1e1:	8b 55 0c             	mov    0xc(%ebp),%edx
 1e4:	8d 4a 01             	lea    0x1(%edx),%ecx
 1e7:	89 4d 0c             	mov    %ecx,0xc(%ebp)
 1ea:	0f b6 12             	movzbl (%edx),%edx
 1ed:	88 10                	mov    %dl,(%eax)
 1ef:	0f b6 00             	movzbl (%eax),%eax
 1f2:	84 c0                	test   %al,%al
 1f4:	75 e2                	jne    1d8 <strcpy+0xd>
    ;
  return os;
 1f6:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 1f9:	c9                   	leave  
 1fa:	c3                   	ret    

000001fb <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1fb:	55                   	push   %ebp
 1fc:	89 e5                	mov    %esp,%ebp
  while(*p && *p == *q)
 1fe:	eb 08                	jmp    208 <strcmp+0xd>
    p++, q++;
 200:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 204:	83 45 0c 01          	addl   $0x1,0xc(%ebp)
}

int
strcmp(const char *p, const char *q)
{
  while(*p && *p == *q)
 208:	8b 45 08             	mov    0x8(%ebp),%eax
 20b:	0f b6 00             	movzbl (%eax),%eax
 20e:	84 c0                	test   %al,%al
 210:	74 10                	je     222 <strcmp+0x27>
 212:	8b 45 08             	mov    0x8(%ebp),%eax
 215:	0f b6 10             	movzbl (%eax),%edx
 218:	8b 45 0c             	mov    0xc(%ebp),%eax
 21b:	0f b6 00             	movzbl (%eax),%eax
 21e:	38 c2                	cmp    %al,%dl
 220:	74 de                	je     200 <strcmp+0x5>
    p++, q++;
  return (uchar)*p - (uchar)*q;
 222:	8b 45 08             	mov    0x8(%ebp),%eax
 225:	0f b6 00             	movzbl (%eax),%eax
 228:	0f b6 d0             	movzbl %al,%edx
 22b:	8b 45 0c             	mov    0xc(%ebp),%eax
 22e:	0f b6 00             	movzbl (%eax),%eax
 231:	0f b6 c0             	movzbl %al,%eax
 234:	29 c2                	sub    %eax,%edx
 236:	89 d0                	mov    %edx,%eax
}
 238:	5d                   	pop    %ebp
 239:	c3                   	ret    

0000023a <strlen>:

uint
strlen(char *s)
{
 23a:	55                   	push   %ebp
 23b:	89 e5                	mov    %esp,%ebp
 23d:	83 ec 10             	sub    $0x10,%esp
  int n;

  for(n = 0; s[n]; n++)
 240:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
 247:	eb 04                	jmp    24d <strlen+0x13>
 249:	83 45 fc 01          	addl   $0x1,-0x4(%ebp)
 24d:	8b 55 fc             	mov    -0x4(%ebp),%edx
 250:	8b 45 08             	mov    0x8(%ebp),%eax
 253:	01 d0                	add    %edx,%eax
 255:	0f b6 00             	movzbl (%eax),%eax
 258:	84 c0                	test   %al,%al
 25a:	75 ed                	jne    249 <strlen+0xf>
    ;
  return n;
 25c:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 25f:	c9                   	leave  
 260:	c3                   	ret    

00000261 <memset>:

void*
memset(void *dst, int c, uint n)
{
 261:	55                   	push   %ebp
 262:	89 e5                	mov    %esp,%ebp
  stosb(dst, c, n);
 264:	8b 45 10             	mov    0x10(%ebp),%eax
 267:	50                   	push   %eax
 268:	ff 75 0c             	pushl  0xc(%ebp)
 26b:	ff 75 08             	pushl  0x8(%ebp)
 26e:	e8 32 ff ff ff       	call   1a5 <stosb>
 273:	83 c4 0c             	add    $0xc,%esp
  return dst;
 276:	8b 45 08             	mov    0x8(%ebp),%eax
}
 279:	c9                   	leave  
 27a:	c3                   	ret    

0000027b <strchr>:

char*
strchr(const char *s, char c)
{
 27b:	55                   	push   %ebp
 27c:	89 e5                	mov    %esp,%ebp
 27e:	83 ec 04             	sub    $0x4,%esp
 281:	8b 45 0c             	mov    0xc(%ebp),%eax
 284:	88 45 fc             	mov    %al,-0x4(%ebp)
  for(; *s; s++)
 287:	eb 14                	jmp    29d <strchr+0x22>
    if(*s == c)
 289:	8b 45 08             	mov    0x8(%ebp),%eax
 28c:	0f b6 00             	movzbl (%eax),%eax
 28f:	3a 45 fc             	cmp    -0x4(%ebp),%al
 292:	75 05                	jne    299 <strchr+0x1e>
      return (char*)s;
 294:	8b 45 08             	mov    0x8(%ebp),%eax
 297:	eb 13                	jmp    2ac <strchr+0x31>
}

char*
strchr(const char *s, char c)
{
  for(; *s; s++)
 299:	83 45 08 01          	addl   $0x1,0x8(%ebp)
 29d:	8b 45 08             	mov    0x8(%ebp),%eax
 2a0:	0f b6 00             	movzbl (%eax),%eax
 2a3:	84 c0                	test   %al,%al
 2a5:	75 e2                	jne    289 <strchr+0xe>
    if(*s == c)
      return (char*)s;
  return 0;
 2a7:	b8 00 00 00 00       	mov    $0x0,%eax
}
 2ac:	c9                   	leave  
 2ad:	c3                   	ret    

000002ae <gets>:

char*
gets(char *buf, int max)
{
 2ae:	55                   	push   %ebp
 2af:	89 e5                	mov    %esp,%ebp
 2b1:	83 ec 18             	sub    $0x18,%esp
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2b4:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
 2bb:	eb 42                	jmp    2ff <gets+0x51>
    cc = read(0, &c, 1);
 2bd:	83 ec 04             	sub    $0x4,%esp
 2c0:	6a 01                	push   $0x1
 2c2:	8d 45 ef             	lea    -0x11(%ebp),%eax
 2c5:	50                   	push   %eax
 2c6:	6a 00                	push   $0x0
 2c8:	e8 47 01 00 00       	call   414 <read>
 2cd:	83 c4 10             	add    $0x10,%esp
 2d0:	89 45 f0             	mov    %eax,-0x10(%ebp)
    if(cc < 1)
 2d3:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 2d7:	7e 33                	jle    30c <gets+0x5e>
      break;
    buf[i++] = c;
 2d9:	8b 45 f4             	mov    -0xc(%ebp),%eax
 2dc:	8d 50 01             	lea    0x1(%eax),%edx
 2df:	89 55 f4             	mov    %edx,-0xc(%ebp)
 2e2:	89 c2                	mov    %eax,%edx
 2e4:	8b 45 08             	mov    0x8(%ebp),%eax
 2e7:	01 c2                	add    %eax,%edx
 2e9:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 2ed:	88 02                	mov    %al,(%edx)
    if(c == '\n' || c == '\r')
 2ef:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 2f3:	3c 0a                	cmp    $0xa,%al
 2f5:	74 16                	je     30d <gets+0x5f>
 2f7:	0f b6 45 ef          	movzbl -0x11(%ebp),%eax
 2fb:	3c 0d                	cmp    $0xd,%al
 2fd:	74 0e                	je     30d <gets+0x5f>
gets(char *buf, int max)
{
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2ff:	8b 45 f4             	mov    -0xc(%ebp),%eax
 302:	83 c0 01             	add    $0x1,%eax
 305:	3b 45 0c             	cmp    0xc(%ebp),%eax
 308:	7c b3                	jl     2bd <gets+0xf>
 30a:	eb 01                	jmp    30d <gets+0x5f>
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
 30c:	90                   	nop
    buf[i++] = c;
    if(c == '\n' || c == '\r')
      break;
  }
  buf[i] = '\0';
 30d:	8b 55 f4             	mov    -0xc(%ebp),%edx
 310:	8b 45 08             	mov    0x8(%ebp),%eax
 313:	01 d0                	add    %edx,%eax
 315:	c6 00 00             	movb   $0x0,(%eax)
  return buf;
 318:	8b 45 08             	mov    0x8(%ebp),%eax
}
 31b:	c9                   	leave  
 31c:	c3                   	ret    

0000031d <stat>:

int
stat(char *n, struct stat *st)
{
 31d:	55                   	push   %ebp
 31e:	89 e5                	mov    %esp,%ebp
 320:	83 ec 18             	sub    $0x18,%esp
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 323:	83 ec 08             	sub    $0x8,%esp
 326:	6a 00                	push   $0x0
 328:	ff 75 08             	pushl  0x8(%ebp)
 32b:	e8 0c 01 00 00       	call   43c <open>
 330:	83 c4 10             	add    $0x10,%esp
 333:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(fd < 0)
 336:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 33a:	79 07                	jns    343 <stat+0x26>
    return -1;
 33c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
 341:	eb 25                	jmp    368 <stat+0x4b>
  r = fstat(fd, st);
 343:	83 ec 08             	sub    $0x8,%esp
 346:	ff 75 0c             	pushl  0xc(%ebp)
 349:	ff 75 f4             	pushl  -0xc(%ebp)
 34c:	e8 03 01 00 00       	call   454 <fstat>
 351:	83 c4 10             	add    $0x10,%esp
 354:	89 45 f0             	mov    %eax,-0x10(%ebp)
  close(fd);
 357:	83 ec 0c             	sub    $0xc,%esp
 35a:	ff 75 f4             	pushl  -0xc(%ebp)
 35d:	e8 c2 00 00 00       	call   424 <close>
 362:	83 c4 10             	add    $0x10,%esp
  return r;
 365:	8b 45 f0             	mov    -0x10(%ebp),%eax
}
 368:	c9                   	leave  
 369:	c3                   	ret    

0000036a <atoi>:

int
atoi(const char *s)
{
 36a:	55                   	push   %ebp
 36b:	89 e5                	mov    %esp,%ebp
 36d:	83 ec 10             	sub    $0x10,%esp
  int n;

  n = 0;
 370:	c7 45 fc 00 00 00 00 	movl   $0x0,-0x4(%ebp)
  while('0' <= *s && *s <= '9')
 377:	eb 25                	jmp    39e <atoi+0x34>
    n = n*10 + *s++ - '0';
 379:	8b 55 fc             	mov    -0x4(%ebp),%edx
 37c:	89 d0                	mov    %edx,%eax
 37e:	c1 e0 02             	shl    $0x2,%eax
 381:	01 d0                	add    %edx,%eax
 383:	01 c0                	add    %eax,%eax
 385:	89 c1                	mov    %eax,%ecx
 387:	8b 45 08             	mov    0x8(%ebp),%eax
 38a:	8d 50 01             	lea    0x1(%eax),%edx
 38d:	89 55 08             	mov    %edx,0x8(%ebp)
 390:	0f b6 00             	movzbl (%eax),%eax
 393:	0f be c0             	movsbl %al,%eax
 396:	01 c8                	add    %ecx,%eax
 398:	83 e8 30             	sub    $0x30,%eax
 39b:	89 45 fc             	mov    %eax,-0x4(%ebp)
atoi(const char *s)
{
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 39e:	8b 45 08             	mov    0x8(%ebp),%eax
 3a1:	0f b6 00             	movzbl (%eax),%eax
 3a4:	3c 2f                	cmp    $0x2f,%al
 3a6:	7e 0a                	jle    3b2 <atoi+0x48>
 3a8:	8b 45 08             	mov    0x8(%ebp),%eax
 3ab:	0f b6 00             	movzbl (%eax),%eax
 3ae:	3c 39                	cmp    $0x39,%al
 3b0:	7e c7                	jle    379 <atoi+0xf>
    n = n*10 + *s++ - '0';
  return n;
 3b2:	8b 45 fc             	mov    -0x4(%ebp),%eax
}
 3b5:	c9                   	leave  
 3b6:	c3                   	ret    

000003b7 <memmove>:

void*
memmove(void *vdst, void *vsrc, int n)
{
 3b7:	55                   	push   %ebp
 3b8:	89 e5                	mov    %esp,%ebp
 3ba:	83 ec 10             	sub    $0x10,%esp
  char *dst, *src;

  dst = vdst;
 3bd:	8b 45 08             	mov    0x8(%ebp),%eax
 3c0:	89 45 fc             	mov    %eax,-0x4(%ebp)
  src = vsrc;
 3c3:	8b 45 0c             	mov    0xc(%ebp),%eax
 3c6:	89 45 f8             	mov    %eax,-0x8(%ebp)
  while(n-- > 0)
 3c9:	eb 17                	jmp    3e2 <memmove+0x2b>
    *dst++ = *src++;
 3cb:	8b 45 fc             	mov    -0x4(%ebp),%eax
 3ce:	8d 50 01             	lea    0x1(%eax),%edx
 3d1:	89 55 fc             	mov    %edx,-0x4(%ebp)
 3d4:	8b 55 f8             	mov    -0x8(%ebp),%edx
 3d7:	8d 4a 01             	lea    0x1(%edx),%ecx
 3da:	89 4d f8             	mov    %ecx,-0x8(%ebp)
 3dd:	0f b6 12             	movzbl (%edx),%edx
 3e0:	88 10                	mov    %dl,(%eax)
{
  char *dst, *src;

  dst = vdst;
  src = vsrc;
  while(n-- > 0)
 3e2:	8b 45 10             	mov    0x10(%ebp),%eax
 3e5:	8d 50 ff             	lea    -0x1(%eax),%edx
 3e8:	89 55 10             	mov    %edx,0x10(%ebp)
 3eb:	85 c0                	test   %eax,%eax
 3ed:	7f dc                	jg     3cb <memmove+0x14>
    *dst++ = *src++;
  return vdst;
 3ef:	8b 45 08             	mov    0x8(%ebp),%eax
}
 3f2:	c9                   	leave  
 3f3:	c3                   	ret    

000003f4 <fork>:
  name: \
    movl $SYS_ ## name, %eax; \
    int $T_SYSCALL; \
    ret

SYSCALL(fork)
 3f4:	b8 01 00 00 00       	mov    $0x1,%eax
 3f9:	cd 40                	int    $0x40
 3fb:	c3                   	ret    

000003fc <exit>:
SYSCALL(exit)
 3fc:	b8 02 00 00 00       	mov    $0x2,%eax
 401:	cd 40                	int    $0x40
 403:	c3                   	ret    

00000404 <wait>:
SYSCALL(wait)
 404:	b8 03 00 00 00       	mov    $0x3,%eax
 409:	cd 40                	int    $0x40
 40b:	c3                   	ret    

0000040c <pipe>:
SYSCALL(pipe)
 40c:	b8 04 00 00 00       	mov    $0x4,%eax
 411:	cd 40                	int    $0x40
 413:	c3                   	ret    

00000414 <read>:
SYSCALL(read)
 414:	b8 05 00 00 00       	mov    $0x5,%eax
 419:	cd 40                	int    $0x40
 41b:	c3                   	ret    

0000041c <write>:
SYSCALL(write)
 41c:	b8 10 00 00 00       	mov    $0x10,%eax
 421:	cd 40                	int    $0x40
 423:	c3                   	ret    

00000424 <close>:
SYSCALL(close)
 424:	b8 15 00 00 00       	mov    $0x15,%eax
 429:	cd 40                	int    $0x40
 42b:	c3                   	ret    

0000042c <kill>:
SYSCALL(kill)
 42c:	b8 06 00 00 00       	mov    $0x6,%eax
 431:	cd 40                	int    $0x40
 433:	c3                   	ret    

00000434 <exec>:
SYSCALL(exec)
 434:	b8 07 00 00 00       	mov    $0x7,%eax
 439:	cd 40                	int    $0x40
 43b:	c3                   	ret    

0000043c <open>:
SYSCALL(open)
 43c:	b8 0f 00 00 00       	mov    $0xf,%eax
 441:	cd 40                	int    $0x40
 443:	c3                   	ret    

00000444 <mknod>:
SYSCALL(mknod)
 444:	b8 11 00 00 00       	mov    $0x11,%eax
 449:	cd 40                	int    $0x40
 44b:	c3                   	ret    

0000044c <unlink>:
SYSCALL(unlink)
 44c:	b8 12 00 00 00       	mov    $0x12,%eax
 451:	cd 40                	int    $0x40
 453:	c3                   	ret    

00000454 <fstat>:
SYSCALL(fstat)
 454:	b8 08 00 00 00       	mov    $0x8,%eax
 459:	cd 40                	int    $0x40
 45b:	c3                   	ret    

0000045c <link>:
SYSCALL(link)
 45c:	b8 13 00 00 00       	mov    $0x13,%eax
 461:	cd 40                	int    $0x40
 463:	c3                   	ret    

00000464 <mkdir>:
SYSCALL(mkdir)
 464:	b8 14 00 00 00       	mov    $0x14,%eax
 469:	cd 40                	int    $0x40
 46b:	c3                   	ret    

0000046c <chdir>:
SYSCALL(chdir)
 46c:	b8 09 00 00 00       	mov    $0x9,%eax
 471:	cd 40                	int    $0x40
 473:	c3                   	ret    

00000474 <dup>:
SYSCALL(dup)
 474:	b8 0a 00 00 00       	mov    $0xa,%eax
 479:	cd 40                	int    $0x40
 47b:	c3                   	ret    

0000047c <getpid>:
SYSCALL(getpid)
 47c:	b8 0b 00 00 00       	mov    $0xb,%eax
 481:	cd 40                	int    $0x40
 483:	c3                   	ret    

00000484 <sbrk>:
SYSCALL(sbrk)
 484:	b8 0c 00 00 00       	mov    $0xc,%eax
 489:	cd 40                	int    $0x40
 48b:	c3                   	ret    

0000048c <sleep>:
SYSCALL(sleep)
 48c:	b8 0d 00 00 00       	mov    $0xd,%eax
 491:	cd 40                	int    $0x40
 493:	c3                   	ret    

00000494 <uptime>:
SYSCALL(uptime)
 494:	b8 0e 00 00 00       	mov    $0xe,%eax
 499:	cd 40                	int    $0x40
 49b:	c3                   	ret    

0000049c <putc>:
#include "stat.h"
#include "user.h"

static void
putc(int fd, char c)
{
 49c:	55                   	push   %ebp
 49d:	89 e5                	mov    %esp,%ebp
 49f:	83 ec 18             	sub    $0x18,%esp
 4a2:	8b 45 0c             	mov    0xc(%ebp),%eax
 4a5:	88 45 f4             	mov    %al,-0xc(%ebp)
  write(fd, &c, 1);
 4a8:	83 ec 04             	sub    $0x4,%esp
 4ab:	6a 01                	push   $0x1
 4ad:	8d 45 f4             	lea    -0xc(%ebp),%eax
 4b0:	50                   	push   %eax
 4b1:	ff 75 08             	pushl  0x8(%ebp)
 4b4:	e8 63 ff ff ff       	call   41c <write>
 4b9:	83 c4 10             	add    $0x10,%esp
}
 4bc:	90                   	nop
 4bd:	c9                   	leave  
 4be:	c3                   	ret    

000004bf <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4bf:	55                   	push   %ebp
 4c0:	89 e5                	mov    %esp,%ebp
 4c2:	53                   	push   %ebx
 4c3:	83 ec 24             	sub    $0x24,%esp
  static char digits[] = "0123456789ABCDEF";
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
 4c6:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
  if(sgn && xx < 0){
 4cd:	83 7d 14 00          	cmpl   $0x0,0x14(%ebp)
 4d1:	74 17                	je     4ea <printint+0x2b>
 4d3:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
 4d7:	79 11                	jns    4ea <printint+0x2b>
    neg = 1;
 4d9:	c7 45 f0 01 00 00 00 	movl   $0x1,-0x10(%ebp)
    x = -xx;
 4e0:	8b 45 0c             	mov    0xc(%ebp),%eax
 4e3:	f7 d8                	neg    %eax
 4e5:	89 45 ec             	mov    %eax,-0x14(%ebp)
 4e8:	eb 06                	jmp    4f0 <printint+0x31>
  } else {
    x = xx;
 4ea:	8b 45 0c             	mov    0xc(%ebp),%eax
 4ed:	89 45 ec             	mov    %eax,-0x14(%ebp)
  }

  i = 0;
 4f0:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)
  do{
    buf[i++] = digits[x % base];
 4f7:	8b 4d f4             	mov    -0xc(%ebp),%ecx
 4fa:	8d 41 01             	lea    0x1(%ecx),%eax
 4fd:	89 45 f4             	mov    %eax,-0xc(%ebp)
 500:	8b 5d 10             	mov    0x10(%ebp),%ebx
 503:	8b 45 ec             	mov    -0x14(%ebp),%eax
 506:	ba 00 00 00 00       	mov    $0x0,%edx
 50b:	f7 f3                	div    %ebx
 50d:	89 d0                	mov    %edx,%eax
 50f:	0f b6 80 44 0c 00 00 	movzbl 0xc44(%eax),%eax
 516:	88 44 0d dc          	mov    %al,-0x24(%ebp,%ecx,1)
  }while((x /= base) != 0);
 51a:	8b 5d 10             	mov    0x10(%ebp),%ebx
 51d:	8b 45 ec             	mov    -0x14(%ebp),%eax
 520:	ba 00 00 00 00       	mov    $0x0,%edx
 525:	f7 f3                	div    %ebx
 527:	89 45 ec             	mov    %eax,-0x14(%ebp)
 52a:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 52e:	75 c7                	jne    4f7 <printint+0x38>
  if(neg)
 530:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 534:	74 2d                	je     563 <printint+0xa4>
    buf[i++] = '-';
 536:	8b 45 f4             	mov    -0xc(%ebp),%eax
 539:	8d 50 01             	lea    0x1(%eax),%edx
 53c:	89 55 f4             	mov    %edx,-0xc(%ebp)
 53f:	c6 44 05 dc 2d       	movb   $0x2d,-0x24(%ebp,%eax,1)

  while(--i >= 0)
 544:	eb 1d                	jmp    563 <printint+0xa4>
    putc(fd, buf[i]);
 546:	8d 55 dc             	lea    -0x24(%ebp),%edx
 549:	8b 45 f4             	mov    -0xc(%ebp),%eax
 54c:	01 d0                	add    %edx,%eax
 54e:	0f b6 00             	movzbl (%eax),%eax
 551:	0f be c0             	movsbl %al,%eax
 554:	83 ec 08             	sub    $0x8,%esp
 557:	50                   	push   %eax
 558:	ff 75 08             	pushl  0x8(%ebp)
 55b:	e8 3c ff ff ff       	call   49c <putc>
 560:	83 c4 10             	add    $0x10,%esp
    buf[i++] = digits[x % base];
  }while((x /= base) != 0);
  if(neg)
    buf[i++] = '-';

  while(--i >= 0)
 563:	83 6d f4 01          	subl   $0x1,-0xc(%ebp)
 567:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 56b:	79 d9                	jns    546 <printint+0x87>
    putc(fd, buf[i]);
}
 56d:	90                   	nop
 56e:	8b 5d fc             	mov    -0x4(%ebp),%ebx
 571:	c9                   	leave  
 572:	c3                   	ret    

00000573 <printf>:

// Print to the given fd. Only understands %d, %x, %p, %s.
void
printf(int fd, char *fmt, ...)
{
 573:	55                   	push   %ebp
 574:	89 e5                	mov    %esp,%ebp
 576:	83 ec 28             	sub    $0x28,%esp
  char *s;
  int c, i, state;
  uint *ap;

  state = 0;
 579:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  ap = (uint*)(void*)&fmt + 1;
 580:	8d 45 0c             	lea    0xc(%ebp),%eax
 583:	83 c0 04             	add    $0x4,%eax
 586:	89 45 e8             	mov    %eax,-0x18(%ebp)
  for(i = 0; fmt[i]; i++){
 589:	c7 45 f0 00 00 00 00 	movl   $0x0,-0x10(%ebp)
 590:	e9 59 01 00 00       	jmp    6ee <printf+0x17b>
    c = fmt[i] & 0xff;
 595:	8b 55 0c             	mov    0xc(%ebp),%edx
 598:	8b 45 f0             	mov    -0x10(%ebp),%eax
 59b:	01 d0                	add    %edx,%eax
 59d:	0f b6 00             	movzbl (%eax),%eax
 5a0:	0f be c0             	movsbl %al,%eax
 5a3:	25 ff 00 00 00       	and    $0xff,%eax
 5a8:	89 45 e4             	mov    %eax,-0x1c(%ebp)
    if(state == 0){
 5ab:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
 5af:	75 2c                	jne    5dd <printf+0x6a>
      if(c == '%'){
 5b1:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 5b5:	75 0c                	jne    5c3 <printf+0x50>
        state = '%';
 5b7:	c7 45 ec 25 00 00 00 	movl   $0x25,-0x14(%ebp)
 5be:	e9 27 01 00 00       	jmp    6ea <printf+0x177>
      } else {
        putc(fd, c);
 5c3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 5c6:	0f be c0             	movsbl %al,%eax
 5c9:	83 ec 08             	sub    $0x8,%esp
 5cc:	50                   	push   %eax
 5cd:	ff 75 08             	pushl  0x8(%ebp)
 5d0:	e8 c7 fe ff ff       	call   49c <putc>
 5d5:	83 c4 10             	add    $0x10,%esp
 5d8:	e9 0d 01 00 00       	jmp    6ea <printf+0x177>
      }
    } else if(state == '%'){
 5dd:	83 7d ec 25          	cmpl   $0x25,-0x14(%ebp)
 5e1:	0f 85 03 01 00 00    	jne    6ea <printf+0x177>
      if(c == 'd'){
 5e7:	83 7d e4 64          	cmpl   $0x64,-0x1c(%ebp)
 5eb:	75 1e                	jne    60b <printf+0x98>
        printint(fd, *ap, 10, 1);
 5ed:	8b 45 e8             	mov    -0x18(%ebp),%eax
 5f0:	8b 00                	mov    (%eax),%eax
 5f2:	6a 01                	push   $0x1
 5f4:	6a 0a                	push   $0xa
 5f6:	50                   	push   %eax
 5f7:	ff 75 08             	pushl  0x8(%ebp)
 5fa:	e8 c0 fe ff ff       	call   4bf <printint>
 5ff:	83 c4 10             	add    $0x10,%esp
        ap++;
 602:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 606:	e9 d8 00 00 00       	jmp    6e3 <printf+0x170>
      } else if(c == 'x' || c == 'p'){
 60b:	83 7d e4 78          	cmpl   $0x78,-0x1c(%ebp)
 60f:	74 06                	je     617 <printf+0xa4>
 611:	83 7d e4 70          	cmpl   $0x70,-0x1c(%ebp)
 615:	75 1e                	jne    635 <printf+0xc2>
        printint(fd, *ap, 16, 0);
 617:	8b 45 e8             	mov    -0x18(%ebp),%eax
 61a:	8b 00                	mov    (%eax),%eax
 61c:	6a 00                	push   $0x0
 61e:	6a 10                	push   $0x10
 620:	50                   	push   %eax
 621:	ff 75 08             	pushl  0x8(%ebp)
 624:	e8 96 fe ff ff       	call   4bf <printint>
 629:	83 c4 10             	add    $0x10,%esp
        ap++;
 62c:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 630:	e9 ae 00 00 00       	jmp    6e3 <printf+0x170>
      } else if(c == 's'){
 635:	83 7d e4 73          	cmpl   $0x73,-0x1c(%ebp)
 639:	75 43                	jne    67e <printf+0x10b>
        s = (char*)*ap;
 63b:	8b 45 e8             	mov    -0x18(%ebp),%eax
 63e:	8b 00                	mov    (%eax),%eax
 640:	89 45 f4             	mov    %eax,-0xc(%ebp)
        ap++;
 643:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
        if(s == 0)
 647:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 64b:	75 25                	jne    672 <printf+0xff>
          s = "(null)";
 64d:	c7 45 f4 f3 09 00 00 	movl   $0x9f3,-0xc(%ebp)
        while(*s != 0){
 654:	eb 1c                	jmp    672 <printf+0xff>
          putc(fd, *s);
 656:	8b 45 f4             	mov    -0xc(%ebp),%eax
 659:	0f b6 00             	movzbl (%eax),%eax
 65c:	0f be c0             	movsbl %al,%eax
 65f:	83 ec 08             	sub    $0x8,%esp
 662:	50                   	push   %eax
 663:	ff 75 08             	pushl  0x8(%ebp)
 666:	e8 31 fe ff ff       	call   49c <putc>
 66b:	83 c4 10             	add    $0x10,%esp
          s++;
 66e:	83 45 f4 01          	addl   $0x1,-0xc(%ebp)
      } else if(c == 's'){
        s = (char*)*ap;
        ap++;
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 672:	8b 45 f4             	mov    -0xc(%ebp),%eax
 675:	0f b6 00             	movzbl (%eax),%eax
 678:	84 c0                	test   %al,%al
 67a:	75 da                	jne    656 <printf+0xe3>
 67c:	eb 65                	jmp    6e3 <printf+0x170>
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 67e:	83 7d e4 63          	cmpl   $0x63,-0x1c(%ebp)
 682:	75 1d                	jne    6a1 <printf+0x12e>
        putc(fd, *ap);
 684:	8b 45 e8             	mov    -0x18(%ebp),%eax
 687:	8b 00                	mov    (%eax),%eax
 689:	0f be c0             	movsbl %al,%eax
 68c:	83 ec 08             	sub    $0x8,%esp
 68f:	50                   	push   %eax
 690:	ff 75 08             	pushl  0x8(%ebp)
 693:	e8 04 fe ff ff       	call   49c <putc>
 698:	83 c4 10             	add    $0x10,%esp
        ap++;
 69b:	83 45 e8 04          	addl   $0x4,-0x18(%ebp)
 69f:	eb 42                	jmp    6e3 <printf+0x170>
      } else if(c == '%'){
 6a1:	83 7d e4 25          	cmpl   $0x25,-0x1c(%ebp)
 6a5:	75 17                	jne    6be <printf+0x14b>
        putc(fd, c);
 6a7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 6aa:	0f be c0             	movsbl %al,%eax
 6ad:	83 ec 08             	sub    $0x8,%esp
 6b0:	50                   	push   %eax
 6b1:	ff 75 08             	pushl  0x8(%ebp)
 6b4:	e8 e3 fd ff ff       	call   49c <putc>
 6b9:	83 c4 10             	add    $0x10,%esp
 6bc:	eb 25                	jmp    6e3 <printf+0x170>
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6be:	83 ec 08             	sub    $0x8,%esp
 6c1:	6a 25                	push   $0x25
 6c3:	ff 75 08             	pushl  0x8(%ebp)
 6c6:	e8 d1 fd ff ff       	call   49c <putc>
 6cb:	83 c4 10             	add    $0x10,%esp
        putc(fd, c);
 6ce:	8b 45 e4             	mov    -0x1c(%ebp),%eax
 6d1:	0f be c0             	movsbl %al,%eax
 6d4:	83 ec 08             	sub    $0x8,%esp
 6d7:	50                   	push   %eax
 6d8:	ff 75 08             	pushl  0x8(%ebp)
 6db:	e8 bc fd ff ff       	call   49c <putc>
 6e0:	83 c4 10             	add    $0x10,%esp
      }
      state = 0;
 6e3:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)
  int c, i, state;
  uint *ap;

  state = 0;
  ap = (uint*)(void*)&fmt + 1;
  for(i = 0; fmt[i]; i++){
 6ea:	83 45 f0 01          	addl   $0x1,-0x10(%ebp)
 6ee:	8b 55 0c             	mov    0xc(%ebp),%edx
 6f1:	8b 45 f0             	mov    -0x10(%ebp),%eax
 6f4:	01 d0                	add    %edx,%eax
 6f6:	0f b6 00             	movzbl (%eax),%eax
 6f9:	84 c0                	test   %al,%al
 6fb:	0f 85 94 fe ff ff    	jne    595 <printf+0x22>
        putc(fd, c);
      }
      state = 0;
    }
  }
}
 701:	90                   	nop
 702:	c9                   	leave  
 703:	c3                   	ret    

00000704 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 704:	55                   	push   %ebp
 705:	89 e5                	mov    %esp,%ebp
 707:	83 ec 10             	sub    $0x10,%esp
  Header *bp, *p;

  bp = (Header*)ap - 1;
 70a:	8b 45 08             	mov    0x8(%ebp),%eax
 70d:	83 e8 08             	sub    $0x8,%eax
 710:	89 45 f8             	mov    %eax,-0x8(%ebp)
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 713:	a1 60 0c 00 00       	mov    0xc60,%eax
 718:	89 45 fc             	mov    %eax,-0x4(%ebp)
 71b:	eb 24                	jmp    741 <free+0x3d>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 71d:	8b 45 fc             	mov    -0x4(%ebp),%eax
 720:	8b 00                	mov    (%eax),%eax
 722:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 725:	77 12                	ja     739 <free+0x35>
 727:	8b 45 f8             	mov    -0x8(%ebp),%eax
 72a:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 72d:	77 24                	ja     753 <free+0x4f>
 72f:	8b 45 fc             	mov    -0x4(%ebp),%eax
 732:	8b 00                	mov    (%eax),%eax
 734:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 737:	77 1a                	ja     753 <free+0x4f>
free(void *ap)
{
  Header *bp, *p;

  bp = (Header*)ap - 1;
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 739:	8b 45 fc             	mov    -0x4(%ebp),%eax
 73c:	8b 00                	mov    (%eax),%eax
 73e:	89 45 fc             	mov    %eax,-0x4(%ebp)
 741:	8b 45 f8             	mov    -0x8(%ebp),%eax
 744:	3b 45 fc             	cmp    -0x4(%ebp),%eax
 747:	76 d4                	jbe    71d <free+0x19>
 749:	8b 45 fc             	mov    -0x4(%ebp),%eax
 74c:	8b 00                	mov    (%eax),%eax
 74e:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 751:	76 ca                	jbe    71d <free+0x19>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
 753:	8b 45 f8             	mov    -0x8(%ebp),%eax
 756:	8b 40 04             	mov    0x4(%eax),%eax
 759:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 760:	8b 45 f8             	mov    -0x8(%ebp),%eax
 763:	01 c2                	add    %eax,%edx
 765:	8b 45 fc             	mov    -0x4(%ebp),%eax
 768:	8b 00                	mov    (%eax),%eax
 76a:	39 c2                	cmp    %eax,%edx
 76c:	75 24                	jne    792 <free+0x8e>
    bp->s.size += p->s.ptr->s.size;
 76e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 771:	8b 50 04             	mov    0x4(%eax),%edx
 774:	8b 45 fc             	mov    -0x4(%ebp),%eax
 777:	8b 00                	mov    (%eax),%eax
 779:	8b 40 04             	mov    0x4(%eax),%eax
 77c:	01 c2                	add    %eax,%edx
 77e:	8b 45 f8             	mov    -0x8(%ebp),%eax
 781:	89 50 04             	mov    %edx,0x4(%eax)
    bp->s.ptr = p->s.ptr->s.ptr;
 784:	8b 45 fc             	mov    -0x4(%ebp),%eax
 787:	8b 00                	mov    (%eax),%eax
 789:	8b 10                	mov    (%eax),%edx
 78b:	8b 45 f8             	mov    -0x8(%ebp),%eax
 78e:	89 10                	mov    %edx,(%eax)
 790:	eb 0a                	jmp    79c <free+0x98>
  } else
    bp->s.ptr = p->s.ptr;
 792:	8b 45 fc             	mov    -0x4(%ebp),%eax
 795:	8b 10                	mov    (%eax),%edx
 797:	8b 45 f8             	mov    -0x8(%ebp),%eax
 79a:	89 10                	mov    %edx,(%eax)
  if(p + p->s.size == bp){
 79c:	8b 45 fc             	mov    -0x4(%ebp),%eax
 79f:	8b 40 04             	mov    0x4(%eax),%eax
 7a2:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
 7a9:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7ac:	01 d0                	add    %edx,%eax
 7ae:	3b 45 f8             	cmp    -0x8(%ebp),%eax
 7b1:	75 20                	jne    7d3 <free+0xcf>
    p->s.size += bp->s.size;
 7b3:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7b6:	8b 50 04             	mov    0x4(%eax),%edx
 7b9:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7bc:	8b 40 04             	mov    0x4(%eax),%eax
 7bf:	01 c2                	add    %eax,%edx
 7c1:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7c4:	89 50 04             	mov    %edx,0x4(%eax)
    p->s.ptr = bp->s.ptr;
 7c7:	8b 45 f8             	mov    -0x8(%ebp),%eax
 7ca:	8b 10                	mov    (%eax),%edx
 7cc:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7cf:	89 10                	mov    %edx,(%eax)
 7d1:	eb 08                	jmp    7db <free+0xd7>
  } else
    p->s.ptr = bp;
 7d3:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7d6:	8b 55 f8             	mov    -0x8(%ebp),%edx
 7d9:	89 10                	mov    %edx,(%eax)
  freep = p;
 7db:	8b 45 fc             	mov    -0x4(%ebp),%eax
 7de:	a3 60 0c 00 00       	mov    %eax,0xc60
}
 7e3:	90                   	nop
 7e4:	c9                   	leave  
 7e5:	c3                   	ret    

000007e6 <morecore>:

static Header*
morecore(uint nu)
{
 7e6:	55                   	push   %ebp
 7e7:	89 e5                	mov    %esp,%ebp
 7e9:	83 ec 18             	sub    $0x18,%esp
  char *p;
  Header *hp;

  if(nu < 4096)
 7ec:	81 7d 08 ff 0f 00 00 	cmpl   $0xfff,0x8(%ebp)
 7f3:	77 07                	ja     7fc <morecore+0x16>
    nu = 4096;
 7f5:	c7 45 08 00 10 00 00 	movl   $0x1000,0x8(%ebp)
  p = sbrk(nu * sizeof(Header));
 7fc:	8b 45 08             	mov    0x8(%ebp),%eax
 7ff:	c1 e0 03             	shl    $0x3,%eax
 802:	83 ec 0c             	sub    $0xc,%esp
 805:	50                   	push   %eax
 806:	e8 79 fc ff ff       	call   484 <sbrk>
 80b:	83 c4 10             	add    $0x10,%esp
 80e:	89 45 f4             	mov    %eax,-0xc(%ebp)
  if(p == (char*)-1)
 811:	83 7d f4 ff          	cmpl   $0xffffffff,-0xc(%ebp)
 815:	75 07                	jne    81e <morecore+0x38>
    return 0;
 817:	b8 00 00 00 00       	mov    $0x0,%eax
 81c:	eb 26                	jmp    844 <morecore+0x5e>
  hp = (Header*)p;
 81e:	8b 45 f4             	mov    -0xc(%ebp),%eax
 821:	89 45 f0             	mov    %eax,-0x10(%ebp)
  hp->s.size = nu;
 824:	8b 45 f0             	mov    -0x10(%ebp),%eax
 827:	8b 55 08             	mov    0x8(%ebp),%edx
 82a:	89 50 04             	mov    %edx,0x4(%eax)
  free((void*)(hp + 1));
 82d:	8b 45 f0             	mov    -0x10(%ebp),%eax
 830:	83 c0 08             	add    $0x8,%eax
 833:	83 ec 0c             	sub    $0xc,%esp
 836:	50                   	push   %eax
 837:	e8 c8 fe ff ff       	call   704 <free>
 83c:	83 c4 10             	add    $0x10,%esp
  return freep;
 83f:	a1 60 0c 00 00       	mov    0xc60,%eax
}
 844:	c9                   	leave  
 845:	c3                   	ret    

00000846 <malloc>:

void*
malloc(uint nbytes)
{
 846:	55                   	push   %ebp
 847:	89 e5                	mov    %esp,%ebp
 849:	83 ec 18             	sub    $0x18,%esp
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 84c:	8b 45 08             	mov    0x8(%ebp),%eax
 84f:	83 c0 07             	add    $0x7,%eax
 852:	c1 e8 03             	shr    $0x3,%eax
 855:	83 c0 01             	add    $0x1,%eax
 858:	89 45 ec             	mov    %eax,-0x14(%ebp)
  if((prevp = freep) == 0){
 85b:	a1 60 0c 00 00       	mov    0xc60,%eax
 860:	89 45 f0             	mov    %eax,-0x10(%ebp)
 863:	83 7d f0 00          	cmpl   $0x0,-0x10(%ebp)
 867:	75 23                	jne    88c <malloc+0x46>
    base.s.ptr = freep = prevp = &base;
 869:	c7 45 f0 58 0c 00 00 	movl   $0xc58,-0x10(%ebp)
 870:	8b 45 f0             	mov    -0x10(%ebp),%eax
 873:	a3 60 0c 00 00       	mov    %eax,0xc60
 878:	a1 60 0c 00 00       	mov    0xc60,%eax
 87d:	a3 58 0c 00 00       	mov    %eax,0xc58
    base.s.size = 0;
 882:	c7 05 5c 0c 00 00 00 	movl   $0x0,0xc5c
 889:	00 00 00 
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 88c:	8b 45 f0             	mov    -0x10(%ebp),%eax
 88f:	8b 00                	mov    (%eax),%eax
 891:	89 45 f4             	mov    %eax,-0xc(%ebp)
    if(p->s.size >= nunits){
 894:	8b 45 f4             	mov    -0xc(%ebp),%eax
 897:	8b 40 04             	mov    0x4(%eax),%eax
 89a:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 89d:	72 4d                	jb     8ec <malloc+0xa6>
      if(p->s.size == nunits)
 89f:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8a2:	8b 40 04             	mov    0x4(%eax),%eax
 8a5:	3b 45 ec             	cmp    -0x14(%ebp),%eax
 8a8:	75 0c                	jne    8b6 <malloc+0x70>
        prevp->s.ptr = p->s.ptr;
 8aa:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8ad:	8b 10                	mov    (%eax),%edx
 8af:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8b2:	89 10                	mov    %edx,(%eax)
 8b4:	eb 26                	jmp    8dc <malloc+0x96>
      else {
        p->s.size -= nunits;
 8b6:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8b9:	8b 40 04             	mov    0x4(%eax),%eax
 8bc:	2b 45 ec             	sub    -0x14(%ebp),%eax
 8bf:	89 c2                	mov    %eax,%edx
 8c1:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8c4:	89 50 04             	mov    %edx,0x4(%eax)
        p += p->s.size;
 8c7:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8ca:	8b 40 04             	mov    0x4(%eax),%eax
 8cd:	c1 e0 03             	shl    $0x3,%eax
 8d0:	01 45 f4             	add    %eax,-0xc(%ebp)
        p->s.size = nunits;
 8d3:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8d6:	8b 55 ec             	mov    -0x14(%ebp),%edx
 8d9:	89 50 04             	mov    %edx,0x4(%eax)
      }
      freep = prevp;
 8dc:	8b 45 f0             	mov    -0x10(%ebp),%eax
 8df:	a3 60 0c 00 00       	mov    %eax,0xc60
      return (void*)(p + 1);
 8e4:	8b 45 f4             	mov    -0xc(%ebp),%eax
 8e7:	83 c0 08             	add    $0x8,%eax
 8ea:	eb 3b                	jmp    927 <malloc+0xe1>
    }
    if(p == freep)
 8ec:	a1 60 0c 00 00       	mov    0xc60,%eax
 8f1:	39 45 f4             	cmp    %eax,-0xc(%ebp)
 8f4:	75 1e                	jne    914 <malloc+0xce>
      if((p = morecore(nunits)) == 0)
 8f6:	83 ec 0c             	sub    $0xc,%esp
 8f9:	ff 75 ec             	pushl  -0x14(%ebp)
 8fc:	e8 e5 fe ff ff       	call   7e6 <morecore>
 901:	83 c4 10             	add    $0x10,%esp
 904:	89 45 f4             	mov    %eax,-0xc(%ebp)
 907:	83 7d f4 00          	cmpl   $0x0,-0xc(%ebp)
 90b:	75 07                	jne    914 <malloc+0xce>
        return 0;
 90d:	b8 00 00 00 00       	mov    $0x0,%eax
 912:	eb 13                	jmp    927 <malloc+0xe1>
  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
  if((prevp = freep) == 0){
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 914:	8b 45 f4             	mov    -0xc(%ebp),%eax
 917:	89 45 f0             	mov    %eax,-0x10(%ebp)
 91a:	8b 45 f4             	mov    -0xc(%ebp),%eax
 91d:	8b 00                	mov    (%eax),%eax
 91f:	89 45 f4             	mov    %eax,-0xc(%ebp)
      return (void*)(p + 1);
    }
    if(p == freep)
      if((p = morecore(nunits)) == 0)
        return 0;
  }
 922:	e9 6d ff ff ff       	jmp    894 <malloc+0x4e>
}
 927:	c9                   	leave  
 928:	c3                   	ret    
