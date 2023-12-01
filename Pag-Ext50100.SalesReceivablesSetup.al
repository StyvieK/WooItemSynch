pageextension 50100 "Sales & Receivables Setup" extends "Sales & Receivables Setup"
{
    layout
    {
        addlast(content)
        {
            group(WooCommerce)
            {
                field("Base URL"; Rec."Base URL")
                {
                    ApplicationArea = All;
                }
                field("Consumer Secret"; Rec."Consumer Secret")
                {
                    ApplicationArea = All;
                }
                field("Consumer Token"; Rec."Consumer Token")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
