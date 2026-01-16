#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# Build Script - Promotudo Project
# Prepara a aplicação para PRODUÇÃO (compilar assets, otimizar, etc)
# Deve ser executado ANTES de fazer deploy em produção
# Uso: bash build-production.sh
# ═══════════════════════════════════════════════════════════════════════════════

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funções auxiliares
echo_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════════${NC}\n"
}

echo_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

echo_error() {
    echo -e "${RED}✗ $1${NC}"
}

echo_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

echo_header "🔨 BUILD PARA PRODUÇÃO"

# Verificar se estamos no diretório correto
if [ ! -f "docker-compose.yml" ]; then
    echo_error "docker-compose.yml não encontrado. Execute o script na raiz do projeto."
    exit 1
fi

# Limpar builds antigos
echo_header "LIMPANDO BUILDS ANTIGOS"

echo_info "Removendo node_modules e build antigos..."
rm -rf app/node_modules app/public/build app/public/hot 2>/dev/null || true
echo_success "Limpeza concluída"

# Instalar dependências
echo_header "INSTALANDO DEPENDÊNCIAS"

echo_info "Executando npm ci (determinístico, usa package-lock.json)..."
cd app
npm ci
echo_success "Dependências Node instaladas"

# Compilar assets para produção
echo_header "COMPILANDO ASSETS PARA PRODUÇÃO"

echo_info "Executando 'npm run build' (otimizado para produção)..."
npm run build
echo_success "Assets compilados com sucesso"

cd ..

# Instalar dependências PHP
echo_header "INSTALANDO DEPENDÊNCIAS PHP"

echo_info "Executando 'composer install --no-dev --optimize-autoloader'..."
docker exec promotudo composer install --no-dev --optimize-autoloader 2>/dev/null || \
composer install --no-dev --optimize-autoloader
echo_success "Dependências PHP instaladas"

# Resumo
echo_header "✅ BUILD CONCLUÍDO!"

echo_success "Aplicação está pronta para produção"
echo ""
echo_info "Próximas ações:"
echo "  1. Commit das mudanças (se necessário)"
echo "  2. Build da imagem Docker (se usando CI/CD)"
echo "  3. Deploy com: bash setup-production.sh"
echo ""
echo_info "Arquivos gerados:"
echo "  • app/public/build/ - Assets compilados"
echo "  • app/vendor/ - Dependências PHP"
echo "  • node_modules/ - Dependências Node (será removido antes de deploy)"
echo ""
echo_success "Build finalizado em: $(date)"
