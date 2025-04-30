public with sharing class OrgPermissions {

    /**
     * Invocable method to retrieve permissions based on entity type.
     * This method can be invoked from Agentforce Agent actions.
     */
    @InvocableMethod(label='Get Permissions' description='Retrieve permissions from FieldPermissions or ObjectPermissions object.')
    public static List<Response> getPermissions(List<Request> requests) {
        // Ensure the request list is not null or empty
        if (requests == null || requests.isEmpty()) {
            return new List<Response>();
        }
        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);

        for (Request req : requests) {
            // Validate required fields
            if (String.isBlank(req.entityType) || String.isBlank(req.objectApiName)) {
                output.Prompt =  'EntityType and ObjectApiName are required.';
                continue;
            }

            try {
                // Handle FieldPermissions
                if (req.entityType == 'FieldPermissions') {
                    if (String.isBlank(req.fieldApiName)) {
                        output.Prompt =  'FieldApiName is required for FieldPermissions.';
                        continue;
                    }

                    List<FieldPermissions> fieldPermissions = [
                        SELECT parent.name, parent.profile.name, SObjectType, Field, PermissionsRead, PermissionsEdit 
                        FROM FieldPermissions 
                        WHERE SObjectType = :req.objectApiName AND Field = :req.fieldApiName
                        AND PermissionsRead = true
                    ];

                    output.Prompt = JSON.serialize(fieldPermissions);
                }
                // Handle ObjectPermissions
                else if (req.entityType == 'ObjectPermissions') {
                    List<ObjectPermissions> objectPermissions = [
                        SELECT parent.name, parent.profile.name, SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, PermissionsDelete 
                        FROM ObjectPermissions 
                        WHERE SObjectType = :req.objectApiName
                        and PermissionsRead = true
                    ];

                    output.Prompt = JSON.serialize(objectPermissions);
                }
            } catch (Exception e) {
                output.Prompt = 'Error retrieving permissions: ' + e.getMessage();
            }
        }

        return responses;
    }

    // Request class to encapsulate input parameters
    public class Request {
        @InvocableVariable(required=true label='Entity Type' description='Type of entity: FieldPermissions or ObjectPermissions')
        public String entityType;

        @InvocableVariable(required=true label='Object API Name' description='API name of the object (e.g., Account)')
        public String objectApiName;

        @InvocableVariable(required=false label='Field API Name' description='API name of the field (required for FieldPermissions)')
        public String fieldApiName;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}