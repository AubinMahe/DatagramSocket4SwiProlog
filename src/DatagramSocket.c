#include <errno.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <arpa/inet.h>
#include <netdb.h>

#include <SWI-Prolog.h>

#define INVALID_SOCKET (-1)
#define closesocket close

typedef int SOCKET;
typedef unsigned char byte;

#define ELEVATOR_SHAFT_ID_MSG           1
#define CABIN_MSG_ID                    2
#define MAX_MESSAGE_SIZE                73

typedef struct {

   byte *   bytes;
   unsigned capacity;
   unsigned limit;
   unsigned index;

} ByteBuffer;

typedef struct {

   int                sockfd;
   ByteBuffer         recvbuf;
   struct sockaddr_in remote;

} DatagramSocket;

static functor_t request2;

static foreign_t decodeByte( ByteBuffer * buffer, byte * target ) {
   if( buffer->index < buffer->limit ) {
      *target = buffer->bytes[buffer->index++];
      PL_succeed;
   }
   PL_fail;
}

static foreign_t decodeULong( ByteBuffer * buffer, uint64_t * target ) {
   if( buffer->index + sizeof( uint64_t ) <= buffer->limit ) {
      uint64_t value;
      memcpy( &value, buffer->bytes + buffer->index, sizeof( value ));
      value = (( value & 0xFF00000000000000LL ) >> 56 )
             |(( value & 0x00FF000000000000LL ) >> 40 )
             |(( value & 0x0000FF0000000000LL ) >> 24 )
             |(( value & 0x000000FF00000000LL ) >>  8 )
             |(( value & 0x00000000FF000000LL ) <<  8 )
             |(( value & 0x0000000000FF0000LL ) << 24 )
             |(( value & 0x000000000000FF00LL ) << 40 )
             |(  value                          << 56 );
      buffer->index += sizeof( uint64_t );
      *target = value;
      PL_succeed;
   }
   PL_fail;
}

static foreign_t decodeDouble( ByteBuffer * buffer, double * target ) {
   uint64_t u64;
   if( decodeULong( buffer, &u64 )) {
      *target = *(double *)&u64;
      PL_succeed;
   }
   PL_fail;
}

/**
 * createAndConnectDatagramSocket( +LocalHostOrIP, +LocalPort, +RemoteHostOrIP, +RemotePort, +MsgMaxSize, ?DatagramSocket )
 */
