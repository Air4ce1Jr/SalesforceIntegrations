/**
 * @description Mock implementation of QuickBooks service for testing
 * @author Salesforce Administrator
 * @date 2024
 */
@TestVisible
public class QuickBooksMockService implements IQuickBooksService {
    
    private Boolean shouldFail;
    private String errorMessage;
    public Boolean customerNotFound = false;
    
    /**
     * @description Constructor for mock service
     * @param shouldFail Whether the service should simulate failures
     * @param errorMessage The error message to return if shouldFail is true
     */
    public QuickBooksMockService(Boolean shouldFail, String errorMessage) {
        this.shouldFail = shouldFail;
        this.errorMessage = errorMessage != null ? errorMessage : 'Mock service error';
    }
    
    /**
     * @description Default constructor for success scenarios
     */
    public QuickBooksMockService() {
        this(false, null);
    }
    
    /**
     * @description Create or update a customer in QuickBooks
     * @param customer The customer data to sync
     * @return QuickBooks Customer ID or error message
     */
    public String syncCustomer(QuickBooksModels.QBCustomer customer) {
        if (shouldFail) {
            return 'Error: ' + errorMessage;
        }
        
        // Return mock customer ID
        return 'MOCK_CUSTOMER_' + Math.abs(Crypto.getRandomInteger());
    }
    
    /**
     * @description Find an existing customer in QuickBooks by name
     * @param customerName The customer name to search for
     * @return QuickBooks Customer ID if found, null otherwise
     */
    public String findCustomerByName(String customerName) {
        if (shouldFail) {
            return null;
        }
        
        if (customerNotFound) {
            return null;
        }
        
        // Simulate customer found for test customers
        if (customerName != null && customerName.toLowerCase().contains('test')) {
            return 'MOCK_EXISTING_CUSTOMER_123';
        }
        
        return null;
    }
    
    /**
     * @description Create an invoice in QuickBooks
     * @param invoice The invoice data to create
     * @return QuickBooks Invoice ID or error message
     */
    public String createInvoice(QuickBooksModels.QBInvoice invoice) {
        if (shouldFail) {
            return 'Error: ' + errorMessage;
        }
        
        // Return mock invoice ID
        return 'MOCK_INVOICE_' + Math.abs(Crypto.getRandomInteger());
    }
    
    /**
     * @description Update an existing invoice in QuickBooks
     * @param invoice The invoice data to update
     * @return QuickBooks Invoice ID or error message
     */
    public String updateInvoice(QuickBooksModels.QBInvoice invoice) {
        if (shouldFail) {
            return 'Error: ' + errorMessage;
        }
        
        // Return the same invoice ID to simulate successful update
        return invoice.Id != null ? invoice.Id : 'MOCK_INVOICE_UPDATED';
    }
    
    /**
     * @description Delete an invoice in QuickBooks
     * @param invoiceId The QuickBooks Invoice ID to delete
     * @return Success message or error message
     */
    public String deleteInvoice(String invoiceId) {
        if (shouldFail) {
            return 'Error: ' + errorMessage;
        }
        
        return 'Success: Invoice deleted';
    }
    
    /**
     * @description Get the QuickBooks company realm ID
     * @return The realm ID for API calls
     */
    public String getRealmId() {
        return '9341454816381446';
    }
    
    /**
     * @description Test the connection to QuickBooks API
     * @return True if connection is successful, false otherwise
     */
    public Boolean testConnection() {
        return !shouldFail;
    }
}