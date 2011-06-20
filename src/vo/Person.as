package vo
{
	
	[Bindable]
	[RemoteClass(alias="hoytstaff.cfc.person")]
	[Entity]
	public class Person
	{
		[Id]
		[GeneratedValue(strategy="INCREMENT",initialValue=1,incrementBy=1)]
		public var personID:int;
		public var firstName:String;
		public var lastName:String;
		public var blog:String;
		public var twitter:String;
		public var location:String;
		
		public function Person()
		{
		}
	}
}