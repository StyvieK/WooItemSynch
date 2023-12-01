pageextension 50158 "Item Extension" extends "Item Card"
{
    layout
    {
        addlast(content)
        {
            group(WooCommerce)
            {
                field("Synch To Woo Commerce"; Rec."Synch To Woo Commerce")
                {
                    ApplicationArea = All;
                    trigger OnValidate()
                    var
                        Woo: Codeunit WooMgt;
                    begin
                        Rec.TestField("Woo Commerce Id");

                    end;

                }
                field("Woo Commerce Id"; Rec."Woo Commerce Id")
                {
                    ApplicationArea = All;
                    Editable = false;

                }
            }
        }
    }

    actions
    {
        addlast(Functions)
        {
            action(SynchWoo)
            {
                Image = OutlookSyncSubFields;
                trigger OnAction()
                var
                    Woo: Codeunit WooMgt;
                begin
                    Woo.Run();
                end;
            }
        }
    }

}
