const INITIAL_TABLE_SIZE = 16;

import tango.io.Stdout;
import tango.stdc.stdlib;
import tango.stdc.string;

import amqp_base;
import amqp;
import amqp_private;
import amqp_mem;

int amqp_decode_table(amqp_bytes_t encoded,
		      amqp_pool_t *pool,
		      amqp_table_t *output,
		      int *offsetptr)
{

  Stdout.format("amqp_decode_table #1").newline;

  int result_ = -1;

  int offset = *offsetptr;
  uint32_t tablesize = D_32(encoded, offset);
  int num_entries = 0;
  amqp_table_entry_t *entries = cast(amqp_table_entry_t *)malloc(INITIAL_TABLE_SIZE * amqp_table_entry_t.sizeof);
  int allocated_entries = INITIAL_TABLE_SIZE;
  int limit;

  if (entries is null) {
    return -ENOMEM;
  }

  offset += 4;
  limit = offset + tablesize;

  Stdout.format("amqp_decode_table #2").newline;

  while (offset < limit) {
    size_t keylen;
    amqp_table_entry_t *entry;

    keylen = D_8(encoded, offset);
    offset++;

    if (num_entries >= allocated_entries) {
      void *newentries;
      allocated_entries = allocated_entries * 2;
      newentries = realloc(entries, allocated_entries * amqp_table_entry_t.sizeof);
      if (newentries is null) {
	free(entries);
	return -ENOMEM;
      }
      entries = cast(amqp_table_entry_t *)newentries;
    }
    entry = &entries[num_entries];

    Stdout.format("amqp_decode_table #3").newline;

    (*entry).key.len = keylen;
    (*entry).key.bytes = D_BYTES(encoded, offset, keylen);
    offset += keylen;

    (*entry).kind = D_8(encoded, offset);
    offset++;

    switch ((*entry).kind) {
      case 'S':
	(*entry).value.bytes.len = D_32(encoded, offset);
	offset += 4;
	(*entry).value.bytes.bytes = D_BYTES(encoded, offset, (*entry).value.bytes.len);
	offset += (*entry).value.bytes.len;
	break;
      case 'I':
	(*entry).value.i32 = cast(int32_t) D_32(encoded, offset);
	offset += 4;
	break;
      case 'D':
	(*entry).value.decimal.decimals = D_8(encoded, offset);
	offset++;
	(*entry).value.decimal.value = D_32(encoded, offset);
	offset += 4;
	break;
      case 'T':
	(*entry).value.u64 = D_64(encoded, offset);
	offset += 8;
	break;
      case 'F':
	result_ = amqp_decode_table(encoded, pool, &((*entry).value.table), &offset);
	if(result_ < 0)
	  return result_;
	break;
      default:
	return -EINVAL;
    }

    num_entries++;
  }

  Stdout.format("amqp_decode_table #4").newline;

  (*output).num_entries = num_entries;
  (*output).entries = cast(amqp_table_entry_t *)amqp_pool_alloc(pool, num_entries * amqp_table_entry_t.sizeof);
  memcpy((*output).entries, entries, num_entries * amqp_table_entry_t.sizeof);

  *offsetptr = offset;
  Stdout.format("amqp_decode_table #5").newline;
  return 0;
}

int amqp_encode_table(amqp_bytes_t encoded,
		      amqp_table_t *input,
		      int *offsetptr)
{
  int offset = *offsetptr;
  int tablesize_offset = offset;
  int i;
  int result_ = -1;

  offset += 4; /* skip space for the size of the table to be filled in later */

  for (i = 0; i < (*input).num_entries; i++) {
    amqp_table_entry_t *entry = &((*input).entries[i]);

    E_8(encoded, offset, (*entry).key.len);
    offset++;

    E_BYTES(encoded, offset, (*entry).key.len, (*entry).key.bytes);
    offset += (*entry).key.len;

    E_8(encoded, offset, (*entry).kind);
    offset++;

    switch ((*entry).kind) {
      case 'S':
	E_32(encoded, offset, (*entry).value.bytes.len);
	offset += 4;
	E_BYTES(encoded, offset, (*entry).value.bytes.len, (*entry).value.bytes.bytes);
	offset += (*entry).value.bytes.len;
	break;
      case 'I':
	E_32(encoded, offset, cast(uint32_t) (*entry).value.i32);
	offset += 4;
	break;
      case 'D':
	E_8(encoded, offset, (*entry).value.decimal.decimals);
	offset++;
	E_32(encoded, offset, (*entry).value.decimal.value);
	offset += 4;
	break;
      case 'T':
	E_64(encoded, offset, (*entry).value.u64);
	offset += 8;
	break;
      case 'F':
	result_ = amqp_encode_table(encoded, &((*entry).value.table), &offset);
	if(result_ < 0)
	  return result_;
	break;
      default:
	return -EINVAL;
    }
  }

  E_32(encoded, tablesize_offset, (offset - *offsetptr - 4));
  *offsetptr = offset;
  return 0;
}

int amqp_table_entry_cmp(void *entry1, void *entry2) {
  amqp_table_entry_t *p1 = cast(amqp_table_entry_t *) entry1;
  amqp_table_entry_t *p2 = cast(amqp_table_entry_t *) entry2;

  int d;
  int minlen;

  minlen = (*p1).key.len;
  if ((*p2).key.len < minlen) minlen = (*p2).key.len;

  d = memcmp((*p1).key.bytes, (*p2).key.bytes, minlen);
  if (d != 0) {
    return d;
  }

  return (*p1).key.len - (*p2).key.len;
}
