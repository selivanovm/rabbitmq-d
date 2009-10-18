#!/bin/sh
dmd -version=Tango -Iexport /usr/include/d/tango-dmd/tango/net/InternetAddress /usr/include/d/tango-dmd/tango/net/Socket /usr/include/d/tango-dmd/tango/stdc/stdarg.d /usr/include/d/tango-dmd/tango/stdc/errno.d examples/example_utils.d examples/amqp_sendstring.d librabbitmq.a -O -release -ofSendString

dmd -version=Tango -Iexport /usr/include/d/tango-dmd/tango/net/InternetAddress /usr/include/d/tango-dmd/tango/net/Socket /usr/include/d/tango-dmd/tango/stdc/stdarg.d /usr/include/d/tango-dmd/tango/stdc/errno.d examples/example_utils.d examples/amqp_listen.d librabbitmq.a -O -release -ofListen


rm *.o