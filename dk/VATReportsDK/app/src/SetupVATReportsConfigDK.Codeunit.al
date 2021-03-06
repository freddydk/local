// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 13691 "Setup VAT Reports Config DK"
{
    var
        MSECSLDKTok: Label 'ECSL-DK', Locked = true;
        NewFileExport2022ReportMsg: Label 'The Intrastat report for the calendar year 2022 is now available. To use it, open the VAT Reports Configuration page. In the line where the VAT Report Type field is set to Intrastat Report, set the Content Codeunit ID field to 0.';
        OpenVATReportConfigMsg: Label 'Open the VAT Reports Configuration page.';

    [EventSubscriber(ObjectType::Page, Page::"ECSL Report", 'OnOpenPageEvent', '', false, false)]
    local procedure ConfigureECSL();
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"EC Sales List");
        VATReportsConfiguration.SetRange("VAT Report Version", MSECSLDKTok);
        if VATReportsConfiguration.Count() > 0 then
            exit;

        VATReportsConfiguration.SetRange("VAT Report Version", 'CURRENT');
        if VATReportsConfiguration.FindFirst() then
            if VATReportsConfiguration."Submission Codeunit ID" = 0 then begin
                VATReportsConfiguration.Validate("Submission Codeunit ID", Codeunit::"MS - ECSL Report Export File");
                VATReportsConfiguration.Modify(true);
                exit;
            end;

        AddECSLConfiguration();
    end;

    [EventSubscriber(ObjectType::Page, Page::"Intrastat Journal", 'OnOpenPageEvent', '', false, false)]
    local procedure ConfigureIntrastat();
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
        Notification: Notification;
    begin
        IF NOT VATReportsConfiguration.Get(VATReportsConfiguration."VAT Report Type"::"Intrastat Report", 'CURRENT') then
            AddIntrastatConfiguration();

        VATReportsConfiguration.SetRange("VAT Report Type", VATReportsConfiguration."VAT Report Type"::"Intrastat Report");
        VATReportsConfiguration.SetFilter("Validate Codeunit ID", '<>%1', 0);
        VATReportsConfiguration.SetFilter("Content Codeunit ID", '<>%1', 0);
        if VATReportsConfiguration.IsEmpty() then
            exit;

        Notification.Message := NewFileExport2022ReportMsg;
        Notification.Scope := NotificationScope::LocalScope;
        Notification.AddAction(OpenVATReportConfigMsg, Codeunit::"Setup VAT Reports Config DK", 'OpenVATReportConfig');
        Notification.Send();
    end;

    procedure OpenVATReportConfig(Notification: Notification)
    begin
        Page.RunModal(Page::"VAT Reports Configuration");
    end;

    local procedure AddECSLConfiguration();
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        with VATReportsConfiguration do begin
            Validate("VAT Report Type", "VAT Report Type"::"EC Sales List");
            Validate("VAT Report Version", MSECSLDKTok);
            Validate("Suggest Lines Codeunit ID", Codeunit::"EC Sales List Suggest Lines");
            Validate("Validate Codeunit ID", CODEUNIT::"ECSL Report Validate");
            Validate("Submission Codeunit ID", Codeunit::"MS - ECSL Report Export File");
            Insert();
        end;
    end;

    local procedure AddIntrastatConfiguration();
    var
        VATReportsConfiguration: Record "VAT Reports Configuration";
    begin
        with VATReportsConfiguration do begin
            Validate("VAT Report Type", "VAT Report Type"::"Intrastat Report");
            Validate("VAT Report Version", 'CURRENT');
            Validate("Suggest Lines Codeunit ID", Codeunit::"Intrastat Suggest Lines");
            Validate("Validate Codeunit ID", CODEUNIT::"Intrastat Validate Lines");
            Validate("Content Codeunit ID", Codeunit::"Intrastat Export Lines");
            Insert();
        end;
    end;
}
