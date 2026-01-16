# Promotudo

Uma aplicação moderna de gerenciamento construída com **Laravel 12** e **Vite**, com interface responsiva usando **Tailwind CSS**.

## 📋 Sobre o Projeto

**Promotudo** é uma aplicação web full-stack desenvolvida com:
- **Backend**: Laravel 12 com PHP 8.2
- **Frontend**: Vite com Tailwind CSS v4
- **Database**: MariaDB 11
- **Web Server**: Nginx 1.25
- **Containerização**: Docker & Docker Compose

## 🛠 Requisitos do Sistema

Para desenvolvimento local, você precisa de:

- **Docker** (v24+)
- **Docker Compose** (v2+)
- **Git**
- **Node.js** (v18+) - apenas se preferir rodar fora do Docker
- **PHP 8.2+** - apenas se preferir rodar fora do Docker

## 🚀 Guia de Instalação e Desenvolvimento

### 1. Clone o Repositório

```bash
git clone <seu-repositorio>
cd promotudo
```

### 2. Configure as Permissões (Linux/Mac)

Se necessário, ajuste as permissões da pasta `app`:

```bash
sudo chown -R $USER:$USER ./app
chmod -R 755 ./app
```

### 3. Inicie os Containers Docker

```bash
docker-compose up -d
```

Este comando irá:
- Construir a imagem PHP 8.2-FPM
- Iniciar o serviço PHP-FPM (porta 9000)
- Iniciar o Nginx (porta 8080)
- Iniciar o MariaDB (porta 3306)
- Criar a rede interna `promotudo-network`

### 4. Instale as Dependências do Backend

```bash
docker exec promotudo composer install
```

### 5. Configure o Arquivo `.env`

```bash
cd app
cp .env.example .env
```

Edite o `.env` se necessário. Para MariaDB via Docker, configure:

```bash
DB_CONNECTION=mysql
DB_HOST=promotudo-db
DB_PORT=3306
DB_DATABASE=promotudo
DB_USERNAME=promotudo
DB_PASSWORD=promotudo
```

### 6. Gere a Application Key

```bash
docker exec promotudo php artisan key:generate
```

### 7. Execute as Migrações do Banco de Dados

```bash
docker exec promotudo php artisan migrate
```

### 8. Instale as Dependências do Frontend

```bash
docker exec promotudo npm install
```

### 9. Compile os Assets

```bash
docker exec promotudo npm run build
```

## 📍 Acessar a Aplicação

Após completar os passos acima, acesse:

- **Aplicação**: http://localhost:8080
- **PHP-FPM**: localhost:9000
- **MariaDB**: localhost:3306

## 🔧 Desenvolvimento Local

### Modo Watch (Desenvolvimento com Hot Reload)

Para desenvolvimento, use o modo watch que monitora mudanças em tempo real:

```bash
docker exec -it promotudo npm run dev
```

Em outro terminal, você pode acompanhar os logs:

```bash
docker logs -f promotudo-nginx
```

### Executar Comandos Artisan

Qualquer comando Laravel pode ser executado via Docker:

```bash
# Criar modelo com migration
docker exec promotudo php artisan make:model Post -m

# Criar controller
docker exec promotudo php artisan make:controller PostController

# Limpar cache
docker exec promotudo php artisan cache:clear
```

### Executar Testes

```bash
docker exec promotudo php artisan test
```

### Acessar o Container em Tempo Real

Para debugging ou investigação:

```bash
docker exec -it promotudo bash
```

## 📁 Estrutura do Projeto

```
promotudo/
├── app/                          # Código-fonte Laravel
│   ├── app/
│   │   ├── Http/Controllers/    # Controllers
│   │   ├── Models/              # Modelos Eloquent
│   │   └── Providers/           # Service Providers
│   ├── bootstrap/               # Bootstrap da aplicação
│   ├── config/                  # Arquivos de configuração
│   ├── database/
│   │   ├── factories/           # Factories para testes
│   │   ├── migrations/          # Migrações do BD
│   │   └── seeders/             # Seeders
│   ├── public/                  # Arquivo público (index.php)
│   ├── resources/
│   │   ├── css/                 # Estilos CSS/Tailwind
│   │   ├── js/                  # JavaScript
│   │   └── views/               # Blade templates
│   ├── routes/                  # Definições de rotas
│   ├── storage/                 # Armazenamento de arquivos
│   ├── tests/                   # Testes da aplicação
│   ├── .env                     # Variáveis de ambiente
│   └── package.json             # Dependências Node.js
├── docker/                      # Configurações Docker
│   └── nginx/
│       └── default.conf         # Configuração do Nginx
├── docker-compose.yml           # Definição dos serviços
└── Dockerfile                   # Imagem PHP-FPM
```

