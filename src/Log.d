/**
 License:                GNU General Public License version 3 (see license.txt, also available online at http://www.gnu.org/licenses/gpl-3.0.html)
 Authors:                OrbitalLab (http://www.orbitallab.ru/dee0xd/), 2008

 File:                   log.d
 Description:    some logging stuff
 Date:                   09.12.2008 by Digited
 **/
module Log;

private import tango.util.log.Log;

private import tango.time.Clock;
private import tango.time.WallClock;
private import tango.util.log.AppendFile;
private import tango.util.log.AppendConsole;
private import tango.text.convert.Layout;

package
{
	Logger log;
	Layout!(char) _layout;
}

private
{
	AppendFile _logFile;

	static this()
	{
		_layout = new Layout!(char);

		//-------------------- log -------------------------------------------------

		// all loggers, as children of root, print also to console by default
		//                Log.root.add( new AppendConsole( new VerySimpleLayout ) );

		// trace is the lowest level, so all levels are logged
		Log.root.level(Logger.Level.Trace);

		log = Log.getLogger("trace");

		_logFile = new AppendFile("rabbitmq-client.log", new VerySimpleLayout);
		log.add(_logFile);
	}

	static ~this()
	{
		_logFile.close;
		delete log;
	}

	class VerySimpleLayout: Appender.Layout
	{
		private:
			bool localTime;

			char[] convert(char[] tmp, long i)
			{
				return Integer.formatter(tmp, i, 'u', '?', 8);
			}

		public:
			this(bool localTime = true)
			{
				this.localTime = localTime;
			}

			void format(LogEvent event, size_t delegate(void[]) dg)
			{
				char[] level = event.levelName;

				char[13] tmp = void;
				char[256] tmp2 = void;

				// convert time to field values
				auto tm = event.time;
				auto dt = (localTime) ? WallClock.toDate(tm) : Clock.toDate(tm);

				dg(_layout("{}.{} {}:{}:{},{} ---> {}", convert(tmp[0 .. 2], dt.date.month), convert(tmp[2 .. 4], dt.date.day), convert(tmp[4 .. 6],
						dt.time.hours), convert(tmp[6 .. 8], dt.time.minutes), convert(tmp[8 .. 10], dt.time.seconds), convert(tmp[10 .. 13],
						dt.time.millis), event.toString));
			}

			void format(LogEvent event, void delegate(void[]) dg)
			{
				char[] level = event.levelName;

				char[13] tmp = void;
				char[256] tmp2 = void;

				// convert time to field values
				auto tm = event.time;
				auto dt = (localTime) ? WallClock.toDate(tm) : Clock.toDate(tm);

				dg(_layout("{}.{} {}:{}:{},{} ---> {}", convert(tmp[0 .. 2], dt.date.month), convert(tmp[2 .. 4], dt.date.day), convert(tmp[4 .. 6],
						dt.time.hours), convert(tmp[6 .. 8], dt.time.minutes), convert(tmp[8 .. 10], dt.time.seconds), convert(tmp[10 .. 13],
						dt.time.millis), event.toString));
			}
	}
}
