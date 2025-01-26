# Dad Knows Siege Best

A RTS game à la Total War, where you control your army through natural language! Created for the 2025 Mistral AI Game Jam, with the theme `"You don't control the character."`

## 🎮 Concept

In this Total War-inspired RTS, you play as the ghost of a veteran warrior watching over your strategically-challenged son during a siege battle. At the beginning of each assault, you provide tactical advice through natural language, which gets parsed into an actionable battle algorithm.

## 🔧 Technical Innovation

The game features a novel approach to unit control:

1. **Natural Language Processing**: Uses Mistral AI to interpret tactical advice into structured commands
2. **Custom AST Parser**: Implements a robust Abstract Syntax Tree parser (`godotproject/llm_call.gd`) that converts LLM output into game logic
3. **Real-time Strategy**: Units respond to parsed commands, taking cover, utilizing power-ups (speed-up, healing, shields), and avoiding cannon fire

### How it Works

1. Player provides tactical advice through text input
2. Mistral AI processes the input and generates structured command logic
3. Our custom AST parser (`llm_call.gd`) interprets these commands into game actions
4. Units execute the interpreted commands in real-time

## 🛠️ Key Components

- `llm_call.gd`: The heart of the system, featuring:
  - Custom AST parser for interpreting LLM-generated logic
  - Integration with Mistral AI API
  - Real-time command processing and execution
  - Condition-based action system for unit behavior

## 🚀 Technologies Used

- Godot Engine
- Mistral AI API
- Eleven Labs API (for voice feedback)
- Custom AST parsing system

## 🎯 Challenges Overcome

The main technical challenge was working around browser limitations for code evaluation. Instead of using Godot's `eval()`, we implemented a custom AST parser that safely interprets LLM-generated commands while maintaining security in the web build.

## 🎨 Credits

Created for the Mistral AI Game Jame by:
- Antoine G.
- Antoine V.
- Brecht L.
- Tristan D.
- Ruben G.
- Philippe S.

## 🔗 Try It Out

[Link to playable version](https://huggingface.co/spaces/Mistral-AI-Game-Jam/equipe-11-2/tree/main)
