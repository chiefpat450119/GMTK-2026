Bootstrap / Setup: 
- Please install Godot 4.7.1. 
- Please read the [README.md](README.md) to setup your local development environment before contributing. 
 
Code Format:
Use built-in VSCode or similar IDE formatters to format your code (should adhere to official GDScript [format](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html)

Code Design: 
- Prioritize Type Safety (use inferred typing or static typing)
- Connect Signals in Code (rather than in Inspector)
- Remember to disconnect Signals (if relevant)
- Use exports (instead of getting nodes by name)
- For UI use Containers

Git Commits: 
Follow [this](https://www.conventionalcommits.org/en/v1.0.0/#:~:text=Commits%20MUST%20be%20prefixed%20with,to%20your%20application%20or%20library) convention for commit names.

Pull Request (PR) Guideline:
1. Always open a new PR for a new feature
2. Always include a useful description
3. Keep the PRs small so we can review them fast.
4. Do not change scenes other people work on. Test your own scenes.
5. Test changes manually before merging.
6. Document your public methods if you think other people will rely on them.
7. Ping in discord to get your PR reviewed. 

