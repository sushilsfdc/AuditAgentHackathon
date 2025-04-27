public with sharing class UserPermissionRetrieval {

    /**
     * Invocable method to retrieve a list of users who have a specific permission.
     * This method can be invoked from Agentforce Agent actions.
     */
    @InvocableMethod(label='Get Users With Permission' description='Retrieve a list of users who have a specific permission.')
    public static List<Response> getUsersWithPermission(List<Request> permissionNames) {
        // Ensure a permission name is provided
        if (permissionNames == null || permissionNames.isEmpty()) {
            return new List<Response>();
        }

        String permissionName = permissionNames[0].permissionName;

        // Query to fetch users with the specified permission
        List<PermissionSetAssignment> psaList = Database.query(
            'SELECT AssigneeId ' +
            'FROM PermissionSetAssignment ' +
            'WHERE PermissionSet.' + String.escapeSingleQuotes(permissionName) + ' = true'
        );
            

        // Extract user IDs from the PermissionSetAssignment records
        Set<Id> userIds = new Set<Id>();
        for (PermissionSetAssignment psa : psaList) {
            userIds.add(psa.AssigneeId);
        }

        List<User> users = [SELECT Id, Name, Email FROM User WHERE Id IN :userIds];

        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);
   
        output.Prompt = JSON.serialize(users);
        return responses;
    }

    public class Request {
        @InvocableVariable(label='Permission Name' description='The name of the permission to check for.')
        public String permissionName;
    }
    public class Response {
        @InvocableVariable
        public String Prompt;
    }
    

}