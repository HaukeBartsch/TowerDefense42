# Tower Defense Game

A rectangular arena with tower positions on the arena border. Enemies are moving across the arena using billiard ball physics.

[Link to Game Page](https://haukebartsch.github.io/TowerDefense42/)


## How to start the project with claude code?


```
export ANTHROPIC_AUTH_TOKEN=lmstudio
export ANTHROPIC_BASE_URL=http://localhost:1234
export GODOT_PATH=/Applications/Godot.app/Contents/MacOS/godot
export DEBUG=true

# Setup the mcp server
# claude mcp add godot -- npx @coding-solo/godot-mcp
# claude mcp add godot -e GODOT_PATH=/Applications/Godot.app/Contents/MacOS/godot -e DEBUG=true -- npx @coding-solo/godot-mcp

claude --model openai/qwen3-coder-30b

```