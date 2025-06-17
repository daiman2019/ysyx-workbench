#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <stdio.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

//void putch(char ch);
int printf(const char *fmt, ...) 
{
  char buf[1024];
  va_list ap;
  va_start(ap,fmt);
  int val = vsnprintf(buf,1024,fmt,ap);
  char* tmp = buf;
  while(*tmp!=0)
  {
    putch(*tmp);
    tmp++;
  }
  va_end(ap);
  return val;
}

int sprintf(char *out, const char *fmt, ...) {
  //%s和%d implementation
  va_list ap;
  va_start(ap,fmt);
  int val = vsprintf(out,fmt,ap);
  va_end(ap);
  return val;
}


int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap,fmt);
  int result;
  result = vsnprintf(out, n, fmt, ap);
  va_end(ap);
  return result;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  //%s和%d implementation
  char* start=out;
  int d;
  char c;
  char *s;
  while (*fmt!='\0')
  {
    if(*fmt=='%')
    {
      fmt++;
      switch(*fmt)
      {
        case 's':
          s = va_arg(ap, char *);
          strcpy(out,s);
          out+=strlen(s);
          break;
        case 'd':
          d = va_arg(ap, int);
          if(d<0) 
          { 
            d=-1*d;
            *out++='-';
          }
          int len=0,temp = d,temp_len=0;
          do
          {
            d = d/10;
            len++;
          } while (d);
          out = out + len -1;
          temp_len = len;
          while(temp_len--)
          {
            *out-- = temp%10 + '0';
            temp = temp/10;
          }
          out+=len+1;
          break;
        case 'c':
          c = va_arg(ap,int);
          *out = c;
          out++;
          break;
        default:
          break;
      }
    }
    else
    {
      *out = *fmt;
      out++;
    }
    fmt++;
  }
  *out = '\0';
  return out-start;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  char* start=out;
  int d;
  unsigned int d_pos;
  char c;
  char *s;
  while (n-- && *fmt!='\0')
  {
    if(*fmt=='%')
    {
      fmt++;
      switch(*fmt)
      {
        case 's':
          s = va_arg(ap, char *);
          strcpy(out,s);
          out+=strlen(s);
          break;
        case 'd':
          d = va_arg(ap, int);
          //out+=itoa(d,out,10);break;
          if(d<0) 
          { 
            *out++='-';
            if(d==-2147483648) d_pos = 2147483648u;
            else d_pos = -1*d;
          }
          else
            d_pos = d;
          int len=0;
          unsigned int temp = d_pos;
          int temp_len=0;
          do
          {
            d_pos = d_pos/10;
            len++;
          } while (d_pos);
          out = out + len -1;
          temp_len = len;
          while(temp_len--)
          {
            *out-- = temp%10 + '0';
            temp = temp/10;
          }
          out+=len+1;
          break;
        case 'c':
          c = va_arg(ap,int);
          *out = c;
          out++;
          break;
        default:
          break;
      }
    }
    else
    {
      *out = *fmt;
      out++;
    }
    fmt++;
  }
  *out = '\0';
  return out-start;
}


#endif