static foreign_t createAndConnectDatagramSocket(
   term_t LocalHostOrIP,
   term_t LocalPort,
   term_t RemoteHostOrIP,
   term_t RemotePort,
   term_t MsgMaxSize,
   term_t DatagramSocketHandle )
{
   char * localHostOrIP = NULL;
   if( ! PL_get_chars( LocalHostOrIP, &localHostOrIP, CVT_ALL )) {
      PL_fail;
   }
   int localPort = 0;
   if( ! PL_get_integer( LocalPort, &localPort )) {
      fprintf( stderr, "%s:%d:%s: PL_get_integer( LocalPort, &localPort ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   char * remoteHostOrIP = NULL;
   if( ! PL_get_chars( RemoteHostOrIP, &remoteHostOrIP, CVT_ALL )) {
      fprintf( stderr, "%s:%d:%s: PL_get_chars( RemoteHostOrIP, &remoteHostOrIP, CVT_ALL ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   int remotePort = 0;
   if( ! PL_get_integer( RemotePort, &remotePort )) {
      fprintf( stderr, "%s:%d:%s: PL_get_integer( RemotePort, &remotePort ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   int msgMaxSize = 0;
   if( ! PL_get_integer( MsgMaxSize, &msgMaxSize )) {
      fprintf( stderr, "%s:%d:%s: PL_get_integer( MsgMaxSize, &msgMaxSize ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   if( msgMaxSize < 2 ) {
      fprintf( stderr, "%s:%d:%s: msgMaxSize < 2\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   int sockfd = socket( AF_INET, SOCK_DGRAM, 0 );
   if( sockfd < 1 ) {
      fprintf( stderr, "%s:%d:%s: socket: %s\n", __FILE__, __LINE__, __func__, strerror( errno ));
      PL_fail;
   }
   struct hostent * he = gethostbyname( localHostOrIP );
   if( NULL == he ) {
      fprintf( stderr, "%s:%d:%s: gethostbyname: %s\n", __FILE__, __LINE__, __func__, strerror( errno ));
      closesocket( sockfd );
      PL_fail;
   }
   struct sockaddr_in local;
   memset( &local, 0, sizeof( local ));
   local.sin_family = AF_INET;
   local.sin_port   = htons( localPort );
   memcpy( &local.sin_addr, he->h_addr_list[0], (size_t)he->h_length );
   if( 0 != bind( sockfd, (struct sockaddr *)&local, sizeof( local ))) {
      fprintf( stderr, "%s:%d:%s: bind: %s\n", __FILE__, __LINE__, __func__, strerror( errno ));
      closesocket( sockfd );
      PL_fail;
   }
   he = gethostbyname( remoteHostOrIP );
   if( NULL == he ) {
      fprintf( stderr, "%s:%d:%s: gethostbyname: %s\n", __FILE__, __LINE__, __func__, strerror( errno ));
      closesocket( sockfd );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)malloc( sizeof( DatagramSocket ));
   if( NULL == This ) {
      fprintf( stderr, "%s:%d:%s: malloc( sizeof( DatagramSocket )) fails\n", __FILE__, __LINE__, __func__ );
      closesocket( sockfd );
      PL_fail;
   }
   This->sockfd           = sockfd;
   This->recvbuf.capacity = msgMaxSize;
   This->recvbuf.limit    = 0;
   This->recvbuf.index    = 0;
   This->recvbuf.bytes    = (byte *)malloc( This->recvbuf.capacity + 1 );
   if( NULL == This->recvbuf.bytes ) {
      fprintf( stderr, "%s:%d:%s: malloc( This->recvbuf.capacity + 1 ) fails\n", __FILE__, __LINE__, __func__ );
      closesocket( sockfd );
      free( This );
      PL_fail;
   }
   memset( &(This->remote), 0, sizeof( struct sockaddr_in ));
   This->remote.sin_family = AF_INET;
   This->remote.sin_port   = htons( remotePort );
   memcpy( &(This->remote.sin_addr), he->h_addr_list[0], (size_t)he->h_length );
   term_t handle = PL_new_term_ref();
   if( ! PL_put_pointer( handle, This )) {
      fprintf( stderr, "%s:%d:%s: PL_put_pointer( handle, This ) fails\n", __FILE__, __LINE__, __func__ );
      closesocket( This->sockfd );
      free( This->recvbuf.bytes );
      free( This );
      PL_fail;
   }
   if( ! PL_unify( DatagramSocketHandle, handle )) {
      fprintf( stderr, "%s:%d:%s: PL_unify( DatagramSocketHandle, handle ) fails\n", __FILE__, __LINE__, __func__ );
      closesocket( This->sockfd );
      free( This->recvbuf.bytes );
      free( This );
      PL_fail;
   }
   PL_succeed;
}

/**
 * receiveDatagram( +DatagramSocket )
 */
static foreign_t receiveDatagram( term_t DatagramSocketHandle ) {
   void * ptr = NULL;
   if( ! PL_get_pointer( DatagramSocketHandle, &ptr )) {
      fprintf( stderr, "%s:%d:%s: PL_get_pointer( DatagramSocketHandle, &ptr ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   if( NULL == ptr ) {
      fprintf( stderr, "%s:%d:%s: DatagramSocketHandle is null\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)ptr;
   This->recvbuf.index = 0;
   ssize_t ret = recvfrom( This->sockfd, This->recvbuf.bytes, This->recvbuf.capacity + 1, 0, NULL, 0 );
   if( ret < 0 ) {
      fprintf( stderr, "%s:%d:%s: recvfrom: %s\n", __FILE__, __LINE__, __func__, strerror( errno ));
      PL_fail;
   }
   if( ret > This->recvbuf.capacity ) {
      fprintf( stderr, "%s:%d:%s: recvfrom, too long message received: over %ld bytes\n", __FILE__, __LINE__, __func__, ret );
      PL_fail;
   }
   This->recvbuf.limit = (unsigned)ret;
   PL_succeed;
}

/**
 * getByteFromDatagramSocket( +DatagramSocket, ?Byte )
 */
static foreign_t getByteFromDatagramSocket( term_t DatagramSocketHandle, term_t Byte ) {
   void * ptr = NULL;
   if( ! PL_get_pointer( DatagramSocketHandle, &ptr )) {
      PL_fail;
   }
   if( NULL == ptr ) {
      fprintf( stderr, "%s:%d:%s: DatagramSocketHandle is null\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)ptr;
   byte b;
   if( decodeByte( &This->recvbuf, &b )) {
      return PL_unify_integer( Byte, b );
   }
   PL_fail;
}

/**
 * getBooleanFromDatagramSocket( +DatagramSocket, ?Boolean )
 */
static foreign_t getBooleanFromDatagramSocket( term_t DatagramSocketHandle, term_t Boolean ) {
   void * ptr = NULL;
   if( ! PL_get_pointer( DatagramSocketHandle, &ptr )) {
      PL_fail;
   }
   if( NULL == ptr ) {
      fprintf( stderr, "%s:%d:%s: DatagramSocketHandle is null\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)ptr;
   byte b;
   return decodeByte( &This->recvbuf, &b ) && PL_unify_bool( Boolean, b == true );
}

/**
 * getLongFromDatagramSocket( +DatagramSocket, ?Long64 )
 */
static foreign_t getLongFromDatagramSocket( term_t DatagramSocketHandle, term_t Long64 ) {
   void * ptr = NULL;
   if( ! PL_get_pointer( DatagramSocketHandle, &ptr )) {
      PL_fail;
   }
   if( NULL == ptr ) {
      fprintf( stderr, "%s:%d:%s: DatagramSocketHandle is null\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)ptr;
   uint64_t ul64 = 0;
   if( ! decodeULong( &This->recvbuf, &ul64 )) {
      fprintf( stderr, "%s:%d:%s: decodeULong( &This->recvbuf, &ul64 ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   int64_t value = (int64_t)ul64;
   if( ! PL_unify_int64( Long64, value )) {
      fprintf( stderr, "%s:%d:%s: PL_unify_int64( Long64, value ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   PL_succeed;
}

/**
 * getDoubleFromDatagramSocket( +DatagramSocket, ?Double )
 */
static foreign_t getDoubleFromDatagramSocket( term_t DatagramSocketHandle, term_t Double ) {
   void * ptr = NULL;
   if( ! PL_get_pointer( DatagramSocketHandle, &ptr )) {
      PL_fail;
   }
   if( NULL == ptr ) {
      fprintf( stderr, "%s:%d:%s: DatagramSocketHandle is null\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)ptr;
   /*
   uint64_t ul64 = 0;
   if( ! decodeULong( &This->recvbuf, &ul64 )) {
      fprintf( stderr, "%s:%d:%s: decodeULong( &This->recvbuf, &ul64 ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   double value = (double)ul64;
   */
   double value = 0.0;
   if( ! decodeDouble( &This->recvbuf, &value )) {
      fprintf( stderr, "%s:%d:%s: decodeDouble( &This->recvbuf, &value ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   if( ! PL_unify_float( Double, value )) {
      fprintf( stderr, "%s:%d:%s: PL_unify_int64( Long64, value ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   PL_succeed;
}

/**
 * sendDatagram( +DatagramSocket, +Message )
 */
static foreign_t sendDatagram( term_t DatagramSocketHandle, term_t Message ) {
   void * ptr = NULL;
   if( ! PL_get_pointer( DatagramSocketHandle, &ptr )) {
      PL_fail;
   }
   if( NULL == ptr ) {
      fprintf( stderr, "%s:%d:%s: DatagramSocketHandle is null\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)ptr;
   size_t count = 0U;
   if( ! PL_skip_list( Message, 0, &count )) {
      fprintf( stderr, "%s:%d:%s: PL_skip_list( Message, 0, &count ) fails\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   byte * buffer = (byte *)malloc( count );
   term_t head   = PL_new_term_ref();
   unsigned i = 0;
   while( PL_get_list( Message, head, Message )) {
      int type = PL_term_type( head );
      int value;
      switch( type ) {
      case PL_INTEGER:
         if( ! PL_get_integer( head, &value )) {
            fprintf( stderr, "%s:%d:%s: PL_get_integer( head, buffer + i++ ) fails\n", __FILE__, __LINE__, __func__ );
            free( buffer );
            PL_fail;
         }
         buffer[i] = (byte)value;
         if( value != (int)buffer[i]) {
            fprintf( stderr, "%s:%d:%s: data %d truncated %d\n", __FILE__, __LINE__, __func__, value, buffer[i] );
            free( buffer );
            PL_fail;
         }
         ++i;
         break;
      default:
         fprintf( stderr, "%s:%d:%s: unexpected term type: %d\n", __FILE__, __LINE__, __func__, type );
         break;
      }
   }
   if( sendto( This->sockfd, buffer, count, 0, (const struct sockaddr *)&(This->remote), sizeof( struct sockaddr_in )) != count ) {
      fprintf( stderr, "%s:%d:%s: send: %s\n", __FILE__, __LINE__, __func__, strerror( errno ));
      free( buffer );
      PL_fail;
   }
   free( buffer );
   PL_succeed;
}

/**
 * closeDatagramSocket( +DatagramSocket )
 */
static foreign_t closeDatagramSocket( term_t DatagramSocketHandle ) {
   void * ptr = NULL;
   if( ! PL_get_pointer( DatagramSocketHandle, &ptr )) {
      PL_fail;
   }
   if( NULL == ptr ) {
      fprintf( stderr, "%s:%d:%s: DatagramSocketHandle is null\n", __FILE__, __LINE__, __func__ );
      PL_fail;
   }
   DatagramSocket * This = (DatagramSocket *)ptr;
   closesocket( This->sockfd );
   This->sockfd = INVALID_SOCKET;
   free( This->recvbuf.bytes );
   free( This );
   if( PL_put_pointer( DatagramSocketHandle, NULL )) {
      PL_succeed;
   }
   PL_fail;
}

void install_libDatagramSocket( void ) {
   request2 = PL_new_functor( PL_new_atom( "request" ), 2 );
   PL_register_foreign( "createAndConnectDatagramSocket", 6, createAndConnectDatagramSocket, 0 );
   PL_register_foreign( "receiveDatagram"               , 1, receiveDatagram               , 0 );
   PL_register_foreign( "getByteFromDatagramSocket"     , 2, getByteFromDatagramSocket     , 0 );
   PL_register_foreign( "getBooleanFromDatagramSocket"  , 2, getBooleanFromDatagramSocket  , 0 );
   PL_register_foreign( "getLongFromDatagramSocket"     , 2, getLongFromDatagramSocket   , 0 );
   PL_register_foreign( "getDoubleFromDatagramSocket"   , 2, getDoubleFromDatagramSocket   , 0 );
   PL_register_foreign( "sendDatagram"                  , 2, sendDatagram                  , 0 );
   PL_register_foreign( "closeDatagramSocket"           , 1, closeDatagramSocket           , 0 );
}
