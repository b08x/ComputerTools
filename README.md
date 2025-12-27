# **ComputerTools**

A comprehensive, modular Ruby CLI toolkit built on the **Sublayer** framework. ComputerTools provides AI-enhanced utilities for software development, content extraction, system maintenance, and automated reporting.

## **🚀 Overview**

ComputerTools leverages the power of Large Language Models (LLMs) via RubyLLM and the Sublayer framework to turn standard CLI tasks into intelligent workflows. Unlike static scripts that perform rigid operations, ComputerTools injects semantic understanding into your terminal commands.

It features a robust dependency injection container and a modular architecture allowing for easy extension. By decoupling business logic (Actions) from user interfaces (Commands) and external integrations (Wrappers), the toolkit ensures that adding new AI capabilities or swapping underlying tools is seamless and testable.

### **Key Capabilities**

* **AI Model Management**: Query and list available models from various providers (Gemini, Anthropic, OpenAI, etc.). This acts as a central registry to verify which LLMs are currently accessible for your generators.  
* **Intelligent Reporting**: Generate AI-summarized overviews of project status and file activity.  
  * **Project Context**: Instantly understand a new codebase by generating high-level architectural summaries.  
  * **Activity Logs**: Turn raw git diffs and file timestamps into readable, narrative reports about recent development progress.  
* **Content Extraction**: Wrappers for **Docling** and **Trafilatura** to parse documents and web content.  
  * **Docling Integration**: sophisticated parsing of complex document formats (PDF, DOCX) into machine-readable text.  
  * **Trafilatura Integration**: Efficiently scrapes main text from web pages, stripping away boilerplate navigation and ads to feed clean context into your AI agents.  
* **System & Config Management**: Integrations for **Restic** (backups) and **YADM** (dotfiles analysis).  
  * **Restic**: automate interactions with your encrypted backup repositories.  
  * **YADM**: Analyze and manage your dotfiles across different environments using AI to detect configuration drift or improvements.  
* **Interactive Menu**: A TTY-based interactive menu for easy navigation of tools, perfect for users who prefer a guided UI over memorizing specific CLI flags.

## **🛠️ Installation**

Prerequisites: Ensure you have a recent version of Ruby installed on your system.

git clone \[<https://github.com/yourusername/ComputerTools.git\>](<https://github.com/yourusername/ComputerTools.git>)  
cd ComputerTools  
bundle install

*Note: After installation, you must configure your API keys (see the Configuration section) to enable the AI-powered features.*

## **💻 Usage**

You can use ComputerTools via the interactive menu or direct CLI commands. The toolkit is designed to be flexible, supporting both ad-hoc commands for power users and a guided experience for exploration.

### **Interactive Mode**

The easiest way to explore available tools is the interactive menu. This mode presents a navigable list of all registered commands, allowing you to select operations without needing to remember exact syntax.

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

Manage the internal configuration for the toolkit. This command assists in verifying that your environment is correctly set up to communicate with external APIs and local tools.

./exe/ComputerTools config

## **🧩 Architecture & Integrations**

ComputerTools is designed with a strict separation of concerns using a Dependency Injection container. This architecture allows specific implementations (like swapping a file system wrapper or an AI provider) to be changed without rewriting the core command logic.

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

To add a new tool, register it in the container and create the corresponding Command and Action. This standardized process ensures that every tool has logging, error handling, and dependency management built-in.

1. **Create Command**: Add to lib/ComputerTools/commands/ (defines the CLI interface).  
2. **Create Action**: Add to lib/ComputerTools/actions/ (defines the logic).  
3. **Register**: Update lib/ComputerTools/container/registrations.rb to make the new tool available to the DI container.

## **⚙️ Configuration**

Create a .env file in the root directory to configure your AI providers. The toolkit uses RubyLLM to unify requests, so you simply need to provide the keys for the services you wish to use.

\# Required for Google Gemini models  
GEMINI\_API\_KEY=your\_key\_here

\# Required for Anthropic Claude models  
ANTHROPIC\_API\_KEY=your\_key\_here

## **🤝 Contributing**

We welcome contributions to expand the toolkit's capabilities\!

1. Fork the repository.  
2. Create a feature branch.  
3. Ensure code follows the ComputerTools::Container pattern (Command \-\> Action \-\> Generator/Wrapper).  
4. Submit a pull request.

## **📄 License**

MIT License
