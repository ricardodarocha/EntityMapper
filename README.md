# EntityMapper

An open-source ORM for Delphi with both-side mapper Database to Object and Object to Database

# Dependencies

It uses https://github.com/ricardodarocha/rttiInterceptor and https://github.com/ricardodarocha/SqlExtrator to simplicity

# Example

```delphi
{First step - Add a FdConnection and Configure the database connection}

{Step 2 - Declare models that represent your database}

  TUser = class
    ID: Integer;
    Name: string;
    Email: string;
    Password: string;
  end;
  
  var UserMap: TUser;

{Step 3 - Generate the CREATE TABLE sql using TSqlExtractor<TUser>}
UserMap := TUser.Create;
FdConnection1.ExecSql(TSqlExtractor<TUser>.ExtractCreateTableSql(UserMap));

{Step 4 - Open a FdQuery with live data to bind a DbGrid using a Datasource - The classical RAD}
FdQuery1.Open(TSqlExtractor<TUser>.ExtractSelectSql(UserMap, []))

{Step 5 - Bring data into User Instance using EntityMapper}
TEntityMapper<TUser>.Open(SqlExtractor<TUser>.ExtractSelectSql(UserMap, []), UserMap);

{Step 6 - Manage a List of Objects into a Listbox}
procedure LoadData(Sender: TObject);
var
  aUser: TUser;
  I: Integer;
begin
  ListBox1.Clear;

  if assigned(UserList) then
    FreeAndNil(UserList);

  UserList := TEntityMapper<TUser>.List(FDConnection1, TSqlExtractor<TUser>.ExtractSelectSql(UserMap, []), []);
  for aUser in UserList do
    ListBox1.AddItem(aUser.ID.ToString + ' - ' + aUser.Name, aUser);
end;

{Step 7 : Persit data of TUser into Database}
procedure Post(Sender: Tobject);
var
  Sql: String;
  CurrentUser: TUser;
begin
    CurrentUser := TUser.Create;
    try
      With currentUser do
      begin
        ID := StrToIntDef(edtUserId.Text, 0);
        Name := edtUserName.Text;
        Email := edtUserEmail.Text;
        Password := Md0(edtUserPassword.Text);
      end;

      Sql := TSqlExtractor<TUser>.ExtractSelectSql(UserMap, ['id']);
      TEntityMapper<TUser>.Post(FdConnection1, Sql, [Currentuser.Id], CurrentUser);
      Showmessage('User was recorded into database'#13#13);
      LoadData(sender);

    finally
      freeAndNil(CurrentUser);
    end;


```
