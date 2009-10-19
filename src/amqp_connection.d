import tango.stdc.stdlib;
//import tango.stdc.posix.unistd : write;
import tango.io.Stdout;
import tango.net.Socket;

import amqp_base;
import amqp_private;
import amqp;
import amqp_mem;
import amqp_framing;
import amqp_framing_;
import amqp_socket;

const INITIAL_FRAME_POOL_PAGE_SIZE = 65536;
const INITIAL_DECODING_POOL_PAGE_SIZE = 131072;
const INITIAL_INBOUND_SOCK_BUFFER_SIZE = 131072;

public static void ENFORCE_STATE(amqp_connection_state_t *statevec, int statenum)				
{									
  amqp_connection_state_t *_check_state = statevec;			
  int _wanted_state = statenum;					
  amqp_assert((*_check_state).state == _wanted_state,			
	      "Programming error: invalid AMQP connection state: expected %d, got %d", 
	      _wanted_state,						
	      (*_check_state).state);					
}

amqp_connection_state_t* amqp_new_connection(Socket socket) {
  amqp_connection_state_t* state =
    cast(amqp_connection_state_t*) calloc(1, amqp_connection_state_t.sizeof);

  if (state is null) {
    return null;
  }

  init_amqp_pool(&(*state).frame_pool, INITIAL_FRAME_POOL_PAGE_SIZE);
  init_amqp_pool(&(*state).decoding_pool, INITIAL_DECODING_POOL_PAGE_SIZE);

  (*state).state = amqp_connection_state_enum.CONNECTION_STATE_IDLE;

  (*state).inbound_buffer.bytes = null;
  (*state).outbound_buffer.bytes = null;
  if (amqp_tune_connection(state, 0, INITIAL_FRAME_POOL_PAGE_SIZE, 0) != 0) {
    empty_amqp_pool(&(*state).frame_pool);
    empty_amqp_pool(&(*state).decoding_pool);
    free(state);
    return null;
  }

  (*state).inbound_offset = 0;
  (*state).target_size = HEADER_SIZE;

  (*state).socket = socket;
  (*state).sock_inbound_buffer.len = INITIAL_INBOUND_SOCK_BUFFER_SIZE;
  (*state).sock_inbound_buffer.bytes = malloc(INITIAL_INBOUND_SOCK_BUFFER_SIZE);
  if ((*state).sock_inbound_buffer.bytes is null) {
    amqp_destroy_connection(state);
    return null;
  }

  (*state).sock_inbound_offset = 0;
  (*state).sock_inbound_limit = 0;

  (*state).first_queued_frame = null;
  (*state).last_queued_frame = null;

  return state;
}

Socket amqp_get_sockfd(amqp_connection_state_t *state) {
  return (*state).socket;
}

void amqp_set_sockfd(amqp_connection_state_t *state,
		     Socket socket)
{
  (*state).socket = socket;
}

int amqp_tune_connection(amqp_connection_state_t *state,
			 int channel_max,
			 int frame_max,
			 int heartbeat)
{
  void *newbuf;

  ENFORCE_STATE(state, amqp_connection_state_enum.CONNECTION_STATE_IDLE);

  (*state).channel_max = channel_max;
  (*state).frame_max = frame_max;
  (*state).heartbeat = heartbeat;

  empty_amqp_pool(&(*state).frame_pool);
  init_amqp_pool(&(*state).frame_pool, frame_max);

  (*state).inbound_buffer.len = frame_max;
  (*state).outbound_buffer.len = frame_max;
  newbuf = realloc((*state).outbound_buffer.bytes, frame_max);
  if (newbuf is null) {
    amqp_destroy_connection(state);
    return -ENOMEM;
  }
  (*state).outbound_buffer.bytes = newbuf;

  return 0;
}

int amqp_get_channel_max(amqp_connection_state_t *state) {
  return (*state).channel_max;
}

void amqp_destroy_connection(amqp_connection_state_t *state) {
  empty_amqp_pool(&(*state).frame_pool);
  empty_amqp_pool(&(*state).decoding_pool);
  free((*state).outbound_buffer.bytes);
  free((*state).sock_inbound_buffer.bytes);
  (*state).socket.shutdown(SocketShutdown.BOTH);
  free(state);
}

