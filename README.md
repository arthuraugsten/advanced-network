# Laboratório Advanced Network por TFTEC

Este repositório tem o propósito de criar toda estrutura necessária apresentada no workshop de Advanced Network da TFTEC Treinamentos Online, ministrado por Raphael Andrade.

## Prerequisitos

Para executar este script é necessário ter um resource group já existe, para isso, execute o comando abaixo. Escolha uma região de sua preferência para hospedar os recursos.

```bash
az group create -n RG-LABS-TFTEC -l eastus
```

Caso seja necessário, você poderá alterar as configurações de máquina virtual no arquivo `main.parameters.json` caso esteja utilizando uma subscrição trial.

## Executando o script

Antes de executar o arquivo Bicep, por favor, entre no diretório scripts, utilizando o comando abaixo.

```bash
cd ./scripts
```

Para executar com o Azure CLI, utilize uma console que suporte bash, como o git bash

```bash
az deployment group create -g RG-LABS-TFTEC -n deploy-lab -f ./main.bicep -p @main.parameters.json
```

## Em andamento

Ainda em fase de desenvolvimento, o script também mapeará a unidade de rede nas máquinas virtuais criadas, utilizando o private endpoint criado durante a publicação.
