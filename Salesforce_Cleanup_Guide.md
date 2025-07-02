# Salesforce Custom Component Cleanup Guide

## ✅ What's Been Successfully Preserved

Your **QuickBooks integration** components have been preserved:
- `QuickBooksInvoiceIntegration` class
- `QuickBooksInvoiceIntegrationTest` class  
- `AccountTrigger` (for auto-syncing customers)
- All QuickBooks-related custom fields

## 🛑 Manual Cleanup Required

Due to complex dependencies between Sites, Visualforce pages, components, and Apex classes, these components must be deleted manually in the correct order through the Salesforce UI.

### Step 1: Deactivate and Delete Sites

1. **Navigate to Setup → Digital Experiences → All Sites**
2. **Deactivate sites first:**
   - Find `API` site → Click **Builder** → Settings → **Deactivate**
   - Find `Email_Loop` site → Click **Builder** → Settings → **Deactivate**
3. **Delete the sites:**
   - After deactivation, delete both sites from the All Sites list

### Step 2: Delete Visualforce Pages (Setup → Custom Code → Visualforce Pages)

Delete these pages in any order:
- `AnswersHome`
- `BandwidthExceeded`
- `ChangePassword`
- `CommunitiesLanding`
- `CommunitiesLogin`
- `CommunitiesSelfReg`
- `CommunitiesSelfRegConfirm`
- `CommunitiesTemplate`
- `Exception`
- `FileNotFound`
- `ForgotPassword`
- `ForgotPasswordConfirm`
- `IdeasHome`
- `InMaintenance`
- `MicrobatchSelfReg`
- `MyProfilePage`
- `SiteLogin`
- `SiteRegister`
- `SiteRegisterConfirm`
- `SiteTemplate`
- `StdExceptionTemplate`
- `Unauthorized`
- `UnderConstruction`

### Step 3: Delete Visualforce Components (Setup → Custom Code → Visualforce Components)

Delete these components:
- `SiteFooter`
- `SiteHeader`
- `SiteLogin`
- `SitePoweredBy`

### Step 4: Delete Aura Components (Setup → Custom Code → Lightning Components)

Delete these Aura components:
- `forgotPassword`
- `loginForm`
- `selfRegister`
- `setExpId`
- `setStartUrl`

### Step 5: Delete Apex Classes (Setup → Custom Code → Apex Classes)

Delete these classes:
- `ChangePasswordController`
- `ChangePasswordControllerTest`
- `CommunitiesLandingController`
- `CommunitiesLandingControllerTest`
- `CommunitiesLoginController`
- `CommunitiesLoginControllerTest`
- `CommunitiesSelfRegConfirmController`
- `CommunitiesSelfRegConfirmControllerTest`
- `CommunitiesSelfRegController`
- `CommunitiesSelfRegControllerTest`
- `ForgotPasswordController`
- `ForgotPasswordControllerTest`
- `LightningForgotPasswordController`
- `LightningForgotPasswordControllerTest`
- `LightningLoginFormController`
- `LightningLoginFormControllerTest`
- `LightningSelfRegisterController`
- `LightningSelfRegisterControllerTest`
- `MicrobatchSelfRegController`
- `MicrobatchSelfRegControllerTest`
- `MyProfilePageController`
- `MyProfilePageControllerTest`
- `SiteLoginController`
- `SiteLoginControllerTest`
- `SiteRegisterController`
- `SiteRegisterControllerTest`

### Step 6: Delete Custom Metadata Type

Go to **Setup → Custom Metadata Types** and delete:
- `Load_Configuration_mdt`

### Step 7: Clean Up Custom Fields (Optional)

If you want to remove all custom fields you created (be careful not to delete QuickBooks integration fields):

**⚠️ PRESERVE THESE QuickBooks Integration Fields:**
- `Account.QuickBooks_Customer_Id__c`
- `Account.QuickBooks_Customer_SyncToken__c`
- `Account.QuickBooks_Email__c`
- `rtms__CustomerInvoice__c.QuickBooks_Invoice_Id__c`
- `rtms__CarrierInvoice__c.QBO_Bill_Id__c`
- All other QBO_* fields

**You can safely delete these if you created them:**
- `Account.DBA_Name__c`
- `Account.QBO_Vendor_Id__c` (if not needed)
- Any other custom fields you added

## 🎯 After Cleanup

Once cleanup is complete, your org will have:
- ✅ Clean custom metadata (no community/portal components)
- ✅ Revenova TMS managed package (fully preserved)
- ✅ QuickBooks integration (fully functional)
- ✅ All QuickBooks sync functionality intact

## 🔧 Testing the QuickBooks Integration

After cleanup, you can test the QuickBooks integration:

1. **Create a test customer account:**
   - Set Type = "Customer"
   - Save the record
   - The AccountTrigger will automatically attempt to sync it to QuickBooks

2. **Monitor sync results:**
   - Check debug logs for sync status
   - Verify QuickBooks_Customer_Id__c gets populated

## ❓ Need Help?

If you encounter any issues during manual cleanup or want to verify the QuickBooks integration is working, let me know!