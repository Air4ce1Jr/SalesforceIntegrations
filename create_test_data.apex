/**
 * @description Script to create test data for QuickBooks integration
 * Run this in Developer Console's Execute Anonymous window
 * 
 * This script creates:
 * 1. A test customer account
 * 2. A test invoice linked to that account
 * 
 * @author Salesforce Administrator
 * @date 2024
 */

// Create test customer account
Account testCustomer = new Account(
    Name = 'Test Customer ABC Corp',
    Type = 'Customer',
    Phone = '(555) 123-4567',
    BillingStreet = '123 Main Street',
    BillingCity = 'San Francisco',
    BillingState = 'California',
    BillingPostalCode = '94105',
    BillingCountry = 'United States',
    Description = 'Test customer account for QuickBooks integration testing'
);

try {
    insert testCustomer;
    System.debug('✅ Created test customer account: ' + testCustomer.Name + ' (ID: ' + testCustomer.Id + ')');
} catch (Exception e) {
    System.debug('❌ Error creating test customer: ' + e.getMessage());
    return;
}

// Create test invoice for the customer
SObject testInvoice;

// Try to create an Invoice__c record (Revenova TMS custom object)
try {
    // Get the Invoice__c sObject type
    Schema.SObjectType invoiceType = Schema.getGlobalDescribe().get('Invoice__c');
    
    if (invoiceType != null) {
        testInvoice = invoiceType.newSObject();
        testInvoice.put('Name', 'INV-TEST-001');
        testInvoice.put('Account__c', testCustomer.Id);
        testInvoice.put('Total_Amount__c', 2500.00);
        testInvoice.put('Invoice_Date__c', Date.today());
        testInvoice.put('Status__c', 'Draft'); // Start as Draft, we'll update to trigger sync
        
        // Add description if field exists
        try {
            testInvoice.put('Description__c', 'Test invoice for QuickBooks integration - contains consulting services and software licensing fees');
        } catch (Exception ex) {
            // Description field might not exist, continue without it
        }
        
        insert testInvoice;
        System.debug('✅ Created test invoice: INV-TEST-001 (ID: ' + testInvoice.Id + ')');
        
        // Now update the invoice to 'Approved' status to trigger QuickBooks sync
        testInvoice.put('Status__c', 'Approved');
        update testInvoice;
        System.debug('✅ Updated invoice status to Approved - this should trigger QuickBooks sync');
        
    } else {
        System.debug('⚠️  Invoice__c custom object not found. This is expected if Revenova TMS package is not installed yet.');
        System.debug('   You can create the invoice manually once the package is installed.');
    }
    
} catch (Exception e) {
    System.debug('❌ Error creating test invoice: ' + e.getMessage());
    System.debug('   This might be because Revenova TMS package is not installed yet.');
}

// Alternative: Create using standard objects if custom objects don't exist
if (testInvoice == null) {
    System.debug('');
    System.debug('📋 ALTERNATIVE TEST DATA CREATION:');
    System.debug('   Since Invoice__c is not available, you can:');
    System.debug('   1. Install your Revenova TMS managed package first');
    System.debug('   2. Then run this script again');
    System.debug('   3. Or manually create an Invoice__c record with these values:');
    System.debug('      - Name: INV-TEST-001');
    System.debug('      - Account: ' + testCustomer.Name + ' (' + testCustomer.Id + ')');
    System.debug('      - Total Amount: $2,500.00');
    System.debug('      - Status: Approved (to trigger sync)');
}

System.debug('');
System.debug('🎯 TESTING INSTRUCTIONS:');
System.debug('1. The test customer account "' + testCustomer.Name + '" has been created');
System.debug('2. Update the account Type to "Customer" or add "Customer" to the name to test account sync');
System.debug('3. Create an Invoice__c record linked to this account with Status = "Approved"');
System.debug('4. Check Debug Logs to see the QuickBooks sync activity');
System.debug('5. Verify the customer and invoice appear in your QuickBooks sandbox');

System.debug('');
System.debug('🔍 TO MONITOR SYNC ACTIVITY:');
System.debug('1. Go to Setup > Debug Logs');
System.debug('2. Click "New" and add a trace flag for your user');
System.debug('3. Set log level to Debug for all categories');
System.debug('4. Watch for "InvoiceTrigger" and "QuickBooksInvoiceIntegration" messages');

// Create additional test data variations
Account testCustomer2 = new Account(
    Name = 'Customer XYZ Ltd', // Name contains "Customer"
    Type = 'Prospect', // Different type but name has "Customer"
    Phone = '(555) 987-6543',
    BillingStreet = '456 Oak Avenue',
    BillingCity = 'Los Angeles',
    BillingState = 'California',
    BillingPostalCode = '90210',
    BillingCountry = 'United States'
);

try {
    insert testCustomer2;
    System.debug('✅ Created second test account: ' + testCustomer2.Name + ' (ID: ' + testCustomer2.Id + ')');
    System.debug('   This account has "Customer" in the name, so it should also trigger customer sync when updated');
} catch (Exception e) {
    System.debug('❌ Error creating second test customer: ' + e.getMessage());
}