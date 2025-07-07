# Interactive Menu System

ComputerTools provides a user-friendly interactive menu system that allows you to navigate and execute commands through a guided interface, making it easier to discover and use all available functionality.

## 🚀 Quick Start

Launch the interactive menu by running ComputerTools without any arguments:

```bash
./exe/ComputerTools
```

This will present you with a main menu showing all available commands:

```
🚀 ComputerTools - Select a command:
  Blueprint - Manage code blueprints with AI-enhanced metadata and vector search capabilities
  Deepgram - Parse and analyze Deepgram JSON output with AI-enhanced insights  
  Example - An example command that generates a story based on the command line arguments
  Exit
```

## 🎯 How It Works

### Main Menu Navigation

1. **Command Selection**: Use arrow keys to navigate and Enter to select
2. **Command Categories**: Each selection takes you to a submenu with specific operations
3. **Guided Parameters**: Interactive prompts collect required parameters
4. **Seamless Return**: After execution, you return to the menu automatically

### Blueprint Operations

When you select "Blueprint", you'll see:

```
📋 Blueprint - Choose operation:
  Submit new blueprint
  List all blueprints
  Browse blueprints interactively
  View specific blueprint
  Edit blueprint
  Search blueprints
  Export blueprint
  Configuration
  Back to main menu
```

Each operation guides you through parameter collection:

- **Submit**: File path or code string, auto-description options
- **View**: Blueprint ID, format options, AI analysis toggle
- **Search**: Query string, result limit
- **Export**: Blueprint ID, optional output file path

### Deepgram Operations

The Deepgram submenu provides:

```
🎙️ Deepgram - Choose operation:
  Parse JSON output
  Analyze with AI insights
  Convert to different format
  Configuration
  Back to main menu
```

Parameter collection includes:

- **Parse/Convert**: JSON file path, output format, console/file output options
- **Analyze**: JSON file path, interactive mode, console output options

### Example Command

Demonstrates the system with a simple story generation that showcases:
- Command execution
- Colored output
- User interaction (press any key to continue)
- Menu return

## 🔧 Features

### Error Handling

- **File Validation**: Checks if JSON files exist before processing
- **Parameter Validation**: Ensures required parameters are provided
- **Graceful Failures**: User-friendly error messages with menu return
- **Exception Handling**: Comprehensive error catching with context

### User Experience

- **Colorized Output**: Color-coded messages for better readability
- **Clear Navigation**: "Back to main menu" options in all submenus
- **Interactive Prompts**: Yes/No questions and format selections
- **Parameter Memory**: Remembers choices within session

### Integration

- **Command Compatibility**: All interactive operations execute the same underlying commands
- **Option Passing**: Properly constructs and passes command options
- **Return Values**: Handles command results and menu flow control

## 🛠️ Advanced Usage

### Debug Mode

Enable detailed logging to troubleshoot menu behavior:

```bash
COMPUTERTOOLS_DEBUG=true ./exe/ComputerTools
```

Debug output includes:

```
🔍 DEBUG: Building main menu with commands: ["blueprint", "deepgram", "example"]
🔍 DEBUG: Choice selected: "blueprint" (String)
🔍 DEBUG: Handling command: blueprint
🔍 DEBUG: Looking for command: "blueprint"
🔍 DEBUG: Command found: YES
🔍 DEBUG: Executing command handler for: blueprint
🔍 DEBUG: Entering handle_blueprint_command
```

### CLI Compatibility

The interactive menu system is completely optional:

```bash
# Traditional CLI usage still works
./exe/ComputerTools blueprint submit my_file.rb
./exe/ComputerTools deepgram parse transcript.json markdown
./exe/ComputerTools help

# Interactive menu only launches with no arguments
./exe/ComputerTools
```

## 🏗️ Architecture

### MenuCommand Class

The interactive system is implemented as a separate `MenuCommand` class:

- **Modular Design**: Doesn't interfere with existing CLI commands
- **TTY Integration**: Uses `tty-prompt` for interactive elements
- **Command Delegation**: Directly instantiates and calls command objects
- **Flow Control**: Manages menu navigation and return values

### Menu Flow

```
Main Menu → Command Selection → Submenu → Parameter Collection → Execution → Return to Menu
```

### Error Boundaries

Each level has error handling:

- **Menu Level**: Catches menu system errors
- **Command Level**: Catches command execution errors  
- **Parameter Level**: Validates user input
- **System Level**: Handles missing dependencies

## 🚦 Troubleshooting

### Common Issues

**Menu not appearing**: 
- Ensure `tty-prompt` gem is installed: `bundle install`
- Check Ruby version compatibility

**Debug mode not working**:
- Use exact syntax: `COMPUTERTOOLS_DEBUG=true ./exe/ComputerTools`
- Ensure environment variable is exported if using in scripts

**Command execution failures**:
- Enable debug mode to see detailed execution flow
- Check that underlying commands work in traditional CLI mode
- Verify file paths and parameters are correct

### Dependencies

The interactive menu requires:

- **tty-prompt**: Interactive prompts and menus
- **colorize**: Colored output (already included)
- **Ruby 2.7+**: Modern Ruby features

## 🎨 Customization

The menu system is designed for easy extension:

### Adding New Commands

1. Create command class inheriting from `BaseCommand`
2. Add to `Commands` module
3. Menu system auto-discovers new commands

### Adding New Subcommands

1. Add case to command's `execute` method
2. Add menu choice in interactive handler
3. Create parameter collection logic

### Styling

Modify colors and emojis in `MenuCommand`:

```ruby
# Main menu styling
@prompt.select("🚀 ComputerTools - Select a command:".colorize(:cyan))

# Debug output styling  
debug_log("Message")  # Uses magenta color

# Error styling
puts "❌ Error message".colorize(:red)
```

The interactive menu system makes ComputerTools more accessible while maintaining full CLI compatibility for automation and scripting needs.