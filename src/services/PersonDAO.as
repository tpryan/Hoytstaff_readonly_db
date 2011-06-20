package services
{
	import events.DAOResultEvent;
	
	import flash.data.SQLConnection;
	import flash.data.SQLResult;
	import flash.data.SQLStatement;
	import flash.errors.SQLError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.SQLEvent;
	import flash.filesystem.File;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;
	
	import vo.Person;
	
	[Event(name="result", type="events.DAOResultEvent")]
	[Event(name="ready", type="flash.events.Event")]

	public class PersonDAO extends EventDispatcher
	{
		
		
		private var _conn:SQLConnection = new SQLConnection();
		public var lastResult:Object;
		
		
		public function PersonDAO()
		{
			
			var dbFile:File = File.applicationDirectory.resolvePath("hoytstaff.db");
			_conn.openAsync(dbFile);
			_conn.addEventListener(SQLEvent.OPEN, handleOpen);
			
		}
		
		protected function handleOpen(event:SQLEvent):void
		{
			createTable();
			synchFromRemote();
			
		}		
		
		private function createTable():void
		{
			var createStmt:SQLStatement = new SQLStatement();
			createStmt.sqlConnection = _conn;
			var sql:String = "";
			sql += "CREATE TABLE IF NOT EXISTS person (";
			sql += "	personID		INTEGER PRIMARY KEY,";
			sql += "	firstName	TEXT,";
			sql += "	lastName	TEXT,";
			sql += "	blog	TEXT,";
			sql += "	twitter	TEXT,";
			sql += "	location		TEXT";
			sql += ")";
			createStmt.text = sql;
			
			try
			{
				createStmt.execute();
			}
			catch (error:SQLError)
			{
				trace("Error creating table");
				trace("CREATE TABLE error:", error);
				trace("error.message:", error.message);
				trace("error.details:", error.details);
			}
		}
		
		protected function handleReady(event:SQLEvent):void
		{
			dispatchEvent(new Event("ready"));
			
		}
		
		public function synchFromRemote():void{
			var personService:RemoteObject = new RemoteObject();
			personService.destination="ColdFusion";
			personService.endpoint = "http://centaur.dev/flex2gateway/";
			personService.source="hoytstaff.services.personService";
			personService.addEventListener(ResultEvent.RESULT, handleListFromNetwork);
			personService.list();
		}
		
		protected function handleListFromNetwork(event:ResultEvent):void
		{
			var resultArray:Array = event.result as Array;
			
			var results:ArrayCollection  = new ArrayCollection(resultArray);
			
			for (var i:int = 0; i < results.length; i++){
				var person:Person = results.getItemAt(i) as Person;
				upsert(person);
			}
			handleReady(null);
			
		}
		
		public function upsert(person:Person):void {
			var query:String = "INSERT OR REPLACE INTO person (" + 
				"personID, " +
				"firstName, " + 
				"lastName, " + 
				"blog, " +
				"twitter, " +
				"location)" + 
				"VALUES ( " + 
				":personID, " +
				":firstName, " + 
				":lastName, " + 
				":blog, " +
				":twitter, " +
				":location)";
			
			var sqlInsert:SQLStatement = new SQLStatement();
			sqlInsert.sqlConnection = _conn;
			//sqlInsert.addEventListener( SQLEvent.RESULT, onSQLSave );
			//sqlInsert.addEventListener( SQLErrorEvent.ERROR, onSQLError );				
			
			sqlInsert.text = query;
			sqlInsert.parameters[":personID"] = person.personID;
			sqlInsert.parameters[":firstName"] = person.firstName;
			sqlInsert.parameters[":lastName"] = person.lastName;
			sqlInsert.parameters[":blog"] = person.blog;
			sqlInsert.parameters[":twitter"] = person.twitter;
			sqlInsert.parameters[":location"] = person.location;
			
			sqlInsert.execute();	
		}
		
		public function list():void{
			var query:String = "";
			
			query = "SELECT * " + 
				"FROM  person " +
				"ORDER BY personID";
			
			var sqlSelect:SQLStatement = new SQLStatement();
			sqlSelect.sqlConnection = _conn;
			
			sqlSelect.text = query;
			sqlSelect.addEventListener(SQLEvent.RESULT, handleList);
			sqlSelect.execute();
			
		}
		
		protected function handleList(event:SQLEvent):void
		{
			var result:SQLResult = event.currentTarget.getResult();
			
			var ac:ArrayCollection = new ArrayCollection();
			if (result.data != null){
				for (var i:int = 0; i < result.data.length; i++){
					var person:Person = castPlainObjectAsPerson(result.data[i]);
					ac.addItem(person);
				}
			}
			
			lastResult = ac;
			
			var resultEvent:DAOResultEvent = new DAOResultEvent("result");
			resultEvent.result = ac;
			dispatchEvent(resultEvent);
			
		}
		
		private function castPlainObjectAsPerson(obj:Object):Person{
			var result:Person = new Person();
			result.firstName = obj.firstName;
			result.lastName = obj.lastName;
			result.blog = obj.blog;
			result.twitter = obj.twitter;
			result.location = obj.location;
			
			return result;
		}
	
	}
}