# Blueprint Manager

AI-enhanced code blueprint management with semantic search and automatic metadata generation.

## Overview

The Blueprint Manager is a comprehensive tool for storing, searching, and managing code blueprints with AI-powered intelligence. It integrates with a Rails server application that provides a web interface and API for blueprint management.

## Features

- 🤖 **AI-Generated Metadata**: Automatic names, descriptions, and categorization using Google Gemini
- 🔍 **Semantic Search**: Vector-powered similarity search across code blueprints  
- 📊 **Direct Database**: PostgreSQL with pgvector for efficient operations
- ✏️ **Smart Editing**: Delete-and-resubmit workflow ensures fresh embeddings
- 📤 **Export/Import**: Multiple format support with metadata preservation
- 🎯 **Interactive UI**: TTY-powered browsing and management interface

## Prerequisites

### Required Software

- Ruby 3.4+
- PostgreSQL with pgvector extension
- Google Gemini API key (for AI features)

### Blueprint Rails Server Setup

The Blueprint Manager requires a Rails server application for full functionality. Follow these steps to set up the blueprints server:

#### Installation Options

##### Option 1: Standard Setup

1. **Clone the blueprints repository:**

   ```bash
   git clone https://github.com/sublayerapp/blueprints
   cd blueprints
   ```

2. **Install dependencies:**

   ```bash
   bundle install
   ```

3. **Install PostgreSQL and pgvector:**

   ```bash
   # On macOS
   brew install postgres
   brew install pgvector  # if using postgres14
   ```

4. **Set up environment variables:**

   ```bash
   # AI Provider Configuration
   export GEMINI_API_KEY="your_gemini_api_key"
   # or for OpenAI
   export OPENAI_API_KEY="your_openai_api_key"
   ```

5. **Database setup:**

   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

6. **Generate CSS assets:**

   ```bash
   bin/rails tailwindcss:build
   ```

7. **Start the server:**

   ```bash
   bin/rails s
   ```

##### Option 2: Docker Compose Setup

For easier deployment, you can use Docker Compose:

1. **Clone and navigate to the repository:**

   ```bash
   git clone https://github.com/sublayerapp/blueprints
   cd blueprints
   ```

2. **Start services:**

   ```bash
   docker-compose up -d
   ```

3. **Access the application:**
   - Via Nginx proxy: `http://localhost`
   - Direct Rails access: `http://localhost:3000`

4. **Stop services when done:**

   ```bash
   docker-compose down
   ```

### ComputerTools Configuration

Once the Rails server is running, configure the Blueprint Manager:

```bash
# Configure the blueprint database connection
exe/ComputerTools blueprint config setup

# Set the required environment variables
export GEMINI_API_KEY="your_gemini_api_key"
export BLUEPRINT_DATABASE_URL="postgresql://user:pass@host:port/database"
```

## Usage

### Basic Operations

```bash
# Submit a code blueprint
exe/ComputerTools blueprint submit my_script.rb

# Search semantically
exe/ComputerTools blueprint search "authentication helper"

# Interactive browser
exe/ComputerTools blueprint browse

# View with AI analysis
exe/ComputerTools blueprint view 123 --analyze
```

### Advanced Workflows

```bash
# Submit with custom metadata
exe/ComputerTools blueprint submit app/models/user.rb --category "Models"

# Export blueprints
exe/ComputerTools blueprint export 42 user_model.rb

# Edit existing blueprint (triggers re-embedding)
exe/ComputerTools blueprint edit 42

# List all blueprints with filtering
exe/ComputerTools blueprint list --category "Authentication"
```

## Integration with Rails Server

### How It Works

1. **Blueprint Creation**: When you submit code via the ComputerTools CLI, it sends the code to the Rails server, which uses AI to generate descriptions and names, then creates vector embeddings.

2. **Semantic Search**: The CLI interfaces with the Rails server's vector search capabilities, powered by pgvector for efficient similarity matching.

3. **Web Interface**: The Rails server provides a web interface at `http://localhost:3000` for browsing and managing blueprints visually.

### API Endpoints

The Rails server exposes these key endpoints:

- `POST /api/v1/blueprints` - Create new blueprints
- `GET /api/v1/blueprints` - List and search blueprints
- `GET /api/v1/blueprints/:id` - Get specific blueprint
- `POST /api/v1/blueprint_variants` - Generate code variants

### Editor Plugins

For enhanced workflow, install editor plugins:

- **Vim**: [blueprints.vim](https://github.com/sublayerapp/blueprints.vim)
- **VSCode**: [blueprints.code](https://github.com/sublayerapp/blueprints.code)
- **IntelliJ**: [blueprints.idea](https://github.com/sublayerapp/blueprints.idea)
- **SublimeText**: [blueprints_subl](https://github.com/sublayerapp/blueprints_subl)

## Configuration

### Blueprint Database Configuration

The Blueprint Manager uses YAML configuration files located in `lib/ComputerTools/config/`:

```yaml
# Example: blueprints.yml
database:
  url: "postgresql://localhost/blueprints_development"

ai:
  provider: "gemini"
  model: "text-embedding-004"

features:
  auto_description: true
  auto_categorize: true
  improvement_analysis: true
```

### Environment Variables

```bash
# AI Provider Keys
GEMINI_API_KEY=your_gemini_key
OPENAI_API_KEY=your_openai_key

# Database Connections
BLUEPRINT_DATABASE_URL=postgresql://...

# Editor Preferences  
EDITOR=vim
VISUAL=code
```

## Performance & Reliability

- **Direct Database Access**: No HTTP overhead for local operations
- **Vector Embeddings**: Efficient semantic search with pgvector
- **Connection Pooling**: Optimized database connections
- **Error Handling**: Graceful degradation and helpful error messages

## Troubleshooting

### Common Issues

1. **Database Connection Errors**:
   - Ensure PostgreSQL is running
   - Verify pgvector extension is installed
   - Check database URL configuration

2. **AI Provider Errors**:
   - Verify API key is set correctly
   - Check internet connection
   - Ensure sufficient API quota

3. **Rails Server Issues**:
   - Confirm server is running on expected port
   - Check for port conflicts
   - Verify database migrations are up to date

### Getting Help

For additional support:

- Join the [Sublayer Discord](https://discord.gg/sjTJszPwXt)
- Check the [Sublayer documentation](https://github.com/sublayerapp/sublayer)
- Review the blueprints project [README](https://github.com/sublayerapp/blueprints)
