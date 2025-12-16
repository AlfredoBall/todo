### Set the following environment variables for the Services/API/Todo.API project

  - AzureAd__Audience
  - AzureAd__TenantId
  - AzureAd__ClientID
  - AzureAd__Instance
  - AzureAd__Scopes

### Create .env files for the Angular and React applications respectively

### If "RunWithAuth": true - [appsettings.Development.json](Services\API\Todo.API\appsettings.Development.json) create an Azure App Registrations for the Angular and React apps and one for the API and configure API permissions accordingly. Populate .env files with generated values.

### See [AUTHENTICATION.md](Services\Web\Angular\todo\AUTHENTICATION.md) for guidance.

### See [React - auth-config.ts](Services/Web/React/todo/src/authConfig.ts) and [Angular - auth-config.ts](Services\Web\Angular\todo\src\app\auth-config.ts) for usage requirements.

### Suggested tools to install for further development

dotnet
dotnet-ef
cubectl
docker-compose
docker
az cli