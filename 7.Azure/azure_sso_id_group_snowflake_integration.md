## 1.Azure Entra ID
- Entra ID is a central place to manage identity and access to application
- Tenant is a space of organization. it may include:
    + User
    + group
    + Enterprise application 
- user is a object that represent for a specific person
- group is a set of users, instead of assign permission to one by one, create a group and assign once. user can be a member of multiple group
- enterprise application is a application object managed in tenant, it can content:
    + SSO sign in
    + user/group assigned to application
    + without it, user sign in with account snowflake and snowflake will authenticate. with it authenticate will be moved to Azure 
- service principal represent for a enterprose application in tenant (like user represent for a person in ternant)
- can assign user and group to enterprise application and after that can sync to snowflake and assign role automatically with SCIM provision 
- SCIM provision is a set of general rule help Snowflake manage user, role and assign role base on information from entra 
- SSO allow to use authenticated ID from system to other systems. For example, I sign in successfully in entra and I can use it to sign in snowflake without password
- SAML is a standard for one system to send proof of identity authentication to another system.
## 2. Snowflake RBAC
- RBAC: Role Based Access Control
- after authentication, need to define what users can do
- user will be assign roles
- role will be provided privilege (select, create, insert, update)
- grant for providing (privilege -> role, role -> user, role -> role)
- revoke for removing 
- role can inherit
- Least privilege: always provide enough permission,not redundant 
## 3. Azure SSO → Snowflake
- the purpose of SSO make snowflake trust entra, we need o config to make them know and trust each other (follow document and set up)
