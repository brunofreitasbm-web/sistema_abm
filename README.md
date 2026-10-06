# Passagem de Serviço ABM v3.1.0 — SOURCE FULL

Esta versão corrige os dois problemas de interface relatados:

1. **Menu cobrindo/comendo parte da página em celular**
   - Sidebar móvel passou a ser off-canvas por `transform`, sem ocupar largura da página.
   - Topbar tem altura dinâmica e o conteúdo começa sempre depois dela.
   - Textos longos da unidade não empurram mais os botões nem sobrepõem a página.
   - Rolagem horizontal bloqueada e tabelas permanecem roláveis dentro do próprio card.

2. **Páginas brancas sem conteúdo**
   - Todas as rotas administrativas agora possuem loading, tratamento de erro e fallback visual.
   - Se uma API falhar, a página mostra mensagem e botão `Tentar novamente`, em vez de ficar branca.
   - Se a API retornar listas vazias, continuam sendo mostrados estados vazios.
   - Assets HTML/JS/CSS são enviados com `no-cache`, evitando carregar código antigo depois de atualização.
   - Corrigido também `sheet is not defined` no Portal Operacional, que impedia cadastro e outras janelas.

## Estrutura

- `cmd/server/` — código-fonte Go da API/VPS.
- `web/admin/` — painel administrativo completo.
- `web/app/` — portal operacional web usado também como base visual do Android.
- `install.sh` — instalação/atualização completa.
- `INSTALAR-VPS-LIMPA.sh` — atalho para VPS Ubuntu limpa.
- `TESTAR-SISTEMA.sh` — diagnóstico após instalação.

## Instalação em VPS Ubuntu limpa

```bash
cd /root/PASSAGEM-SERVICO-PAINEL-VPS-v3.1.0
ADMIN_USER=admin ADMIN_PASS='SUA-SENHA-FORTE' sudo -E bash INSTALAR-VPS-LIMPA.sh
```

Acesso padrão sem domínio:

- Painel: `http://IP-DA-VPS:3007/admin/`
- Portal operacional: `http://IP-DA-VPS:3007/app/`

## Teste pós-instalação

```bash
sudo bash TESTAR-SISTEMA.sh
```

## Compilar o servidor

AMD64:

```bash
GOOS=linux GOARCH=amd64 go build -o passagem-servico-amd64 ./cmd/server
```

ARM64:

```bash
GOOS=linux GOARCH=arm64 go build -o passagem-servico-arm64 ./cmd/server
```
