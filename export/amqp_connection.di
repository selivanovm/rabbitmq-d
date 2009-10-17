// D import file generated from 'src/amqp_connection.d'
import tango.stdc.stdlib;
import tango.stdc.posix.unistd;
import tango.io.Stdout;
import amqp_base;
import amqp_private;
import amqp;
import amqp_mem;
import amqp_framing;
import amqp_framing_;
const INITIAL_FRAME_POOL_PAGE_SIZE = 65536;
const INITIAL_DECODING_POOL_PAGE_SIZE = 131072;
const INITIAL_INBOUND_SOCK_BUFFER_SIZE = 131072;
public
{
    static 
{
    void ENFORCE_STATE(amqp_connection_state_t* statevec, int statenum)
{
amqp_connection_state_t* _check_state = statevec;
int _wanted_state = statenum;
amqp_assert((*_check_state).state == _wanted_state,"Programming error: invalid AMQP connection state: expected %d, got %d",_wanted_state,(*_check_state).state);
}
}
}
amqp_connection_state_t* amqp_new_connection();
int amqp_get_sockfd(amqp_connection_state_t* state)
{
return (*state).sockfd;
}
void amqp_set_sockfd(amqp_connection_state_t* state, int sockfd)
{
(*state).sockfd = sockfd;
}
int amqp_tune_connection(amqp_connection_state_t* state, int channel_max, int frame_max, int heartbeat);
int amqp_get_channel_max(amqp_connection_state_t* state)
{
return (*state).channel_max;
}
void amqp_destroy_connection(amqp_connection_state_t* state)
{
empty_amqp_pool(&(*state).frame_pool);
empty_amqp_pool(&(*state).decoding_pool);
free((*state).outbound_buffer.bytes);
free((*state).sock_inbound_buffer.bytes);
free(state);
}
static 
{
    void return_to_idle(amqp_connection_state_t* state)
{
(*state).inbound_buffer.bytes = null;
(*state).inbound_offset = 0;
(*state).target_size = HEADER_SIZE;
(*state).state = amqp_connection_state_enum.CONNECTION_STATE_IDLE;
}
}
int amqp_handle_input(amqp_connection_state_t* state, amqp_bytes_t received_data, amqp_frame_t* decoded_frame);
amqp_boolean_t amqp_release_buffers_ok(amqp_connection_state_t* state)
{
return cast(amqp_boolean_t)((*state).state == amqp_connection_state_enum.CONNECTION_STATE_IDLE && (*state).first_queued_frame is null);
}
void amqp_release_buffers(amqp_connection_state_t* state)
{
ENFORCE_STATE(state,amqp_connection_state_enum.CONNECTION_STATE_IDLE);
amqp_assert((*state).first_queued_frame is null,"Programming error: attempt to amqp_release_buffers while waiting events enqueued");
recycle_amqp_pool(&(*state).frame_pool);
recycle_amqp_pool(&(*state).decoding_pool);
}
void amqp_maybe_release_buffers(amqp_connection_state_t* state);
static 
{
    int inner_send_frame(amqp_connection_state_t* state, amqp_frame_t* frame, amqp_bytes_t* encoded, int* payload_len);
}
int amqp_send_frame(amqp_connection_state_t* state, amqp_frame_t* frame);
int amqp_send_frame_to(amqp_connection_state_t* state, amqp_frame_t* frame, int function(void* context, void* buffer, size_t count) fn, void* context);