## 🗄️ Banco de Dados

O projeto usa **MariaDB 11** com as seguintes configurações padrão:

- **Host**: `promotudo-db` (via Docker)
- **Porta**: 3306
- **Database**: `promotudo`
- **Usuário**: `promotudo`
- **Senha**: `promotudo`
- **Root Password**: `root`

### Conectar ao BD

```bash
docker exec -it promotudo-db mysql -u promotudo -p promotudo
```

## 🎨 Frontend

O projeto usa:

- **Vite**: Build tool moderno e rápido
- **Tailwind CSS v4**: Framework CSS utilitário
- **Laravel Vite Plugin**: Integração perfeita com Laravel

### Estrutura de Assets

```
resources/
├── css/
│   └── app.css                  # Arquivo Tailwind principal
├── js/
│   ├── app.js                   # Entry point JavaScript
│   └── bootstrap.js             # Configurações do Bootstrap
└── views/
    └── welcome.blade.php        # View de boas-vindas
```

## 📦 Dependências Principais

### Backend

```
- laravel/framework: ^12.0
- laravel/tinker: ^2.10.1
```

### Frontend

```
- vite: ^7.0.7
- laravel-vite-plugin: ^2.0.0
- tailwindcss: ^4.0.0
- @tailwindcss/vite: ^4.0.0
- axios: ^1.11.0
```

### Desenvolvimento

```
- phpunit/phpunit: ^11.5.3
- laravel/pint: ^1.24
- laravel/sail: ^1.41
```

## 🔍 Troubleshooting

### Erro: "Permission denied" ao salvar arquivos

Se não conseguir salvar arquivos na pasta `app`, execute:

```bash
sudo chown -R $USER:$USER ./app
chmod -R 755 ./app
```

### Erro: "Connection refused" no banco de dados

Verifique se o container MariaDB está rodando:

```bash
docker-compose ps
```

Se não estiver, reinicie:

```bash
docker-compose restart promotudo-db
```

### Porta já em uso

Se a porta 8080 ou 3306 estiver em uso, edite o `docker-compose.yml`:

```yaml
ports:
  - "SUA_PORTA:80"  # Para Nginx
  - "SUA_PORTA:3306"  # Para MariaDB
```

### Limpar dados Docker

Para resetar o banco de dados e começar do zero:

```bash
docker-compose down -v
docker-compose up -d
docker exec promotudo php artisan migrate
```

## 🛑 Parar a Aplicação

```bash
docker-compose down
```

Para parar e remover todos os dados (volumes):

```bash
docker-compose down -v
```

## 📝 Úteis

### Abrir logs em tempo real

```bash
# Logs do container PHP
docker logs -f promotudo

# Logs do Nginx
docker logs -f promotudo-nginx

# Logs do MariaDB
docker logs -f promotudo-db
```

### Executar comando único no container

```bash
docker exec promotudo [COMANDO]
```

### Entrar no container interativamente

```bash
docker exec -it promotudo bash
```

## 🤝 Contribuindo

1. Crie uma branch para sua feature (`git checkout -b feature/MinhaFeature`)
2. Commit suas mudanças (`git commit -m 'Add MinhaFeature'`)
3. Push para a branch (`git push origin feature/MinhaFeature`)
4. Abra um Pull Request

## 📄 Licença

MIT License - veja o arquivo LICENSE para detalhes.

## 👤 Autor

Desenvolvido com ❤️ para Promotudo

---

**Última atualização**: Janeiro 2026
**Versão do Laravel**: 12.x
**Versão do PHP**: 8.2
