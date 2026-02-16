# ComputerTools

A modular Ruby CLI toolkit built on Sublayer. It provides AI-enhanced utilities for software development, content extraction, system maintenance, and automated reporting.

## **🚀 Overview**

ComputerTools uses RubyLLM and the Sublayer framework to create intelligent CLI workflows. Unlike static scripts that perform rigid operations, it injects semantic understanding into your terminal commands.

A robust dependency injection container powers the toolkit, enabling easy extension. By decoupling business logic (Actions) from user interfaces (Commands) and external integrations (Wrappers), the toolkit ensures that adding new AI capabilities or swapping underlying tools stays seamless and testable.

### Key Capabilities

* **AI Model Management**: View available LLMs from various providers (Gemini, Anthropic, OpenAI, etc.). This acts as a central registry to verify which LLMs are currently accessible.
* **Project Context**: Generate architectural summaries to understand a new codebase instantly.
* **Activity Logs**: Turn raw git diffs and file timestamps into readable, narrative reports about recent development progress.
* **Docling Integration**: Parse PDFs and DOCX into machine-readable text.
* **Trafilatura Integration**: Extract clean text from web pages, stripping boilerplate and ads.
* **Restic**: Run backup commands for encrypted repositories.
* **YADM**: Analyze dotfiles across environments using AI to detect configuration drift.
* **Interactive Menu**: A TTY-based selectable list for navigating all available commands.

## **🛠️ Installation**

Prerequisites: Ensure you have a recent version of Ruby installed on your system.

git clone \[<https://github.com/yourusername/ComputerTools.git\>](<https://github.com/yourusername/ComputerTools.git>)  
cd ComputerTools  
bundle install

*Note: Configure your API keys (see the Configuration section) to enable AI-powered features.*

## **💻 Usage**

Use ComputerTools via the interactive menu or direct CLI commands. The toolkit stays flexible, supporting both ad-hoc commands for power users and a guided experience for exploration.

### **Interactive Mode**

The interactive menu displays available commands, letting you select operations without memorizing syntax.

./exe/ComputerTools  
\# or  
./exe/ComputerTools menu

### **Core Commands**

Based on the latest codebase, the following commands are available:

#### **1\. AI Model Management**

View available LLMs configured in your environment. This is essential for debugging API connections or choosing the right model for specific tasks (e.g., selecting a cheaper model for simple summaries or a reasoning model for complex code analysis).

./exe/ComputerTools list\_models  
\# Optionally filter by provider to narrow down the list  
./exe/ComputerTools list\_models \--provider google

#### **2\. Project Overview**

Generate a high-level overview of the current directory or project context using AI generation. This command scans your project structure and uses an LLM to generate a "Read Me" style introduction, explaining what the project does based on its file composition.

./exe/ComputerTools overview

#### **3\. Latest Changes & Activity**

Analyze file activity and recent changes. This is particularly useful for generating daily stand-up notes or drafting detailed commit messages by aggregating scattered file modifications into a coherent narrative.

./exe/ComputerTools latest\_changes

#### **4\. Configuration**

Manage the internal configuration for the toolkit. This command verifies your environment is correctly set up to communicate with external APIs and local tools.

./exe/ComputerTools config

## **🧩 Architecture & Integrations**

ComputerTools uses a Dependency Injection container to separate concerns. This architecture lets you swap implementations (file system wrappers, AI providers) without rewriting command logic.

### **Directory Structure**

The codebase is organized to promote modularity:

* **actions/**: Business logic units (e.g., yadm\_analysis\_action, display\_available\_models\_action). These orchestrate the flow of data between wrappers and generators.  
* **commands/**: Thor-based CLI entry points. These handle user input, argument parsing, and output formatting, delegating the actual work to Actions.  
* **generators/**: AI-prompting logic (e.g., file\_activity\_report\_generator, overview\_generator). These classes define the specific prompts and expected output schemas sent to the LLM.  
* **wrappers/**: Interfaces for external tools, providing a Ruby-native way to interact with system binaries:  
  * **Docling**: For advanced document parsing and structure extraction.  
  * **Trafilatura**: For web scraping and main text extraction.  
  * **Restic**: For interacting with Restic backup repositories and snapshots.  
  * **Git**: For version control operations and diff analysis.  
  * **YADM**: For managing and analyzing dotfiles configurations.

### **Adding New Tools**

Add a new tool by registering it in the container and creating the corresponding Command and Action. This process ensures every tool has logging, error handling, and dependency management built-in.

1. **Create Command**: Add to `lib/ComputerTools/commands/` to define the CLI interface.
2. **Create Action**: Add to `lib/ComputerTools/actions/` to define the logic.
3. **Register**: Update `lib/ComputerTools/container/registrations.rb` to make the tool available.

## **⚙️ Configuration**

Create a `.env` file in the root directory to configure your AI providers. RubyLLM unifies requests, so provide keys only for the services you use.

\# Required for Google Gemini models  
GEMINI\_API\_KEY=your\_key\_here

\# Required for Anthropic Claude models  
ANTHROPIC\_API\_KEY=your\_key\_here

## **🤝 Contributing**

We welcome contributions!

1. Fork the repository.
2. Create a feature branch.
3. Follow the Command → Action → Generator pattern in `lib/ComputerTools/`.
4. Submit a pull request.

## **📄 License**

MIT License
