# ✨ SpecGen ✨

🚀 **Turn your brilliant ideas into detailed specs with AI!** 🚀

SpecGen is a fun CLI tool that uses OpenAI's GPT-4o to help you develop comprehensive specifications through interactive conversation. Perfect for developers, product managers, or anyone who needs to transform vague ideas into actionable plans!

## 🎯 Features

- 💡 Interactive Q&A to refine your ideas
- 🤖 Powered by OpenAI's GPT-4o
- 📝 Generates detailed markdown specifications
- 🌈 Colorful and friendly CLI interface
- 📂 Load ideas directly from files
- 🔍 Verbose mode for debugging

## 🚀 Getting Started

### Prerequisites

- macOS 15 or later
- Swift 5.9+
- OpenAI API key

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/specgen.git
cd specgen

# Build the project
swift build -c release

# Move binary to a location in your PATH (optional)
cp .build/release/specgen /usr/local/bin/
```

### Set Your OpenAI API Key

```bash
# Add to your environment variables
export OPENAI_API_KEY="your-api-key-here"

# Or create a .env file in the directory where you run specgen
echo "OPENAI_API_KEY=your-api-key-here" > .env
```

## 🎮 Usage

```bash
# Interactive mode - type your idea at the prompt
specgen

# Load idea from a file
specgen --idea-file path/to/your/idea.txt

# Enable verbose logging
specgen --verbose
```

During the conversation:
- Answer each question from the AI to refine your spec
- Type `/finish` when you're ready to generate the final spec
- Your spec will be saved as a markdown file with a timestamp

## 🛠️ Development

This project uses Swift Package Manager for dependencies:
- ArgumentParser for CLI interface
- Foundation for core functionality

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- OpenAI for their amazing API
- All contributors who make this project better!

---

Made with ❤️ by developers, for developers