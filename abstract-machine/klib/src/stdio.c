#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <stdio.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int printf(const char *fmt, ...) {
  panic("Not implemented");
  // va_list args;
  // va_start(args,fmt);
  // sprintf(stdout,fmt,args);
  // va_end(args);
}

int sprintf(char *out, const char *fmt, ...) {
  //%s和%d implementation
  va_list ap;
  char* start=out;
  int d;
  char c;
  char *s;
  va_start(ap, fmt);
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
  va_end(ap);
  return out-start;
}


int snprintf(char *out, size_t n, const char *fmt, ...) {
  panic("Not implemented");
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
  panic("Not implemented");
}


#endif
