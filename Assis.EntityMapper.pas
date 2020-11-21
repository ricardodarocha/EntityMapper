unit Assis.EntityMapper;

interface

uses FireDAC.Comp.Client, System.Generics.Collections, System.SysUtils,
  Data.DB;

type

  TEntityMapper<T: class, constructor> = class

    fConnection: TFdConnection;
    constructor Create(aConnection: TFdConnection);
    /// <remarks>
    ///   If Sql returns more then 1 record, just first one will be mapped
    /// </remarks>
    class function Open(aConnection: TFdConnection; aSQL: String; aParam: Array of variant): T; overload;
    class procedure Open(aConnection: TFdConnection; aSQL: String; aParam: Array of variant; var aInstance: T);  overload;
    /// <summary>
    ///   Instantiate new object of type T
    /// </summary>
    class function ReadDataset(aDataset: TDataset): T; overload;
    /// <summary>
    ///  It reads a dataset field by field and map to each property or class field with same name
    ///  To match table colums with different names use the anotation [map()]
    /// </summary>
    /// <remarks>
    ///   Use this version of Map to work with an alread created Instance of T
    /// </remarks>
    class procedure ReadDataset(aDataset: TDataset; var aInstance: T); overload;

    class procedure WriteDataset(var aInstance: T; var aDataset: TDataset);

    class function List(aConnection: TFdConnection; aSql: String ; aParam: Array of variant): TObjectList<T>;  overload;

    function Open(aSQL: String; aParam: Array of variant): T; overload;
    procedure Open(aSQL: String; aParam: Array of variant; var aInstance: T); overload;

    class Procedure Post(aConnection: TFdConnection; aMatchSql: String; aParam: array of variant; aInstance: T); overload;
    procedure Post(aMatchSql: String; aParam: array of variant; aInstance: T); overload;

    function List(aSql: String; aParam: Array of variant): TObjectList<T>; overload;

  private
    class procedure Iterate(aQuery: TFdQuery; aProc: TProc<TFdQuery>);
    class function TestConnection(aConnection: TFdConnection): boolean;
  end;

implementation

uses
  System.Rtti, Assis.RttiInterceptor, System.Classes, FireDAC.Stan.Param;

{ TEntityMapper<T> }

constructor TEntityMapper<T>.Create(aConnection: TFdConnection);
begin
  fConnection := aConnection;
end;

class function TEntityMapper<T>.TestConnection(aConnection: TFdConnection): boolean;
begin         
  result := false;
  if aConnection.Connected then Exit(true)
  else
    if aConnection.Offlined then
      begin
        try
          aConnection.Online;
          result := aConnection.Connected;
          aConnection.Offline;
        except
          exit(false);

        end;

      end;
end;
class function TEntityMapper<T>.Open(aConnection: TFdConnection; aSQL: String; aParam: array of variant): T;
begin
  result := T.Create;
  Open(aConnection, aSql, aParam, Result);
end;

class procedure TEntityMapper<T>.Open(aConnection: TFdConnection; aSQL: String; aParam: array of variant; var aInstance: T);
var
  VQuery: TFdQuery;

