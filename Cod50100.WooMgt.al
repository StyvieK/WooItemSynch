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
        RstHlp: Codeunit "REST Helper WLD";
        SRSetup: Record "Sales & Receivables Setup";
    begin
        SRSetup.Get();
        ItemAsJson.Add('id', Item."Woo Commerce Id");
        ItemAsJson.Add('name', Item.Description);
        ItemAsJson.Add('regular_price', Format(Item."Unit Price"));
        ItemAsJson.AsToken().WriteTo(ItemJsonAsText);

        RstHlp.Initialize('POST', StrSubstNo('%1wp-json/wc/v3/products/%2', SRSetup."Base URL", Item."Woo Commerce Id"));
        RstHlp.AddBody(ItemJsonAsText);

        RstHlp.AddRequestHeader('Authorization', GetHttpBasicAuthHeader(SRSetup."Consumer Secret", SRSetup."Consumer Token"));
        RstHlp.SetContentType('application/json');
        RstHlp.Send();
    end;

    local procedure GetAllProduct(WCS: Record "Sales & Receivables Setup") itemArray: JsonArray
    var
        RstHlp: Codeunit "REST Helper WLD";
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

        RstHlp.Initialize('GET', WCS."Base URL" + 'wp-json/wc/v3/products/?per_page=100&page=1');
        RstHlp.AddRequestHeader('Authorization', GetHttpBasicAuthHeader(wcs."Consumer Secret", wcs."Consumer Token"));
        if not RstHlp.Send() then
            RstHlp.GetErrorResponse();

        itemArray.ReadFrom(RstHlp.GetResponseContentAsText());

        XTotalPagesString := GetHeader(RstHlp.GetResponseHeaders(), 'X-WP-TotalPages');
        //XTotalPagesString := '2';//debug
        if Evaluate(XTotalPages, XTotalPagesString) then begin
            for j := 2 to XTotalPages do begin
                dl.Update();
                clear(RstHlp);
                RstHlp.Initialize('GET', strsubstno(WCS."Base URL" + 'wp-json/wc/v3/products/?per_page=100&page=%1', j));
                RstHlp.AddRequestHeader('Authorization', GetHttpBasicAuthHeader(wcs."Consumer Secret", wcs."Consumer Token"));
                if not RstHlp.Send() then
                    RstHlp.GetErrorResponse();

                clear(nextArray);
                nextArray.ReadFrom(RstHlp.GetResponseContentAsText());
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


}