static void return_to_idle(amqp_connection_state_t *state) {
  (*state).inbound_buffer.bytes = null;
  (*state).inbound_offset = 0;
  (*state).target_size = HEADER_SIZE;
  (*state).state = amqp_connection_state_enum.CONNECTION_STATE_IDLE;
}

int amqp_handle_input(amqp_connection_state_t *state,
		      amqp_bytes_t received_data,
		      amqp_frame_t *decoded_frame)
{
  int total_bytes_consumed = 0;
  int bytes_consumed;
  int result_ = -1;

  //Stdout.format("amqp_handle_input #1").newline;

  /* Returning frame_type of zero indicates either insufficient input,
     or a complete, ignored frame was read. */
  (*decoded_frame).frame_type = 0;

 read_more:
  if (received_data.len == 0) {
    return total_bytes_consumed;
  }

  //Stdout.format("amqp_handle_input #2").newline;

  if ((*state).state == amqp_connection_state_enum.CONNECTION_STATE_IDLE) {
    (*state).inbound_buffer.bytes = amqp_pool_alloc(&(*state).frame_pool, (*state).inbound_buffer.len);
    (*state).state = amqp_connection_state_enum.CONNECTION_STATE_WAITING_FOR_HEADER;
  }

  //Stdout.format("amqp_handle_input #3").newline;

  bytes_consumed = (*state).target_size - (*state).inbound_offset;
  if (received_data.len < bytes_consumed) {
    bytes_consumed = received_data.len;
  }

  //Stdout.format("amqp_handle_input #4").newline;

  E_BYTES((*state).inbound_buffer, (*state).inbound_offset, bytes_consumed, received_data.bytes);
  (*state).inbound_offset += bytes_consumed;
  total_bytes_consumed += bytes_consumed;

  //Stdout.format("amqp_handle_input #5").newline;

  assert((*state).inbound_offset <= (*state).target_size);

  if ((*state).inbound_offset < (*state).target_size) {
    return total_bytes_consumed;
  }

  //Stdout.format("amqp_handle_input #6").newline;

  switch ((*state).state) {
  case amqp_connection_state_enum.CONNECTION_STATE_WAITING_FOR_HEADER:
    {
      //Stdout.format("amqp_handle_input #7").newline;
      if (D_8((*state).inbound_buffer, 0) == AMQP_PSEUDOFRAME_PROTOCOL_HEADER &&
	  D_16((*state).inbound_buffer, 1) == AMQP_PSEUDOFRAME_PROTOCOL_CHANNEL)
      {
	(*state).target_size = 8;
	(*state).state = amqp_connection_state_enum.CONNECTION_STATE_WAITING_FOR_PROTOCOL_HEADER;
      } else {
	(*state).target_size = D_32((*state).inbound_buffer, 3) + HEADER_SIZE + FOOTER_SIZE;
	(*state).state = amqp_connection_state_enum.CONNECTION_STATE_WAITING_FOR_BODY;
      }

      /* Wind buffer forward, and try to read some body out of it. */
      received_data.len -= bytes_consumed;
      received_data.bytes = (cast(char *) received_data.bytes) + bytes_consumed;
      goto read_more;
    }
    case amqp_connection_state_enum.CONNECTION_STATE_WAITING_FOR_BODY: {
      //Stdout.format("amqp_handle_input #8").newline;
      int frame_type = D_8((*state).inbound_buffer, 0);

      /*#if 0
      printf("recving:\n");
      amqp_dump((*state).inbound_buffer.bytes, (*state).target_size);
#endif(*/

      /* Check frame end marker (footer) */
      if (D_8((*state).inbound_buffer, (*state).target_size - 1) != AMQP_FRAME_END) {
	return -EINVAL;
      }

      (*decoded_frame).channel = cast(amqp_channel_t)D_16((*state).inbound_buffer, 1);

      //Stdout.format("amqp_handle_input #9").newline;

      switch (frame_type) {
	case AMQP_FRAME_METHOD: {
	  amqp_bytes_t encoded;
	  //Stdout.format("amqp_handle_input #91").newline;
	  /* Four bytes of method ID before the method args. */
	  encoded.len = (*state).target_size - (HEADER_SIZE + 4 + FOOTER_SIZE);
	  //Stdout.format("amqp_handle_input #911").newline;
	  encoded.bytes = D_BYTES((*state).inbound_buffer, HEADER_SIZE + 4, encoded.len);
	  //Stdout.format("amqp_handle_input #912").newline;
	  (*decoded_frame).frame_type = AMQP_FRAME_METHOD;
	  (*decoded_frame).payload.method.id = cast(amqp_method_number_t)D_32((*state).inbound_buffer, HEADER_SIZE);
	  //Stdout.format("amqp_handle_input #913").newline;
	  int _result = amqp_decode_method((*decoded_frame).payload.method.id,
					       &(*state).decoding_pool,
					       encoded,
					       &((*decoded_frame).payload.method.decoded));
	  if (_result < 0) return _result;		

	  //Stdout.format("amqp_handle_input #914").newline;
	  break;
	}

	case AMQP_FRAME_HEADER: {
	  amqp_bytes_t encoded;
	  //Stdout.format("amqp_handle_input #92").newline;
	  /* 12 bytes for properties header. */
	  encoded.len = (*state).target_size - (HEADER_SIZE + 12 + FOOTER_SIZE);
	  encoded.bytes = D_BYTES((*state).inbound_buffer, HEADER_SIZE + 12, encoded.len);

	  (*decoded_frame).frame_type = AMQP_FRAME_HEADER;
	  (*decoded_frame).payload.properties.class_id = D_16((*state).inbound_buffer, HEADER_SIZE);
	  (*decoded_frame).payload.properties.body_size = D_64((*state).inbound_buffer, HEADER_SIZE+4);

	  //Stdout.format("amqp_handle_input #921").newline;

	  result_ = amqp_decode_properties((*decoded_frame).payload.properties.class_id,
						   &(*state).decoding_pool,
						   encoded,
						   &((*decoded_frame).payload.properties.decoded));
	  if (result_ < 0)
	    return result_;

	  break;
	}

	case AMQP_FRAME_BODY: {
	  //Stdout.format("amqp_handle_input #93").newline;
	  size_t fragment_len = (*state).target_size - (HEADER_SIZE + FOOTER_SIZE);

	  (*decoded_frame).frame_type = AMQP_FRAME_BODY;
	  (*decoded_frame).payload.body_fragment.len = fragment_len;
	  (*decoded_frame).payload.body_fragment.bytes =
	    D_BYTES((*state).inbound_buffer, HEADER_SIZE, fragment_len);
	  break;
	}

	case AMQP_FRAME_HEARTBEAT:
	  //Stdout.format("amqp_handle_input #94").newline;
	  (*decoded_frame).frame_type = AMQP_FRAME_HEARTBEAT;
	  break;

	default:
	  /* Ignore the frame by not changing frame_type away from 0. */
	  break;
      }

      return_to_idle(state);

      //Stdout.format("amqp_handle_input #END1").newline;

      return total_bytes_consumed;
    }

    case amqp_connection_state_enum.CONNECTION_STATE_WAITING_FOR_PROTOCOL_HEADER:
      (*decoded_frame).frame_type = AMQP_PSEUDOFRAME_PROTOCOL_HEADER;
      (*decoded_frame).channel = AMQP_PSEUDOFRAME_PROTOCOL_CHANNEL;
      amqp_assert(D_8((*state).inbound_buffer, 3) == cast(uint8_t) 'P',
		  "Invalid protocol header received");
      (*decoded_frame).payload.protocol_header.transport_high = D_8((*state).inbound_buffer, 4);
      (*decoded_frame).payload.protocol_header.transport_low = D_8((*state).inbound_buffer, 5);
      (*decoded_frame).payload.protocol_header.protocol_version_major = D_8((*state).inbound_buffer, 6);
      (*decoded_frame).payload.protocol_header.protocol_version_minor = D_8((*state).inbound_buffer, 7);

      return_to_idle(state);
      return total_bytes_consumed;

    default:
      amqp_assert(0, "Internal error: invalid amqp_connection_state_t->state %d", (*state).state);
  }

  //Stdout.format("amqp_handle_input #10").newline;

}

