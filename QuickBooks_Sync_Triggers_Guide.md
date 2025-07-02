# QuickBooks Sync Triggers & Testing Guide

## 🚀 What's Already Deployed

Your Salesforce sandbox now has:

✅ **QuickBooksInvoiceIntegration** - Main integration class  
✅ **QuickBooksInvoiceIntegrationTest** - Test class  
✅ **AccountTrigger** - Automatically detects customer accounts  
⏳ **InvoiceTrigger** - Will be deployed after Revenova TMS package installation

## 🎯 What Triggers QuickBooks Syncing?

### 1. Customer Account Syncing

**Account Trigger** automatically detects accounts that should be synced to QuickBooks when:

- **Account Type** contains "Customer" (case insensitive)
- **Account Name** contains "Customer" (case insensitive)  
- Important customer fields are updated (Name, Billing Address, Phone)

**Trigger Events:**
- Creating new customer accounts
- Updating existing customer accounts
- Changing Type field to "Customer"

### 2. Invoice Syncing (After Revenova TMS Installation)

**Invoice Trigger** will automatically sync invoices to QuickBooks when:

- Invoice **Status** changes to any of these values:
  - `Approved`
  - `Finalized` 
  - `Sent`
  - `Published`
  - `Complete`
  - `Ready`

- Important invoice fields change on already approved invoices:
  - Total Amount
  - Customer Account
  - Invoice Date
  - Description

- Manual sync is requested (via `Sync_to_QuickBooks__c` checkbox field)

## 🧪 Testing Instructions

### Step 1: Create Test Data

1. **Open Developer Console** in your Salesforce sandbox
2. **Go to Debug > Open Execute Anonymous Window**  
3. **Copy and paste the test data script** from `create_test_data.apex`
4. **Click Execute**

The script will create:
- **Test Customer ABC Corp** (Type = "Customer")
- **Customer XYZ Ltd** (Name contains "Customer")
- Test invoice (if Revenova TMS is installed)

### Step 2: Test Customer Account Sync

1. **Navigate to the test accounts** created by the script
2. **Update Account Type** to "Customer" or add "Customer" to the name
3. **Save the record**
4. **Check Debug Logs** for sync activity:
   ```
   AccountTrigger: Syncing X customer accounts to QuickBooks
   ```

### Step 3: Test Invoice Sync (After Revenova TMS Installation)

1. **Create an Invoice__c record** linked to your test customer:
   - Name: `INV-TEST-001`
   - Account: Link to test customer
   - Total Amount: `$2,500.00`
   - Status: `Draft`

2. **Update Invoice Status** to `Approved`

3. **Monitor Debug Logs** for:
   ```
   InvoiceTrigger: Syncing X invoices to QuickBooks
   QuickBooksInvoiceIntegration: Starting sync for invoice...
   ```

## 🔍 Monitoring Sync Activity

### Enable Debug Logs

1. **Go to Setup > Debug Logs**
2. **Click "New"** and add a trace flag for your user
3. **Set log level to Debug** for all categories
4. **Duration:** Set for several hours

### Watch for These Log Messages

**Account Trigger:**
```
AccountTrigger: Syncing 1 customer accounts to QuickBooks
```

**Invoice Trigger:**
```
InvoiceTrigger: Syncing 1 invoices to QuickBooks
```

**Integration Activity:**
```
QuickBooksInvoiceIntegration: Starting sync for invoice ID: 001...
QuickBooksInvoiceIntegration: Customer created in QuickBooks: 123
QuickBooksInvoiceIntegration: Invoice created in QuickBooks: 456
```

**Error Messages:**
```
Error: Failed to create customer in QuickBooks. Status: 401
Error: Failed to create invoice in QuickBooks. Status: 400
```

## 📋 Manual Testing Commands

You can also test the integration manually using these commands in the Developer Console:

### Test Single Invoice Sync
```apex
// Replace with actual invoice ID
Id invoiceId = '001XXXXXXXXXXXXXXX'; 
String result = QuickBooksInvoiceIntegration.syncInvoiceToQuickBooks(invoiceId);
System.debug('Sync Result: ' + result);
```

### Test Batch Invoice Sync
```apex
List<Id> invoiceIds = new List<Id>{
    '001XXXXXXXXXXXXXXX',
    '001YYYYYYYYYYYYYYY'
};
Map<Id, String> results = QuickBooksInvoiceIntegration.batchSyncInvoicesToQuickBooks(invoiceIds);
for (Id invId : results.keySet()) {
    System.debug('Invoice ' + invId + ': ' + results.get(invId));
}
```

### Test Async Sync
```apex
Set<Id> invoiceIds = new Set<Id>{'001XXXXXXXXXXXXXXX'};
QuickBooksInvoiceIntegration.syncInvoicesAsync(invoiceIds);
```

## 🛠️ Required Custom Fields

Before full testing, ensure these custom fields exist:

### On Account Object:
- `QuickBooks_Customer_Id__c` (Text, 255) - Stores QB Customer ID

### On Invoice__c Object:
- `QuickBooks_Invoice_Id__c` (Text, 255) - Stores QB Invoice ID
- `QuickBooks_Sync_Status__c` (Picklist) - Values: Draft, Synced, Error
- `QuickBooks_Sync_Date__c` (DateTime) - Last sync timestamp
- `Sync_to_QuickBooks__c` (Checkbox) - Manual sync trigger

## 🔄 Deployment Steps for Invoice Trigger

After installing your Revenova TMS managed package:

1. **Deploy the Invoice Trigger:**
   ```bash
   sf project deploy start --source-dir force-app/main/default/triggers/InvoiceTrigger.trigger --target-org QuickBooksSandbox
   ```

2. **Test the complete flow:**
   - Create test data
   - Update invoice status to "Approved"
   - Verify sync in QuickBooks

## 🎪 Live Testing Scenarios

### Scenario 1: New Customer Account
1. Create Account with Type = "Customer"
2. Watch for automatic customer detection in logs
3. Create invoice for this customer
4. Set invoice status to "Approved"
5. Verify customer and invoice appear in QuickBooks

### Scenario 2: Existing Account Becomes Customer
1. Create Account with Type = "Prospect" 
2. Update Type to "Customer"
3. Watch trigger detect the change
4. Create and approve invoice
5. Verify sync to QuickBooks

### Scenario 3: Invoice Updates
1. Create approved invoice (synced to QB)
2. Update total amount
3. Watch trigger detect change
4. Verify updated amount in QuickBooks

## ⚠️ Troubleshooting

### Common Issues:

**"Invoice__c not supported"**
- Install Revenova TMS managed package first
- Deploy Invoice trigger after package installation

**"Named credential not found"**
- Verify `QuickBooks_NC` named credential exists
- Check authentication and permissions

**"Customer creation failed"**
- Check QuickBooks API limits
- Verify realm ID is correct
- Ensure named credential has proper scopes

### Success Indicators:

✅ Debug logs show trigger firing  
✅ Customer created in QuickBooks  
✅ Invoice created in QuickBooks  
✅ Salesforce records updated with QB IDs  
✅ No error messages in logs

## 📊 Expected Results in QuickBooks

After successful sync, you should see:

1. **New Customer** in QuickBooks with:
   - Name matching Salesforce Account name
   - Address from Salesforce billing address
   - Phone number from Salesforce

2. **New Invoice** in QuickBooks with:
   - Customer reference
   - Invoice amount
   - Line items with descriptions
   - Invoice date

The integration is working correctly when test data flows seamlessly from Salesforce to QuickBooks with proper error handling and logging throughout the process.