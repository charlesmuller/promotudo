#!/bin/bash

# ═══════════════════════════════════════════════════════════════════════════════
# Setup Script - Promotudo Project (PRODUCTION)
# Automatiza a primeira instalação da aplicação em ambiente de PRODUÇÃO
# Uso: bash setup-production.sh
# 
# ⚠️  REQUISITOS:
#     • As variáveis de ambiente devem estar configuradas ANTES de executar
#     • app/.env deve EXISTIR com valores corretos
#     • Backup do banco de dados deve ser feito ANTES
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
echo_header "VERIFICAÇÕES PRÉ-PRODUÇÃO"

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

# CRÍTICO: Verificar que .env existe e está configurado
if [ ! -f "app/.env" ]; then
    echo_error ".env não encontrado! Em produção, o .env DEVE estar configurado ANTES."
    echo_error "Por favor, copie seu .env.production para app/.env"
    exit 1
fi
echo_success "app/.env encontrado"

# Verificar variáveis críticas no .env
echo_info "Verificando variáveis críticas..."

check_env_var() {
    if ! grep -q "^$1=" app/.env; then
        echo_warning "Variável $1 não encontrada em app/.env"
        return 1
    fi
}

check_env_var "APP_KEY" || (echo_error "APP_KEY não configurada!"; exit 1)
check_env_var "DB_HOST" || (echo_error "DB_HOST não configurada!"; exit 1)
check_env_var "DB_DATABASE" || (echo_error "DB_DATABASE não configurada!"; exit 1)
check_error "DB_USERNAME" || (echo_error "DB_USERNAME não configurada!"; exit 1)

echo_success "Variáveis críticas configuradas"

# Confirmação manual
echo_warning "🚨 CONFIRMAÇÃO NECESSÁRIA 🚨"
echo "Você está prestes a fazer DEPLOY EM PRODUÇÃO"
echo ""
echo "Por favor, confirme:"
echo "1. ✓ Backup do banco de dados foi realizado"
echo "2. ✓ app/.env está configurado com valores CORRETOS"
echo "3. ✓ Você não vai corromper dados em produção"
echo ""
read -p "Digite 'sim' para continuar: " confirm

if [ "$confirm" != "sim" ]; then
    echo_error "Deploy cancelado."
    exit 1
fi

echo_success "Confirmação recebida. Prosseguindo com deploy..."

# Subir containers
echo_header "INICIANDO CONTAINERS DOCKER"

echo_info "Subindo containers..."
docker-compose up -d
echo_success "Containers iniciados"

# Aguardar banco de dados
echo_info "Aguardando banco de dados inicializar..."
sleep 10

# Instalar dependências PHP (ONLY production deps)
echo_header "INSTALANDO DEPENDÊNCIAS PHP"

echo_info "Executando 'composer install --no-dev --optimize-autoloader'..."
docker exec promotudo composer install --no-dev --optimize-autoloader
echo_success "Dependências PHP instaladas (otimizadas para produção)"

# NÃO instalar npm em produção - apenas usar assets pre-compilados
# Se precisar compilar, fazer ANTES em CI/CD

# Gerar Application Key (se não estiver configurado)
if ! grep -q "APP_KEY=base64:" app/.env; then
    echo_header "GERANDO APPLICATION KEY"
    echo_info "Gerando chave da aplicação..."
    docker exec promotudo php artisan key:generate
    echo_success "Application Key gerada"
else
    echo_header "APPLICATION KEY"
    echo_success "APP_KEY já configurada"
fi

# Executar migrações
echo_header "EXECUTANDO MIGRAÇÕES"

echo_warning "⚠️  Banco de dados será modificado!"
read -p "Confirme migrações digitando 'migrar': " migrate_confirm

if [ "$migrate_confirm" = "migrar" ]; then
    echo_info "Criando tabelas no banco de dados..."
    docker exec promotudo php artisan migrate --force
    echo_success "Migrações executadas com sucesso"
else
    echo_warning "Migrações puladas."
fi

# Ajustar permissões
echo_header "AJUSTANDO PERMISSÕES"

echo_info "Configurando permissões de storage..."
docker exec promotudo chown -R www-data:www-data /app/storage /app/bootstrap/cache
docker exec promotudo chmod -R 775 /app/storage /app/bootstrap/cache
echo_success "Permissões ajustadas"

# Otimizar cache para produção
echo_header "OTIMIZANDO PARA PRODUÇÃO"

echo_info "Limpando cache..."
docker exec promotudo php artisan cache:clear
echo_info "Gerando cache de configuração..."
docker exec promotudo php artisan config:cache
echo_info "Gerando cache de rotas..."
docker exec promotudo php artisan route:cache
echo_info "Gerando cache de views..."
docker exec promotudo php artisan view:cache
echo_success "Cache otimizado"

# Health check
echo_header "VERIFICAÇÃO DE SAÚDE"

echo_info "Verificando se aplicação está respondendo..."
if curl -f http://localhost:8080 > /dev/null 2>&1; then
    echo_success "✓ Aplicação está respondendo"
else
    echo_warning "⚠️  Aplicação pode estar com problemas"
fi

# Resumo final
echo_header "✅ DEPLOY EM PRODUÇÃO CONCLUÍDO!"

echo_success "Aplicação está rodando em produção!"
echo ""
echo_info "Informações importantes:"
echo "  • Nginx: http://localhost:8080"
echo "  • Logs: docker logs -f promotudo"
echo "  • Status: docker-compose ps"
echo ""
echo_warning "⚠️  LEMBRETE IMPORTANTE:"
echo "  • Não exponha PhpMyAdmin em produção"
echo "  • Configure SSL/TLS (HTTPS)"
echo "  • Configure backup automático de banco"
echo "  • Monitore logs regularmente"
echo "  • Mantenha dependências atualizadas"
echo ""

# Mostrar status dos containers
echo_info "Status dos containers:"
docker-compose ps

echo ""
echo_success "Deploy finalizado em: $(date)"
echo_info "Se tiver problemas, consulte os logs:"
echo "  docker logs -f promotudo"
echo "  docker logs -f promotudo-nginx"
echo "  docker logs -f promotudo-db"
