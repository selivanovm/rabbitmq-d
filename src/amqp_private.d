// The contents of this file are subject to the Mozilla Public License
// Version 1.1 (the "License"); you may not use this file except in
// compliance with the License. You may obtain a copy of the License at
// http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS"
// basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
// License for the specific language governing rights and limitations
// under the License.
//
// The Original Code is RabbitMQ.
//
// The Initial Developers of the Original Code are LShift Ltd,
// Cohesive Financial Technologies LLC, and Rabbit Technologies Ltd.
//
// Portions created before 22-Nov-2008 00:00:00 GMT by LShift Ltd,
// Cohesive Financial Technologies LLC, or Rabbit Technologies Ltd
// are Copyright (C) 2007-2008 LShift Ltd, Cohesive Financial
// Technologies LLC, and Rabbit Technologies Ltd.
//
// Portions created by LShift Ltd are Copyright (C) 2007-2009 LShift
// Ltd. Portions created by Cohesive Financial Technologies LLC are
// Copyright (C) 2007-2009 Cohesive Financial Technologies
// LLC. Portions created by Rabbit Technologies Ltd are Copyright
// (C) 2007-2009 Rabbit Technologies Ltd.
//
// All Rights Reserved.
//
// Contributor(s): Mikhail Selivanov.       
//
import tango.net.device.Socket;
//import tango.stdc.posix.arpa.inet;
import tango.stdc.string;
import tango.stdc.stdio;
import tango.stdc.stdlib;
import amqp_base;
import amqp;
/*
 * Connection states:
 *
 * - CONNECTION_STATE_IDLE: initial state, and entered again after
 *   each frame is completed. Means that no bytes of the next frame
 *   have been seen yet. Connections may only be reconfigured, and the
 *   connection's pools recycled, when in this state. Whenever we're
 *   in this state, the inbound_buffer's bytes pointer must be NULL;
 *   any other state, and it must point to a block of memory allocated
 *   from the frame_pool.
 *
 * - CONNECTION_STATE_WAITING_FOR_HEADER: Some bytes of an incoming
 *   frame have been seen, but not a complete frame header's worth.
 *
 * - CONNECTION_STATE_WAITING_FOR_BODY: A complete frame header has
 *   been seen, but the frame is not yet complete. When it is
 *   completed, it will be returned, and the connection will return to
 *   IDLE state.
 *
 * - CONNECTION_STATE_WAITING_FOR_PROTOCOL_HEADER: The beginning of a
 *   protocol version header has been seen, but the full eight bytes
 *   hasn't yet been received. When it is completed, it will be
 *   returned, and the connection will return to IDLE state.
 *
 */
enum amqp_connection_state_enum {
  CONNECTION_STATE_IDLE = 0,
  CONNECTION_STATE_WAITING_FOR_HEADER,
  CONNECTION_STATE_WAITING_FOR_BODY,
  CONNECTION_STATE_WAITING_FOR_PROTOCOL_HEADER
};

/* 7 bytes up front, then payload, then 1 byte footer */
const HEADER_SIZE = 7;
const FOOTER_SIZE = 1;

struct amqp_link_t {
  amqp_link_t *next;
  void *data;
};

struct amqp_connection_state_t {
  amqp_pool_t frame_pool;
  amqp_pool_t decoding_pool;

  amqp_connection_state_enum state;

  int channel_max;
  int frame_max;
  int heartbeat;
  amqp_bytes_t inbound_buffer;

  size_t inbound_offset;
  size_t target_size;

  amqp_bytes_t outbound_buffer;

  //int sockfd;
  Socket socket;
  amqp_bytes_t sock_inbound_buffer;
  size_t sock_inbound_offset;
  size_t sock_inbound_limit;

  amqp_link_t *first_queued_frame;
  amqp_link_t *last_queued_frame;
};
//typedef *amqp_connection_state_t_ amqp_connection_state_t;

template CL(T) {
  T CHECK_LIMIT (amqp_bytes_t b, int o, int l, T v)
  { 
    assert ((o + l) <= b.len);
    return v;
      //      return -EFAULT; 
  }
}
public static uint8_t* BUF_AT(amqp_bytes_t b, int o) 
{
  return (&((cast(uint8_t *) b.bytes)[o]));
  //  return &(cast(uint8_t *)(b.bytes[cast(uint)o]));
}

