# Executando o script

az deployment group create -g RG-LAB -n deploy-infra -f ./main.bicep -p @main.parameters.json

New-AzResourceGroupDeployment -Name ExampleDeployment -ResourceGroupName RG-LAB -TemplateFile main.bicep -TemplateParameterFile main.parameters.json
