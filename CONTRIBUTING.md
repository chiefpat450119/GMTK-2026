Bootstrap / Setup: 
- Please install Godot 4.7.1. 
- Please read the [README.md](README.md) to setup your local development environment before contributing. 
 
Code Format:
Use built-in VSCode or similar IDE formatters to format your code (should adhere to official GDScript [format](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

Code Design: 
- Prioritize Type Safety (use inferred typing or static typing)
- Connect Signals in Code (rather than in Inspector)
- Use exports to reference other nodes in the tree (instead of getting nodes by name)
- For UI try to use Containers (better for scaling)

Git Commits: 
Follow [this](https://www.conventionalcommits.org/en/v1.0.0/#:~:text=Commits%20MUST%20be%20prefixed%20with,to%20your%20application%20or%20library) convention for commit names. (not super strict)

Feature development guide:
1. Pull latest main
2. Branch off main (or someone else's branch if you're working on top of their feature)
3. Make your changes
4. Create a new scene uneder `scenes/test` to test (if applicable); you can add other components into this scene (player, enemyspawner, etc.) Feel free to copy other people's test scenes just give it a distinct name.
5. Push and open a PR on github

Pull Request (PR) Guideline:
1. Always open a new PR for a new feature
2. Always include a useful description (keep it short and readable)
3. Keep the PRs small so we can review them fast.
4. Do not change scenes other people work on. Test in your own scenes.
5. Test changes manually before merging.
6. Document your public methods if you think other people will rely on them.
7. Ping in discord to get your PR reviewed.
8. Let others know if you think they should be aware of changes you just merged to main.

