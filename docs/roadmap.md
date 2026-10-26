# Roteiro de implementação

## Fase 1 — Fundação
- [x] Criar repositório e estrutura inicial React/TypeScript/Vite
- [x] Criar primeiro layout da Torre de Controle (dados demonstrativos/sem conexão)
- [x] Definir esquema inicial de dados relacionais
- [ ] Criar projeto Supabase de desenvolvimento
- [ ] Aplicar migração e validar integridade do esquema
- [ ] Implementar autenticação, perfis e políticas RLS
- [ ] Adicionar testes e validação de build

## Fase 2 — Cadastros e sinistros
- [ ] Cadastro, busca, edição e inativação de veículos
- [ ] Cadastro de carretas e associação ao veículo
- [ ] Cadastro, busca, edição e inativação de motoristas
- [ ] Importação Excel com pré-validação, prévia e relatório de erros
- [ ] Cadastro de sinistro com numeração interna automática
- [ ] Validação de responsável, prazo e próxima ação em sinistros ativos
- [ ] Dossiê e timeline com trilha de auditoria

## Fase 3 — Documentos e terceiros
- [ ] Storage privado e limites de arquivo por categoria
- [ ] Links externos com token seguro, expiração e revogação
- [ ] Formulário do terceiro com dados, fotos, vídeos e documentos
- [ ] Validação e triagem dos envios por usuário interno
- [ ] Exportar dossiê em DOCX e pacote ZIP de documentos

## Fase 4 — Oficina e financeiro
- [ ] Controle de entrada, diagnóstico, reparo e entrega
- [ ] Custo interno de reparo independente da cobrança
- [ ] Lançamento de cobranças e pagamentos parciais
- [ ] Saldo pendente calculado pelo banco
- [ ] Veículos indisponíveis e dias parados

## Fase 5 — Gestão
- [ ] Dashboard conectado a dados reais
- [ ] SLA por etapa e alerta de 2 dias sem movimentação
- [ ] Central de pendências e ações necessárias hoje
- [ ] Indicadores por período, seguradora, motorista, cliente e tipo
- [ ] Exportação Excel/CSV e relatórios gerenciais

## Critérios de aceite
- Nenhum sinistro ativo pode ser salvo sem responsável, prazo e próxima ação com data.
- Mudanças relevantes geram histórico com data/hora e usuário.
- Usuário de consulta não altera dados.
- Usuário de oficina só altera os sinistros atribuídos à oficina, conforme regras de acesso.
- Uploads não ficam públicos e os links de terceiros não dão acesso ao dossiê interno.
- O saldo de cobrança é separado do custo de reparo.
- O dashboard não apresenta valores fictícios como se fossem dados reais.
