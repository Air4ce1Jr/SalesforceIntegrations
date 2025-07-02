# QuickBooks Invoice Integration for Revenova TMS

This integration allows you to synchronize customer invoices from your Revenova TMS managed package to QuickBooks using the existing named credential `QuickBooks_NC`.

## Files Created

1. **QuickBooksInvoiceIntegration.cls** - Main integration class
2. **QuickBooksInvoiceIntegrationTest.cls** - Comprehensive test class
3. Corresponding meta.xml files

## Prerequisites

### 1. Named Credential
✅ You already have the named credential `QuickBooks_NC` configured

### 2. Custom Fields Required
You'll need to add these custom fields to your objects:

**On Account Object:**
- `QuickBooks_Customer_Id__c` (Text, 255) - Stores the QuickBooks Customer ID

**On Invoice Object (Invoice__c):**
- `QuickBooks_Invoice_Id__c` (Text, 255) - Stores the QuickBooks Invoice ID
- `QuickBooks_Sync_Status__c` (Picklist) - Values: Draft, Synced, Error
- `QuickBooks_Sync_Date__c` (DateTime) - Last sync timestamp

### 3. Invoice Object Structure
The integration assumes your Revenova TMS has an Invoice custom object (`Invoice__c`) with these fields:
- `Name` - Invoice number
- `Account__c` - Customer lookup
- `Total_Amount__c` - Invoice total
- `Invoice_Date__c` - Invoice date
- `Status__c` - Invoice status

## Usage Examples

### 1. Sync a Single Invoice
```apex
Id invoiceId = '001XXXXXXXXXXXXXXX'; // Your invoice ID
String result = QuickBooksInvoiceIntegration.syncInvoiceToQuickBooks(invoiceId);

if (!result.startsWith('Error:')) {
    System.debug('Successfully synced. QuickBooks Invoice ID: ' + result);
} else {
    System.debug('Error occurred: ' + result);
}
```

### 2. Batch Sync Multiple Invoices
```apex
List<Id> invoiceIds = new List<Id>{
    '001XXXXXXXXXXXXXXX',
    '001YYYYYYYYYYYYYYY'
};

Map<Id, String> results = QuickBooksInvoiceIntegration.batchSyncInvoicesToQuickBooks(invoiceIds);

for (Id invoiceId : results.keySet()) {
    String result = results.get(invoiceId);
    System.debug('Invoice ' + invoiceId + ': ' + result);
}
```

### 3. Asynchronous Sync (Recommended for Large Batches)
```apex
Set<Id> invoiceIds = new Set<Id>{
    '001XXXXXXXXXXXXXXX',
    '001YYYYYYYYYYYYYYY'
};

QuickBooksInvoiceIntegration.syncInvoicesAsync(invoiceIds);
```

## Integration Features

### ✅ Customer Management
- Automatically creates customers in QuickBooks if they don't exist
- Stores QuickBooks Customer ID on Account for future reference
- Uses Account Name as customer display name

### ✅ Invoice Synchronization
- Maps Salesforce invoice data to QuickBooks format
- Creates line items with invoice details
- Updates Salesforce records with QuickBooks IDs
- Tracks sync status and timestamps

### ✅ Error Handling
- Comprehensive error handling and logging
- Returns descriptive error messages
- Graceful handling of API failures

### ✅ Security
- Uses named credential for secure authentication
- No hardcoded credentials in code

## Configuration

### 1. Update Realm ID
In the `getRealmId()` method, replace the default value with your actual QuickBooks company realm ID:

```apex
private static String getRealmId() {
    // Replace with your actual realm ID or retrieve from custom settings
    return 'YOUR_ACTUAL_REALM_ID';
}
```

### 2. Customize Field Mappings
Update the SOQL query in `syncInvoiceToQuickBooks()` method to match your actual field names:

```apex
List<SObject> invoices = Database.query(
    'SELECT Id, Name, Account__c, Account__r.Name, Account__r.QuickBooks_Customer_Id__c, ' +
    'Total_Amount__c, Invoice_Date__c, Status__c ' +
    'FROM Invoice__c WHERE Id = :invoiceId LIMIT 1'
);
```

### 3. Line Item Enhancement
For detailed line items, modify the `buildQuickBooksInvoice()` method to query and map actual invoice line items:

```apex
// Query invoice line items
List<SObject> lineItems = Database.query(
    'SELECT Product__r.Name, Quantity__c, Unit_Price__c, Total_Price__c ' +
    'FROM Invoice_Line_Item__c WHERE Invoice__c = :invoiceId'
);
```

## Automation Options

### 1. Process Builder/Flow
Create a Process Builder or Flow to automatically sync invoices when status changes to "Approved" or "Finalized".

### 2. Trigger
```apex
trigger InvoiceTrigger on Invoice__c (after update) {
    Set<Id> invoicesToSync = new Set<Id>();
    
    for (Invoice__c invoice : Trigger.new) {
        Invoice__c oldInvoice = Trigger.oldMap.get(invoice.Id);
        
        // Sync when status changes to "Approved"
        if (invoice.Status__c == 'Approved' && oldInvoice.Status__c != 'Approved') {
            invoicesToSync.add(invoice.Id);
        }
    }
    
    if (!invoicesToSync.isEmpty()) {
        QuickBooksInvoiceIntegration.syncInvoicesAsync(invoicesToSync);
    }
}
```

### 3. Scheduled Batch
Create a schedulable class to sync invoices on a regular basis:

```apex
global class QuickBooksScheduledSync implements Schedulable {
    global void execute(SchedulableContext ctx) {
        // Query unsync invoices
        List<Invoice__c> invoices = [
            SELECT Id FROM Invoice__c 
            WHERE Status__c = 'Approved' 
            AND QuickBooks_Sync_Status__c != 'Synced'
            LIMIT 100
        ];
        
        Set<Id> invoiceIds = new Set<Id>();
        for (Invoice__c invoice : invoices) {
            invoiceIds.add(invoice.Id);
        }
        
        if (!invoiceIds.isEmpty()) {
            QuickBooksInvoiceIntegration.syncInvoicesAsync(invoiceIds);
        }
    }
}
```

## Testing

Run the test class to ensure everything is working correctly:

```apex
// Run all tests
Test.runAllTests();

// Run specific test class
Test.testClass(QuickBooksInvoiceIntegrationTest.class);
```

## Monitoring and Troubleshooting

### 1. Debug Logs
The integration logs important information to System.debug(). Enable debug logs for the running user.

### 2. Custom Reports
Create reports on Invoice records to monitor sync status:
- Filter by `QuickBooks_Sync_Status__c = 'Error'` to find failed syncs
- Track sync dates with `QuickBooks_Sync_Date__c`

### 3. Error Handling
All errors are returned as strings starting with "Error:". Parse these messages for specific troubleshooting.

## Security Considerations

1. **Field-Level Security**: Ensure users have appropriate permissions on QuickBooks-related fields
2. **Object Permissions**: Grant read/write access to Invoice and Account objects
3. **Named Credential**: Verify the named credential has proper authentication
4. **API Limits**: Be mindful of QuickBooks API rate limits

## Support

For issues related to:
- **Salesforce configuration**: Check field mappings and permissions
- **QuickBooks authentication**: Verify named credential setup
- **API errors**: Check QuickBooks API documentation and rate limits
- **Data mapping**: Customize field mappings in the integration class