public static uint8_t D_8(amqp_bytes_t b, int o)
{
  return CL!(uint8_t).CHECK_LIMIT(b, o, 1, *(cast(uint8_t *) BUF_AT(b, o)));
}

public static uint16_t D_16(amqp_bytes_t b, int o) 
{
  uint16_t v; 
  memcpy(&v, BUF_AT(b, o), 2); 
  return CL!(uint16_t).CHECK_LIMIT(b, o, 2, _htons(v));
}

public static uint32_t D_32(amqp_bytes_t b, int o) 
{
  uint32_t v; 
  memcpy(&v, BUF_AT(b, o), 4); 
  return CL!(uint32_t).CHECK_LIMIT(b, o, 4, _htonl(v));
}

public static uint64_t D_64(amqp_bytes_t b, int o) 
{				
  uint64_t hi = D_32(b, o);			
  uint64_t lo = D_32(b, o + 4);			
  return hi << 32 | lo;
}

public static uint8_t* D_BYTES(amqp_bytes_t b, int o, int l) 
{
  return CL!(uint8_t*).CHECK_LIMIT(b, o, l, BUF_AT(b, o));
}

public static uint8_t E_8(amqp_bytes_t b, int o, uint8_t v) 
{
  *(cast(uint8_t *) BUF_AT(b, o)) = v;
  return CL!(uint8_t).CHECK_LIMIT(b, o, 1, *(cast(uint8_t *) BUF_AT(b, o)));
}

public static uint16_t E_16(amqp_bytes_t b, int o, uint16_t v)
{
  uint16_t vv = _htons(v); 
  memcpy(BUF_AT(b, o), &vv, 2);
  return CL!(uint16_t).CHECK_LIMIT(b, o, 2, vv);
}

public static uint32_t E_32(amqp_bytes_t b, int o, uint32_t v)
{ 
  uint32_t vv = _htonl(v); 
  memcpy(BUF_AT(b, o), &vv, 4);
  return CL!(uint32_t).CHECK_LIMIT(b, o, 4, vv);
}

public static uint64_t E_64(amqp_bytes_t b, int o, int v) 
{
  E_32(b, o, cast(uint32_t) ((cast(uint64_t) v) >> 32));
  return E_32(b, o + 4, cast(uint32_t) ((cast(uint64_t) v) & 0xFFFFFFFF));
}

public static void E_BYTES(amqp_bytes_t b, int o, int l, void* v)
{
  CL!(void*).CHECK_LIMIT(b, o, l, memcpy(BUF_AT(b, o), v, l));
}

/*extern int amqp_decode_table(amqp_bytes_t encoded,
			     amqp_pool_t *pool,
			     amqp_table_t *output,
			     int *offsetptr);

extern int amqp_encode_table(amqp_bytes_t encoded,
			     amqp_table_t *input,
			     int *offsetptr);*/

public static void amqp_assert(bool condition, ...)
{						
  if (!(condition)) {				
    fprintf(stderr, cast(char*)_argptr);		
    fputc('\n', stderr);			
    abort();					
  }						
}

/*public static int AMQP_CHECK_RESULT(int expr)			
{						
  int _result = (expr);			
  if (_result < 0) return _result;
  //  _result;					
  }*/

public static int AMQP_CHECK_EOF_RESULT(int expr)		
{						
  int _result = (expr);			
  if (_result <= 0) return _result;		
  //  _result;					
}

//extern void amqp_dump(void const *buffer, size_t len);
public static void amqp_dump(void* buffer, size_t len)
{
  return cast(void) 0;
}





			 
/*******************************************************************************

        conversions for network byte-order

*******************************************************************************/

version(BigEndian)
{
        private ushort _htons (ushort x)
        {
                return x;
        }

        private uint _htonl (uint x)
        {
                return x;
        }
}
else 
{
        private import tango.core.BitManip;

        private ushort _htons (ushort x)
        {
                return cast(ushort) ((x >> 8) | (x << 8));
        }

        private uint _htonl (uint x)
        {
                return bswap(x);
        }
}

/*******************************************************************************/