amqp_boolean_t amqp_release_buffers_ok(amqp_connection_state_t *state) {
  return cast(amqp_boolean_t)(((*state).state == amqp_connection_state_enum.CONNECTION_STATE_IDLE) && 
			      ((*state).first_queued_frame is null));
}

void amqp_release_buffers(amqp_connection_state_t *state) {
  ENFORCE_STATE(state, amqp_connection_state_enum.CONNECTION_STATE_IDLE);

  amqp_assert((*state).first_queued_frame is null,
	      "Programming error: attempt to amqp_release_buffers while waiting events enqueued");

  recycle_amqp_pool(&(*state).frame_pool);
  recycle_amqp_pool(&(*state).decoding_pool);
}

void amqp_maybe_release_buffers(amqp_connection_state_t *state) {
  if (amqp_release_buffers_ok(state)) {
    amqp_release_buffers(state);
  }
}

static int inner_send_frame(amqp_connection_state_t *state,
			    amqp_frame_t *frame,
			    amqp_bytes_t *encoded,
			    int *payload_len)
{

  //Stdout.format("inner_send_frame #START").newline;

  int separate_body;

  int result_ = -1;

  E_8((*state).outbound_buffer, 0, (*frame).frame_type);
  E_16((*state).outbound_buffer, 1, (*frame).channel);
  switch ((*frame).frame_type) {
    case AMQP_FRAME_METHOD:
      {
	//Stdout.format("inner_send_frame #1").newline;
	E_32((*state).outbound_buffer, HEADER_SIZE, (*frame).payload.method.id);
	(*encoded).len = (*state).outbound_buffer.len - (HEADER_SIZE + 4 + FOOTER_SIZE);
	(*encoded).bytes = D_BYTES((*state).outbound_buffer, HEADER_SIZE + 4, (*encoded).len);
	//Stdout.format("inner_send_frame #12").newline;

	 result_ = amqp_encode_method((*frame).payload.method.id, (*frame).payload.method.decoded, *encoded);

	 if (result_ < 0)
	   {
	     //Stdout.format("inner_send_frame ERR#12").newline;
	     return result_;
	   }
	 *payload_len = result_ + 4;
	 separate_body = 0;
	 break;
      }
    case AMQP_FRAME_HEADER:
      {
	//Stdout.format("inner_send_frame #2").newline;
	E_16((*state).outbound_buffer, HEADER_SIZE, (*frame).payload.properties.class_id);
	E_16((*state).outbound_buffer, HEADER_SIZE+2, 0); /* "weight" */
	E_64((*state).outbound_buffer, HEADER_SIZE+4, (*frame).payload.properties.body_size);
	(*encoded).len = (*state).outbound_buffer.len - (HEADER_SIZE + 12 + FOOTER_SIZE);
	(*encoded).bytes = D_BYTES((*state).outbound_buffer, HEADER_SIZE + 12, (*encoded).len);

	result_ = amqp_encode_properties((*frame).payload.properties.class_id,
					 (*frame).payload.properties.decoded,
					 *encoded);
	if(result_ < 0)
	  return result_;

	*payload_len = result_ + 12;
	separate_body = 0;
	break;
      }
    case AMQP_FRAME_BODY:
      {
	//Stdout.format("inner_send_frame #3").newline;
	*encoded = (*frame).payload.body_fragment;
	*payload_len = (*encoded).len;
	separate_body = 1;
	break;
      }
    case AMQP_FRAME_HEARTBEAT:
      {
	//Stdout.format("inner_send_frame #4").newline;
	*encoded = AMQP_EMPTY_BYTES;
	*payload_len = 0;
	separate_body = 0;
	break;
      }
    default:
      {
	//Stdout.format("inner_send_frame #5").newline;
	return -EINVAL;
      }
  }

  //Stdout.format("inner_send_frame #6").newline;

  E_32((*state).outbound_buffer, 3, *payload_len);
  if (!separate_body) {
    E_8((*state).outbound_buffer, *payload_len + HEADER_SIZE, AMQP_FRAME_END);
  }

  /*#if 0
  if (separate_body) {
    printf("sending body frame (header):\n");
    amqp_dump((*state).outbound_buffer.bytes, HEADER_SIZE);
    printf("sending body frame (payload):\n");
    amqp_dump((*encoded).bytes, *payload_len);
  } else {
    printf("sending:\n");
    amqp_dump((*state).outbound_buffer.bytes, *payload_len + HEADER_SIZE + FOOTER_SIZE);
  }
  #endif*/
  //Stdout.format("inner_send_frame #END").newline;
  return separate_body;
}

