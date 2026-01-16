#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# Setup Script - Promotudo Project (DEVELOPMENT)
# Automatiza a primeira instalação da aplicação em ambiente de DESENVOLVIMENTO
# Uso: bash setup.sh
# 
# ⚠️  NÃO USE EM PRODUÇÃO - Veja setup-production.sh
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

echo_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

echo_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Verificações iniciais
echo_header "VERIFICAÇÕES INICIAIS"

if ! command -v docker &> /dev/null; then
    echo_error "Docker não encontrado. Instale Docker antes de continuar."
    exit 1
fi
echo_success "Docker instalado"

if ! command -v docker-compose &> /dev/null; then
    echo_error "Docker Compose não encontrado. Instale Docker Compose antes de continuar."
    exit 1
fi
echo_success "Docker Compose instalado"

# Verificar estrutura do projeto
if [ ! -f "docker-compose.yml" ]; then
    echo_error "docker-compose.yml não encontrado. Execute o script na raiz do projeto."
    exit 1
fi
echo_success "Estrutura do projeto validada"

# Criar .env se não existir
echo_header "CONFIGURAÇÃO DE AMBIENTE"

if [ ! -f "app/.env" ]; then
    if [ ! -f "app/.env.example" ]; then
        echo_error "app/.env.example não encontrado!"
        exit 1
    fi
    echo_info "Criando app/.env a partir de app/.env.example..."
    cp app/.env.example app/.env
    echo_success "app/.env criado"
    echo_warning "Edite app/.env com suas configurações específicas se necessário"
else
    echo_success "app/.env já existe"
fi

# Subir containers
echo_header "INICIANDO CONTAINERS DOCKER"

echo_info "Subindo containers..."
docker-compose up -d
echo_success "Containers iniciados"

# Aguardar banco de dados
echo_info "Aguardando banco de dados inicializar..."
sleep 5

# Instalar dependências PHP
echo_header "INSTALANDO DEPENDÊNCIAS PHP"

echo_info "Executando 'composer install'..."
docker exec promotudo composer install
echo_success "Dependências PHP instaladas"

# Instalar dependências Node
echo_header "INSTALANDO DEPENDÊNCIAS NODE"

echo_info "Executando 'npm install'..."
docker exec promotudo npm install
echo_success "Dependências Node instaladas"

# Gerar Application Key
echo_header "GERANDO APPLICATION KEY"

echo_info "Gerando chave da aplicação..."
docker exec promotudo php artisan key:generate
echo_success "Application Key gerada"

# Executar migrações
echo_header "EXECUTANDO MIGRAÇÕES"

echo_info "Criando tabelas no banco de dados..."
docker exec promotudo php artisan migrate --force
echo_success "Migrações executadas com sucesso"

# Ajustar permissões
echo_header "AJUSTANDO PERMISSÕES"

echo_info "Configurando permissões de storage..."
docker exec promotudo chown -R www-data:www-data /app/storage /app/bootstrap/cache
docker exec promotudo chmod -R 775 /app/storage /app/bootstrap/cache
echo_success "Permissões ajustadas"

# Compilar assets
echo_header "COMPILANDO ASSETS"

echo_info "Executando 'npm run build'..."
docker exec promotudo npm run build
echo_success "Assets compilados"

# Limpar cache
echo_header "LIMPANDO CACHE"

echo_info "Limpando cache da aplicação..."
docker exec promotudo php artisan cache:clear
docker exec promotudo php artisan config:cache
echo_success "Cache limpado"

# Resumo final
echo_header "✅ SETUP CONCLUÍDO COM SUCESSO!"

echo_success "Seu ambiente está pronto para uso!"
echo_info "Acesse a aplicação em: http://localhost:8080"
echo_info "PhpMyAdmin em: http://localhost:8081"
echo_info "Nginx logs: docker logs -f promotudo-nginx"
echo_info "PHP logs: docker logs -f promotudo"
echo ""
echo_info "Próximos passos:"
echo "  1. Abra http://localhost:8080 no seu navegador"
echo "  2. Se necessário, edite app/.env com suas configurações"
echo "  3. Para parar: docker-compose down"
echo "  4. Para reiniciar: docker-compose up -d"
echo ""

# Mostrar status dos containers
echo_info "Status dos containers:"
docker-compose ps

echo ""
echo_success "Setup finalizado em: $(date)"
