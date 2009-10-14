// D import file generated from 'src/amqp_socket.d'
import tango.core.Vararg;
import tango.net.Socket;
import amqp_base;
import amqp;
import amqp_framing;
import amqp_private;
int amqp_open_socket(char* hostname, int portnumber);
static 
{
    char* header()
{
static char[8] header;
header[0] = 'A';
header[1] = 'M';
header[2] = 'Q';
header[3] = 'P';
header[4] = 1;
header[5] = 1;
header[6] = AMQP_PROTOCOL_VERSION_MAJOR;
header[7] = AMQP_PROTOCOL_VERSION_MINOR;
return header;
}
}
int amqp_send_header(amqp_connection_state_t state)
{
return write(state.sockfd,header(),8);
}
int amqp_send_header_to(amqp_connection_state_t state, int function(void* context, void* buffer, size_t count), void* context)
{
return fn(context,header(),8);
}
static 
{
    amqp_bytes_t sasl_method_name(amqp_sasl_method_enum method);
}
static 
{
    amqp_bytes_t sasl_response(amqp_pool_t* pool, amqp_sasl_method_enum method, va_list args);
}
amqp_boolean_t amqp_frames_enqueued(amqp_connection_state_t state)
{
return state.first_queued_frame !is null;
}
static 
{
    int wait_frame_inner(amqp_connection_state_t state, amqp_frame_t* decoded_frame);
}
int amqp_simple_wait_frame(amqp_connection_state_t state, amqp_frame_t* decoded_frame);
int amqp_simple_wait_method(amqp_connection_state_t state, amqp_channel_t expected_channel, amqp_method_number_t expected_method, amqp_method_t* output)
{
amqp_frame_t frame;
AMQP_CHECK_EOF_RESULT(amqp_simple_wait_frame(state,&frame));
amqp_assert(frame.channel == expected_channel,"Expected 0x%08X method frame on channel %d, got frame on channel %d",expected_method,expected_channel,frame.channel);
amqp_assert(frame.frame_type == AMQP_FRAME_METHOD,"Expected 0x%08X method frame on channel %d, got frame type %d",expected_method,expected_channel,frame.frame_type);
amqp_assert(frame.payload.method.id == expected_method,"Expected method ID 0x%08X on channel %d, got ID 0x%08X",expected_method,expected_channel,frame.payload.method.id);
*output = frame.payload.method;
return 1;
}
int amqp_send_method(amqp_connection_state_t state, amqp_channel_t channel, amqp_method_number_t id, void* decoded)
{
amqp_frame_t frame;
frame.frame_type = AMQP_FRAME_METHOD;
frame.channel = channel;
frame.payload.method.id = id;
frame.payload.method.decoded = decoded;
return amqp_send_frame(state,&frame);
}
amqp_rpc_reply_t amqp_simple_rpc(amqp_connection_state_t state, amqp_channel_t channel, amqp_method_number_t request_id, amqp_method_number_t expected_reply_id, void* decoded_request_method);
static 
{
    int amqp_login_inner(amqp_connection_state_t state, int channel_max, int frame_max, int heartbeat, amqp_sasl_method_enum sasl_method, va_list vl);
}
amqp_rpc_reply_t amqp_login(amqp_connection_state_t state, char* vhost, int channel_max, int frame_max, int heartbeat, amqp_sasl_method_enum sasl_method,...);