int amqp_send_frame(amqp_connection_state_t *state,
		    amqp_frame_t *frame)
{

  //Stdout.format("amqp_send_frame #START").newline;

  amqp_bytes_t encoded;
  int payload_len;
  int separate_body;
  int result_ =  -1;

  separate_body = inner_send_frame(state, frame, &encoded, &payload_len);
  switch (separate_body) {
    case 0:
      //Stdout.format("amqp_send_frame #1 {} {} {}", (*state).socket.sock, (*state).outbound_buffer.bytes, 
      //	    payload_len + (HEADER_SIZE + FOOTER_SIZE)).newline;

  //for(uint i = 0; i < payload_len + (HEADER_SIZE + FOOTER_SIZE); i++)
	//Stdout.format("{},",*(cast(char*)((*state).outbound_buffer.bytes) + i)); 


      //Stdout.format("").newline; 

      result_ = send_buffer_to_socket((*state).socket, (*state).outbound_buffer.bytes,
				     payload_len + (HEADER_SIZE + FOOTER_SIZE));

	//write((*state).sockfd,

      //Stdout.format("amqp_send_frame #21").newline;
      if(result_ < 0)
	{
	  //Stdout.format("amqp_send_frame #ERR1").newline;
	  return result_;
	}
      //Stdout.format("amqp_send_frame #END1").newline;
      return 0;

    case 1:
      //Stdout.format("amqp_send_frame #2").newline;
      result_ = send_buffer_to_socket((*state).socket, (*state).outbound_buffer.bytes, HEADER_SIZE);
	//write(
      if(result_ < 0)
	return result_;

      result_ = send_buffer_to_socket((*state).socket, encoded.bytes, payload_len);
	//write
      if(result_ < 0)
	return result_;

      {
	assert(FOOTER_SIZE == 1);
	char frame_end_byte = AMQP_FRAME_END;
	result_ = send_buffer_to_socket((*state).socket, &frame_end_byte, FOOTER_SIZE);
	  //write

	if(result_ < 0)
	  return result_;
	
      }
      //Stdout.format("amqp_send_frame #END2").newline;
      return 0;
      
    default:
      {
	//Stdout.format("amqp_send_frame #END3").newline;
	return separate_body;
      }
  }
}

int amqp_send_frame_to(amqp_connection_state_t *state,
		       amqp_frame_t *frame,
		       int function(void *context, void *buffer, size_t count) fn,
		       void *context)
{
  amqp_bytes_t encoded;
  int payload_len;
  int separate_body;

  int result_ = -1;

  separate_body = inner_send_frame(state, frame, &encoded, &payload_len);
  switch (separate_body) {
    case 0:
      result_ = fn(context,
			   (*state).outbound_buffer.bytes,
			   payload_len + (HEADER_SIZE + FOOTER_SIZE));
      if(result_ < 0)
	return result_;

      return 0;

    case 1:
      result_ = fn(context, (*state).outbound_buffer.bytes, HEADER_SIZE);
      if(result_ < 0)
	return result_;

      result_ = fn(context, encoded.bytes, payload_len);
      if(result_ < 0)
	return result_;

      {
	assert(FOOTER_SIZE == 1);
	char frame_end_byte = AMQP_FRAME_END;
	result_ = fn(context, &frame_end_byte, FOOTER_SIZE);
	if(result_ < 0)
	  return result_;
      }
      return 0;

    default:
      return separate_body;
  }
}
