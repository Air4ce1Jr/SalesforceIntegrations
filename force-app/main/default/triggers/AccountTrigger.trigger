/**
 * @description Trigger for Account object to sync customers to QuickBooks
 * @author Salesforce Administrator
 * @date 2024
 */
trigger AccountTrigger on Account (after insert, after update) {
    
    // Set to collect Account IDs that need QuickBooks customer sync
    Set<Id> accountsToSync = new Set<Id>();
    
    // Process records after insert or update
    for (Account acc : Trigger.new) {
        // Check if account should be synced to QuickBooks
        Boolean shouldSync = false;
        
        // Sync if account type contains 'customer' (case insensitive)
        if (String.isNotBlank(acc.Type) && acc.Type.toLowerCase().contains('customer')) {
            shouldSync = true;
        }
        
        // Also sync if account name contains 'customer' (case insensitive)
        if (String.isNotBlank(acc.Name) && acc.Name.toLowerCase().contains('customer')) {
            shouldSync = true;
        }
        
        // For updates, also check if relevant fields changed
        if (Trigger.isUpdate) {
            Account oldAcc = Trigger.oldMap.get(acc.Id);
            
            // Sync if Type field changed and now indicates customer
            if (acc.Type != oldAcc.Type && shouldSync) {
                accountsToSync.add(acc.Id);
                continue;
            }
            
            // Sync if Name changed and indicates customer
            if (acc.Name != oldAcc.Name && shouldSync) {
                accountsToSync.add(acc.Id);
                continue;
            }
            
            // Sync if other important fields changed for existing customers
            if (String.isNotBlank(acc.QuickBooks_Customer_Id__c) || shouldSync) {
                Boolean fieldsChanged = (
                    acc.Name != oldAcc.Name ||
                    acc.BillingStreet != oldAcc.BillingStreet ||
                    acc.BillingCity != oldAcc.BillingCity ||
                    acc.BillingState != oldAcc.BillingState ||
                    acc.BillingPostalCode != oldAcc.BillingPostalCode ||
                    acc.BillingCountry != oldAcc.BillingCountry ||
                    acc.Phone != oldAcc.Phone
                );
                
                if (fieldsChanged) {
                    accountsToSync.add(acc.Id);
                }
            }
        } else if (Trigger.isInsert && shouldSync) {
            // Sync new customer accounts
            accountsToSync.add(acc.Id);
        }
    }
    
    // Call the QuickBooks integration asynchronously if we have accounts to sync
    if (!accountsToSync.isEmpty()) {
        System.debug('AccountTrigger: Syncing ' + accountsToSync.size() + ' customer accounts to QuickBooks');
        
        // Since we don't have a specific customer sync method yet, we'll create the customers
        // when invoices are synced. For now, just log the action.
        // In the future, you could create a specific customer sync method.
        
        // Note: Customer creation is handled automatically by the invoice sync process
        // when an invoice references an account that doesn't have a QuickBooks Customer ID
    }
}