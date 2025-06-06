### Prepare Your GitHub Repository
Ensure that your ARM templates and static website files are stored in a GitHub repository.

### Create an Azure DevOps Project
1. Sign in to Azure DevOps.
2. If you do not have an organization, create one at [dev.azure.com](https://dev.azure.com).
3. Create a new project if one does not already exist.

### Set Up a Service Connection
1. Navigate to your project settings in Azure DevOps.
2. Under **Pipelines**, select **Service connections**.
3. Create a new Azure Resource Manager connection.

### Create a Pipeline
1. In Azure DevOps, go to **Pipelines** and select **New pipeline**.
2. Connect to your GitHub repository.
3. Choose a **Starter pipeline** and configure it to deploy your ARM templates.

### Configure the Pipeline
1. Use the **Azure PowerShell** task or **ARM template deployment** task to deploy your resources.
2. Specify the deployment scope, resource group, and other necessary parameters.

### Verify and Update
1. Run the pipeline to deploy your static website.
2. Make any necessary updates to your templates and redeploy as needed.

### Additional Resources
For detailed guidance on deploying ARM templates using Azure DevOps pipelines, refer to the official documentation:  
[Deploy ARM templates using a pipeline](https://learn.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-tutorial-pipeline?wt.mc_id=knowledgesearch_inproduct_copilot-in-azure)