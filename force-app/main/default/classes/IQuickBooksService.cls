/**
 * @description Interface for QuickBooks API service operations
 * @author Salesforce Administrator
 * @date 2024
 */
public interface IQuickBooksService {
    
    /**
     * @description Create or update a customer in QuickBooks
     * @param customer The customer data to sync
     * @return QuickBooks Customer ID or error message
     */
    String syncCustomer(QuickBooksModels.QBCustomer customer);
    
    /**
     * @description Find an existing customer in QuickBooks by name
     * @param customerName The customer name to search for
     * @return QuickBooks Customer ID if found, null otherwise
     */
    String findCustomerByName(String customerName);
    
    /**
     * @description Create an invoice in QuickBooks
     * @param invoice The invoice data to create
     * @return QuickBooks Invoice ID or error message
     */
    String createInvoice(QuickBooksModels.QBInvoice invoice);
    
    /**
     * @description Update an existing invoice in QuickBooks
     * @param invoice The invoice data to update
     * @return QuickBooks Invoice ID or error message
     */
    String updateInvoice(QuickBooksModels.QBInvoice invoice);
    
    /**
     * @description Delete an invoice in QuickBooks
     * @param invoiceId The QuickBooks Invoice ID to delete
     * @return Success message or error message
     */
    String deleteInvoice(String invoiceId);
    
    /**
     * @description Get the QuickBooks company realm ID
     * @return The realm ID for API calls
     */
    String getRealmId();
    
    /**
     * @description Test the connection to QuickBooks API
     * @return True if connection is successful, false otherwise
     */
    Boolean testConnection();
}