begin
  if not assigned(aConnection) then
    raise  Exception.Create('Conexão não atribuída'#13 + aConnection.Params.ToString);

  if not TestConnection(aConnection) then
    raise  Exception.Create('Conexão indisponível'#13 + aConnection.Params.ToString);
  vQuery := TFDQuery.Create(nil);
  try
    vQuery.Connection := aConnection;
    vQuery.Open(aSql, aParam);

    if VQuery.Active and (vQuery.RecordCount > 0) then
      ReadDataset(VQuery, aInstance)

    else raise Exception.Create(aInstance.classname + ' not found'#13'"'+aSql+'" returned no record');

  finally
    FreeAndNil(vQuery);
  end;
end;

class function TEntityMapper<T>.List(aConnection: TFdConnection; aSql: String; aParam: array of variant): TObjectList<T>;
var  
  aQuery: TFdQuery;
  Data: TObjectList<T>;
begin
  aQuery := TFDQuery.Create(nil);
  try
    aQuery.Connection := aConnection;
    aQuery.Open(aSql, aParam);
    if aQuery.RecordCount = 0 then
      Exit(nil)
    else
    begin
      Data := TObjectList<T>.Create;
      Iterate(aQuery, procedure (iQuery: TFdQuery)
        begin
          Data.Add(TEntityMapper<T>.ReadDataset(iQuery));
        end);
    end;

    result := Data;

  finally
    FreeAndNil(aQuery);
  end;

end;

class function TEntityMapper<T>.ReadDataset(aDataset: TDataset): T;
begin
  result := T.Create;
  ReadDataset(aDataset, Result);
end;

class procedure TEntityMapper<T>.ReadDataset(aDataset: TDataset; var aInstance: T);

var   LocalInstance: T;
begin
  //Don't move the dataset cursor, because it is used inside iterator

  LocalInstance := AInstance;  
  TRttiInterceptor<T>.mapProperty(aInstance, procedure (prop: TRttiProperty) begin
      if Prop.IsWritable then
      begin
        if aDataset.FindField(prop.Name) <> nil then
        begin
          try
            prop.SetValue(Pointer(LocalInstance), TValue.From(aDataset.FieldByName(prop.Name).Value));
          finally

          end;
        end;
      end;

    end);

  TRttiInterceptor<T>.mapField(aInstance, procedure (field: TRttiField) begin
      if aDataset.FindField(field.Name) <> nil then
      begin
        try
            field.SetValue(Pointer(LocalInstance), TValue.From(aDataset.FieldByName(field.Name).Value));
        finally

        end;
      end;
   end);
end;

class procedure TEntityMapper<T>.WriteDataset(var aInstance: T; var aDataset: TDataset);
var
  LocalInstance: T;
  LocalDataset: TDataset;
begin
  LocalInstance := aInstance;
  LocalDataset := aDataset;
  TRttiInterceptor<T>.mapProperty(aInstance, procedure (prop: TRttiProperty) begin
      if Prop.IsReadable then 
      begin
        if LocalDataset.FindField(prop.Name) <> nil then
        begin
          try
            if LocalDataset.FieldByName(prop.Name).FieldKind = fkData then
              LocalDataset.FieldByName(prop.Name).Value := prop.GetValue(Pointer(LocalInstance)).AsVariant;
          finally

          end;
        end;
      end;

    end);

  TRttiInterceptor<T>.mapField(aInstance, procedure (field: TRttiField) begin
      if LocalDataset.FindField(field.Name) <> nil then
      begin
        try
          if LocalDataset.FieldByName(field.Name).FieldKind = fkData then
            LocalDataset.FieldByName(field.Name).Value := field.GetValue(Pointer(LocalInstance)).AsVariant;
        finally

        end;
      end;
  end);


end;

function TEntityMapper<T>.List(aSql: String; aParam: array of variant): TObjectList<T>;
begin
  result := TEntityMapper<T>.List(fConnection, aSql, aParam);
end;

function TEntityMapper<T>.Open(aSQL: String; aParam: array of variant): T;
begin
  Result := TEntityMapper<T>.Open(fConnection, aSql, aParam);
end;


procedure TEntityMapper<T>.Open(aSQL: String; aParam: array of variant; var aInstance: T);
begin
  TEntityMapper<T>.Open(fConnection, aSql, aParam, aInstance);
end;

procedure TEntityMapper<T>.Post(aMatchSql: String; aParam: array of variant; aInstance: T);
begin
  TEntityMapper<T>.Post(fConnection, aMatchSql, aParam, aInstance);
end;

class procedure TEntityMapper<T>.Post(aConnection: TFdConnection; aMatchSql: String; aParam: array of variant; aInstance: T);
var
  aQuery: TFdQuery;
  aMessage: string;
begin
  aQuery:= TFdquery.Create(nil);    
  aMessage := '';
  try
    aQuery.Connection := aConnection;
    aQuery.Open(aMatchSql, aParam);

    if aQuery.RecordCount = 0 then
      aQuery.Insert;

    if aQuery.RecordCount = 1 then
      aQuery.Edit;

    if aQuery.RecordCount > 1 then
      aMessage := 'the MatchSQL has returned ' + aQuery.RecordCount.ToString + ' records. Just first one has been updated';
                                                                                                                        
    try  
      WriteDataset(aInstance, TDataset(aQuery));
    except
      on e: Exception do
        aMessage := e.Message;

    end;
    aQuery.Post;

  finally
    freeAndNil(aQuery);
    if aMessage <> '' then
      raise Exception.Create(aMessage);

  end;

end;

//Design pattern: Iterator
class procedure TEntityMapper<T>.Iterate(aQuery: TFdQuery; aProc: TProc<TFdQuery>);
begin
  aQuery.First;
  while not aQuery.Eof do
  begin
    aProc(aQuery);
    aQuery.Next;
  end;
end;


end.
