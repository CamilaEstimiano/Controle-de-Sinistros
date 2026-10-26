# CONTROLE DE SINISTROS

Sistema web de gestão de sinistros de frota, com foco em rastreabilidade, prazos, documentos, reparos, custos e cobrança.

> **Princípio operacional:** nenhum sinistro pode ficar sem responsável, prazo, próxima ação ou histórico.

## Objetivos iniciais
- Torre de controle com indicadores e ações necessárias.
- Cadastro relacionado de sinistros, veículos, carretas, motoristas, seguradoras e terceiros.
- Fluxo por etapas, prazos/SLA e timeline de auditoria.
- Oficina interna, indisponibilidade de veículos e controle financeiro separado.
- Portal externo de terceiros com envio seguro de dados e arquivos.
- Perfis: gestor de frota, oficina e consulta.
- Exportação de relatórios e geração de dossiê.

## Stack proposta
- React + TypeScript + Vite
- Supabase (PostgreSQL, Auth, Storage e Row Level Security)
- GitHub para versionamento

## Status
Estrutura inicial do projeto. A aplicação ainda não está pronta para uso operacional e não deve receber dados reais até configurar autenticação, banco, políticas de acesso, armazenamento privado e validações.

## Desenvolvimento local
```bash
npm install
npm run dev
```

## Próximas etapas
1. Configurar projeto Supabase e variáveis de ambiente.
2. Aplicar o esquema inicial de banco em `supabase/migrations`.
3. Implementar autenticação e permissões no servidor/banco.
4. Desenvolver cadastro e dossiê de sinistro.
5. Desenvolver portal de terceiros com links revogáveis e expiráveis.
6. Adicionar testes, exportações e geração de documentos.

## Segurança
Nunca commitar chaves, senhas, tokens, documentos de terceiros ou dados pessoais reais. Use variáveis de ambiente e dados fictícios no desenvolvimento.