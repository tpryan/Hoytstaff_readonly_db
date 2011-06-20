package events
{
	import flash.events.Event;
	
	public class DAOResultEvent extends Event
	{
		
		public var result:Object;
		
		public function DAOResultEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
	}
}