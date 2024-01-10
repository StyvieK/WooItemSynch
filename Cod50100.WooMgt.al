codeunit 50100 WooMgt
{
    trigger OnRun()
    var
        Jsongroups: JsonArray;
        jsongroup: JsonObject;
        CurrentNo: Text;
        SKU: JsonToken;
        ID: JsonToken;
        Description: JsonToken;
        ItemId: Integer;
        SRSetup: Record "Sales & Receivables Setup";
        i: Integer;
        SkuText: Text;
        Item: Record Item;
        jtoken: JsonToken;
    begin
        SRSetup.Get();
        jsonGroups := GetAllProduct(SRSetup);
        for i := 0 to jsonGroups.Count() - 1 do begin

            jsonGroups.Get(i, jtoken);
            jsongroup := jtoken.AsObject();
            jsongroup.Get('sku', SKU);
            jsongroup.Get('id', ID);
            ItemId := ID.AsValue().AsInteger();

            SkuText := SKU.AsValue().AsText();

            Item.SetRange("No.", SkuText);
            if item.FindSet() then
                repeat
                    Item."Woo Commerce Id" := ItemId;
                    Item.Modify();
                until item.Next() = 0;
        end;
    end;

    [EventSubscriber(ObjectType::Table, Database::Item, 'OnAfterValidateEvent', 'Unit Price', false, false)]
    local procedure OnModifyGenJournalLine(var Rec: Record Item; var xRec: Record Item; CurrFieldNo: Integer)
    begin
        if Rec."Synch To Woo Commerce" then begin
            PostItem(Rec);
        end;
    end;

    local procedure PostItem(Item: Record Item)
    var
        ItemAsJson: JsonObject;

        ItemJsonAsText: text;

        SRSetup: Record "Sales & Receivables Setup";
    begin
        SRSetup.Get();
        ItemAsJson.Add('id', Item."Woo Commerce Id");
        ItemAsJson.Add('name', Item.Description);
        ItemAsJson.Add('regular_price', Format(Item."Unit Price"));
        ItemAsJson.AsToken().WriteTo(ItemJsonAsText);

        Initialize('POST', StrSubstNo('%1wp-json/wc/v3/products/%2', SRSetup."Base URL", Item."Woo Commerce Id"));
        AddBody(ItemJsonAsText);

        AddRequestHeader('Authorization', GetHttpBasicAuthHeader(SRSetup."Consumer Secret", SRSetup."Consumer Token"));
        SetContentType('application/json');
        Send();
    end;

    local procedure GetAllProduct(WCS: Record "Sales & Receivables Setup") itemArray: JsonArray
    var

        RespnseHeader: HttpHeaders;
        Continue: Boolean;
        NextLink: text;
        nextArray: JsonArray;
        XTotalPages: Integer;
        XTotalPagesString: Text;
        j: Integer;
        i: Integer;
        jToken: JsonToken;
        Dl: Dialog;
    begin
        j := 1;
        Dl.Open('Fetching data , page #1', j);

        Initialize('GET', WCS."Base URL" + 'wp-json/wc/v3/products/?per_page=100&page=1');
        AddRequestHeader('Authorization', GetHttpBasicAuthHeader(wcs."Consumer Secret", wcs."Consumer Token"));
        if not Send() then
            GetErrorResponse();

        itemArray.ReadFrom(GetResponseContentAsText());

        XTotalPagesString := GetHeader(GetResponseHeaders(), 'X-WP-TotalPages');
        //XTotalPagesString := '2';//debug
        if Evaluate(XTotalPages, XTotalPagesString) then begin
            for j := 2 to XTotalPages do begin
                dl.Update();
                ClearRstHlp;
                Initialize('GET', strsubstno(WCS."Base URL" + 'wp-json/wc/v3/products/?per_page=100&page=%1', j));
                AddRequestHeader('Authorization', GetHttpBasicAuthHeader(wcs."Consumer Secret", wcs."Consumer Token"));
                if not Send() then
                    GetErrorResponse();

                clear(nextArray);
                nextArray.ReadFrom(GetResponseContentAsText());
                for i := 0 to nextArray.Count() - 1 do begin
                    nextArray.Get(i, jToken);
                    itemArray.Add(jToken);

                end;
            end;
        end;

        Dl.close;
    end;

    procedure GetHeader(h: HttpHeaders; k: Text) t: Text
    begin
        if TryGetHeader(h, k, t) then;
    end;

    [TryFunction]
    local procedure TryGetHeader(h: HttpHeaders; k: Text; var t: Text)
    var
        a: array[1] of Text;
    begin
        // Note, it's not possible yet to receive a List of all headers (https://github.com/microsoft/AL/issues/6319)
        if not h.Contains(k) then
            exit;
        if not h.GetValues(k, a) then
            exit;
        t := a[1];
    end;

    local procedure GetHttpBasicAuthHeader(UserName: Text[50]; Password: Text[50]) AuthString: Text
    var
        BaseHelper: Codeunit "Base64 Convert";
        PriceListLine: Record "Price List Line";

    begin
        AuthString := STRSUBSTNO('%1:%2', UserName, Password);
        AuthString := BaseHelper.ToBase64(AuthString);
        AuthString := STRSUBSTNO('Basic %1', AuthString);
    end;

    procedure InitializeJsonObjectFromText(JSONText: Text)
    begin
        if not JsonObjectVar.ReadFrom(JSONText) then
            Error('Invalid JSON Text \ %1', JSONText);
    end;

    procedure InitializeJsonObjectFromToken(Token: JsonToken)
    begin
        JsonObjectVar := Token.AsObject();
    end;

    procedure GetJsonObject(): JsonObject
    begin
        exit(jsonObjectVar);
    end;

    procedure GetJsonToken(JsonObject: JsonObject; TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure GetJsonToken(TokenKey: text) JsonToken: JsonToken
    begin
        if not JsonObjectVar.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure GetJsonTokenAsValue(JsonObject: JsonObject; TokenKey: text) JsonValue: JsonValue
    var
        JsonToken: JsonToken;
    begin
        if not JsonObject.Get(TokenKey, JsonToken) then
            Error('Could not find a token with key %1', TokenKey);
        JsonValue := JsonToken.AsValue();
    end;

    procedure SelectJsonToken(Path: text) JsonToken: JsonToken
    begin
        if not JsonObjectVar.SelectToken(Path, JsonToken) then
            Error('Could not find a token with path %1', Path);
    end;

    procedure SelectJsonToken(JsonObject: JsonObject; Path: text) JsonToken: JsonToken
    begin
        if not JsonObject.SelectToken(Path, JsonToken) then
            Error('Could not find a token with path %1', Path);
    end;

    procedure SetValue("Key": Text; "Value": text)
    begin
        if JsonObjectVar.Contains("Key") then
            JsonObjectVar.Replace("Key", "Value")
        else
            JsonObjectVar.Add("Key", "Value");

    end;

    procedure Initialize(Method: Text; URI: Text);
    begin
        WebRequest.Method := Method;
        WebRequest.SetRequestUri(URI);

        WebRequest.GetHeaders(WebRequestHeaders);
    end;

    procedure AddRequestHeader(HeaderKey: Text; HeaderValue: Text)
    begin
        RestHeaders.AppendLine(HeaderKey + ': ' + HeaderValue);

        WebRequestHeaders.Add(HeaderKey, HeaderValue);
    end;

    procedure AddBody(Body: Text)
    begin
        WebContent.WriteFrom(Body);

        ContentTypeSet := true;
    end;

    procedure SetContentType(ContentType: Text)
    begin
        CurrentContentType := ContentType;

        webcontent.GetHeaders(WebContentHeaders);
        if WebContentHeaders.Contains('Content-Type') then
            WebContentHeaders.Remove('Content-Type');
        WebContentHeaders.Add('Content-Type', ContentType);
    end;

    procedure Send() SendSuccess: Boolean
    var
        StartDateTime: DateTime;
        TotalDuration: Duration;
    begin
        if ContentTypeSet then
            WebRequest.Content(WebContent);

        OnBeforeSend(WebRequest, WebResponse);
        StartDateTime := CurrentDateTime();
        SendSuccess := WebClient.Send(WebRequest, WebResponse);
        TotalDuration := CurrentDateTime() - StartDateTime;
        OnAfterSend(WebRequest, WebResponse);

        if SendSuccess then
            if not WebResponse.IsSuccessStatusCode() then
                SendSuccess := false;

        //Log(StartDateTime, TotalDuration);
    end;

    procedure GetResponseContentAsText() ResponseContentText: Text
    var
        RestBlob: Codeunit "Temp Blob";
        Instr: Instream;
    begin

        RestBlob.CreateInStream(Instr);
        WebResponse.Content().ReadAs(ResponseContentText);
    end;

    procedure GetResponseHeaders(): HttpHeaders
    begin
        exit(WebResponse.Headers())
    end;

    procedure GetResponseReasonPhrase(): Text
    begin
        exit(WebResponse.ReasonPhrase());
    end;

    procedure GetErrorResponse(): Text
    begin
        error('Error:' + Format(GetHttpStatusCode()) + GetResponseContentAsText());
    end;

    procedure GetHttpStatusCode(): Integer
    begin
        exit(WebResponse.HttpStatusCode());
    end;

    procedure ClearRstHlp()
    begin
        clear(WebClient);
        clear(WebRequest);
        clear(WebResponse);
        clear(WebRequestHeaders);
        clear(WebContentHeaders);
        clear(WebContent);
        clear(CurrentContentType);
        clear(RestHeaders);
        clear(ContentTypeSet);
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeSend(WebRequest: HttpRequestMessage; WebResponse: HttpResponseMessage)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterSend(WebRequest: HttpRequestMessage; WebResponse: HttpResponseMessage)
    begin
    end;

    var
        WebClient: HttpClient;
        WebRequest: HttpRequestMessage;
        WebResponse: HttpResponseMessage;
        WebRequestHeaders: HttpHeaders;
        WebContentHeaders: HttpHeaders;
        WebContent: HttpContent;
        CurrentContentType: Text;
        RestHeaders: TextBuilder;
        ContentTypeSet: Boolean;
        JsonObjectVar: JsonObject;

}
