#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t len = 0;
  while (s[len]!='\0')
    len++;
  return len;
}

char *strcpy(char *dst, const char *src) {
  if(dst==NULL || src==NULL) return NULL;
  // char* p = dst;
  // while((*p=*src)!='\0')
  // {
  //   p++;src++;
  // }
  size_t i;
  for(i=0;src[i]!='\0';i++)
    dst[i]=src[i];
  dst[i]='\0';
  return dst;
}

char *strncpy(char *dst, const char *src, size_t n) {
  size_t i;
  for (i = 0; i < n && src[i] != '\0'; i++)
    dst[i] = src[i];
  for ( ; i < n; i++)
    dst[i] = '\0';
  return dst;
}

char *strcat(char *dst, const char *src) {
  size_t len = strlen(dst);
  size_t i = 0;
  for(i=0;src[i]!='\0';i++)
  {
    dst[len+i]=src[i];
  }
  dst[len+strlen(src)]='\0';
  return dst;
}

int strcmp(const char *s1, const char *s2) {
  while(*s1 && *s2 && (*s1==*s2))
  {
    s1++;
    s2++;
  }
  return *(unsigned char*)s1 - *(unsigned char*)s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  while(n-- && *s1 && *s2 && (*s1==*s2))
  {
    s1++;
    s2++;
  }
  return n==(size_t)-1?0:*(unsigned char*)s1 - *(unsigned char*)s2;
}

void *memset(void *s, int c, size_t n) {
  unsigned char* p = (unsigned char*)s;
  size_t i;
  for(i=0;i<n;i++)
    p[i]=c;
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  char* p1 = (char*)dst;
  const char* p2 = (const char*) src;
  if(p1<p2) //normal order
  {
    while(n--) *p1++ = *p2++;
  }
  else
  {
    while(n--) p1[n]=p2[n];
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  char* p = (char*) out;
  const char* s = (const char*) in;
  while(n--)
  {
    *p++ =*s++;
  }
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const unsigned char* p1 = (const unsigned char*) s1;
  const unsigned char* p2 = (const unsigned char*) s2;
  while(n--)
  {
    if(*p1!=*p2) return *p1-*p2;
    p1++;
    p2++;
  }
  return 0;
}

#endif
