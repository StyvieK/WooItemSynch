tableextension 50100 "Sales & Rec Setup" extends "Sales & Receivables Setup"
{
    fields
    {
        field(50194; "Base URL"; Text[250])
        {
            Caption = 'Base URL ';
            DataClassification = ToBeClassified;
        }
        field(50195; "Consumer Token"; Text[80])
        {
            Caption = 'Consumer Token';
            DataClassification = ToBeClassified;
        }
        field(50196; "Consumer Secret"; Text[80])
        {
            Caption = 'Consumer Secret';
            DataClassification = ToBeClassified;
        }
        field(50197; "Last Synch"; DateTime)
        {
            Caption = 'Last Synch';
            DataClassification = ToBeClassified;
        }
    }
}
